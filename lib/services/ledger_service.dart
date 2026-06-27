import 'api_client.dart';
import '../models/ledger_entry.dart';

class LedgerService {
  final ApiClient _client = ApiClient();

  Future<List<LedgerEntry>> getByCustomer(String customerId, {String? from, String? to}) async {
    final response = await _client.get('/ledger/$customerId', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    return (response.data['data'] as List).map((e) => LedgerEntry.fromJson(e)).toList();
  }
}
