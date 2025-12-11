import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<RuleItem> rules = [
      RuleItem(
        icon: Icons.info_outline,
        iconColor: Colors.blue,
        number: '1',
        title: 'Quy định chung',
        subtitle: 'Có hiệu lực từ 28/11/2023',
        content:
            'Để quản lý chung cư hiệu quả, tất cả cư dân và người ngoài vào chung cư phải tuân thủ nội quy này ❤️',
        details: [
          'Đóng góp chi phí chung trực tiếp vào quỹ nhà chung (23h00)',
          'Nếu có muốn sau ghi ghi nhận, vui lòng báo trước trong Zalo chung',
          'Sau 23h từ 04:00 đến 06:00 là giờ vàng để gặc giá tiền',
          'Hoặc gặp đội phó tại lô 51',
        ],
      ),
      RuleItem(
        icon: Icons.cleaning_services,
        iconColor: Colors.orange,
        number: '2',
        title: 'Vệ sinh & Rác thải',
        subtitle: '',
        content: '',
        details: [
          'Ấp công phát sẽ đi dọn dẹp phòng có đồ bất sạch',
          'Rác sinh hoạt đúng 18h00 hàng ngày',
          'Khu vực biệt thự xung quanh phải sạch như mới',
          'Dụng lụcị (Chi luân phiên) không để đồ gì ngăn khoảnh',
        ],
      ),
      RuleItem(
        icon: Icons.people,
        iconColor: Colors.pink,
        number: '3',
        title: 'Khách & Bạn bè',
        subtitle: '',
        content: '',
        details: [
          'Không đón người lạ ban nhân khác về ngủ qua đêm trừ trường hợp đặc biệt chúng ta',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: const Text(
          'Nội quy Ngôi nhà',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rule_rounded,
                  color: Colors.green.shade800,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              ...rules.map((rule) => RuleItemWidget(rule: rule)),
            ],
          ),
        ),
      ),
    );
  }
}

class RuleItem {
  final IconData icon;
  final Color iconColor;
  final String number;
  final String title;
  final String subtitle;
  final String content;
  final List<String> details;

  RuleItem({
    required this.icon,
    required this.iconColor,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.details,
  });
}

class RuleItemWidget extends StatelessWidget {
  final RuleItem rule;

  const RuleItemWidget({
    Key? key,
    required this.rule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rule.iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                rule.icon,
                color: rule.iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rule.number}. ${rule.title}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (rule.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        rule.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rule.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44, bottom: 12),
            child: Text(
              rule.content,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...rule.details.map((detail) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rule.iconColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Row(
            children: [
              Icon(
                Icons.note_add,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Để xuất sửa đổi',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

