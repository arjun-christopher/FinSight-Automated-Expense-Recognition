import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/expense.dart';
import '../../../../core/models/classification_result.dart';
import '../../../../core/constants/expense_constants.dart';
import '../../../../services/ocr_workflow_service.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../settings/providers/currency_providers.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/notification_scheduler.dart';
import '../../../../services/budget_service.dart';
import '../../../budget/providers/budget_providers.dart';
import '../../../../core/providers/database_providers.dart';

/// Provider for workflow result
final workflowResultProvider = StateProvider<WorkflowResult?>((ref) => null);

/// Confirmation screen for reviewing OCR-processed expense
class ExpenseConfirmationPage extends ConsumerStatefulWidget {
  final WorkflowResult result;

  const ExpenseConfirmationPage({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<ExpenseConfirmationPage> createState() =>
      _ExpenseConfirmationPageState();
}

class _ExpenseConfirmationPageState
    extends ConsumerState<ExpenseConfirmationPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _notesController;
  
  late String _selectedCategory;
  late DateTime _selectedDate;
  String? _selectedPaymentMethod;
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize from workflow result
    final receipt = widget.result.parsedReceipt!;
    _amountController = TextEditingController(
      text: receipt.totalAmount?.toStringAsFixed(2) ?? '',
    );
    _merchantController = TextEditingController(
      text: receipt.merchantName ?? '',
    );
    _notesController = TextEditingController(
      text: receipt.items?.map((i) => i.name).join(', ') ?? '',
    );
    
    _selectedCategory = widget.result.classification?.category ?? ExpenseCategories.other;
    _selectedDate = receipt.date ?? DateTime.now();
    _selectedPaymentMethod = receipt.paymentMethod;
    
    // Animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount is required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currency = ref.read(currencyNotifierProvider);
      final expense = Expense(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        description: _notesController.text.isEmpty 
            ? _merchantController.text 
            : _notesController.text,
        paymentMethod: _selectedPaymentMethod,
        currency: currency,
      );

      final repository = ref.read(expenseRepositoryProvider);
      await repository.createExpense(expense);

      // Check budget alerts after creating expense
      try {
        final settingsAsync = ref.read(notificationSettingsProvider);
        final settings = settingsAsync.valueOrNull;
        if (settings?.budgetAlertsEnabled == true) {
          final notificationService = ref.read(notificationServiceProvider);
          final budgetService = ref.read(budgetServiceProvider);
          await notificationService.checkAndSendBudgetAlerts(budgetService);
        }
      } catch (e) {
        // Don't fail expense save if notification check fails
        print('Failed to check budget alerts: $e');
      }

      if (mounted) {
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
          ),
        );

        // Navigate back to receipt capture for next scan
        context.go('/receipt-capture');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Expense'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            tooltip: _isEditing ? 'Done editing' : 'Edit details',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Confidence indicator
              _buildConfidenceCard(result),
              
              const SizedBox(height: 16),
              
              // Receipt image preview
              _buildImagePreview(result.imagePath),
              
              const SizedBox(height: 24),
              
              // Extracted data
              Text(
                'Extracted Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Amount
              _buildAmountField(theme),
              
              const SizedBox(height: 16),
              
              // Merchant
              _buildMerchantField(theme),
              
              const SizedBox(height: 16),
              
              // Category
              _buildCategorySelector(theme),
              
              const SizedBox(height: 16),
              
              // Date
              _buildDateSelector(theme),
              
              const SizedBox(height: 16),
              
              // Payment method
              _buildPaymentMethodSelector(theme),
              
              const SizedBox(height: 16),
              
              // Notes
              _buildNotesField(theme),
              
              const SizedBox(height: 24),
              
              // Classification info (if available)
              if (result.classification != null)
                _buildClassificationInfo(result.classification!),
              
              const SizedBox(height: 24),
              
              // Save button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceCard(WorkflowResult result) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final confidence = result.overallConfidence;
    final needsReview = result.needsReview;
    
    Color cardColor = needsReview 
        ? (isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50)
        : (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50);
    Color iconColor = needsReview ? Colors.orange : Colors.green;
    IconData icon = needsReview ? Icons.warning : Icons.check_circle;
    String message = needsReview ? 'Please review carefully' : 'High confidence';
    
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(color: iconColor),
                  ),
                ],
              ),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imagePath) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                final errorTheme = Theme.of(context);
                return Container(
                  color: errorTheme.colorScheme.surfaceVariant,
                  child: Center(
                    child: Icon(
                      Icons.broken_image, 
                      size: 48,
                      color: errorTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Receipt Image',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: _amountController,
      enabled: _isEditing,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount *',
        prefixText: '\$',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _isEditing ? null : (isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade100),
      ),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMerchantField(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: _merchantController,
      enabled: _isEditing,
      decoration: InputDecoration(
        labelText: 'Merchant',
        prefixIcon: const Icon(Icons.store),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _isEditing ? null : (isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade100),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: _isEditing ? null : (isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade100),
          ),
          child: DropdownButton<String>(
            value: _selectedCategory,
            isExpanded: true,
            underline: const SizedBox(),
            items: ExpenseCategories.all.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Text(ExpenseCategories.getEmoji(category)),
                    const SizedBox(width: 8),
                    Text(category),
                  ],
                ),
              );
            }).toList(),
            onChanged: _isEditing
                ? (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: _isEditing ? () => _selectDate(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
          color: _isEditing ? null : (isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: _isEditing ? null : (isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade100),
          ),
          child: DropdownButton<String?>(
            value: _selectedPaymentMethod,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Select payment method'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Not specified'),
              ),
              ...PaymentMethods.all.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }),
            ],
            onChanged: _isEditing
                ? (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: _notesController,
      enabled: _isEditing,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notes',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _isEditing ? null : (isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade100),
      ),
    );
  }

  Widget _buildClassificationInfo(ClassificationResult classification) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final infoColor = isDark ? Colors.blue.shade700 : Colors.blue.shade700;
    final bgColor = isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50;
    
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: infoColor),
                const SizedBox(width: 8),
                Text(
                  'AI Classification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: infoColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Method: ${classification.method.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: infoColor,
                  ),
                ),
                Text(
                  '${(classification.confidence * 100).toStringAsFixed(1)}% confident',
                  style: TextStyle(
                    fontSize: 12,
                    color: infoColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveExpense,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Save Expense',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
