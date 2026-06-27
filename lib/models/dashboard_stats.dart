import 'package:equatable/equatable.dart';
import 'customer.dart';
import 'bill.dart';
import 'payment.dart';

class DashboardStats extends Equatable {
  final double todayRevenue;
  final int todayOrders;
  final double monthlyCollection;
  final double outstanding;
  final int totalCustomers;
  final int pendingCustomers;
  final List<Customer> topCustomers;
  final List<Bill> recentBills;
  final List<Payment> recentPayments;
  final List<SalesData> salesSeries;

  const DashboardStats({
    this.todayRevenue = 0,
    this.todayOrders = 0,
    this.monthlyCollection = 0,
    this.outstanding = 0,
    this.totalCustomers = 0,
    this.pendingCustomers = 0,
    this.topCustomers = const [],
    this.recentBills = const [],
    this.recentPayments = const [],
    this.salesSeries = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
    todayOrders: json['todayOrders'] ?? 0,
    monthlyCollection: (json['monthlyCollection'] ?? 0).toDouble(),
    outstanding: (json['outstanding'] ?? 0).toDouble(),
    totalCustomers: json['totalCustomers'] ?? 0,
    pendingCustomers: json['pendingCustomers'] ?? 0,
    topCustomers: (json['topCustomers'] as List<dynamic>?)
        ?.map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    recentBills: (json['recentBills'] as List<dynamic>?)
        ?.map((e) => Bill.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    recentPayments: (json['recentPayments'] as List<dynamic>?)
        ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    salesSeries: (json['salesSeries'] as List<dynamic>?)
        ?.map((e) => SalesData.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  @override
  List<Object?> get props => [todayRevenue, todayOrders, monthlyCollection, outstanding];
}

class SalesData extends Equatable {
  final String month;
  final double sales;

  const SalesData({required this.month, required this.sales});

  factory SalesData.fromJson(Map<String, dynamic> json) => SalesData(
    month: json['month'] ?? '',
    sales: (json['sales'] ?? 0).toDouble(),
  );

  @override
  List<Object?> get props => [month, sales];
}
