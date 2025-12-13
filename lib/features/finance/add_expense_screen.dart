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
  // --- GIỮ NGUYÊN LOGIC KHỞI TẠO TỪ CODE CŨ ---
  final _amountController = TextEditingController(text: '1000');
  final _titleController = TextEditingController();
  int _selectedPayerIndex = 0;
  SplitMode _splitMode = SplitMode.equal;

  // Percent split fields
  int _percent = 30;
  int _percentMemberIndex = 0;
  final TextEditingController _percentController = TextEditingController(
    text: '30',
  );

  final List<Map<String, dynamic>> _members = [
    {'id': 'you', 'name': 'Bạn', 'color': const Color(0xFF8E54E9)},
    {'id': 'an', 'name': 'An', 'color': const Color(0xFF5A31D8)},
    {'id': 'binh', 'name': 'Bình', 'color': const Color(0xFF80CBC4)},
    {'id': 'chi', 'name': 'Chi', 'color': const Color(0xFFEF9A9A)},
  ];

  late List<bool> _memberSelected;
  NumberFormat get _moneyFmt =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _memberSelected = List<bool>.filled(_members.length, true);
    // Set default title logic if needed, or leave empty as per original
    _titleController.text = "Ăn trưa nhóm";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  // --- CÁC HÀM TÍNH TOÁN GIỮ NGUYÊN BẢN ---
  double get _parsedAmount {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9\.]'), '');
    return double.tryParse(raw) ?? 0.0;
  }

  double _perPersonShare() {
    final amt = _parsedAmount;
    if (_members.isEmpty) return 0.0;
    return double.parse((amt / _members.length).toStringAsFixed(0));
  }

  int get _selectedCount => _memberSelected.where((v) => v).length;

  double get _perPersonAmountSelected {
    final sc = _selectedCount;
    if (sc == 0) return 0.0;
    return double.parse((_parsedAmount / sc).toStringAsFixed(0));
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    // SỬA LỖI: Dùng Scaffold làm gốc
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildCustomHeader(), // Header Gradient tím
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Số Tiền'),
                  const SizedBox(height: 8),
                  _buildAmountInput(), // Input số to

                  const SizedBox(height: 16),
                  _buildLabel('Tiêu Đề'),
                  const SizedBox(height: 8),
                  _buildStyledTextField(
                    _titleController,
                    'Ví dụ: Ăn trưa nhóm',
                  ),

                  const SizedBox(height: 16),
                  _buildLabel('Người Trả'),
                  const SizedBox(height: 8),
                  _buildPayerSelector(),

                  const SizedBox(height: 16),
                  _buildLabel('Cách Chia'),
                  const SizedBox(height: 8),
                  _buildSplitModeToggle(), // Toggle 3 chế độ

                  const SizedBox(height: 16),

                  // LOGIC HIỂN THỊ DỰA THEO CHẾ ĐỘ CHIA
                  if (_splitMode == SplitMode.percent)
                    _buildPercentUI() // Giao diện % (Ảnh 1)
                  else
                    _buildMembersList(), // List thành viên (Ảnh 2 & 3)
                  // Hiển thị tổng kết nếu là Chia theo người (Ảnh 3)
                  if (_splitMode == SplitMode.perPerson)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildSummaryBox(
                        'Đã chọn $_selectedCount người. Mỗi người trả ${_moneyFmt.format(_perPersonAmountSelected)}.',
                        const Color(0xFFE8F1FF),
                        const Color(0xFF1B4F9C),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Nút bấm Gradient
                  _buildGradientButton(
                    text: 'Thêm Chi Phí',
                    onTap: _onAddPressed, // Gọi hàm save cũ
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  _buildGradientButton(
                    text: 'Huỷ',
                    onTap: () => Navigator.pop(context),
                    isPrimary: false,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET GIAO DIỆN (UI) ---

  // 1. Header Tím
  Widget _buildCustomHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E54E9), Color(0xFF5A31D8)],
        ),
        // borderRadius: BorderRadius.only(
        //   bottomLeft: Radius.circular(20),
        //   bottomRight: Radius.circular(20),
        // ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Thêm Chi Phí',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // 2. Input Số tiền (To, Đậm, Xanh)
  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5A55E6),
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '0',
          suffixText: 'đ',
          suffixStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A55E6),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // 3. Toggle Chế độ chia (Đều | % | Theo người)
  Widget _buildSplitModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildModeBtn(SplitMode.equal, 'Đều'),
          _buildModeBtn(SplitMode.percent, '%'),
          _buildModeBtn(SplitMode.perPerson, 'Theo người'),
        ],
      ),
    );
  }

  Widget _buildModeBtn(SplitMode mode, String label) {
    bool isSelected = _splitMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _splitMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF5A55E6) : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // 4. Giao diện List thành viên (Dùng cho "Đều" và "Theo người")
  Widget _buildMembersList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // Nền xám nhạt bao ngoài
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: List.generate(_members.length, (index) {
          final m = _members[index];

          // Tính toán số tiền hiển thị (Logic cũ)
          double amount = 0;
          if (_splitMode == SplitMode.perPerson) {
            amount = _memberSelected[index]
                ? (_selectedCount > 0 ? _parsedAmount / _selectedCount : 0)
                : 0;
          } else {
            amount = _parsedAmount / _members.length;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Checkbox cho chế độ "Theo người" (Ảnh 3)
                if (_splitMode == SplitMode.perPerson)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _memberSelected[index],
                        activeColor: const Color(0xFF5A55E6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) =>
                            setState(() => _memberSelected[index] = v ?? false),
                      ),
                    ),
                  ),

                CircleAvatar(
                  backgroundColor: m['color'],
                  radius: 18,
                  child: Text(
                    m['name'][0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    m['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  _moneyFmt.format(amount),
                  style: const TextStyle(
                    color: Color(0xFF5A55E6),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // 5. Giao diện Phần trăm (Ảnh 1)
  Widget _buildPercentUI() {
    final selected = _members[_percentMemberIndex];
    final total = _parsedAmount;
    final percentAmount = (total * (_percent / 100));
    final remaining = total - percentAmount;
    final others = (_members.length - 1) > 0 ? (_members.length - 1) : 1;
    final perOther = remaining / others;

    return Column(
      children: [
        Row(
          children: [
            // Input %
            Container(
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: TextField(
                controller: _percentController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) {
                  final parsed =
                      int.tryParse(v.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
                  setState(() {
                    _percent = parsed.clamp(0, 100);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // Chọn người trả %
            Expanded(
              child: InkWell(
                onTap: _showPercentMemberPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selected['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Card tóm tắt
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: selected['color'],
                child: Text(
                  selected['name'][0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                selected['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _moneyFmt.format(percentAmount),
                style: const TextStyle(
                  color: Color(0xFF5A55E6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Summary Box xanh nhạt
        _buildSummaryBox(
          '${selected['name']} trả $_percent% (${_moneyFmt.format(percentAmount)}). Số tiền còn lại ${_moneyFmt.format(remaining)} sẽ được chia đều cho $others người khác (mỗi người ${_moneyFmt.format(perOther)}).',
          const Color(0xFFE8F1FF),
          const Color(0xFF1B4F9C),
        ),
      ],
    );
  }

  // --- CÁC WIDGET PHỤ TRỢ ---

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildPayerSelector() {
    return InkWell(
      onTap: _showPayerPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _members[_selectedPayerIndex]['name'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String text, Color bg, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: textColor, width: 4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF6B5CFF), Color(0xFF5A4AD1)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF7C5CFF), Color(0xFF6B4FE8)],
                ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // --- MODAL PICKER (GIỮ NGUYÊN) ---
  void _showPayerPicker() async {
    final idx = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _members.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _members[i]['color'],
                  child: Text(
                    _members[i]['name'][0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(_members[i]['name']),
                onTap: () => Navigator.pop(context, i),
              ),
            ),
          ],
        ),
      ),
    );
    if (idx != null) setState(() => _selectedPayerIndex = idx);
  }

  void _showPercentMemberPicker() async {
    final idx = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _members.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _members[i]['color'],
                  child: Text(
                    _members[i]['name'][0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(_members[i]['name']),
                onTap: () => Navigator.pop(context, i),
              ),
            ),
          ],
        ),
      ),
    );
    if (idx != null) setState(() => _percentMemberIndex = idx);
  }

  // --- HÀM XỬ LÝ DỮ LIỆU ĐẦU RA (GIỮ NGUYÊN BẢN GỐC CỦA BẠN) ---
  // Quan trọng: Hàm này đảm bảo dữ liệu trả về giống hệt code cũ để không lỗi tính toán
  void _onAddPressed() {
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
      'date': DateTime.now(), // Thêm ngày giờ hiện tại
    };
    Navigator.of(context).pop(expense);
  }
}
