import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/expense_constants.dart';
import '../../providers/expense_form_provider.dart';
import '../../widgets/expense_form_widgets.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  const AddExpensePage({super.key});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final formState = ref.read(expenseFormProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: formState.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(expenseFormProvider.notifier).setDate(picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(expenseFormProvider.notifier).saveExpense();

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Expense saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _amountController.clear();
        _merchantController.clear();
        _notesController.clear();
        ref.read(expenseFormProvider.notifier).reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(expenseFormProvider);
    final formNotifier = ref.watch(expenseFormProvider.notifier);

    // Show error message if any
    ref.listen(expenseFormProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount Field
                  CustomTextField(
                    label: 'Amount *',
                    hint: '0.00',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.attach_money),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: formNotifier.validateAmount,
                    onChanged: (value) {
                      formNotifier.setAmount(value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category Selection
                  Text(
                    'Category *',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategories.all.map((category) {
                      return CategoryChip(
                        category: category,
                        emoji: ExpenseCategories.getEmoji(category),
                        isSelected: formState.category == category,
                        onTap: () {
                          formNotifier.setCategory(category);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Date Picker
                  CustomTextField(
                    label: 'Date *',
                    hint: 'Select date',
                    controller: TextEditingController(
                      text: DateFormat('MMM dd, yyyy').format(formState.date),
                    ),
                    readOnly: true,
                    prefixIcon: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 24),

                  // Merchant Field
                  CustomTextField(
                    label: 'Merchant',
                    hint: 'Store or vendor name',
                    controller: _merchantController,
                    prefixIcon: const Icon(Icons.store),
                    onChanged: (value) {
                      formNotifier.setMerchant(value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Payment Method Dropdown
                  CustomDropdownField<String>(
                    label: 'Payment Method',
                    value: formState.paymentMethod,
                    items: PaymentMethods.all,
                    itemLabel: (item) => item,
                    prefixIcon: const Icon(Icons.payment),
                    onChanged: (value) {
                      formNotifier.setPaymentMethod(value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Notes Field
                  CustomTextField(
                    label: 'Notes',
                    hint: 'Add additional details...',
                    controller: _notesController,
                    maxLines: 3,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes),
                    ),
                    onChanged: (value) {
                      formNotifier.setNotes(value);
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  AnimatedSubmitButton(
                    onPressed: _handleSubmit,
                    isLoading: formState.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Required fields hint
                  Center(
                    child: Text(
                      '* Required fields',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
