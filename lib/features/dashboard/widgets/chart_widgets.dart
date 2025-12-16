import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/expense_constants.dart';
import '../providers/dashboard_provider.dart';
import '../../../services/currency_service.dart';
import '../../settings/providers/currency_providers.dart';

/// Category pie chart widget
class CategoryPieChart extends ConsumerStatefulWidget {
  final Map<String, double> categoryTotals;
  final double size;

  const CategoryPieChart({
    super.key,
    required this.categoryTotals,
    this.size = 220,
  });

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTotals.isEmpty) {
      return _buildEmptyState(context);
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: _showingSections(context),
              ),
            ),
          ),
          Expanded(
            child: _buildLegend(context),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.categoryTotals.values.fold<double>(
      0.0,
      (sum, value) => sum + value,
    );

    final colors = _getCategoryColors(context);
    final entries = widget.categoryTotals.entries.toList();

    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? widget.size * 0.35 : widget.size * 0.3;
      final category = entries[i].key;
      final value = entries[i].value;
      final percentage = (value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: colors[category] ?? Colors.grey,
        value: value,
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }

  Widget _buildLegend(BuildContext context) {
    final colors = _getCategoryColors(context);
    final entries = widget.categoryTotals.entries.toList();
    
    // Sort by value descending
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final emoji = ExpenseCategories.getEmoji(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[entry.key],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$emoji ${entry.key}',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final currency = ref.watch(currencyNotifierProvider);
                  final symbol = CurrencyService.getSymbol(currency);
                  return Text(
                    '$symbol${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: widget.size,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No category data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getCategoryColors(BuildContext context) {
    return {
      ExpenseCategories.food: const Color(0xFFFF6B6B),
      ExpenseCategories.groceries: const Color(0xFF4ECDC4),
      ExpenseCategories.transportation: const Color(0xFF45B7D1),
      ExpenseCategories.shopping: const Color(0xFFFFA07A),
      ExpenseCategories.entertainment: const Color(0xFF98D8C8),
      ExpenseCategories.utilities: const Color(0xFFF7DC6F),
      ExpenseCategories.healthcare: const Color(0xFFE74C3C),
      ExpenseCategories.education: const Color(0xFF3498DB),
      ExpenseCategories.travel: const Color(0xFF9B59B6),
      ExpenseCategories.fitness: const Color(0xFF1ABC9C),
      ExpenseCategories.personal: const Color(0xFFE91E63),
      ExpenseCategories.home: const Color(0xFF795548),
      ExpenseCategories.business: const Color(0xFF607D8B),
      ExpenseCategories.insurance: const Color(0xFF00BCD4),
      ExpenseCategories.gifts: const Color(0xFFFFC107),
      ExpenseCategories.subscriptions: const Color(0xFF673AB7),
      ExpenseCategories.other: Colors.grey,
    };
  }
}

/// Monthly trend line chart
class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyData> monthlyData;

  const MonthlyTrendChart({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);
    final maxY = monthlyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 100,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                      final month = monthlyData[value.toInt()].month;
                      final monthName = _getMonthAbbreviation(month.month);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY > 0 ? maxY / 4 : 100,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                left: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
            ),
            minX: 0,
            maxX: (monthlyData.length - 1).toDouble(),
            minY: minY,
            maxY: maxY * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: monthlyData.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value.amount);
                }).toList(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.primary,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.3),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: theme.colorScheme.surface,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '\$${spot.y.toStringAsFixed(2)}',
                      TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No trend data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Weekly bar chart
class WeeklyBarChart extends StatelessWidget {
  final List<WeeklyData> weeklyData;

  const WeeklyBarChart({
    super.key,
    required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);
    final maxY = weeklyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: theme.colorScheme.surface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '\$${rod.toY.toStringAsFixed(2)}',
                    TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          weeklyData[value.toInt()].day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: maxY > 0 ? maxY / 4 : 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                left: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 50,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: weeklyData.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.amount,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No weekly data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
