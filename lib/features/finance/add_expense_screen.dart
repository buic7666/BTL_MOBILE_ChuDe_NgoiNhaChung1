import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';

enum SplitMode { equal, percent, perPerson }

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController(text: '1000');
  final _titleController = TextEditingController();
  int _selectedPayerIndex = 0;
  SplitMode _splitMode = SplitMode.equal; // default: Đều
  // percent split fields
  int _percent = 30;
  int _percentMemberIndex = 0;
  final TextEditingController _percentController = TextEditingController(
    text: '30',
  );

  final List<Map<String, dynamic>> _members = [
    {'id': 'you', 'name': 'Bạn', 'color': const Color(0xFF8E54E9)},
    {'id': 'an', 'name': 'An', 'color': const Color(0xFF5A31D8)},
    {'id': 'binh', 'name': 'Binh', 'color': const Color(0xFF80CBC4)},
    {'id': 'chi', 'name': 'Chi', 'color': const Color(0xFFEF9A9A)},
  ];

  NumberFormat get _moneyFmt =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late List<bool> _memberSelected;

  double get _parsedAmount {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(raw) ?? 0.0;
  }

  double _perPersonShare() {
    final amt = _parsedAmount;
    if (_members.isEmpty) return 0.0;
    return double.parse((amt / _members.length).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _memberSelected = List<bool>.filled(_members.length, true);
  }

  int get _selectedCount => _memberSelected.where((v) => v).length;

  double get _perPersonAmountSelected {
    final sc = _selectedCount;
    if (sc == 0) return 0.0;
    return double.parse((_parsedAmount / sc).toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    // Designed as a modal sheet
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildAmountField(),
                const SizedBox(height: 12),
                _buildTitleField(),
                const SizedBox(height: 12),
                _buildPayerField(),
                const SizedBox(height: 12),
                _buildSplitModeToggle(),
                const SizedBox(height: 12),
                if (_splitMode == SplitMode.percent) _buildPercentControls(),
                _buildMembersList(),
                const SizedBox(height: 12),
                if (_splitMode == SplitMode.perPerson)
                  PerPersonSummary(
                    selectedCount: _selectedCount,
                    formattedAmount: _moneyFmt.format(_perPersonAmountSelected),
                  ),
                const SizedBox(height: 18),
                _buildActions(context),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E54E9), Color(0xFF5A31D8)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Thêm Chi Phí',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // to balance the back button
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Số Tiền', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintText: '0',
            suffixText: 'đ',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tiêu Đề', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintText: 'Ví dụ: Ăn trưa nhóm',
          ),
        ),
      ],
    );
  }

  Widget _buildPayerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Người Trả', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    _members[_selectedPayerIndex]['color'] as Color,
                radius: 14,
                child: Text(_members[_selectedPayerIndex]['name'][0]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_members[_selectedPayerIndex]['name'] as String),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: _showPayerPicker,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPayerPicker() async {
    final idx = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: _members[index]['color'] as Color,
            child: Text((_members[index]['name'] as String)[0]),
          ),
          title: Text(_members[index]['name'] as String),
          onTap: () => Navigator.of(context).pop(index),
        ),
      ),
    );

    if (idx != null) setState(() => _selectedPayerIndex = idx);
  }

  Widget _buildSplitModeToggle() {
    return Row(
      children: [
        _buildSplitModeButton(SplitMode.equal, 'Đều'),
        const SizedBox(width: 8),
        _buildSplitModeButton(SplitMode.percent, '%'),
        const SizedBox(width: 8),
        _buildSplitModeButton(SplitMode.perPerson, 'Theo người'),
      ],
    );
  }

  Widget _buildPercentControls() {
    final selected = _members[_percentMemberIndex];
    final total = _parsedAmount;
    final percentAmount = (total * (_percent / 100));
    final remaining = total - percentAmount;
    final others = (_members.length - 1) > 0 ? (_members.length - 1) : 1;
    final perOther = remaining / others;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 84,
              child: TextField(
                controller: _percentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) {
                  final parsed =
                      int.tryParse(v.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
                  setState(() {
                    _percent = parsed.clamp(0, 100);
                    // keep the controller value sanitized
                    _percentController.text = _percent.toString();
                    _percentController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _percentController.text.length),
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _showPercentMemberPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: selected['color'] as Color,
                        child: Text((selected['name'] as String)[0]),
                      ),
                      const SizedBox(width: 8),
                      Text(selected['name'] as String),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // highlight selected member and amount they pay
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: selected['color'] as Color,
                child: Text((selected['name'] as String)[0]),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(selected['name'] as String)),
              const SizedBox(width: 8),
              Text(
                _moneyFmt.format(percentAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A31D8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${selected['name']} trả ${_percent}% (${_moneyFmt.format(percentAmount)}). Số tiền còn lại ${_moneyFmt.format(remaining)} sẽ được chia đều cho $others người khác (mỗi người ${_moneyFmt.format(perOther)}).',
            style: const TextStyle(color: Color(0xFF1B4F9C)),
          ),
        ),
      ],
    );
  }

  void _showPercentMemberPicker() async {
    final idx = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: _members[index]['color'] as Color,
            child: Text((_members[index]['name'] as String)[0]),
          ),
          title: Text(_members[index]['name'] as String),
          onTap: () => Navigator.of(context).pop(index),
        ),
      ),
    );

    if (idx != null) setState(() => _percentMemberIndex = idx);
  }

  Widget _buildSplitModeButton(SplitMode mode, String label) {
    final selected = _splitMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _splitMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentPurple : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final total = _parsedAmount;
    double percentAmount = 0;
    double perOther = 0;
    if (_splitMode == SplitMode.percent) {
      percentAmount = total * (_percent / 100);
      final remaining = total - percentAmount;
      final others = (_members.length - 1) > 0 ? (_members.length - 1) : 1;
      perOther = remaining / others;
    }

    final isPerPerson = _splitMode == SplitMode.perPerson;
    final selectedCount = isPerPerson
        ? _memberSelected.where((v) => v).length
        : _members.length;
    final perPersonAmount = selectedCount > 0 ? (total / selectedCount) : 0.0;

    return Column(
      children: _members.asMap().entries.map((entry) {
        final index = entry.key;
        final m = entry.value;

        final amount = () {
          if (_splitMode == SplitMode.percent) {
            return index == _percentMemberIndex ? percentAmount : perOther;
          }

          if (isPerPerson) {
            return _memberSelected[index] ? perPersonAmount : 0.0;
          }

          return _perPersonShare();
        }();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (isPerPerson)
                  Checkbox(
                    value: _memberSelected[index],
                    onChanged: (v) =>
                        setState(() => _memberSelected[index] = v ?? false),
                  )
                else
                  const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: m['color'] as Color,
                  child: Text((m['name'] as String)[0]),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(m['name'] as String)),
                const SizedBox(width: 8),
                Text(
                  _moneyFmt.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (_splitMode == SplitMode.perPerson && _selectedCount == 0)
                ? null
                : _onAddPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Thêm Chi Phí',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hủy'),
          ),
        ),
      ],
    );
  }

  void _onAddPressed() {
    // For now just return the created expense data
    final expense = {
      'amount': _parsedAmount,
      'title': _titleController.text,
      'payer': _members[_selectedPayerIndex]['id'],
      'splitMode': _splitMode.toString(),
      'splitDetails': _splitMode == SplitMode.percent
          ? {
              'percent': _percent,
              'memberId': _members[_percentMemberIndex]['id'],
            }
          : null,
      'selectedMembers': _splitMode == SplitMode.perPerson
          ? _members
                .asMap()
                .entries
                .where((e) => _memberSelected[e.key])
                .map((e) => e.value['id'])
                .toList()
          : null,
    };
    Navigator.of(context).pop(expense);
  }
}

// Small widget showing per-person summary used by the Add Expense modal.
class PerPersonSummary extends StatelessWidget {
  final int selectedCount;
  final String formattedAmount;

  const PerPersonSummary({
    super.key,
    required this.selectedCount,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Đã chọn $selectedCount người. Mỗi người trả $formattedAmount.',
        style: const TextStyle(color: Color(0xFF1B4F9C)),
      ),
    );
  }
}
