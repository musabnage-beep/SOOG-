import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/address.dart';
import 'core_providers.dart';

class AddressState {
  const AddressState({this.items = const [], this.isLoading = false, this.error});

  final List<Address> items;
  final bool isLoading;
  final String? error;

  Address? get defaultAddress {
    if (items.isEmpty) return null;
    return items.firstWhere((a) => a.isDefault, orElse: () => items.first);
  }

  AddressState copyWith({
    List<Address>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AddressState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AddressController extends StateNotifier<AddressState> {
  AddressController(this._ref) : super(const AddressState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ref.read(addressRepositoryProvider).list();
      state = AddressState(items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Address> create(Map<String, dynamic> body) async {
    final address = await _ref.read(addressRepositoryProvider).create(body);
    await load();
    return address;
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _ref.read(addressRepositoryProvider).update(id, body);
    await load();
  }

  Future<void> remove(String id) async {
    await _ref.read(addressRepositoryProvider).remove(id);
    state = state.copyWith(items: state.items.where((a) => a.id != id).toList());
  }
}

final addressControllerProvider =
    StateNotifierProvider<AddressController, AddressState>((ref) => AddressController(ref));
