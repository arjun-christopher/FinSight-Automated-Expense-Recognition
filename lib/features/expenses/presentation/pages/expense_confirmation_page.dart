import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/expense.dart';
import '../../core/constants/expense_constants.dart';
import '../../services/ocr_workflow_service.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/providers/database_providers.dart';

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
      text: receipt.items?.map((i) => i.description).join(', ') ?? '',
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
      final expense = Expense(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        merchantName: _merchantController.text.isEmpty 
            ? null 
            : _merchantController.text,
        notes: _notesController.text.isEmpty 
            ? null 
            : _notesController.text,
        paymentMethod: _selectedPaymentMethod,
        receiptImagePath: widget.result.imagePath,
      );

      final repository = ref.read(expenseRepositoryProvider);
      await repository.createExpense(expense);

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

        // Navigate back to home
        context.go('/');
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
    final confidence = result.overallConfidence;
    final needsReview = result.needsReview;
    
    Color cardColor = Colors.green.shade50;
    Color iconColor = Colors.green;
    IconData icon = Icons.check_circle;
    String message = 'High confidence';
    
    if (needsReview) {
      cardColor = Colors.orange.shade50;
      iconColor = Colors.orange;
      icon = Icons.warning;
      message = 'Please review carefully';
    }
    
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
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Receipt Image',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(ThemeData theme) {
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
        fillColor: _isEditing ? null : Colors.grey.shade100,
      ),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMerchantField(ThemeData theme) {
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
        fillColor: _isEditing ? null : Colors.grey.shade100,
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: _isEditing ? null : Colors.grey.shade100,
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
    return InkWell(
      onTap: _isEditing ? () => _selectDate(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: _isEditing ? null : Colors.grey.shade100,
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
                      color: Colors.grey.shade600,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: _isEditing ? null : Colors.grey.shade100,
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
        fillColor: _isEditing ? null : Colors.grey.shade100,
      ),
    );
  }

  Widget _buildClassificationInfo(ClassificationResult classification) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'AI Classification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (classification.reasoning != null) ...[
              Text(
                classification.reasoning!,
                style: TextStyle(color: Colors.blue.shade900),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Method: ${classification.method.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
                Text(
                  '${(classification.confidence * 100).toStringAsFixed(1)}% confident',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
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
