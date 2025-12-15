import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/expenses/presentation/pages/expense_confirmation_page.dart';
import '../../features/receipt/presentation/pages/receipt_capture_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../services/ocr_workflow_service.dart';
import '../widgets/main_navigation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/add-expense',
            name: 'add-expense',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AddExpensePage(),
            ),
          ),
          GoRoute(
            path: '/receipt-capture',
            name: 'receipt-capture',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReceiptCapturePage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
      // Full screen routes (outside shell)
      GoRoute(
        path: '/expense-confirmation',
        name: 'expense-confirmation',
        pageBuilder: (context, state) {
          final result = state.extra as WorkflowResult;
          return MaterialPage(
            child: ExpenseConfirmationPage(result: result),
          );
        },
      ),
    ],
  );
});
