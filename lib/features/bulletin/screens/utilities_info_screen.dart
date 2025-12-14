import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';

class UtilitiesInfoScreen extends StatefulWidget {
  const UtilitiesInfoScreen({Key? key}) : super(key: key);

  @override
  State<UtilitiesInfoScreen> createState() => _UtilitiesInfoScreenState();
}

class _UtilitiesInfoScreenState extends State<UtilitiesInfoScreen> {
  late List<UtilityRecord> electricityRecords;
  late List<UtilityRecord> waterRecords;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    electricityRecords = [
      UtilityRecord(
        date: DateTime(2025, 1, 15),
        reading: 1250,
        cost: 275000,
        unit: 'kWh',
      ),
      UtilityRecord(
        date: DateTime(2024, 12, 15),
        reading: 1180,
        cost: 259600,
        unit: 'kWh',
      ),
      UtilityRecord(
        date: DateTime(2024, 11, 15),
        reading: 1120,
        cost: 246400,
        unit: 'kWh',
      ),
      UtilityRecord(
        date: DateTime(2024, 10, 15),
        reading: 1095,
        cost: 240900,
        unit: 'kWh',
      ),
    ];

    waterRecords = [
      UtilityRecord(
        date: DateTime(2025, 1, 15),
        reading: 125,
        cost: 150000,
        unit: 'm³',
      ),
      UtilityRecord(
        date: DateTime(2024, 12, 15),
        reading: 120,
        cost: 144000,
        unit: 'm³',
      ),
      UtilityRecord(
        date: DateTime(2024, 11, 15),
        reading: 115,
        cost: 138000,
        unit: 'm³',
      ),
      UtilityRecord(
        date: DateTime(2024, 10, 15),
        reading: 110,
        cost: 132000,
        unit: 'm³',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông tin Điện & Nước',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Electricity Section
            _buildUtilitySection(
              title: '⚡ Điện',
              icon: Icons.flash_on,
              records: electricityRecords,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            // Water Section
            _buildUtilitySection(
              title: '💧 Nước',
              icon: Icons.water_drop,
              records: waterRecords,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            // Summary Card
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilitySection({
    required String title,
    required IconData icon,
    required List<UtilityRecord> records,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(record.date),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chỉ số: ${record.reading} ${record.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${NumberFormat('#,###').format(record.cost)} đ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (index < records.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Divider(
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final currentElec = electricityRecords.first;
    final currentWater = waterRecords.first;
    final previousElec = electricityRecords.length > 1 ? electricityRecords[1] : currentElec;
    final previousWater = waterRecords.length > 1 ? waterRecords[1] : currentWater;

    final elecUsage = currentElec.reading - previousElec.reading;
    final waterUsage = currentWater.reading - previousWater.reading;
    final totalCost = currentElec.cost + currentWater.cost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentPurple.withOpacity(0.1), AppColors.accentPurple.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt tháng hiện tại',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                label: 'Điện tiêu thụ',
                value: '$elecUsage kWh',
                color: Colors.amber,
              ),
              _buildSummaryItem(
                label: 'Nước tiêu thụ',
                value: '$waterUsage m³',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng chi phí',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(totalCost)} đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class UtilityRecord {
  final DateTime date;
  final int reading;
  final int cost;
  final String unit;

  UtilityRecord({
    required this.date,
    required this.reading,
    required this.cost,
    required this.unit,
  });
}
