import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/expense.dart';
import '../../../core/constants/expense_constants.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../core/providers/database_providers.dart';
import '../../settings/providers/currency_providers.dart';

// Form state class
class ExpenseFormState {
  final double? amount;
  final DateTime date;
  final String category;
  final String? merchant;
  final String? notes;
  final String? paymentMethod;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  ExpenseFormState({
    this.amount,
    required this.date,
    required this.category,
    this.merchant,
    this.notes,
    this.paymentMethod,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ExpenseFormState copyWith({
    double? amount,
    DateTime? date,
    String? category,
    String? merchant,
    String? notes,
    String? paymentMethod,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ExpenseFormState(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  bool get isValid {
    return amount != null && amount! > 0 && category.isNotEmpty;
  }
}

// State notifier for expense form
class ExpenseFormNotifier extends StateNotifier<ExpenseFormState> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpenseFormNotifier(this._repository, this._ref)
      : super(ExpenseFormState(
          date: DateTime.now(),
          category: ExpenseCategories.other,
        ));

  void setAmount(String value) {
    final amount = double.tryParse(value);
    state = state.copyWith(amount: amount, errorMessage: null);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date, errorMessage: null);
  }

  void setCategory(String category) {
    state = state.copyWith(category: category, errorMessage: null);
  }

  void setMerchant(String merchant) {
    state = state.copyWith(merchant: merchant, errorMessage: null);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes, errorMessage: null);
  }

  void setPaymentMethod(String? paymentMethod) {
    state = state.copyWith(paymentMethod: paymentMethod, errorMessage: null);
  }

  Future<bool> saveExpense() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Please fill in all required fields',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final currency = _ref.read(currencyNotifierProvider);
      final expense = Expense(
        amount: state.amount!,
        category: state.category,
        description: state.notes,
        date: state.date,
        paymentMethod: state.paymentMethod,
        currency: currency,
      );

      await _repository.createExpense(expense);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save expense: $e',
      );
      return false;
    }
  }

  void reset() {
    state = ExpenseFormState(
      date: DateTime.now(),
      category: ExpenseCategories.other,
    );
  }

  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category is required';
    }
    return null;
  }
}

// Provider for expense form
final expenseFormProvider =
    StateNotifierProvider.autoDispose<ExpenseFormNotifier, ExpenseFormState>(
  (ref) {
    final repository = ref.watch(expenseRepositoryProvider);
    return ExpenseFormNotifier(repository, ref);
  },
);
