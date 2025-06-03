import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TimeFrame { weekly, monthly, quarterly, yearly, custom }

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}

extension DateOnlyWeekly on DateTime {
  int get weekOfYear {
    final beginningOfYear = DateTime(this.year, 1, 1);
    final firstDayOfYear = beginningOfYear.weekday;
    final daysToFirstWeek =
        (firstDayOfYear <= 4) ? (1 - firstDayOfYear) : (8 - firstDayOfYear);
    final firstWeekStart = beginningOfYear.add(Duration(days: daysToFirstWeek));
    final difference = this.difference(firstWeekStart).inDays.abs();
    int weeks = (difference / 7).floor() + 1;

    if (this.isBefore(firstWeekStart)) {
      final lastYear = DateTime(this.year - 1, 12, 31);
      return lastYear.weekOfYear;
    }

    final endOfYear = DateTime(this.year, 12, 31);
    final lastDayOfYear = endOfYear.weekday;
    final daysToNextWeek =
        (lastDayOfYear <= 4) ? (1 - lastDayOfYear) : (8 - lastDayOfYear);
    final firstWeekOfNextYear = endOfYear.add(Duration(days: daysToNextWeek));
    if (this.isAfter(firstWeekOfNextYear) ||
        this.isAtSameMomentAs(firstWeekOfNextYear)) {
      return 1;
    }

    return weeks;
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TimeFrame selectedTimeFrame = TimeFrame.yearly;
  DateRange? customDateRange;
  int? selectedYear;
  int? selectedMonth;
  int? selectedQuarter;
  int? selectedWeek;

  // Simple Dashboard Data
  int totalUsers = 0;
  int newUsers = 0;
  int totalOrders = 0;
  double totalRevenue = 0;
  double totalProfit = 0;
  List<Map<String, dynamic>> bestSellingProducts = [];

  // Advanced Dashboard Data
  Map<String, dynamic> timeFrameData = {
    'orders': 0,
    'revenue': 0.0,
    'profit': 0.0,
  };
  List<Map<String, dynamic>> revenueByTime = [];
  List<Map<String, dynamic>> profitByTime = [];
  List<Map<String, dynamic>> productsByTime = [];
  List<Map<String, dynamic>> comparativeData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
    selectedQuarter = ((now.month - 1) ~/ 3) + 1;
    selectedWeek = now.weekOfYear;
    fetchDashboardData();
    fetchAdvancedDashboardData();
  }

