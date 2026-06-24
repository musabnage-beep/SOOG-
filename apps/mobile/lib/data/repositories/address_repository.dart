import '../../core/network/api_client.dart';
import '../models/address.dart';

class AddressRepository {
  AddressRepository(this._api);

  final ApiClient _api;

  Future<List<Address>> list() async {
    final data = await _api.get<List<dynamic>>('/addresses');
    return data.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Address> create(Map<String, dynamic> body) async {
    final data = await _api.post<Map<String, dynamic>>('/addresses', data: body);
    return Address.fromJson(data);
  }

  Future<Address> update(String id, Map<String, dynamic> body) async {
    final data = await _api.patch<Map<String, dynamic>>('/addresses/$id', data: body);
    return Address.fromJson(data);
  }

  Future<void> remove(String id) async {
    await _api.delete<dynamic>('/addresses/$id');
  }
}
