import 'package:equatable/equatable.dart';

class CustomerListParams extends Equatable {
  final String search;
  final int page;
  final int limit;
  final String sort;
  final String order;

  const CustomerListParams({
    this.search = '',
    this.page = 1,
    this.limit = 20,
    this.sort = 'name',
    this.order = 'asc',
  });

  CustomerListParams copyWith({String? search, int? page}) => CustomerListParams(
    search: search ?? this.search,
    page: page ?? this.page,
    limit: limit, sort: sort, order: order,
  );

  @override
  List<Object?> get props => [search, page, limit, sort, order];
}

class BillListParams extends Equatable {
  final String search;
  final String status;
  final String? from;
  final String? to;
  final int page;
  final int limit;

  const BillListParams({
    this.search = '',
    this.status = 'all',
    this.from,
    this.to,
    this.page = 1,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [search, status, from, to, page, limit];
}

class PaymentListParams extends Equatable {
  final String? customerId;
  final int page;
  final int limit;

  const PaymentListParams({
    this.customerId,
    this.page = 1,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [customerId, page, limit];
}

class LedgerParams extends Equatable {
  final String customerId;
  final String? from;
  final String? to;

  const LedgerParams({required this.customerId, this.from, this.to});

  @override
  List<Object?> get props => [customerId, from, to];
}

class StatementParams extends Equatable {
  final String customerId;
  final String from;
  final String to;

  const StatementParams({required this.customerId, required this.from, required this.to});

  @override
  List<Object?> get props => [customerId, from, to];
}
