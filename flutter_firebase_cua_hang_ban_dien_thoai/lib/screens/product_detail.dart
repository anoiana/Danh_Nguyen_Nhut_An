import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart' if (dart.library.html) 'package:web_socket_channel/html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/cart_service.dart';
import 'cart_product.dart';

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

const double kWebAppBreakpoint = 800.0;

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int selectedVariantIndex = 0;
  double selectedRating = 5.0;
  late List<String> imageUrls;
  List<Map<String, dynamic>> variants = [];
  bool isLoading = true;
  List<Map<String, dynamic>> comments = [];
  String uid = 'unknown';
  double averageRating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  bool isExpanded = false;
  bool isAddingToCart = false;
  int quantity = 1;
  int cartItemCount = 0; // Biến theo dõi số lượng trong giỏ
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String productId = "";
  String userName = " ";
  Set<String> deletingComments = {};

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  bool _isWebSocketConnected = false;
  Timer? _reconnectTimer;

  bool _currentUserHasReviewed = false;
  Map<String, dynamic>? _currentUserReview;

  @override
  void initState() {
    super.initState();
    productId = widget.product['id'] ?? '';
    imageUrls = List<String>.from(widget.product['image'] ?? []);

    if (productId.isEmpty) {
      print("Critical Error: Product ID is empty. Cannot initialize screen properly.");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (productId.isNotEmpty) {
        fetchVariants();
        loadRatings();
        _connectWebSocket();
      }
      getCurrentUser();
      loadUserName();
      loadCartItemCount(); // Load số lượng từ giỏ khi khởi động
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    print("ProductDetailsScreen disposed, WebSocket connection closed.");
    super.dispose();
  }

  void _connectWebSocket() {
    if (productId.isEmpty || _isWebSocketConnected && _channel != null) return;

    // final wsUrl = Uri.parse('ws://192.168.1.83:8765/ws/comments/$productId');
    // final wsUrl = Uri.parse('ws://nhutan-production.up.railway.app/ws/comments/$productId');
    final wsUrl = Uri.parse('wss://nhutan-production.up.railway.app/ws/comments/$productId');
    print("Attempting to connect to WebSocket: $wsUrl (kIsWeb: $kIsWeb)");

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _isWebSocketConnected = true;
      print("WebSocket connection initiated to $wsUrl");

      _channelSubscription = _channel!.stream.listen(
            (message) {
          if (!mounted) return;
          try {
            final decodedMessage = jsonDecode(message);
            _handleWebSocketMessage(decodedMessage);
          } catch (e) {
            print("Error decoding WebSocket message: $e");
          }
        },
        onDone: () {
          if (!mounted) return;
          print("WebSocket connection closed by server.");
          _isWebSocketConnected = false;
          if (!kIsWeb) _scheduleReconnect();
          else print("Auto-reconnect disabled for web platform.");
        },
        onError: (error) {
          if (!mounted) return;
          print("WebSocket error: $error");
          _isWebSocketConnected = false;
          if (!kIsWeb) _scheduleReconnect();
          else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("WebSocket connection error: $error")),
            );
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (!mounted) return;
      print("Failed to connect to WebSocket: $e");
      _isWebSocketConnected = false;
      if (!kIsWeb) _scheduleReconnect();
      else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initiate WebSocket: $e")),
        );
      }
    }
  }

  // void _connectWebSocket() {
  //   // final wsUrl = Uri.parse('wss://yourserver/ws/comments/$productId');
  //   final wsUrl = Uri.parse('wss://nhutan-production.up.railway.app/ws/comments/$productId');
  //   print("Attempting to connect to WebSocket: $wsUrl");
  //
  //   try {
  //     _channel = WebSocketChannel.connect(wsUrl);
  //     _isWebSocketConnected = true;
  //     print("WebSocket connected successfully!");
  //
  //     _channelSubscription = _channel!.stream.listen(
  //           (message) {
  //         print("Received message from WebSocket: $message");
  //         // Xử lý message
  //       },
  //       onDone: () {
  //         print("WebSocket connection closed.");
  //         _isWebSocketConnected = false;
  //         // Thực hiện reconnect hoặc xử lý khi đóng
  //       },
  //       onError: (error) {
  //         print("WebSocket error: $error");
  //         _isWebSocketConnected = false;
  //         // Thực hiện reconnect hoặc xử lý lỗi
  //       },
  //     );
  //   } catch (e) {
  //     print("Failed to connect WebSocket: $e");
  //     _isWebSocketConnected = false;
  //   }
  // }

  void _scheduleReconnect({int retryCount = 0, int maxRetries = 3}) {
    if (retryCount >= maxRetries) {
      print("Đã đạt số lần thử tối đa ($maxRetries). Dừng thử lại.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không thể kết nối đến WebSocket sau $maxRetries lần thử.")),
        );
      }
      return;
    }

    print("Lên lịch tái kết nối sau 5 giây... (Lần thử: ${retryCount + 1}/$maxRetries)");
    Future.delayed(Duration(seconds: 5), () {
      if (!mounted) return;
      _connectWebSocket();
    });
  }

  // void _scheduleReconnect() {
  //   if (!mounted || _isWebSocketConnected || kIsWeb) return;
  //   _reconnectTimer?.cancel();
  //   _reconnectTimer = Timer(const Duration(seconds: 5), () {
  //     print("Attempting to reconnect WebSocket...");
  //     _connectWebSocket();
  //   });
  // }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;
    final type = message['type'];
    final data = message['data'];

    if (type == null || data == null) {
      print("Invalid WebSocket message format: $message");
      return;
    }

    bool commentsChanged = false;
    setState(() {
      if (type == 'new_comment') {
        Map<String, dynamic> newComment = Map<String, dynamic>.from(data);
        if (!comments.any((c) => c['id'] == newComment['id'])) {
          comments.insert(0, newComment);
          commentsChanged = true;
        }
      } else if (type == 'updated_comment') {
        Map<String, dynamic> updatedCommentData = Map<String, dynamic>.from(data);
        int index = comments.indexWhere((c) => c['id'] == updatedCommentData['id']);
        if (index != -1) {
          comments[index] = updatedCommentData;
          commentsChanged = true;
        }
      } else if (type == 'deleted_comment') {
        String commentIdToDelete = data['commentId'];
        comments.removeWhere((c) => c['id'] == commentIdToDelete);
        deletingComments.remove(commentIdToDelete);
        commentsChanged = true;
      } else if (type == 'error') {
        String errorMessage = data is String ? data : (data['message'] as String? ?? "Unknown server error");
        String? errorCode = data['code'] as String?;
        print("Received error from WebSocket: $errorMessage (Code: $errorCode)");

        if (errorCode == 'ALREADY_REVIEWED' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server error: $errorMessage")));
        }
        commentsChanged = true;
      }

      if (commentsChanged) {
        updateAverageRating(comments);
        _checkIfCurrentUserHasReviewed();
      }
    });
  }

  void _checkIfCurrentUserHasReviewed() {
    if (uid == 'unknown' || comments.isEmpty) {
      if (mounted) {
        setState(() {
          _currentUserHasReviewed = false;
          _currentUserReview = null;
          if (!_currentUserHasReviewed) {
            _commentController.clear();
            selectedRating = 5.0;
          }
        });
      }
      return;
    }
    final reviewIndex = comments.indexWhere((comment) => comment['userDocId'] == uid);
    if (mounted) {
      setState(() {
        _currentUserHasReviewed = reviewIndex != -1;
        _currentUserReview = reviewIndex != -1 ? comments[reviewIndex] : null;
        if (_currentUserHasReviewed && _currentUserReview != null) {
          _commentController.text = _currentUserReview!['comment'] ?? '';
          selectedRating = (_currentUserReview!['numberOfStars'] as num?)?.toDouble() ?? 5.0;
        } else {
          _commentController.clear();
          selectedRating = 5.0;
        }
      });
    }
  }

  Widget _buildImage(dynamic imageData, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    const placeholderUrl = 'https://via.placeholder.com/150';

    if (imageData == null || (imageData is String && imageData.isEmpty)) {
      return Image.network(placeholderUrl, height: height, width: width, fit: fit,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red));
    }
    if (imageData is String && imageData.startsWith('data:image')) {
      try {
        final base64String = imageData.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, height: height, width: width, fit: fit,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red));
      } catch (e) {
        print('Invalid base64 image: $e');
        return Image.network(placeholderUrl, height: height, width: width, fit: fit,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red));
      }
    }
    if (imageData is String && Uri.tryParse(imageData)?.hasScheme == true) {
      if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
        return Image.network(imageData, height: height, width: width, fit: fit,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red));
      }
    }
    if (!kIsWeb && imageData is String && File(imageData).existsSync()) {
      return Image.file(File(imageData), height: height, width: width, fit: fit,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red));
    }
    print('Unknown image format or invalid URI: $imageData. Attempting as network image or placeholder.');
    return Image.network(imageData is String ? imageData : placeholderUrl, height: height, width: width, fit: fit,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red));
  }

  Future<void> fetchVariants() async {
    if (productId.isEmpty) {
      if (mounted) setState(() { variants = []; selectedVariantIndex = -1; isLoading = false; });
      return;
    }
    if (mounted) setState(() { isLoading = true; });
    try {
      QuerySnapshot variantSnapshot = await _firestore.collection('variants').where('productId', isEqualTo: productId).get();
      List<Map<String, dynamic>> fetchedVariants = [];
      DateTime now = DateTime.now();
      for (var doc in variantSnapshot.docs) {
        var variantData = doc.data() as Map<String, dynamic>;
        variantData['id'] = doc.id;
        num sellingPrice = num.tryParse(variantData['sellingPrice']?.toString() ?? '0') ?? 0;
        num discountPercentage = num.tryParse(variantData['discountPercentage']?.toString() ?? '0') ?? 0;
        String? expiryStr = variantData['discountExpiry']?.toString();
        DateTime? expiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
        if (discountPercentage > 0 && expiry != null && now.isBefore(expiry)) {
          variantData['discountedPrice'] = sellingPrice * (1 - discountPercentage / 100);
        }
        fetchedVariants.add(variantData);
      }
      if (mounted) {
        setState(() {
          variants = fetchedVariants;
          selectedVariantIndex = variants.isNotEmpty ? 0 : -1;
        });
      }
    } catch (e) {
      print("Error fetching variants: $e");
      if (mounted) setState(() { variants = []; selectedVariantIndex = -1; });
    }
    if (mounted) setState(() { isLoading = false; });
  }

  void updateAverageRating(List<Map<String, dynamic>> currentComments) {
    if (!mounted) return;
    double totalStars = 0.0;
    if (currentComments.isEmpty) {
      setState(() { averageRating = 0.0; });
      return;
    }
    for (var comment in currentComments) {
      var stars = comment["numberOfStars"];
      if (stars != null && stars is num) {
        totalStars += stars.toDouble();
      }
    }
    setState(() { averageRating = totalStars / currentComments.length; });
  }

  Future<String?> getProductIdByName(String productName) async {
    try {
      QuerySnapshot productSnapshot = await _firestore.collection('product').where("name", isEqualTo: productName).limit(1).get();
      return productSnapshot.docs.isNotEmpty ? productSnapshot.docs.first.id : null;
    } catch (error) {
      print("Error fetching productId by name: $error");
      return null;
    }
  }

  Future<void> saveReviewViaWebSocket(String comment, double? rating, String customerName) async {
    if (productId.isEmpty || !_isWebSocketConnected || _channel == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot submit review. Check connection.")));
      _connectWebSocket();
      return;
    }

    final reviewData = {
      "type": _currentUserHasReviewed ? "edit_comment" : "post_comment",
      "payload": {
        "comment": comment,
        "numberOfStars": rating,
        "userDocId": uid,
        "customerName": customerName,
        "productId": productId,
        if (_currentUserHasReviewed && _currentUserReview != null && _currentUserReview!['id'] != null)
          "commentId": _currentUserReview!['id'],
      }
    };
    _channel!.sink.add(jsonEncode(reviewData));
    print("Sent review via WebSocket: ${jsonEncode(reviewData)}");
  }

  Future<List<Map<String, dynamic>>> fetchRatingsForProduct(String currentProductId) async {
    if (currentProductId.isEmpty) return [];
    try {
      DocumentSnapshot productDoc = await _firestore.collection('product').doc(currentProductId).get();
      if (!productDoc.exists) return [];
      List<dynamic> ratingIds = (productDoc.data() as Map<String, dynamic>)['comments'] as List<dynamic>? ?? [];
      if (ratingIds.isEmpty) return [];

      List<Map<String, dynamic>> fetchedRatings = [];
      List<String> stringRatingIds = ratingIds.cast<String>();
      List<Future<QuerySnapshot>> fetchBatches = [];

      for (int i = 0; i < stringRatingIds.length; i += 30) {
        List<String> batchIds = stringRatingIds.sublist(i, i + 30 > stringRatingIds.length ? stringRatingIds.length : i + 30);
        if (batchIds.isNotEmpty) {
          fetchBatches.add(_firestore.collection('rating').where(FieldPath.documentId, whereIn: batchIds).get());
        }
      }

      List<QuerySnapshot> querySnapshots = await Future.wait(fetchBatches);

      for (QuerySnapshot querySnapshot in querySnapshots) {
        for (DocumentSnapshot ratingDoc in querySnapshot.docs) {
          if (ratingDoc.exists) {
            Map<String, dynamic> ratingData = ratingDoc.data() as Map<String, dynamic>;
            ratingData['id'] = ratingDoc.id;
            fetchedRatings.add(ratingData);
          }
        }
      }

      fetchedRatings.sort((a, b) {
        var tsA = a['timestamp'];
        var tsB = b['timestamp'];
        if (tsA is Timestamp && tsB is Timestamp) return tsB.compareTo(tsA);
        if (tsA is String && tsB is String) {
          try {
            return DateTime.parse(tsB).compareTo(DateTime.parse(tsA));
          } catch (e) { return 0; }
        }
        return 0;
      });
      return fetchedRatings;
    } catch (e) {
      print("Error fetching initial ratings: $e");
      return [];
    }
  }

  Future<void> loadRatings() async {
    if (productId.isEmpty) {
      if (mounted) setState(() { comments = []; isLoading = false; updateAverageRating([]); _checkIfCurrentUserHasReviewed(); });
      return;
    }
    if (mounted) setState(() { isLoading = true; });
    List<Map<String, dynamic>> fetchedComments = await fetchRatingsForProduct(productId);
    if (mounted) {
      setState(() {
        comments = fetchedComments;
        isLoading = false;
        updateAverageRating(comments);
        _checkIfCurrentUserHasReviewed();
      });
    }
  }

  Future<String> getUserNameByIdFromFirestore(String userId) async {
    if (userId == 'unknown') return 'Anonymous';
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['fullName'] as String? ?? 'No Name';
      }
    } catch (e) { print("Error getting username: $e"); }
    return 'User Not Found';
  }

  void loadUserName() async {
    if (uid != 'unknown') {
      String fetchedName = await getUserNameByIdFromFirestore(uid);
      if (mounted) setState(() { userName = fetchedName; });
    } else {
      if (mounted) setState(() { userName = "Anonymous"; });
    }
  }

  void getCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() { uid = currentUser?.uid ?? 'unknown'; });
      loadUserName();
    }
  }

  Future<void> deleteCommentViaWebSocket(String commentId) async {
    if (productId.isEmpty || !_isWebSocketConnected || _channel == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot delete. Check connection.")));
      _connectWebSocket();
      return;
    }
    setState(() { deletingComments.add(commentId); });
    final deleteData = {
      "type": "delete_comment",
      "payload": { "commentId": commentId, "userDocId": uid, "productId": productId, }
    };
    _channel!.sink.add(jsonEncode(deleteData));
    print("Sent delete request via WebSocket for comment: $commentId");
  }

  Future<String?> getUserAvatarById(String userDocId) async {
    if (userDocId == 'unknown') return null;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userDocId).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['image'] as String?;
      }
    } catch (e) { print("Error fetching user avatar: $e"); }
    return null;
  }

  bool isOutOfStock() {
    if (variants.isEmpty) return true;
    if (selectedVariantIndex < 0 || selectedVariantIndex >= variants.length) return true;
    return (num.tryParse(variants[selectedVariantIndex]['stock']?.toString() ?? '0') ?? 0).toInt() == 0;
  }

  Future<void> showEditRatingDialog(Map<String, dynamic> commentToEdit, int index) async {
    double newRating = (commentToEdit['numberOfStars'] as num?)?.toDouble() ?? 5.0;
    TextEditingController editCommentController = TextEditingController(text: commentToEdit['comment'] as String? ?? '');
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Edit Your Rating"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Update your rating:"), const SizedBox(height: 10),
                RatingBar.builder(
                  initialRating: newRating, minRating: 1, direction: Axis.horizontal, allowHalfRating: true, itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                  onRatingUpdate: (rating) { newRating = rating; },
                ),
                const SizedBox(height: 20), const Text("Update your comment:"), const SizedBox(height: 10),
                TextField(
                  controller: editCommentController,
                  decoration: InputDecoration(
                    hintText: "Write a comment...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: Colors.grey.shade100,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                if (productId.isEmpty || !_isWebSocketConnected || _channel == null) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot edit. Check connection.")));
                  Navigator.of(dialogContext).pop();
                  return;
                }
                String ratingId = commentToEdit['id'] as String;
                final updateData = {
                  "type": "edit_comment",
                  "payload": { "commentId": ratingId, "comment": editCommentController.text, "numberOfStars": newRating, "userDocId": uid, "productId": productId, }
                };
                _channel!.sink.add(jsonEncode(updateData));
                print("Sent edit request via WebSocket for comment: $ratingId");
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Save!"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageSection(BoxConstraints constraints, bool isWebApp) {
    double swiperHeight = isWebApp ? constraints.maxHeight * 0.8 : 400;
    if (isWebApp && swiperHeight < 300) swiperHeight = 300;
    if (!isWebApp) swiperHeight = 400;

    double swiperWidth = isWebApp ? constraints.maxWidth : double.infinity;

    return Container(
      height: swiperHeight,
      width: swiperWidth,
      margin: isWebApp ? const EdgeInsets.only(right: 16.0, bottom: 16.0) : const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, spreadRadius: 2)],
      ),
      child: imageUrls.isNotEmpty
          ? Swiper(
        itemCount: imageUrls.length,
        pagination: const SwiperPagination(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.all(10.0),
          builder: DotSwiperPaginationBuilder(activeColor: AppColor.primaryColor, color: Colors.grey, size: 8, activeSize: 10),
        ),
        control: imageUrls.length > 1 ? const SwiperControl(color: AppColor.primaryColor, size: 30) : null,
        autoplay: imageUrls.length > 1,
        autoplayDelay: 5000,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(backgroundColor: Colors.black, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
                  body: PhotoView(
                    imageProvider: imageUrls[index].startsWith('data:image')
                        ? MemoryImage(base64Decode(imageUrls[index].split(',')[1])) as ImageProvider
                        : NetworkImage(imageUrls[index]),
                    backgroundDecoration: const BoxDecoration(color: Colors.black),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  ),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImage(imageUrls[index], height: swiperHeight, width: swiperWidth, fit: BoxFit.contain),
            ),
          );
        },
      )
          : Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[300],
        ),
        child: const Center(child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey)),
      ),
    );
  }

  Widget _buildProductInfoCard(bool isWebApp) {
    Map<String, dynamic>? currentVariant;
    bool currentVariantHasActiveDiscount = false;
    num currentPrice = num.tryParse(widget.product['sellingPrice']?.toString() ?? '0') ?? 0;
    num? originalPriceBeforeDiscount;

    if (variants.isNotEmpty && selectedVariantIndex >= 0 && selectedVariantIndex < variants.length) {
      currentVariant = variants[selectedVariantIndex];
      currentPrice = num.tryParse(currentVariant['sellingPrice']?.toString() ?? '0') ?? 0;
      if (currentVariant.containsKey('discountedPrice') && currentVariant['discountedPrice'] != null) {
        num discountPercentage = num.tryParse(currentVariant['discountPercentage']?.toString() ?? '0') ?? 0;
        String? expiryStr = currentVariant['discountExpiry']?.toString();
        DateTime? expiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
        if (discountPercentage > 0 && expiry != null && DateTime.now().isBefore(expiry)) {
          currentVariantHasActiveDiscount = true;
          originalPriceBeforeDiscount = currentPrice;
          currentPrice = num.tryParse(currentVariant['discountedPrice'].toString()) ?? currentPrice;
        }
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.only(top: currentVariantHasActiveDiscount && currentVariant != null ? 20 : 0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: currentVariantHasActiveDiscount && currentVariant != null ? 20 : 0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(formatPrice(currentPrice), style: TextStyle(color: Colors.red, fontSize: isWebApp ? 26 : 24, fontWeight: FontWeight.bold)),
                    if (originalPriceBeforeDiscount != null) ...[
                      const SizedBox(width: 8),
                      Text(formatPrice(originalPriceBeforeDiscount), style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: isWebApp ? 18 : 16)),
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.product['name'] as String? ?? 'Unknown Product', style: TextStyle(fontSize: isWebApp ? 22 : 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: Text(widget.product['description'] as String? ?? '', style: const TextStyle(fontSize: 14, color: Colors.black54), maxLines: 3, overflow: TextOverflow.ellipsis),
                  secondChild: Text(widget.product['description'] as String? ?? '', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                if ((widget.product['description'] as String? ?? '').isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    onPressed: () => setState(() { isExpanded = !isExpanded; }),
                    child: Text(isExpanded ? "Hide" : "Read more", style: const TextStyle(color: AppColor.primaryColor, fontSize: 14)),
                  ),
              ],
            ),
          ),
        ),
        if (currentVariantHasActiveDiscount && currentVariant != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.deepOrange, Colors.orangeAccent], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("-${(currentVariant["discountPercentage"] as num).toDouble().toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 6), const Icon(Icons.flash_on, color: Colors.yellowAccent, size: 18),
                      const SizedBox(width: 4), const Text("FLASH SALE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                    ],
                  ),
                  if (currentVariant["discountExpiry"] != null)
                    CountdownTimer(
                      endTime: DateTime.tryParse(currentVariant["discountExpiry"].toString())?.millisecondsSinceEpoch,
                      widgetBuilder: (_, time) {
                        if (time == null) return const Text("EXPIRED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
                        return RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            children: [
                              const TextSpan(text: "Ends in: "),
                              TextSpan(
                                text: '${time.hours?.toString().padLeft(2, '0') ?? "00"}:${time.min?.toString().padLeft(2, '0') ?? "00"}:${time.sec?.toString().padLeft(2, '0') ?? "00"}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                      onEnd: () { if (mounted) fetchVariants(); },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVariantSelection(bool isWebApp) {
    double childAspectRatio = isWebApp ? 0.85 : 0.7;
    int crossAxisCount = isWebApp ? (variants.length > 3 ? 3 : (variants.length > 1 ? 2 : 1)) : 2;
    if (variants.isEmpty) crossAxisCount = 1;
    double itemHeight = 300;
    double gridHeight = variants.isEmpty ? 80 : (itemHeight * ((variants.length - 1) / crossAxisCount).ceil() + 40);

    if (variants.isEmpty && !isLoading) return const SizedBox.shrink();
    if (isLoading && variants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ExpansionTile(
      key: ValueKey('variantExpansion-${variants.length}'),
      title: const Text("Select Variant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      subtitle: (variants.isNotEmpty && selectedVariantIndex >= 0 && selectedVariantIndex < variants.length)
          ? Text(
        "Selected: ${variants[selectedVariantIndex]['performance']} - ${variants[selectedVariantIndex]['color']}",
        style: const TextStyle(color: Colors.grey, fontSize: 13),
        maxLines: 1, overflow: TextOverflow.ellipsis,
      )
          : (variants.isNotEmpty ? const Text("Please select a variant", style: TextStyle(color: Colors.red, fontSize: 13)) : const Text("No variants available", style: TextStyle(color: Colors.grey, fontSize: 13))),
      initiallyExpanded: isWebApp || variants.length <= 2,
      collapsedIconColor: Colors.grey,
      iconColor: AppColor.primaryColor,
      backgroundColor: isWebApp ? Colors.grey.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      childrenPadding: const EdgeInsets.all(20.0),
      children: [
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: variants.length,
            itemBuilder: (context, index) {
              final variant = variants[index];
              int stock = (num.tryParse(variant["stock"]?.toString() ?? '0') ?? 0).toInt();
              num sellingPrice = num.tryParse(variant["sellingPrice"]?.toString() ?? '0') ?? 0.0;
              num? discountedPrice;
              bool variantHasActiveDiscount = false;

              if (variant.containsKey('discountedPrice') && variant['discountedPrice'] != null) {
                num discountPercentage = num.tryParse(variant['discountPercentage']?.toString() ?? '0') ?? 0;
                String? expiryStr = variant['discountExpiry']?.toString();
                DateTime? expiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
                if (discountPercentage > 0 && expiry != null && DateTime.now().isBefore(expiry)) {
                  variantHasActiveDiscount = true;
                  discountedPrice = num.tryParse(variant['discountedPrice'].toString());
                }
              }

              bool isSelected = selectedVariantIndex == index;

              return GestureDetector(
                onTap: () => setState(() { selectedVariantIndex = index; quantity = 1; }),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [AppColor.primaryColor.withOpacity(0.1), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : null,
                      border: Border.all(color: isSelected ? AppColor.primaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? AppColor.primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: isSelected ? 2 : 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 180,
                              child: _buildImage(variant["image"], fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 11,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                variant["performance"] as String? ?? "N/A",
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                variant["color"] as String? ?? "N/A",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Stock: $stock",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: stock == 0 ? Colors.red.shade700 : Colors.green.shade700,
                                  fontWeight: stock == 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (variantHasActiveDiscount && discountedPrice != null)
                                Column(
                                  children: [
                                    Text(
                                      formatPrice(discountedPrice),
                                      style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      formatPrice(sellingPrice),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  formatPrice(sellingPrice),
                                  style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsAndReviewSection(bool isWebApp) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Customer Ratings ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Icon(Icons.star, color: Colors.orange, size: 22),
                const SizedBox(width: 4),
                Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("/5", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(width: 10),
                Text("(${comments.length} reviews)", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Comments:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            isLoading && comments.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                : comments.isEmpty
                ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text("No comments yet. Be the first to review!", style: TextStyle(color: Colors.grey))))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                String? userDocIdForAvatar = comment['userDocId'] as String?;
                String customerNameForAvatar = comment['customerName'] as String? ?? "New Customer";
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    leading: FutureBuilder<String?>(
                      future: userDocIdForAvatar != null ? getUserAvatarById(userDocIdForAvatar) : Future.value(null),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircleAvatar(radius: 20, backgroundColor: Colors.black12, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70))));
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                          return CircleAvatar(radius: 20, backgroundColor: AppColor.primaryColor.withOpacity(0.7), child: Text(customerNameForAvatar.isNotEmpty ? customerNameForAvatar[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
                        }
                        return CircleAvatar(radius: 20, child: ClipOval(child: _buildImage(snapshot.data!, height: 40, width: 40, fit: BoxFit.cover)));
                      },
                    ),
                    title: Text(customerNameForAvatar, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (comment["numberOfStars"] != null && comment["numberOfStars"] > 0)
                          RatingBarIndicator(rating: (comment["numberOfStars"] as num?)?.toDouble() ?? 0.0, itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.orange), itemCount: 5, itemSize: 15.0),
                        const SizedBox(height: 4),
                        Text(comment["comment"] as String? ?? "", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 4),
                        if (comment["timestamp"] != null)
                          Text(
                            comment["timestamp"] is Timestamp
                                ? (comment["timestamp"] as Timestamp).toDate().toLocal().toString().substring(0, 16)
                                : (comment["timestamp"] is String
                                ? (DateTime.tryParse(comment["timestamp"])?.toLocal().toString().substring(0, 16) ?? comment["timestamp"])
                                : "Unknown date"),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                    trailing: (comment['userDocId'] == uid && uid != 'unknown')
                        ? PopupMenuButton<String>(
                      tooltip: "Options",
                      onSelected: (value) async {
                        if (value == 'edit') await showEditRatingDialog(comment, index);
                        else if (value == 'delete') {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: const Text("Confirm Deletion"),
                              content: const Text("Are you sure you want to delete this review? This action cannot be undone."),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                                TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("Delete")),
                              ],
                            ),
                          ) ?? false;
                          if (confirmDelete) await deleteCommentViaWebSocket(comment['id'] as String);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Edit')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                      ],
                      icon: deletingComments.contains(comment['id'])
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.more_vert_rounded),
                    )
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(uid == 'unknown' ? "Leave a Comment:" : (_currentUserHasReviewed ? "Your Review:" : "Leave a Review:"), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (uid == 'unknown' || (uid != 'unknown' && !_currentUserHasReviewed)) ...[
                  if (uid != 'unknown') ...[
                    RatingBar.builder(
                      initialRating: selectedRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 30.0,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.orange),
                      onRatingUpdate: (rating) { setState(() { selectedRating = rating; }); },
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const Text("You must be logged in to rate this product.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Share your thoughts about this product...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColor.primaryColor)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColor.primaryColor),
                        tooltip: "Submit Comment",
                        onPressed: () async {
                          if (_commentController.text.trim().isEmpty) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comment cannot be empty!")));
                            return;
                          }
                          if (uid == 'unknown' && userName == "User Not Found") {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot post comment as 'User Not Found'.")));
                            return;
                          }
                          await saveReviewViaWebSocket(_commentController.text.trim(), uid == 'unknown' ? null : selectedRating, userName);
                        },
                      ),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ] else if (uid != 'unknown' && _currentUserHasReviewed) ...[
                  const Text("You have already reviewed this product. Edit or delete your review above.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isWebApp) {
    return Container(
      padding: isWebApp ? const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0) : const EdgeInsets.all(16.0).copyWith(top: 8),
      decoration: isWebApp ? null : BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: isWebApp ? 12 : 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: isAddingToCart
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColor.primaryColor, strokeWidth: 2))
                      : Icon(Icons.add_shopping_cart_outlined, color: isOutOfStock() ? Colors.grey.shade700 : AppColor.primaryColor),
                  label: Text(
                    isOutOfStock() ? "Out of Stock" : "Add to Cart",
                    style: TextStyle(color: isOutOfStock() ? Colors.grey.shade700 : AppColor.primaryColor, fontWeight: FontWeight.bold, fontSize: isWebApp ? 15 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isWebApp ? 16 : 14),
                    backgroundColor: isOutOfStock() ? Colors.grey.shade300 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isOutOfStock() ? Colors.grey.shade400 : AppColor.primaryColor, width: 1.5),
                    ),
                    elevation: isOutOfStock() ? 0 : 2,
                  ),
                  onPressed: isOutOfStock() || isAddingToCart
                      ? null
                      : () async {
                    if (variants.isNotEmpty && selectedVariantIndex == -1) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a product variant.")));
                      return;
                    }
                    if (mounted) setState(() { isAddingToCart = true; });
                    String? resolvedProductId = productId;
                    if (resolvedProductId.isEmpty) resolvedProductId = await getProductIdByName(widget.product['name'] as String);

                    if (resolvedProductId == null || resolvedProductId.isEmpty) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Product not found!")));
                      if (mounted) setState(() { isAddingToCart = false; });
                      return;
                    }

                    String? variantId = variants.isNotEmpty && selectedVariantIndex >= 0 && selectedVariantIndex < variants.length ? variants[selectedVariantIndex]['id'] as String? : null;
                    await addToCart(resolvedProductId, uid, variants.isNotEmpty ? selectedVariantIndex : -1, variantId, context, quantity: quantity);
                    if (mounted) setState(() { isAddingToCart = false; cartItemCount += quantity; });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: isAddingToCart && !isOutOfStock() ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.shopping_bag_outlined, color: isOutOfStock() ? Colors.grey.shade300 : Colors.white),
                  label: Text(
                    isOutOfStock() ? "Out of Stock" : "Buy Now",
                    style: TextStyle(color: isOutOfStock() ? Colors.grey.shade300 : Colors.white, fontWeight: FontWeight.bold, fontSize: isWebApp ? 15 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isWebApp ? 16 : 14),
                    backgroundColor: isOutOfStock() ? Colors.grey.shade400 : AppColor.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: isOutOfStock() ? 0 : 2,
                  ),
                  onPressed: isOutOfStock() || isAddingToCart
                      ? null
                      : () async {
                    if (variants.isNotEmpty && selectedVariantIndex == -1) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a product variant.")));
                      return;
                    }
                    if (mounted) setState(() { isAddingToCart = true; });
                    String? resolvedProductId = productId;
                    if (resolvedProductId.isEmpty) resolvedProductId = await getProductIdByName(widget.product['name'] as String);

                    if (resolvedProductId == null || resolvedProductId.isEmpty) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Product not found!")));
                      if (mounted) setState(() { isAddingToCart = false; });
                      return;
                    }
                    String? variantId = variants.isNotEmpty && selectedVariantIndex >= 0 && selectedVariantIndex < variants.length ? variants[selectedVariantIndex]['id'] as String? : null;
                    await addToCart(resolvedProductId, uid, variants.isNotEmpty ? selectedVariantIndex : -1, variantId, context, quantity: quantity);
                    if (mounted) setState(() { isAddingToCart = false; cartItemCount += quantity; });
                    if (mounted && uid != 'unknown') Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen(userId: uid)));
                    else if (mounted && uid == 'unknown') ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item added. Guest cart can be viewed after login.")));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> loadCartItemCount() async {
    if (uid == 'unknown') {
      final prefs = await SharedPreferences.getInstance();
      List<String> guestCartString = prefs.getStringList('guestCart') ?? [];
      if (mounted) setState(() {
        cartItemCount = guestCartString.map((item) => jsonDecode(item)['quantity'] as int? ?? 0).reduce((a, b) => a + b);
      });
    } else {
      final cartDoc = await FirebaseFirestore.instance.collection('cart').doc(uid).get();
      if (cartDoc.exists) {
        List<dynamic> productIds = cartDoc.data()?['productIds'] ?? [];
        if (mounted) setState(() {
          cartItemCount = productIds.map((item) => item['quantity'] as int? ?? 0).reduce((a, b) => a + b);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name'] as String? ?? "Product Details", style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColor.primaryColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: "View Cart",
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen(userId: uid))),
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWebApp = constraints.maxWidth > kWebAppBreakpoint;

            if (isLoading && productId.isNotEmpty) return const Center(child: CircularProgressIndicator());
            if (productId.isEmpty) return const Center(child: Text("Error: Product information is missing. Please go back.", textAlign: TextAlign.center));

            if (isWebApp) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: SingleChildScrollView(padding: const EdgeInsets.all(20.0), child: _buildImageSection(constraints, isWebApp))),
                  Expanded(flex: 7, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(0, 20.0, 20.0, 20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildProductInfoCard(isWebApp),
                    const SizedBox(height: 20),
                    _buildVariantSelection(isWebApp),
                    const SizedBox(height: 20),
                    _buildActionButtons(isWebApp),
                    const SizedBox(height: 24),
                    _buildRatingsAndReviewSection(isWebApp),
                  ]))),
                ],
              );
            } else {
              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageSection(constraints, isWebApp),
                          const SizedBox(height: 16),
                          _buildProductInfoCard(isWebApp),
                          const SizedBox(height: 16),
                          _buildVariantSelection(isWebApp),
                          const SizedBox(height: 16),
                          _buildRatingsAndReviewSection(isWebApp),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildActionButtons(isWebApp),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

Future<void> addToCart(String productId, String userId, int variantIndex, String? variantId, BuildContext context, {int quantity = 1}) async {
  try {
    Map<String, dynamic> cartItem = {
      'id': productId,
      'quantity': quantity,
    };
    if (variantId != null) cartItem['variantId'] = variantId;

    if (userId == 'unknown') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> guestCartString = prefs.getStringList('guestCart') ?? [];
      List<Map<String, dynamic>> guestCart = guestCartString.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();

      int existingIndex = guestCart.indexWhere((item) => item['id'] == productId && item['variantId'] == variantId);
      if (existingIndex != -1) {
        guestCart[existingIndex]['quantity'] = (guestCart[existingIndex]['quantity'] as int? ?? 0) + quantity;
      } else {
        guestCart.add(cartItem);
      }
      await prefs.setStringList('guestCart', guestCart.map((item) => jsonEncode(item)).toList());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$quantity item(s) added to cart! (Guest)")));
    } else {
      DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(userId);
      DocumentSnapshot cartSnapshot = await cartRef.get();

      if (!cartSnapshot.exists) {
        await cartRef.set({'productIds': [cartItem]});
      } else {
        Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
        List<dynamic> productIdsDynamic = cartData['productIds'] ?? [];
        List<Map<String, dynamic>> productItems = productIdsDynamic.map((item) => item as Map<String, dynamic>).toList();

        int existingIndex = productItems.indexWhere((item) => item['id'] == productId && item['variantId'] == variantId);
        if (existingIndex != -1) {
          productItems[existingIndex]['quantity'] = (productItems[existingIndex]['quantity'] as int? ?? 0) + quantity;
        } else {
          productItems.add(cartItem);
        }
        await cartRef.update({'productIds': productItems});
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$quantity item(s) added to cart successfully!")));
    }
  } catch (e) {
    print("Error adding to cart: $e");
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error adding to cart: ${e.toString()}")));
  }
}