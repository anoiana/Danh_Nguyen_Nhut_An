import 'package:flutter/material.dart';
import 'package:mobile/features/product/services/product_service.dart';
import 'package:mobile/features/product/views/screens/product_detail_screen.dart';
import '../../../../shared/models/product_model.dart';
import '../../views/widgets/tour_card.dart'; // Tận dụng lại TourCard có sẵn

class TourListScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? queryParams; // Truyền tham số lọc (VD: sort=-createdAt)

  const TourListScreen({Key? key, required this.title, this.queryParams}) : super(key: key);

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  final ProductService _productService = ProductService();
  List<ProductModel> _tours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _productService.getProducts(params: widget.queryParams);
    if (mounted) {
      setState(() {
        _tours = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.teal))
        : _tours.isEmpty 
            ? const Center(child: Text("Không tìm thấy tour nào"))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _tours.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: 280, // Chiều cao cố định cho TourCard hiển thị đẹp
                    child: TourCard(
                      product: _tours[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(productId: _tours[index].id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}