  Future<void> fetchDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      totalUsers = 0;
      newUsers = 0;
      totalOrders = 0;
      totalRevenue = 0;
      totalProfit = 0;
      bestSellingProducts = [];
    });

    try {
      await fetchSimpleDashboardData();
      await fetchAdvancedDashboardData();
      await fetchComparativeData();
    } catch (e) {
      print('Error fetching dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Có lỗi khi tải dữ liệu: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchSimpleDashboardData() async {
    if (!mounted) return;

    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final ordersSnapshot = await _firestore.collection('orders').get();
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      int newUsersCount = 0;

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final createdAt = userData['createdAt'];
        if (createdAt != null && createdAt is Timestamp) {
          final createdDate = createdAt.toDate();
          if (createdDate.isAfter(sevenDaysAgo)) {
            newUsersCount++;
          }
        }
      }

      double revenue = 0;
      double profit = 0;
      Map<String, int> productSales = {};

      for (var order in ordersSnapshot.docs) {
        final orderData = order.data();
        if (orderData['totalAmount'] != null) {
          revenue += (orderData['totalAmount'] as num).toDouble();
        }

        double orderCost = 0;
        if (orderData['productIds'] != null &&
            orderData['productIds'] is List) {
          final products = orderData['productIds'] as List;
          for (var product in products) {
            if (product is Map<String, dynamic>) {
              final variantId = product['variantId'] as String?;
              final quantity = (product['quantity'] as num?)?.toInt() ?? 1;

              if (variantId != null) {
                final variantDoc =
                    await _firestore
                        .collection('variants')
                        .doc(variantId)
                        .get();
                if (variantDoc.exists) {
                  final variantData = variantDoc.data();
                  final productId = variantData?['productId'] as String?;
                  if (productId != null) {
                    final productDoc =
                        await _firestore
                            .collection('product')
                            .doc(productId)
                            .get();
                    if (productDoc.exists) {
                      final productData = productDoc.data();
                      final importPrice =
                          (productData?['importPrice'] as num?)?.toDouble() ??
                          0.0;
                      orderCost += importPrice * quantity;
                    }
                  }
                }
                productSales[variantId] =
                    ((productSales[variantId] ?? 0) + quantity).toInt();
              }
            }
          }
        }
        profit += (orderData['totalAmount'] as num).toDouble() - orderCost;
      }

      List<MapEntry<String, int>> sortedProducts =
          productSales.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      List<Map<String, dynamic>> topProducts = [];
      for (var i = 0; i < sortedProducts.length && i < 5; i++) {
        var variantDoc =
            await _firestore
                .collection('variants')
                .doc(sortedProducts[i].key)
                .get();
        if (variantDoc.exists) {
          final variantData = variantDoc.data();
          if (variantData != null) {
            final productId = variantData['productId'] as String?;
            if (productId != null) {
              var productDoc =
                  await _firestore.collection('product').doc(productId).get();
              if (productDoc.exists) {
                final productData = productDoc.data();
                if (productData != null) {
                  topProducts.add({
                    'name': productData['name'] ?? 'Unknown',
                    'sales': sortedProducts[i].value,
                  });
                }
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        totalUsers = usersSnapshot.size;
        newUsers = newUsersCount;
        totalOrders = ordersSnapshot.size;
        totalRevenue = revenue;
        totalProfit = profit;
        bestSellingProducts = topProducts;
      });
    } catch (e) {
      print('Error in fetchSimpleDashboardData: $e');
    }
  }

  Future<void> fetchAdvancedDashboardData() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();
    print('Fetching data for period: $startDate to $endDate');

    if (!mounted) return;

    final ordersSnapshot =
        await _firestore
            .collection('orders')
            .where(
              'purchaseDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'purchaseDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    if (ordersSnapshot.docs.isEmpty) {
      print('No orders found for the selected period');
      if (mounted) {
        setState(() {
          timeFrameData = {'orders': 0, 'revenue': 0.0, 'profit': 0.0};
          revenueByTime = [];
          profitByTime = [];
          productsByTime = [];
        });
      }
      return;
    }

    double periodRevenue = 0;
    double periodProfit = 0;
    Map<String, dynamic> timeData = {};
    Map<String, double> importPriceCache = {};

    for (var order in ordersSnapshot.docs) {
      final orderData = order.data() as Map<String, dynamic>? ?? {};
      final purchaseDate =
          (orderData['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final orderId = order.id;
      final revenue = (orderData['totalAmount'] ?? 0).toDouble();

      print(
        'Processing order $orderId - Purchase Date: $purchaseDate, Revenue: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(revenue)}',
      );

      final timeKey = _getTimeKey(purchaseDate);

      if (timeData[timeKey] == null) {
        timeData[timeKey] = {
          'revenue': 0.0,
          'profit': 0.0,
          'orders': 0,
          'product': 0,
          'importCost': 0.0,
        };
      }

      timeData[timeKey]['revenue'] += revenue;
      periodRevenue += revenue;

      double totalImportCost = 0;
      if (orderData['productIds'] != null && orderData['productIds'] is List) {
        final products = orderData['productIds'] as List;
        for (var product in products) {
          if (product is Map<String, dynamic>) {
            final variantId = product['variantId'] as String?;
            final quantity = (product['quantity'] as num?)?.toInt() ?? 1;

            if (variantId != null) {
              double importPrice = 0.0;
              if (importPriceCache.containsKey(variantId)) {
                importPrice = importPriceCache[variantId]!;
              } else {
                final variantDoc =
                    await _firestore
                        .collection('variants')
                        .doc(variantId)
                        .get();
                if (variantDoc.exists) {
                  final variantData = variantDoc.data();
                  if (variantData != null) {
                    importPrice =
                        (variantData['importPrice'] as num?)?.toDouble() ?? 0.0;
                    importPriceCache[variantId] = importPrice;
                    print(
                      'Variant $variantId, Import Price: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(importPrice)}',
                    );
                  }
                }
              }
              totalImportCost += importPrice * quantity;
            }
          }
        }
      }

      timeData[timeKey]['importCost'] += totalImportCost;

      final orderProfit = revenue - totalImportCost;
      timeData[timeKey]['profit'] += orderProfit;
      periodProfit += orderProfit;

      timeData[timeKey]['orders']++;
      timeData[timeKey]['product'] +=
          (orderData['productIds'] as List?)?.length ?? 0;
    }

    List<Map<String, dynamic>> revenueData = [];
    List<Map<String, dynamic>> profitData = [];
    List<Map<String, dynamic>> productsData = [];

    timeData.forEach((key, value) {
      revenueData.add({'time': key, 'value': value['revenue']});
      profitData.add({'time': key, 'value': value['profit']});
      productsData.add({'time': key, 'value': value['product']});
    });

    revenueData.sort((a, b) => a['time'].compareTo(b['time']));
    profitData.sort((a, b) => a['time'].compareTo(b['time']));
    productsData.sort((a, b) => a['time'].compareTo(b['time']));
    print("dataaaaa: $timeData");
    if (mounted) {
      setState(() {
        timeFrameData = {
          'orders': ordersSnapshot.size,
          'revenue': periodRevenue,
          'profit': periodProfit,
        };
        revenueByTime = revenueData;
        profitByTime = profitData;
        productsByTime = productsData;
      });
    }
  }

  Future<void> fetchComparativeData() async {
    final startDate = _getStartDate();
    final endDate = _getEndDate();

    final ordersSnapshot =
        await _firestore
            .collection('orders')
            .where(
              'purchaseDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'purchaseDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    Map<String, Map<String, dynamic>> timeData = {};
    Map<String, double> importPriceCache = {};

    for (var order in ordersSnapshot.docs) {
      final orderData = order.data();
      final orderDate =
          (orderData['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      final revenue = (orderData['totalAmount'] ?? 0).toDouble();

      double orderCost = 0;
      if (orderData['productIds'] != null && orderData['productIds'] is List) {
        final products = orderData['productIds'] as List;
        for (var product in products) {
          if (product is Map<String, dynamic>) {
            final variantId = product['variantId'] as String?;
            final quantity = (product['quantity'] as num?)?.toInt() ?? 1;

            if (variantId != null) {
              double importPrice = 0.0;
              if (importPriceCache.containsKey(variantId)) {
                importPrice = importPriceCache[variantId]!;
              } else {
                final variantDoc =
                    await _firestore
                        .collection('variants')
                        .doc(variantId)
                        .get();
                if (variantDoc.exists) {
                  final variantData = variantDoc.data();
                  if (variantData != null) {
                    final productId = variantData['productId'] as String?;
                    if (productId != null) {
                      final productDoc =
                          await _firestore
                              .collection('product')
                              .doc(productId)
                              .get();
                      if (productDoc.exists) {
                        final productData = productDoc.data();
                        importPrice =
                            (productData?['importPrice'] as num?)?.toDouble() ??
                            0.0;
                        importPriceCache[variantId] = importPrice;
                      }
                    }
                  }
                }
              }
              orderCost += importPrice * quantity;
            }
          }
        }
      }

      final profit = revenue - orderCost;
      final productCount = (orderData['productIds'] as List?)?.length ?? 0;
      final timeKey = _getTimeKey(orderDate);

      timeData[timeKey] ??= {'revenue': 0.0, 'profit': 0.0, 'product': 0};
      timeData[timeKey]!['revenue'] += revenue;
      timeData[timeKey]!['profit'] += profit;
      timeData[timeKey]!['product'] += productCount;
    }

    List<Map<String, dynamic>> formattedData = [];
    timeData.forEach((key, value) {
      formattedData.add({
        'time': key,
        'revenue': value['revenue'],
        'profit': value['profit'],
        'product': value['product'],
      });
    });

    formattedData.sort((a, b) => a['time'].compareTo(b['time']));

    if (mounted) {
      setState(() {
        comparativeData = formattedData;
      });
    }
  }

  DateTime _getStartDate() {
    switch (selectedTimeFrame) {
      case TimeFrame.yearly:
        final endDate = DateTime(selectedYear!, 1, 1);
        return endDate.isAfter(DateTime.now()) ? DateTime.now() : endDate;
      case TimeFrame.quarterly:
        final endMonth = selectedQuarter! * 3 - 2;
        final endDate = DateTime(selectedYear!, endMonth, 1);
        return endDate.isAfter(DateTime.now()) ? DateTime.now() : endDate;
      case TimeFrame.monthly:
        final endDate = DateTime(
          selectedYear!,
          selectedMonth!,
          1,
        ).subtract(const Duration(days: 0));
        return endDate.isAfter(DateTime.now()) ? DateTime.now() : endDate;
      case TimeFrame.weekly:
        DateTime firstDayOfYear = DateTime(selectedYear!, 1, 1);
        DateTime startOfWeek = firstDayOfYear.add(
          Duration(days: (selectedWeek! - 1) * 7),
        );
        return startOfWeek.isAfter(DateTime.now())
            ? DateTime.now()
            : startOfWeek;
      case TimeFrame.custom:
        return customDateRange?.start ??
            DateTime.now().subtract(const Duration(days: 30));
      default:
        return DateTime.now().subtract(const Duration(days: 365));
    }
  }

  DateTime _getEndDate() {
    final now = DateTime.now();
    switch (selectedTimeFrame) {
      case TimeFrame.yearly:
        final endDate = DateTime(selectedYear!, 12, 31);
        return endDate.isAfter(now) ? now : endDate;
      case TimeFrame.quarterly:
        final endMonth = selectedQuarter! * 3;
        final endDate = DateTime(
          selectedYear!,
          endMonth + 1,
          1,
        ).subtract(const Duration(days: 1));
        return endDate.isAfter(now) ? now : endDate;
      case TimeFrame.monthly:
        final endDate = DateTime(
          selectedYear!,
          selectedMonth! + 1,
          1,
        ).subtract(const Duration(days: 1));
        return endDate.isAfter(now) ? now : endDate;
      case TimeFrame.weekly:
        final startDate = _getStartDate();
        final endDate = startDate.add(const Duration(days: 6));
        return endDate.isAfter(now) ? now : endDate;
      case TimeFrame.custom:
        return customDateRange?.end ?? DateTime.now();
      default:
        return DateTime.now();
    }
  }

  String _getTimeKey(DateTime date) {
    switch (selectedTimeFrame) {
      case TimeFrame.yearly:
        return DateFormat('yyyy-MM').format(date);
      case TimeFrame.quarterly:
        return DateFormat('yyyy-MM').format(date);
      case TimeFrame.monthly:
        return DateFormat('yyyy-MM-dd').format(date);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case TimeFrame.weekly:
        final weekNumber = date.weekOfYear;
        return DateFormat('yyyy-MM-dd').format(date);
      case TimeFrame.custom:
        return DateFormat('yyyy-MM-dd').format(date);
      default:
        return DateFormat('yyyy-MM').format(date);
    }
  }

  int _getWeeksInYear(int year) {
    final lastDayOfYear = DateTime(year, 12, 31);
    return lastDayOfYear.weekOfYear;
  }

  String _getTimeFrameText(TimeFrame frame) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    switch (frame) {
      case TimeFrame.yearly:
        return 'Năm $selectedYear';
      case TimeFrame.monthly:
        return 'Tháng $selectedMonth-$selectedYear';
      case TimeFrame.quarterly:
        return 'Quý $selectedQuarter-$selectedYear';
      case TimeFrame.weekly:
        return 'Tuần ${selectedWeek.toString().padLeft(2, '0')}-$selectedYear';
      case TimeFrame.custom:
        if (customDateRange != null) {
          return '${dateFormat.format(customDateRange!.start)}-${dateFormat.format(customDateRange!.end)}';
        }
        // Hiển thị ngày mặc định nếu chưa chọn
        final defaultStart = DateTime.now().subtract(const Duration(days: 30));
        final defaultEnd = DateTime.now();
        return '${dateFormat.format(defaultStart)}-${dateFormat.format(defaultEnd)}';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 6,
          bottom: const TabBar(
            tabs: [Tab(text: 'Tổng quan'), Tab(text: 'Phân tích chi tiết')],
          ),
        ),
        body: TabBarView(
          children: [_buildSimpleDashboard(), _buildAdvancedDashboard()],
        ),
      ),
    );
  }

  Widget _buildSimpleDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan hiệu suất',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Tổng số người dùng',
                  totalUsers.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Người dùng mới (7 ngày)',
                  newUsers.toString(),
                  Icons.person_add,
                  Colors.green,
                ),
                _buildStatCard(
                  'Tổng số đơn hàng',
                  totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Doanh thu',
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(totalRevenue),
                  Icons.monetization_on,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Sản phẩm bán chạy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child:
                  bestSellingProducts.isEmpty
                      ? const Center(child: Text('Không có dữ liệu'))
                      : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              bestSellingProducts
                                  .map((p) => p['sales'] as num)
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >=
                                      bestSellingProducts.length) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      bestSellingProducts[value.toInt()]['name']
                                          .toString()
                                          .split(' ')
                                          .take(2)
                                          .join(' '),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            bestSellingProducts.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                      bestSellingProducts[index]['sales']
                                          .toDouble(),
                                  color: Colors.blue,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedDashboard() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeFrameSelector(),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Đơn hàng trong kỳ',
                  timeFrameData['orders'].toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Doanh thu trong kỳ',
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(timeFrameData['revenue']),
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildStatCard(
                  'Lợi nhuận trong kỳ',
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(timeFrameData['profit']),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildTimeSeriesChart(
              'Doanh thu theo thời gian',
              revenueByTime,
              Colors.blue,
            ),
            const SizedBox(height: 32),
            _buildTimeSeriesChart(
              'Lợi nhuận theo thời gian',
              profitByTime,
              Colors.green,
            ),
            const SizedBox(height: 32),
            _buildTimeSeriesChart(
              'Số lượng sản phẩm bán theo thời gian',
              productsByTime,
              Colors.orange,
            ),
            const SizedBox(height: 32),
            _buildComparativeCharts(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparativeCharts() {
    if (comparativeData.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: const Text(
          'Không có dữ liệu để so sánh',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final maxY =
        [
          comparativeData
              .map((e) => e['revenue'] as num)
              .reduce((a, b) => a > b ? a : b),
          comparativeData
              .map((e) => e['profit'] as num)
              .reduce((a, b) => a > b ? a : b),
          comparativeData
              .map((e) => e['product'] as num)
              .reduce((a, b) => a > b ? a : b),
        ].reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'So sánh theo thời gian',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.1,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval:
                        (comparativeData.length > 5)
                            ? (comparativeData.length / 5).ceil().toDouble()
                            : 1.0,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= comparativeData.length || index < 0) {
                        return const SizedBox();
                      }
                      int skipInterval =
                          comparativeData.length > 5
                              ? (comparativeData.length ~/ 5)
                              : 1;
                      if (skipInterval < 1) skipInterval = 1;
                      if (index % skipInterval != 0) {
                        return const SizedBox();
                      }
                      String label = comparativeData[index]['time'].toString();
                      if (selectedTimeFrame == TimeFrame.weekly) {
                        label = 'Tuần ${label.split('-')[0].substring(1)}';
                      } else if (selectedTimeFrame == TimeFrame.monthly) {
                        label =
                            label.split('-')[1] +
                            '/' +
                            label.split('-')[0].substring(2);
                      } else if (selectedTimeFrame == TimeFrame.quarterly) {
                        label = label;
                      } else if (selectedTimeFrame == TimeFrame.yearly) {
                        label = label;
                      } else if (selectedTimeFrame == TimeFrame.custom) {
                        try {
                          final date = DateFormat('yyyy-MM-dd').parse(label);
                          label = DateFormat('dd/MM').format(date);
                        } catch (e) {
                          label = comparativeData[index]['time'].toString();
                        }
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Transform.rotate(
                          angle: -45 * 0.0174533,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact(locale: 'vi_VN').format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots:
                      comparativeData
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value['revenue'].toDouble(),
                            ),
                          )
                          .toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots:
                      comparativeData
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value['profit'].toDouble(),
                            ),
                          )
                          .toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots:
                      comparativeData
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value['product'].toDouble(),
                            ),
                          )
                          .toList(),
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.orange.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTimeSeriesChart(
    String title,
    List<Map<String, dynamic>> data,
    Color color,
  ) {
    if (data.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: const Text(
          'Không có dữ liệu cho khoảng thời gian này',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final maxY =
        data
            .map((e) => e['value'] as num)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final minY =
        data
            .map((e) => e['value'] as num)
            .reduce((a, b) => a < b ? a : b)
            .toDouble();
    final yMargin = (maxY - minY) * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minY: minY - yMargin,
              maxY: maxY + yMargin,
              gridData: const FlGridData(show: true, drawVerticalLine: true),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval:
                        (data.length > 5)
                            ? (data.length / 5).ceil().toDouble()
                            : 1.0,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= data.length || index < 0) {
                        return const SizedBox();
                      }
                      int skipInterval =
                          data.length > 5 ? (data.length ~/ 5) : 1;
                      if (skipInterval < 1) skipInterval = 1;
                      if (index % skipInterval != 0) {
                        return const SizedBox();
                      }
                      String label = data[index]['time'].toString();
                      if (selectedTimeFrame == TimeFrame.weekly) {
                        label = 'Tuần ${label.split('-')[0].substring(1)}';
                      } else if (selectedTimeFrame == TimeFrame.monthly) {
                        label =
                            label.split('-')[1] +
                            '/' +
                            label.split('-')[0].substring(2);
                      } else if (selectedTimeFrame == TimeFrame.quarterly) {
                        label = label;
                      } else if (selectedTimeFrame == TimeFrame.yearly) {
                        label = label;
                      } else if (selectedTimeFrame == TimeFrame.custom) {
                        try {
                          final date = DateFormat('yyyy-MM-dd').parse(label);
                          label = DateFormat('dd/MM').format(date);
                        } catch (e) {
                          label = data[index]['time'].toString();
                        }
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Transform.rotate(
                          angle: -45 * 0.0174533,
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          NumberFormat.compact(locale: 'vi_VN').format(value),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots:
                      data.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value['value'].toDouble(),
                        );
                      }).toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFrameSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<TimeFrame>(
                value: selectedTimeFrame,
                underline: const SizedBox(),
                items:
                    TimeFrame.values.map((TimeFrame frame) {
                      String text = '';
                      switch (frame) {
                        case TimeFrame.yearly:
                          text = 'Theo năm';
                          break;
                        case TimeFrame.quarterly:
                          text = 'Theo quý';
                          break;
                        case TimeFrame.monthly:
                          text = 'Theo tháng';
                          break;
                        case TimeFrame.weekly:
                          text = 'Theo tuần';
                          break;
                        case TimeFrame.custom:
                          text = 'Tùy chỉnh';
                          break;
                      }
                      return DropdownMenuItem<TimeFrame>(
                        value: frame,
                        child: Text(text, style: TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                onChanged: (TimeFrame? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedTimeFrame = newValue;
                      if (newValue != TimeFrame.custom) {
                        customDateRange = null;
                      }
                    });
                    _showTimePicker(context);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTimeFrameText(selectedTimeFrame),
                      style: const TextStyle(fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      onPressed: () => _showTimePicker(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final now = DateTime.now();

    switch (selectedTimeFrame) {
      case TimeFrame.yearly:
        await _showYearPicker(context);
        break;
      case TimeFrame.quarterly:
        await _showYearPicker(context);
        if (selectedYear != null) {
          await _showQuarterPicker(context);
        }
        break;
      case TimeFrame.monthly:
        await _showYearPicker(context);
        if (selectedYear != null) {
          await _showMonthPicker(context);
        }
        break;
      case TimeFrame.weekly:
        await _showYearPicker(context);
        if (selectedYear != null) {
          await _showWeekPicker(context);
        }
        break;
      case TimeFrame.custom:
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            customDateRange = DateRange(picked.start, picked.end);
          });
          fetchDashboardData();
        }
        break;
    }
  }

  Future<void> _showYearPicker(BuildContext context) async {
    final now = DateTime.now();
    final years = List.generate(now.year - 2019, (index) => now.year - index);
    final initialIndex = years.indexOf(selectedYear ?? now.year);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chọn năm',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedYear = years[index];
                      });
                    },
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    children:
                        years
                            .map(
                              (year) => Center(
                                child: Text(
                                  year.toString(),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        fetchDashboardData();
                      },
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    final months = List.generate(12, (index) => index + 1);
    final maxMonth = selectedYear == now.year ? now.month : 12;
    final initialMonth =
        selectedMonth ?? (selectedYear == now.year ? now.month : 1);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn tháng năm $selectedYear',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMonth = months[index];
                      });
                    },
                    scrollController: FixedExtentScrollController(
                      initialItem: initialMonth - 1,
                    ),
                    children:
                        months
                            .take(maxMonth)
                            .map(
                              (month) => Center(
                                child: Text(
                                  'Tháng $month',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        fetchDashboardData();
                      },
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuarterPicker(BuildContext context) async {
    final now = DateTime.now();
    final quarters = [1, 2, 3, 4];
    final maxQuarter =
        selectedYear == now.year ? ((now.month - 1) ~/ 3) + 1 : 4;
    final initialQuarter =
        selectedQuarter ??
        (selectedYear == now.year ? ((now.month - 1) ~/ 3) + 1 : 1);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn quý năm $selectedYear',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedQuarter = quarters[index];
                      });
                    },
                    scrollController: FixedExtentScrollController(
                      initialItem: initialQuarter - 1,
                    ),
                    children:
                        quarters
                            .take(maxQuarter)
                            .map(
                              (quarter) => Center(
                                child: Text(
                                  'Quý $quarter',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        fetchDashboardData();
                      },
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWeekPicker(BuildContext context) async {
    final now = DateTime.now();
    final weeksInYear = _getWeeksInYear(selectedYear!);
    final weeks = List.generate(weeksInYear, (index) => index + 1);
    final maxWeek = selectedYear == now.year ? now.weekOfYear : weeksInYear;
    final initialWeek =
        selectedWeek ?? (selectedYear == now.year ? now.weekOfYear : 1);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn tuần năm $selectedYear',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedWeek = weeks[index];
                      });
                    },
                    scrollController: FixedExtentScrollController(
                      initialItem: initialWeek - 1,
                    ),
                    children:
                        weeks
                            .take(maxWeek)
                            .map(
                              (week) => Center(
                                child: Text(
                                  'Tuần ${week.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        fetchDashboardData();
                      },
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
