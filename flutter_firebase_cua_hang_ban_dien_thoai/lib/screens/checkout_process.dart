import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cross_platform_mobile_app_development/models/Item.dart';
import 'package:cross_platform_mobile_app_development/screens/thank_you.dart';
import 'package:cross_platform_mobile_app_development/models/address.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

// Định nghĩa thêm một số màu sắc và style để tái sử dụng
const double defaultPadding = 16.0;
const double borderRadius = 12.0;
const Color cardBackgroundColor = Colors.white;
const Color highlightColor = Colors.blueAccent;
const Color mutedTextColor = Colors.grey;

String formatPrice(num price) {
  final formatter = NumberFormat('#,##0', 'vi_VN');
  return '${formatter.format(price)}đ';
}

class CheckoutScreen extends StatefulWidget {
  final String userId;
  final List<Item> selectedItems;
  final String shippingAddress;
  final double shippingFee;
  final double discountAmount;
  final String? appliedCouponCode;
  final bool hasAddress;

  const CheckoutScreen({
    Key? key,
    required this.userId,
    required this.selectedItems,
    required this.shippingAddress,
    required this.shippingFee,
    required this.discountAmount,
    this.appliedCouponCode,
    required this.hasAddress,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final double taxRate = 0.1;
  bool isLoading = false;
  String? selectedPaymentMethod;
  late String currentShippingAddress;
  String? guestEmail;
  String? guestPhoneNumber;
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  String? emailError;
  String? phoneError;
  String? newUserId;
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode addressFocusNode = FocusNode();
  List<Province> provinces = [];
  List<District> districts = [];
  List<Ward> wards = [];
  Province? selectedProvince;
  District? selectedDistrict;
  Ward? selectedWard;
  String? selectedLocation;
  double shippingFee = 0;
  TextEditingController addressDetailController = TextEditingController();

  // Loyalty Program State
  int currentUserLoyaltyPoints = 0;
  double loyaltyDiscountAmount = 0.0;
  int pointsUsedForDiscount = 0;
  bool applyLoyaltyDiscount = false;

  final List<Province> defaultProvinces = [
    Province(name: 'Hà Nội', fullName: 'Hà Nội City', nameEn: 'Hanoi', code: '1', type: 'C'),
    Province(name: 'Hồ Chí Minh', fullName: 'Hồ Chí Minh City', nameEn: 'Ho Chi Minh City', code: '2', type: 'C'),
    Province(name: 'Đà Nẵng', fullName: 'Đà Nẵng City', nameEn: 'Da Nang', code: '3', type: 'C'),
    Province(name: 'Cần Thơ', fullName: 'Cần Thơ City', nameEn: 'Can Tho', code: '4', type: 'C'),
  ];

  final Map<String, double> shippingFees = {
    'Hà Nội City': 20000, 'Hà Nội': 20000,
    'Hồ Chí Minh City': 25000, 'Hồ Chí Minh': 25000,
    'Đà Nẵng City': 30000, 'Đà Nẵng': 30000,
    'Cần Thơ City': 35000, 'Cần Thơ': 35000,
    'An Giang Province': 35000,
  };

  @override
  void initState() {
    super.initState();
    currentShippingAddress = widget.shippingAddress;
    shippingFee = widget.shippingFee;
    fetchProvincesData();
    newUserId = widget.userId;
    if (widget.userId != 'unknown') {
      _fetchUserLoyaltyPoints();
    }
  }

  // Các hàm logic khác giữ nguyên, chỉ thay đổi phần giao diện
  Future<void> _fetchUserLoyaltyPoints() async {
    if (newUserId == null || newUserId == 'unknown') return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(newUserId).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          currentUserLoyaltyPoints = (userDoc.data()! as Map<String, dynamic>)['loyaltyPoints'] ?? 0;
          _calculatePotentialLoyaltyDiscount();
        });
      }
    } catch (e) {
      print("Error fetching loyalty points: $e");
      setState(() {
        currentUserLoyaltyPoints = 0;
        _calculatePotentialLoyaltyDiscount();
      });
    }
  }

  void _calculatePotentialLoyaltyDiscount() {
    if (currentUserLoyaltyPoints >= 100) {
      int usablePointsBlocks = (currentUserLoyaltyPoints / 100).floor();
      int tempPointsUsedForDiscount = usablePointsBlocks * 100;

      if (tempPointsUsedForDiscount > 1000) {
        tempPointsUsedForDiscount = 1000;
      }
      double discountPercentage = (tempPointsUsedForDiscount / 100) * 0.1;

      double baseAmountForLoyaltyDiscount = calculateSubtotal() + calculateTax() + shippingFee - widget.discountAmount;
      if (baseAmountForLoyaltyDiscount < 0) baseAmountForLoyaltyDiscount = 0;

      double newLoyaltyDiscountAmount = baseAmountForLoyaltyDiscount * discountPercentage;
      if (loyaltyDiscountAmount != newLoyaltyDiscountAmount || pointsUsedForDiscount != tempPointsUsedForDiscount) {
        setState(() {
          pointsUsedForDiscount = tempPointsUsedForDiscount;
          loyaltyDiscountAmount = newLoyaltyDiscountAmount;
        });
      }
    } else {
      if (loyaltyDiscountAmount != 0.0 || pointsUsedForDiscount != 0) {
        setState(() {
          pointsUsedForDiscount = 0;
          loyaltyDiscountAmount = 0.0;
        });
      }
    }
  }

  Future<void> fetchProvincesData() async {
    try {
      List<Province> fetchedProvinces = await fetchProvinces();
      setState(() {
        provinces = fetchedProvinces;
      });
    } catch (e) {
      setState(() {
        provinces = defaultProvinces;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading provinces: $e. Using default list.'),
            action: SnackBarAction(label: 'Retry', onPressed: fetchProvincesData),
          ),
        );
      }
    }
  }

  Future<void> fetchDistrictsData(String provinceCode) async {
    try {
      List<District> fetchedDistricts = await fetchDistricts(provinceCode);
      setState(() {
        districts = fetchedDistricts;
        selectedDistrict = null;
        selectedWard = null;
        wards = [];
      });
    } catch (e) {
      setState(() { districts = []; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading districts: $e')));
    }
  }

  Future<void> fetchWardsData(String districtCode) async {
    try {
      List<Ward> fetchedWards = await fetchWards(districtCode);
      setState(() {
        wards = fetchedWards;
        selectedWard = null;
      });
    } catch (e) {
      setState(() { wards = []; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading wards: $e')));
    }
  }

  double calculateSubtotal() {
    double subtotal = 0;
    for (var item in widget.selectedItems) {
      subtotal += item.price * item.quantity;
    }
    return subtotal;
  }

  double calculateTax() {
    return calculateSubtotal() * taxRate;
  }

  double calculateTotal() {
    double subtotal = calculateSubtotal();
    double currentLoyaltyDiscount = applyLoyaltyDiscount ? loyaltyDiscountAmount : 0.0;
    double total = subtotal + calculateTax() + shippingFee - widget.discountAmount - currentLoyaltyDiscount;
    return total < 0 ? 0 : total;
  }

  Future<void> updateStockAfterPurchase() async {
    try {
      for (var item in widget.selectedItems) {
        if (item.variantId == null) {
          print("No variantId for item ${item.productId}!");
          continue;
        }
        DocumentReference variantRef = FirebaseFirestore.instance.collection('variants').doc(item.variantId);
        DocumentSnapshot variantDoc = await variantRef.get();
        if (!variantDoc.exists) {
          print("Variant ${item.variantId} does not exist for item ${item.productId}!");
          continue;
        }
        Map<String, dynamic> variantData = variantDoc.data() as Map<String, dynamic>;
        int currentStock = int.tryParse(variantData['stock']?.toString() ?? '0') ?? 0;
        int newStock = currentStock - item.quantity;
        if (newStock < 0) {
          print("Insufficient stock for item ${item.productId}, variant ${item.variantId}!");
          throw Exception("Insufficient stock!");
        }
        await variantRef.update({'stock': newStock});
        print("Updated stock for variant ${item.variantId} of item ${item.productId}: $newStock");
      }
    } catch (e) {
      print("Error updating stock: $e");
      throw e;
    }
  }

  Future<void> decreaseCouponQuantity(String couponCode) async {
    try {
      DocumentSnapshot couponDoc = await FirebaseFirestore.instance.collection('couponCode').doc(couponCode).get();
      if (!couponDoc.exists) {
        print("Coupon code does not exist!");
        return;
      }
      Map<String, dynamic> couponData = couponDoc.data() as Map<String, dynamic>;
      int quantity = couponData['quantity'] ?? 0;
      if (quantity <= 0) {
        print("Coupon code has no remaining uses!");
        return;
      }
      await FirebaseFirestore.instance.collection('couponCode').doc(couponCode).update({'quantity': quantity - 1});
      print("Successfully decreased quantity of coupon $couponCode!");
    } catch (e) {
      print("Error decreasing coupon quantity: $e");
      throw e;
    }
  }

  Future<void> _saveUsedCouponCode(String couponCode) async {
    if (newUserId == null || newUserId == 'unknown') return;
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(newUserId);
      await userRef.update({
        'usedCouponCodes': FieldValue.arrayUnion([couponCode]),
      });
      print("Saved coupon code $couponCode to used list for user $newUserId");
    } catch (e) {
      print("Error saving used coupon code: $e. Attempting to set with merge.");
      await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
        'usedCouponCodes': [couponCode],
      }, SetOptions(merge: true));
    }
  }

  Future<void> _removeSelectedItemsFromCart() async {
    if (newUserId == 'unknown' || newUserId == null) {
      await _removeSelectedItemsFromSharedPreferences();
    } else {
      await _removeSelectedItemsFromFirestore();
    }
  }

  Future<void> _removeSelectedItemsFromFirestore() async {
    if (newUserId == null || newUserId == 'unknown') return;
    try {
      DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(newUserId);
      DocumentSnapshot cartSnapshot = await cartRef.get();
      if (!cartSnapshot.exists) {
        print("Cart does not exist!");
        return;
      }
      Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
      List<dynamic> productIds = List.from(cartData['productIds'] ?? []);

      productIds.removeWhere((entry) {
        return widget.selectedItems.any((item) =>
        item.productId == entry['id'] &&
            item.variantId == entry['variantId'] &&
            item.quantity == (entry['quantity'] as int? ?? 1));
      });

      await cartRef.update({'productIds': productIds});
      print("Removed selected items from cart in Firestore!");
    } catch (e) {
      print("Error removing items from cart in Firestore: $e");
      throw e;
    }
  }

  Future<void> _removeSelectedItemsFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> guestCart = prefs.getStringList('guestCart') ?? [];
    List<Map<String, dynamic>> cartItems = guestCart
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();

    cartItems.removeWhere((entry) {
      return widget.selectedItems.any((item) =>
      item.productId == entry['productId'] &&
          item.variantId == entry['variantId'] &&
          item.selected);
    });

    await prefs.setStringList('guestCart', cartItems.map((item) => jsonEncode(item)).toList());
    print("Removed selected items from cart in SharedPreferences!");
  }

  Future<void> _saveShippingAddressToUser() async {
    if (newUserId == null || newUserId == 'unknown') return;
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(newUserId);
      await userRef.update({'address': currentShippingAddress});
      print("Saved shipping address: $currentShippingAddress for user $newUserId");
    } catch (e) {
      print("Error saving shipping address: $e. Attempting to set with merge.");
      await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
        'address': currentShippingAddress,
      }, SetOptions(merge: true));
    }
  }

  Future<Map<String, dynamic>> _saveOrderToFirestore() async {
    if (newUserId == null) throw Exception("User ID is null, cannot save order.");
    try {
      CollectionReference ordersRef = FirebaseFirestore.instance.collection('orders');
      List<Map<String, dynamic>> productIds = widget.selectedItems.map((item) {
        return {
          'variantId': item.variantId ?? '',
          'quantity': item.quantity,
          'price': item.price,
        };
      }).toList();

      Map<String, dynamic> orderPayload = {
        'totalAmount': calculateTotal(),
        'subtotal': calculateSubtotal(),
        'tax': calculateTax(),
        'shippingFee': shippingFee,
        'couponDiscount': widget.discountAmount,
        'loyaltyDiscount': applyLoyaltyDiscount ? loyaltyDiscountAmount : 0.0,
        'pointsUsedForLoyaltyDiscount': applyLoyaltyDiscount ? pointsUsedForDiscount : 0,
        'orderStatus': 'Pending',
        'purchaseDate': FieldValue.serverTimestamp(),
        'numberOfProducts': widget.selectedItems.length,
        'paymentMethod': selectedPaymentMethod ?? 'Unknown',
        'productIds': productIds,
        'couponCode': widget.appliedCouponCode ?? '',
        'userId': newUserId,
        'shippingAddress': currentShippingAddress,
      };

      DocumentReference orderDoc = await ordersRef.add(orderPayload);
      DocumentSnapshot orderSnapshot = await orderDoc.get();
      Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
      orderData['orderId'] = orderDoc.id;

      print("Saved order to Firestore for user $newUserId with orderId ${orderDoc.id}");
      return orderData;
    } catch (e) {
      print("Error saving order: $e");
      throw e;
    }
  }

  Future<void> syncGuestCartToFirestore(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> guestCart = prefs.getStringList('guestCart') ?? [];
    if (guestCart.isEmpty) return;

    DocumentReference cartRef = FirebaseFirestore.instance.collection('cart').doc(uid);
    DocumentSnapshot cartSnapshot = await cartRef.get();

    List<Map<String, dynamic>> cartItemsToSync = guestCart.map((item) {
      try {
        Map<String, dynamic> decodedItem = jsonDecode(item) as Map<String, dynamic>;
        return {
          'id': decodedItem['productId'],
          'variantId': decodedItem['variantId'],
          'quantity': decodedItem['quantity'],
        };
      } catch (e) {
        print("Error decoding guest cart item: $e, item: $item");
        return <String, dynamic>{};
      }
    }).where((item) => item.isNotEmpty).toList();

    if (cartItemsToSync.isEmpty) {
      print("No valid cart items to sync.");
      return;
    }

    try {
      if (!cartSnapshot.exists) {
        await cartRef.set({'productIds': cartItemsToSync});
      } else {
        Map<String, dynamic> cartData = cartSnapshot.data() as Map<String, dynamic>;
        List<dynamic> existingProductIds = List.from(cartData['productIds'] ?? []);

        for (var newItem in cartItemsToSync) {
          int existingIndex = existingProductIds.indexWhere(
                (existing) => existing['id'] == newItem['id'] && existing['variantId'] == newItem['variantId'],
          );
          if (existingIndex != -1) {
            existingProductIds[existingIndex]['quantity'] = (existingProductIds[existingIndex]['quantity'] as int? ?? 0) + (newItem['quantity'] as int? ?? 1);
          } else {
            existingProductIds.add(newItem);
          }
        }
        await cartRef.update({'productIds': existingProductIds});
      }
      await prefs.remove('guestCart');
      print("Cart synced successfully for user $uid");
    } catch (e) {
      print("Error syncing cart to Firestore: $e");
      throw e;
    }
  }

  String _generateRandomPassword(int length) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<String> _createGuestAccount(String email) async {
    try {
      String password = _generateRandomPassword(6);
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String fullName = email.split('@')[0];

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'fullName': fullName,
        'phoneNumber': guestPhoneNumber,
        'role': 'Customer',
        'status': 'Active',
        'address': currentShippingAddress,
        'createdAt': FieldValue.serverTimestamp(),
        'loyaltyPoints': 0,
        'usedCouponCodes': [],
        'uid': uid,
      });

      print("Created account for guest with email $email and UID $uid");
      newUserId = uid;
      await _fetchUserLoyaltyPoints();
      return password;
    } catch (e) {
      print("Error creating guest account: $e");
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        throw Exception("Email is already in use. Please use a different email or log in.");
      }
      throw Exception("Failed to create account: $e");
    }
  }

  Future<void> _sendEmailViaApi({
    required String email,
    required String subject,
    required String text,
    required String html,
  }) async {
    final uri = Uri.parse('http://localhost:5000/api/send-order-confirmation');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'subject': subject,
        'text': text,
        'html': html,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Email sent from backend successfully!');
    } else {
      print('❌ Failed to send email: ${response.body}');
    }
  }

  Future<void> _handleCheckout() async {
    if (selectedPaymentMethod == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a payment method!')));
      return;
    }

    if (widget.userId == 'unknown') {
      if (guestEmail == null || guestEmail!.isEmpty || !_isValidEmail(guestEmail!)) {
        setState(() { emailError = "Please enter a valid email address."; });
        return;
      } else {
        setState(() { emailError = null; });
      }

      if (guestPhoneNumber == null || guestPhoneNumber!.isEmpty || !_isValidPhoneNumber(guestPhoneNumber!)) {
        setState(() { phoneError = "Please enter a valid 10-digit phone number starting with 0."; });
        return;
      } else {
        setState(() { phoneError = null; });
      }
    }

    setState(() { isLoading = true; });
    String? generatedPassword;

    try {
      if (widget.userId == 'unknown') {
        guestEmail = emailController.text.trim();
        guestPhoneNumber = phoneController.text.trim();

        List<String> methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(guestEmail!);
        bool emailExists = methods.isNotEmpty;

        if (emailExists) {
          if (!mounted) return;
          bool? loginInstead = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Email Already Registered'),
              content: const Text('This email is already registered. Would you like to log in or use a different email?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Use Different Email')),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Log In')),
              ],
            ),
          );
          setState(() { isLoading = false; });
          if (loginInstead == true) {
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
            return;
          } else {
            setState(() { emailError = "Please use a different email."; });
            return;
          }
        }
        generatedPassword = await _createGuestAccount(guestEmail!);
        await syncGuestCartToFirestore(newUserId!);
      } else {
        newUserId = widget.userId;
        if (currentUserLoyaltyPoints == 0 && loyaltyDiscountAmount == 0.0) {
          await _fetchUserLoyaltyPoints();
        }
      }

      double baseAmountForEarningPoints = calculateSubtotal() + calculateTax() + shippingFee - widget.discountAmount;
      if (baseAmountForEarningPoints < 0) baseAmountForEarningPoints = 0;
      int pointsEarned = (baseAmountForEarningPoints / 100000).floor();

      if (newUserId != null && newUserId != 'unknown') {
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(newUserId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot userSnap = await transaction.get(userRef);
          if (!userSnap.exists) {
            transaction.set(userRef, {
              'loyaltyPoints': pointsEarned,
            }, SetOptions(merge: true));
            print("User document for $newUserId did not exist. Created with pointsEarned.");
          } else {
            int currentPoints = (userSnap.data() as Map<String, dynamic>)['loyaltyPoints'] ?? 0;
            int finalLoyaltyPoints = currentPoints + pointsEarned;
            if (applyLoyaltyDiscount) {
              finalLoyaltyPoints -= pointsUsedForDiscount;
            }
            finalLoyaltyPoints = finalLoyaltyPoints < 0 ? 0 : finalLoyaltyPoints;
            transaction.update(userRef, {'loyaltyPoints': finalLoyaltyPoints});
            print("Updated loyalty points for user $newUserId to $finalLoyaltyPoints");
          }
        });
      }

      await updateStockAfterPurchase();
      if (widget.appliedCouponCode != null) {
        await decreaseCouponQuantity(widget.appliedCouponCode!);
        await _saveUsedCouponCode(widget.appliedCouponCode!);
      }
      DocumentSnapshot userSnapForAddress = await FirebaseFirestore.instance.collection('users').doc(newUserId).get();
      String? existingAddress = (userSnapForAddress.data() as Map<String, dynamic>?)?['address'];

      if (!widget.hasAddress || currentShippingAddress != existingAddress) {
        await _saveShippingAddressToUser();
      }

      Map<String, dynamic> orderData = await _saveOrderToFirestore();
      await _removeSelectedItemsFromCart();

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(newUserId).get();
      String? userEmail = userDoc.get('email') as String?;

      if (userEmail != null && userEmail.isNotEmpty) {
        final subject = 'Order Confirmation - Thank You for Your Purchase!';
        final text = _buildEmailText(generatedPassword, pointsEarned, applyLoyaltyDiscount ? pointsUsedForDiscount : 0);
        final html = _buildEmailHtml(generatedPassword, pointsEarned, applyLoyaltyDiscount ? pointsUsedForDiscount : 0);

        if (kIsWeb) {
          await _sendEmailViaApi(
            email: userEmail,
            subject: subject,
            text: text,
            html: html,
          );
        } else {
          final smtpServer = gmail('nguyenhamy2007204@gmail.com', 'gjcfkgmwzfdtuhjn');
          final message = Message()
            ..from = Address('nguyenhamy2007204@gmail.com', 'My Store')
            ..recipients.add(userEmail)
            ..subject = subject
            ..text = text
            ..html = html;
          await send(message, smtpServer);
          print('✅ Email sent via mailer (Android)');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout successful!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ThankYouScreen(order: orderData)),
        );
      }
    } catch (e) {
      print("Error during checkout: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during checkout: ${e.toString()}')));
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  bool _isValidPhoneNumber(String phone) {
    return RegExp(r'^0\d{9}$').hasMatch(phone);
  }

  String _buildEmailText(String? generatedPassword, int pointsEarned, int pointsSpent) {
    String accountInfo = generatedPassword != null
        ? 'Account Details\n\nWe have created an account for you to track your orders.\nEmail: $guestEmail\nPassword: $generatedPassword\n\n'
        : '';
    String loyaltyInfo = '';
    if (pointsEarned > 0) loyaltyInfo += 'Points Earned from this order: $pointsEarned\n';
    if (pointsSpent > 0) loyaltyInfo += 'Points Used for discount: $pointsSpent\n';
    if (loyaltyInfo.isNotEmpty) loyaltyInfo = '\nLoyalty Program:\n$loyaltyInfo\n';

    return '$accountInfo'
        'Order Confirmation\n\nDear Customer,\n\nThank you for your purchase! Here are your order details:\n\n'
        'Order Date: ${DateTime.now().toLocal().toString().substring(0,16)}\n'
        'Total Amount: ₫${calculateTotal().toStringAsFixed(0)}\n'
        'Payment Method: $selectedPaymentMethod\n'
        'Coupon Code: ${widget.appliedCouponCode ?? 'None'}\n'
        '$loyaltyInfo'
        'Products:\n${widget.selectedItems.map((item) => '- ${item.name} (Qty: ${item.quantity}): ₫${(item.price * item.quantity).toStringAsFixed(0)}').join('\n')}\n\n'
        'Subtotal: ₫${calculateSubtotal().toStringAsFixed(0)}\n'
        'Tax (10%): ₫${calculateTax().toStringAsFixed(0)}\n'
        'Shipping Fee: ₫${shippingFee.toStringAsFixed(0)}\n'
        '${widget.discountAmount > 0 ? "Coupon Discount: -₫${widget.discountAmount.toStringAsFixed(0)}\n" : ""}'
        '${applyLoyaltyDiscount && loyaltyDiscountAmount > 0 ? "Loyalty Discount: -₫${loyaltyDiscountAmount.toStringAsFixed(0)}\n" : ""}'
        'Shipping Address: $currentShippingAddress\n\n'
        'Best regards,\nYour Store Team';
  }

  String _buildEmailHtml(String? generatedPassword, int pointsEarned, int pointsSpent) {
    const String primaryColor = '#FF5722';
    const String secondaryColor = '#4CAF50';
    const String textColor = '#333333';
    const String backgroundColor = '#F5F5F5';
    const String fontFamily = 'Arial, Helvetica, sans-serif';

    String accountInfoHtml = generatedPassword != null
        ? '''<div style="background-color: #ffffff; padding: 20px; border-radius: 8px; margin-bottom: 20px; border: 1px solid #e0e0e0;">
          <h2 style="color: $primaryColor; font-family: $fontFamily; font-size: 24px; margin: 0 0 10px;">Account Details</h2>
          <p style="color: $textColor; font-family: $fontFamily; font-size: 16px; margin: 0;">We have created an account for you. Use these details to log in:</p>
          <table style="width: 100%; margin-top: 10px;" cellpadding="5">
            <tr><td style="font-weight: bold;">Email:</td><td>$guestEmail</td></tr>
            <tr><td style="font-weight: bold;">Password:</td><td>$generatedPassword</td></tr>
          </table></div>'''
        : '';

    String loyaltyHtml = '';
    if (pointsEarned > 0 || pointsSpent > 0) {
      loyaltyHtml += '<div style="margin-bottom: 15px; padding:10px; background-color:#e8f5e9; border-left: 4px solid $secondaryColor;">';
      loyaltyHtml += '<h3 style="margin-top:0; color:$secondaryColor;">Loyalty Program</h3>';
      if (pointsEarned > 0) loyaltyHtml += '<p>Points Earned: <strong>$pointsEarned</strong></p>';
      if (pointsSpent > 0) loyaltyHtml += '<p>Points Used: <strong>$pointsSpent</strong> (for -₫${loyaltyDiscountAmount.toStringAsFixed(0)} discount)</p>';
      loyaltyHtml += '</div>';
    }

    String productRows = widget.selectedItems.map((item) {
      return '''<tr style="border-bottom: 1px solid #e0e0e0;">
        <td style="padding: 10px;">${item.name}</td>
        <td style="padding: 10px; text-align: center;">${item.quantity}</td>
        <td style="padding: 10px; text-align: right;">₫${item.price.toStringAsFixed(0)}</td>
        <td style="padding: 10px; text-align: right;">₫${(item.price * item.quantity).toStringAsFixed(0)}</td></tr>''';
    }).join('');

    return '''
    <div style="background-color: $backgroundColor; padding: 20px; font-family: $fontFamily; max-width: 600px; margin: 0 auto;">
      <div style="background-color: #ffffff; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; border-bottom: 2px solid $primaryColor;">
        <h1 style="color: $primaryColor; font-size: 28px; margin: 0;">My Store</h1>
        <p style="color: $textColor; font-size: 16px; margin: 5px 0 0;">Thank You for Your Purchase!</p>
      </div>
      <div style="background-color: #ffffff; padding: 20px; border-radius: 0 0 8px 8px;">
        $accountInfoHtml
        <h2 style="color: $primaryColor; font-size: 24px; margin: 0 0 10px;">Order Confirmation</h2>
        <p>Dear Customer, thank you! Here are your order details:</p>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;" cellpadding="5">
          <tr><td>Order Date:</td><td>${DateTime.now().toLocal().toString().substring(0,16)}</td></tr>
          <tr><td>Payment Method:</td><td>$selectedPaymentMethod</td></tr>
          <tr><td>Coupon Code:</td><td>${widget.appliedCouponCode ?? 'None'}</td></tr>
        </table>
        $loyaltyHtml
        <h3 style="margin: 20px 0 10px;">Products</h3>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;" cellpadding="5">
          <thead><tr style="background-color: #f9f9f9;">
            <th style="text-align: left;">Item</th><th>Quantity</th><th style="text-align: right;">Unit Price</th><th style="text-align: right;">Total</th></tr></thead>
          <tbody>$productRows</tbody>
        </table>
        <h3 style="margin: 20px 0 10px;">Pricing Summary</h3>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;" cellpadding="5">
          <tr><td>Subtotal:</td><td style="text-align: right;">₫${calculateSubtotal().toStringAsFixed(0)}</td></tr>
          <tr><td>Tax (10% VAT):</td><td style="text-align: right;">₫${calculateTax().toStringAsFixed(0)}</td></tr>
          <tr><td>Shipping Fee:</td><td style="text-align: right;">₫${shippingFee.toStringAsFixed(0)}</td></tr>
          ${widget.discountAmount > 0 ? '<tr><td style="color: $secondaryColor;">Coupon Discount:</td><td style="text-align: right; color: $secondaryColor;">-₫${widget.discountAmount.toStringAsFixed(0)}</td></tr>' : ''}
          ${applyLoyaltyDiscount && loyaltyDiscountAmount > 0 ? '<tr><td style="color: $secondaryColor;">Loyalty Discount:</td><td style="text-align: right; color: $secondaryColor;">-₫${loyaltyDiscountAmount.toStringAsFixed(0)}</td></tr>' : ''}
          <tr style="font-weight: bold; border-top: 1px solid #ccc; padding-top: 5px;"><td style="color: $primaryColor; font-size: 18px;">Total Amount:</td><td style="text-align: right; color: $primaryColor; font-size: 18px;">₫${calculateTotal().toStringAsFixed(0)}</td></tr>
        </table>
        <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
          <h3 style="margin: 0 0 10px;">Shipping Address</h3><p style="margin: 0;">$currentShippingAddress</p>
        </div>
        <div style="text-align: center; margin-bottom: 20px;"><p>Please log in to view your order details.</p></div>
      </div>
      <div style="text-align: center; padding: 20px; color: $textColor; font-size: 14px;">
        <p>Best regards,<br>Your Store Team</p>
        <p>© ${DateTime.now().year} My Store. All rights reserved.</p>
      </div>
    </div>''';
  }

  Future<void> _showShippingLocationDialog() async {
    if (provinces.isEmpty) await fetchProvincesData();
    if (!mounted) return;

    bool isLoadingDistricts = false;
    bool isLoadingWards = false;
    TextEditingController localAddressDetailController = TextEditingController(text: addressDetailController.text);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          title: Row(
            children: [
              Icon(Icons.location_on, color: highlightColor),
              SizedBox(width: 8),
              Text('Select Shipping Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.textColor)),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              bool isAddressComplete = provinces.isEmpty || provinces == defaultProvinces
                  ? selectedProvince != null
                  : (selectedProvince != null && selectedDistrict != null && selectedWard != null);

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provinces == defaultProvinces && provinces.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Using default provinces list. API might be unavailable.', style: TextStyle(color: Colors.red, fontSize: 14)),
                      ),
                    Text('Province/City', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mutedTextColor)),
                    SizedBox(height: 8),
                    provinces.isEmpty
                        ? Center(child: CircularProgressIndicator(color: highlightColor))
                        : DropdownButtonFormField<Province>(
                      value: selectedProvince,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.map, color: highlightColor),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: Text('Select province/city', style: TextStyle(color: mutedTextColor)),
                      items: provinces.map((Province province) => DropdownMenuItem<Province>(value: province, child: Text(province.name))).toList(),
                      onChanged: (Province? selection) async {
                        if (selection != null) {
                          setDialogState(() {
                            selectedProvince = selection;
                            selectedDistrict = null;
                            selectedWard = null;
                            districts.clear();
                            wards.clear();
                            isLoadingDistricts = true;
                          });
                          if (provinces != defaultProvinces) {
                            await fetchDistrictsData(selection.code);
                          }
                          setDialogState(() { isLoadingDistricts = false; });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    if (provinces != defaultProvinces) ...[
                      Text('District', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mutedTextColor)),
                      SizedBox(height: 8),
                      isLoadingDistricts
                          ? Center(child: CircularProgressIndicator(color: highlightColor))
                          : districts.isEmpty && selectedProvince != null
                          ? Text('No districts found or select province.', style: TextStyle(color: mutedTextColor))
                          : DropdownButtonFormField<District>(
                        value: selectedDistrict,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.location_city, color: highlightColor),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: Text('Select district', style: TextStyle(color: mutedTextColor)),
                        items: districts.map((District district) => DropdownMenuItem<District>(value: district, child: Text(district.name))).toList(),
                        onChanged: (District? selection) async {
                          if (selection != null) {
                            setDialogState(() {
                              selectedDistrict = selection;
                              selectedWard = null;
                              wards.clear();
                              isLoadingWards = true;
                            });
                            await fetchWardsData(selection.code);
                            setDialogState(() { isLoadingWards = false; });
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      Text('Ward', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mutedTextColor)),
                      SizedBox(height: 8),
                      isLoadingWards
                          ? Center(child: CircularProgressIndicator(color: highlightColor))
                          : wards.isEmpty && selectedDistrict != null
                          ? Text('No wards found or select district.', style: TextStyle(color: mutedTextColor))
                          : DropdownButtonFormField<Ward>(
                        value: selectedWard,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.home, color: highlightColor),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: Text('Select ward', style: TextStyle(color: mutedTextColor)),
                        items: wards.map((Ward ward) => DropdownMenuItem<Ward>(value: ward, child: Text(ward.name))).toList(),
                        onChanged: (Ward? selection) => setDialogState(() => selectedWard = selection),
                      ),
                      SizedBox(height: 16),
                    ],
                    AnimatedOpacity(
                      opacity: isAddressComplete ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: isAddressComplete
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Address Details (house number, street name, etc.)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mutedTextColor)),
                          SizedBox(height: 8),
                          TextField(
                            controller: localAddressDetailController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.location_history, color: highlightColor),
                              hintText: 'E.g., 123 Le Loi Street',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: mutedTextColor)),
              onPressed: () {
                Navigator.of(context).pop();
                localAddressDetailController.dispose();
              },
            ),
            ElevatedButton(
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: highlightColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (selectedProvince == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a province/city!')));
                  return;
                }
                if (provinces != defaultProvinces && (selectedDistrict == null || selectedWard == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select district and ward!')));
                  return;
                }

                String addressDetailText = localAddressDetailController.text.trim();
                String newConstructedAddress;
                if (provinces == defaultProvinces || provinces.isEmpty) {
                  newConstructedAddress = addressDetailText.isNotEmpty
                      ? '$addressDetailText, ${selectedProvince!.name}'
                      : selectedProvince!.name;
                } else {
                  newConstructedAddress = addressDetailText.isNotEmpty
                      ? '$addressDetailText, ${selectedWard!.name}, ${selectedDistrict!.name}, ${selectedProvince!.name}'
                      : '${selectedWard!.name}, ${selectedDistrict!.name}, ${selectedProvince!.name}';
                }

                setState(() {
                  currentShippingAddress = newConstructedAddress;
                  addressDetailController.text = addressDetailText;
                  shippingFee = shippingFees[selectedProvince!.name] ?? shippingFees[selectedProvince!.fullName] ?? 40000;
                  _calculatePotentialLoyaltyDiscount();
                });
                Navigator.of(context).pop();
                localAddressDetailController.dispose();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildItemImage(String image) {
    try {
      if (image.startsWith('data:image')) {
        return Image.memory(
          base64Decode(image.split(',')[1]),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        );
      } else {
        return Image.network(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, stackTrace) => Icon(Icons.broken_image, size: 60, color: mutedTextColor),
        );
      }
    } catch (_) {
      return Icon(Icons.broken_image, size: 60, color: mutedTextColor);
    }
  }

  @override
  void dispose() {
    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    addressFocusNode.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressDetailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Thanh Toán",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))],
              ),
            ),
          ],
        ),
        backgroundColor: AppColor.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColor.primaryColor, AppColor.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColor.primaryColor))
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 800 ? 800 : double.infinity,
            padding: EdgeInsets.all(defaultPadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderItems(),
                  SizedBox(height: 15),
                  _buildShippingInfo(),
                  SizedBox(height: 15),
                  if (widget.userId == 'unknown') ...[
                    _buildGuestInfo(),
                    SizedBox(height: 15),
                  ],
                  if (newUserId != 'unknown' || (widget.userId == 'unknown' && guestEmail != null && _isValidEmail(guestEmail!)))
                    _buildLoyaltySection(),
                  _buildPaymentMethod(),
                  SizedBox(height: 15),
                  _buildSummary(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: 4,
      color: cardBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: AppColor.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  "Sản Phẩm Đã Chọn",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.selectedItems.length,
              itemBuilder: (context, index) {
                final item = widget.selectedItems[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: buildItemImage(item.image),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textColor,
                              ),
                            ),
                            if (item.performance.isNotEmpty)
                              Text(
                                item.performance,
                                style: TextStyle(fontSize: 14, color: mutedTextColor),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "x${item.quantity}",
                                  style: TextStyle(fontSize: 14, color: mutedTextColor),
                                ),
                                Text(
                                  formatPrice(item.price * item.quantity),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: 4,
      color: cardBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: AppColor.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  "Thông Tin Giao Hàng",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: highlightColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentShippingAddress.isEmpty ? "Chưa chọn địa chỉ giao hàng" : currentShippingAddress,
                    style: TextStyle(fontSize: 16, color: AppColor.textColor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _showShippingLocationDialog,
                  child: Text(
                    "Chỉnh Sửa",
                    style: TextStyle(
                      fontSize: 16,
                      color: highlightColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: 4,
      color: cardBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColor.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  "Thông Tin Khách Hàng",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: emailController,
              focusNode: emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Nhập địa chỉ email",
                prefixIcon: Icon(Icons.email_outlined, color: highlightColor, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                errorText: emailError,
              ),
              onChanged: (value) {
                setState(() {
                  guestEmail = value.trim();
                  if (_isValidEmail(guestEmail!)) {
                    emailError = null;
                  } else {
                    emailError = "Định dạng email không hợp lệ.";
                  }
                });
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: phoneController,
              focusNode: phoneFocusNode,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Nhập số điện thoại",
                prefixIcon: Icon(Icons.phone, color: highlightColor, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                errorText: phoneError,
              ),
              maxLength: 10,
              onChanged: (value) {
                setState(() {
                  guestPhoneNumber = value.trim();
                  if (_isValidPhoneNumber(guestPhoneNumber!)) {
                    phoneError = null;
                  } else {
                    phoneError = "Số điện thoại phải có 10 chữ số và bắt đầu bằng 0.";
                  }
                });
              },
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                "Một tài khoản sẽ được tạo với email này.",
                style: TextStyle(fontSize: 13, color: mutedTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltySection() {
    if (newUserId == null || newUserId == 'unknown') {
      return SizedBox.shrink();
    }

    if (currentUserLoyaltyPoints < 100) {
      return Padding(
        padding: EdgeInsets.only(bottom: 15.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_border_purple500_outlined, color: AppColor.primaryColor, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "Chương Trình Tích Điểm",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      "Điểm Của Bạn: ",
                      style: TextStyle(fontSize: 17, color: mutedTextColor),
                    ),
                    Text(
                      "$currentUserLoyaltyPoints",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primaryColor,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.stars, color: Colors.amber.shade600, size: 20),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  "Tích lũy 1 điểm cho mỗi 100,000đ chi tiêu.",
                  style: TextStyle(fontSize: 15, color: mutedTextColor, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 15, color: mutedTextColor, height: 1.4),
                    children: <TextSpan>[
                      TextSpan(text: "Đạt "),
                      TextSpan(
                        text: "100 điểm",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.secondaryColor),
                      ),
                      TextSpan(text: " để nhận "),
                      TextSpan(
                        text: "10% giảm giá",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.secondaryColor),
                      ),
                      TextSpan(text: " cho đơn hàng tiếp theo!"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    int displayPointsToUse = pointsUsedForDiscount;
    double displayDiscountPercentage = (displayPointsToUse / 100.0) * 10.0;
    double displayLoyaltyDiscountAmount = loyaltyDiscountAmount;

    return Padding(
      padding: EdgeInsets.only(bottom: 15.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: AppColor.primaryColor2.withOpacity(0.5), width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.military_tech_outlined, color: AppColor.primaryColor2, size: 28),
                  SizedBox(width: 12),
                  Text(
                    "Ưu Đãi Tích Điểm",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    "Điểm Của Bạn: ",
                    style: TextStyle(fontSize: 17, color: mutedTextColor),
                  ),
                  Text(
                    "$currentUserLoyaltyPoints",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryColor,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.stars, color: Colors.amber.shade600, size: 20),
                ],
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: applyLoyaltyDiscount ? AppColor.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: applyLoyaltyDiscount ? AppColor.primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: CheckboxListTile(
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 15, color: AppColor.textColor, height: 1.4),
                      children: <TextSpan>[
                        TextSpan(text: "Sử dụng "),
                        TextSpan(
                          text: "$displayPointsToUse điểm",
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                        ),
                        TextSpan(text: " để giảm "),
                        TextSpan(
                          text: "${displayDiscountPercentage.toStringAsFixed(0)}% ",
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primaryColor),
                        ),
                        TextSpan(
                          text: formatPrice(displayLoyaltyDiscountAmount),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                  value: applyLoyaltyDiscount,
                  onChanged: (bool? value) {
                    setState(() {
                      applyLoyaltyDiscount = value ?? false;
                      _calculatePotentialLoyaltyDiscount();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColor.primaryColor,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final List<Map<String, dynamic>> paymentMethods = [
      {'name': 'Thanh Toán Khi Nhận Hàng (COD)', 'icon': Icons.local_shipping},
      {'name': 'Thẻ Tín Dụng/Thẻ Ghi Nợ', 'icon': Icons.credit_card,},
      {'name': 'Ví Điện Tử (MoMo, ZaloPay)', 'icon': Icons.account_balance_wallet, },
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: 4,
      color: cardBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppColor.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  "Phương Thức Thanh Toán",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPaymentMethod,
              hint: Text('Chọn phương thức thanh toán', style: TextStyle(color: mutedTextColor)),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: highlightColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
              items: paymentMethods.map((method) {
                bool isDisabled = method['disabled'] ?? false;
                return DropdownMenuItem<String>(
                  value: method['name'],
                  enabled: !isDisabled,
                  child: Row(
                    children: [
                      Icon(
                        method['icon'],
                        color: isDisabled ? Colors.grey : highlightColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          method['name'],
                          style: TextStyle(color: isDisabled ? Colors.grey : AppColor.textColor),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                final selectedMethodData = paymentMethods.firstWhere((m) => m['name'] == value, orElse: () => {});
                if (!(selectedMethodData['disabled'] ?? false)) {
                  setState(() {
                    selectedPaymentMethod = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon ?? Icons.label_outline, size: 20, color: color ?? mutedTextColor),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: color ?? AppColor.textColor,
                ),
              ),
            ],
          ),
          Text(
            formatPrice(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColor.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    double subtotal = calculateSubtotal();
    double tax = calculateTax();
    double currentShippingFee = shippingFee;
    double couponDisc = widget.discountAmount;
    double loyaltyDisc = applyLoyaltyDiscount ? loyaltyDiscountAmount : 0.0;
    double total = calculateTotal();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: 4,
      color: cardBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColor.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  "Tóm Tắt Đơn Hàng",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            _buildPriceRow("Tạm Tính", subtotal, color: mutedTextColor, icon: Icons.list_alt),
            _buildPriceRow("Thuế (10% VAT)", tax, color: mutedTextColor, icon: Icons.gavel),
            _buildPriceRow("Phí Vận Chuyển", currentShippingFee, color: mutedTextColor, icon: Icons.local_shipping),
            if (couponDisc > 0) _buildPriceRow("Giảm Giá Coupon", -couponDisc, color: Colors.green, icon: Icons.confirmation_number),
            if (loyaltyDisc > 0) _buildPriceRow("Giảm Giá Tích Điểm", -loyaltyDisc, color: Colors.orange, icon: Icons.star),
            Divider(thickness: 1, color: Colors.grey.shade200, height: 20),
            _buildPriceRow("Tổng Thanh Toán", total, color: AppColor.primaryColor, isBold: true, icon: Icons.payment),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _handleCheckout,
              icon: isLoading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                isLoading ? "Đang Xử Lý..." : "Xác Nhận Thanh Toán",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                minimumSize: Size(double.infinity, 50),
                shadowColor: AppColor.primaryColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}