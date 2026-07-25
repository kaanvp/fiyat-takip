import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PriceHistoryChart extends StatelessWidget {
  final List<PriceHistoryData> data;
  final String currency;

  const PriceHistoryChart({
    super.key,
    required this.data,
    this.currency = '₺',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Fiyat geçmişi bulunmuyor'),
      );
    }

    final sortedData = List<PriceHistoryData>.from(data);
    sortedData.sort((a, b) => a.date.compareTo(b.date));

    final minPrice = sortedData.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = sortedData.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final minY = (minPrice - priceRange * 0.1).clamp(0.0, double.infinity);
    final maxY = maxPrice + priceRange * 0.1;
    // Ensure horizontalInterval is never zero (happens when all prices are identical)
    final interval = ((maxY - minY) / 5).clamp(1.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withValues(alpha: 0.3),
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
                  interval: _calculateBottomInterval(sortedData.length),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedData.length) {
                      return _buildBottomTitle(sortedData[index].date);
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: (maxY - minY) / 5,
                  getTitlesWidget: (value, meta) {
                    return _buildLeftTitle(value, currency);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            minX: 0,
            maxX: (sortedData.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: sortedData
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(
                          entry.key.toDouble(),
                          entry.value.price,
                        ))
                    .toList(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.black87,
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index >= 0 && index < sortedData.length) {
                      final dataPoint = sortedData[index];
                      return LineTooltipItem(
                        '${dataPoint.price.toStringAsFixed(2)}$currency',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTitle(DateTime date) {
    final formatter = DateFormat('MMM dd');
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        formatter.format(date),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(double value, String currency) {
    return Text(
      '${value.toStringAsFixed(0)}$currency',
      style: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
      ),
    );
  }

  double _calculateBottomInterval(int dataLength) {
    if (dataLength <= 5) return 1;
    if (dataLength <= 10) return 2;
    if (dataLength <= 20) return 4;
    return (dataLength / 5).ceil().toDouble();
  }
}

class PriceHistoryData {
  final DateTime date;
  final double price;

  PriceHistoryData({
    required this.date,
    required this.price,
  });
}
