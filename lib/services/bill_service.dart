import 'api_client.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/bill_adjustment.dart';
import '../models/draft_bill.dart';

class BillService {
  final ApiClient _client = ApiClient();

  Future<({List<Bill> data, Map<String, dynamic>? meta})> getAll({
    String? search, String? status, String? from, String? to,
    int page = 1, int limit = 50,
  }) async {
    final response = await _client.get('/bills', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'all') 'status': status,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      'page': page, 'limit': limit,
    });
    final body = response.data;
    final list = (body['data'] as List).map((e) => Bill.fromJson(e)).toList();
    return (data: list, meta: body['meta'] as Map<String, dynamic>?);
  }

  Future<({Bill bill, List<BillItem> items, List<BillAdjustment> adjustments})> getById(String id) async {
    final response = await _client.get('/bills/$id');
    final data = response.data['data'];
    final bill = Bill.fromJson(data['bill']);
    final items = (data['items'] as List).map((e) => BillItem.fromJson(e)).toList();
    final adjustments = (data['adjustments'] as List).map((e) => BillAdjustment.fromJson(e)).toList();
    return (bill: bill, items: items, adjustments: adjustments);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _client.post('/bills', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> cancel(String id) async {
    await _client.post('/bills/$id/cancel');
  }

  Future<Map<String, dynamic>> adjust(String id, {required List<Map<String, dynamic>> items}) async {
    final response = await _client.put('/bills/$id/adjust', data: {
      'items': items,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<DraftBill>> getDrafts({String? search}) async {
    final response = await _client.get('/bills/drafts', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final list = (response.data['data'] as List)
        .map((e) => DraftBill.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list;
  }

  Future<DraftBill> getDraftById(String id) async {
    final response = await _client.get('/bills/drafts/$id');
    return DraftBill.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<DraftBill> saveDraft(Map<String, dynamic> data) async {
    final response = await _client.post('/bills/drafts', data: data);
    return DraftBill.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<void> discardDraft(String id) async {
    await _client.delete('/bills/drafts/$id');
  }
}
