import 'package:aplikasi_warung_supabase/models/customer_model.dart';
import 'package:aplikasi_warung_supabase/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  num _totalDebt = 0;

  // Gunakan getter filteredCustomers untuk UI utama
  List<CustomerModel> get filteredCustomers => _filteredCustomers;
  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  num get totalDebt => _totalDebt;

  // 1. Fetch Data
  Future<void> fetchCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('customers')
          .select('*')
          .order('name_customer', ascending: true);

      final List<dynamic> data = response;
      _customers = data.map((item) => CustomerModel.fromJson(item)).toList();
      _applySearch(); // Ini akan mengisi _filteredCustomers
    } catch (e) {
      debugPrint('❌ ERROR: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Debt Customer
  Future<void> fetchCustomerTotalDebt(String customerId) async {
    try {
      // 1. Ambil kolom remaining_amount untuk transaksi yang belum 'paid' / belum lunas
      final response = await _supabase
          .from('debt')
          .select('remaining_amount')
          .eq('customer_id', customerId)
          .neq(
            'status',
            'paid',
          ); // Sesuaikan string 'paid' dengan nilai status lunas di DB kamu

      final List<dynamic> data = response;

      // 2. Jumlahkan semua sisa hutangnya
      _totalDebt = data.fold<num>(
        0,
        (sum, item) => sum + (item['remaining_amount'] ?? 0),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetch total debt: $e');
    }
  }

  // 2. Filter Logika
  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) {
        final nameMatch = customer.nameCustomer.toLowerCase().startsWith(
          _searchQuery.toLowerCase(),
        );
        final phoneMatch = customer.phoneNumber.contains(_searchQuery);
        return nameMatch || phoneMatch;
      }).toList();
    }
  }

  // 3. Set Keyword Searching
  void searchCustomer(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  // Tambah Customer
  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      await _supabase.from('customers').insert({
        'name_customer': name,
        'phone_number': phone,
        'address': address,
      });

      await fetchCustomers();
      return true;
    } catch (e) {
      debugPrint('Error add customer: $e');
      return false;
    }
  }

  // Edit Customer
  Future<bool> updateCustomer({
    required String id,
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      await _supabase
          .from('customers')
          .update({
            'name_customer': name,
            'phone_number': phone,
            'address': address,
          })
          .eq('id', id);

      await fetchCustomers();
      return true;
    } catch (e) {
      debugPrint('Error update customer: $e');
      return false;
    }
  }

  // Hapus Customer
  Future<bool> deleteCustomer(String id) async {
    try {
      await _supabase.from('customers').delete().eq('id', id);

      await fetchCustomers();
      return true;
    } catch (e) {
      debugPrint('Error delete customer: $e');
      return false; 
    }
  }
}
