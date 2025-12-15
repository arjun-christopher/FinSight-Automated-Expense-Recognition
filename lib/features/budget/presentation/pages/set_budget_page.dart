import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/budget.dart';
import '../../../../core/constants/expense_constants.dart';
import '../../providers/budget_providers.dart';

/// Page for creating or editing a budget
class SetBudgetPage extends ConsumerStatefulWidget {
  final Budget? budget;

  const SetBudgetPage({super.key, this.budget});

  @override
  ConsumerState<SetBudgetPage> createState() => _SetBudgetPageState();
}

class _SetBudgetPageState extends ConsumerState<SetBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late String _selectedCategory;
  late BudgetPeriod _selectedPeriod;
  late DateTime _startDate;
  DateTime? _endDate;
  late double _alertThreshold;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget?.amount.toStringAsFixed(2) ?? '',
    );
    _selectedCategory = widget.budget?.category ?? ExpenseCategories.food;
    _selectedPeriod = widget.budget?.period ?? BudgetPeriod.monthly;
    _startDate = widget.budget?.startDate ?? DateTime.now();
    _endDate = widget.budget?.endDate;
    _alertThreshold = widget.budget?.alertThreshold ?? 0.8;
    _isActive = widget.budget?.isActive ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.budget != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Budget' : 'Set Budget'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Selection
            Text(
              'Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: ExpenseCategories.all.map((category) {
                final emoji = ExpenseCategories.getEmoji(category);
                return DropdownMenuItem(
                  value: category,
                  child: Text('$emoji $category'),
                );
              }).toList(),
              onChanged: isEditing
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Amount Input
            Text(
              'Budget Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Period Selection
            Text(
              'Budget Period',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BudgetPeriod>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.calendar_month),
              ),
              items: BudgetPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(_getPeriodDisplayName(period)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Start Date
            Text(
              'Start Date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectStartDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.event),
                ),
                child: Text(_formatDate(_startDate)),
              ),
            ),
            const SizedBox(height: 24),

            // End Date (Optional)
            Row(
              children: [
                Text(
                  'End Date (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_endDate != null)
                  TextButton(
                    onPressed: () => setState(() => _endDate = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectEndDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.event),
                ),
                child: Text(
                  _endDate != null
                      ? _formatDate(_endDate!)
                      : 'No end date (recurring)',
                  style: TextStyle(
                    color: _endDate != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Alert Threshold
            Text(
              'Alert Threshold',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alert when reaching',
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          '${(_alertThreshold * 100).toInt()}%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _alertThreshold,
                      min: 0.5,
                      max: 1.0,
                      divisions: 10,
                      label: '${(_alertThreshold * 100).toInt()}%',
                      onChanged: (value) {
                        setState(() => _alertThreshold = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Active Toggle
            SwitchListTile(
              title: const Text('Active'),
              subtitle: Text(
                _isActive
                    ? 'Budget is currently active'
                    : 'Budget is inactive',
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveBudget,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Update Budget' : 'Create Budget',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodDisplayName(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'Daily';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      final budget = Budget(
        id: widget.budget?.id,
        category: _selectedCategory,
        amount: amount,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        alertThreshold: _alertThreshold,
        isActive: _isActive,
        createdAt: widget.budget?.createdAt,
      );

      if (widget.budget != null) {
        await ref.read(budgetListProvider.notifier).updateBudget(budget);
      } else {
        await ref.read(budgetListProvider.notifier).createBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.budget != null
                  ? 'Budget updated successfully'
                  : 'Budget created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
