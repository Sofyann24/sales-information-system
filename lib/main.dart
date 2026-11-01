import 'package:aplikasi_warung_supabase/models/debt_model.dart';
import 'package:aplikasi_warung_supabase/providers/auth_provider.dart';
import 'package:aplikasi_warung_supabase/providers/cart_provider.dart';
import 'package:aplikasi_warung_supabase/providers/category_provider.dart';
import 'package:aplikasi_warung_supabase/providers/customer_provider.dart';
import 'package:aplikasi_warung_supabase/providers/debt_provider.dart';
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:aplikasi_warung_supabase/providers/sales_report_provider.dart';
import 'package:aplikasi_warung_supabase/providers/transaction_details_provider.dart';
import 'package:aplikasi_warung_supabase/providers/transaction_provider.dart';
import 'package:aplikasi_warung_supabase/views/customers/add_customer_screen.dart';
import 'package:aplikasi_warung_supabase/views/dashboard_menu/categories/categories_screen.dart';
import 'package:aplikasi_warung_supabase/views/dashboard_menu/debt/debt_list_screen.dart';
import 'package:aplikasi_warung_supabase/views/dashboard_menu/debt/pay_debt_screen.dart';
import 'package:aplikasi_warung_supabase/views/dashboard_menu/history_transaction.dart';
import 'package:aplikasi_warung_supabase/views/dashboard_menu/report_screen.dart';
import 'package:aplikasi_warung_supabase/views/login_screen.dart';
import 'package:aplikasi_warung_supabase/views/splash_screen.dart';
import 'package:aplikasi_warung_supabase/views/stock/add_stock_screen.dart';
import 'package:aplikasi_warung_supabase/services/supabase_service.dart';
import 'package:aplikasi_warung_supabase/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding. ensureInitialized();
  
  await dotenv.load();
  await SupabaseService.init();
  await initializeDateFormatting('id_ID', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => TransactionDetailsProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => SalesReportProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splashScreen',
      routes: {
        '/splashScreen': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainLayout(),
        '/addStock': (context) => const AddProductScreen(),
        '/addCustomers': (context) => const AddCustomerScreen(),
        '/reportScreen': (context) => const SalesReportScreen(),
        '/historyTransaction': (context) => const HistoryTransactionScreen(),
        '/debtList': (context) => const DebtListScreen(),
        '/category': (context) => const CategoriesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/payDebt') {
          // Tangkap arguments yang dikirim saat Navigator.pushNamed
          final debt = settings.arguments as DebtModel;

          return MaterialPageRoute(
            builder: (context) => PayDebtScreen(debt: debt),
          );
        }
        return null;
      },
    );
  }
}
