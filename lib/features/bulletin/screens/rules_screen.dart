import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/auth_service.dart';
import '../../../core/services/house_service.dart';
import '../../../core/services/bulletin_service.dart';
import '../models/house_rule.dart';

void _showAddRuleDialog(BuildContext context, Future<void> Function(String title, String content) onSubmit) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Đề xuất nội quy mới',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đề xuất nội quy để cải thiện môi trường sống chung',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TIÊU ĐỀ *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'VD: Quy định về thời gian sinh hoạt chung',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'NỘI DUNG *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Mô tả chi tiết về nội quy đề xuất...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Hủy bỏ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty ||
                              contentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng điền đầy đủ thông tin'),
                              ),
                            );
                            return;
                          }
                          await onSubmit(titleController.text, contentController.text);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã gửi đề xuất nội quy thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 18),
                            SizedBox(width: 6),
                            Text('Gửi đề xuất'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showEditRuleDialog(
  BuildContext context, {
  required String initialTitle,
  required String initialSubtitle,
  required String initialContent,
  required Future<void> Function(String title, String subtitle, String content) onSubmit,
}) {
  final titleController = TextEditingController(text: initialTitle);
  final subtitleController = TextEditingController(text: initialSubtitle);
  final contentController = TextEditingController(text: initialContent);

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    const Text('Sửa nội quy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('TIÊU ĐỀ *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('PHỤ ĐỀ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: subtitleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('NỘI DUNG *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty || contentController.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ tiêu đề và nội dung')));
                            return;
                          }
                          await onSubmit(titleController.text, subtitleController.text, contentController.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                        child: const Text('Lưu'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}

class RulesScreen extends StatefulWidget {
  final String? houseId;
  final List<HouseRule> initialRules;

  const RulesScreen({
    Key? key,
    this.houseId,
    this.initialRules = const [],
  }) : super(key: key);

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  StreamSubscription<List<HouseRule>>? _sub;
  List<HouseRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    // Use houseId from widget, fall back to user's house if not provided
    if (widget.houseId != null) {
      _subscribeToRules(widget.houseId!);
    } else {
      // Fallback: get houseId from current user
      final auth = AuthService();
      final houseService = HouseService();
      final uid = auth.currentFirebaseUser?.uid;
      
      if (uid != null) {
        houseService.getHouseId(uid).then((houseId) {
          if (houseId != null && mounted) {
            _subscribeToRules(houseId);
          } else if (mounted) {
            setState(() => _loading = false);
          }
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _subscribeToRules(String houseId) {
    _sub?.cancel();
    _sub = BulletinService().rulesStream(houseId).listen((items) {
      if (!mounted) return;
      setState(() {
        _rules = items;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<RuleItem> rules = _rules.isEmpty
        ? []
        : _rules.asMap().entries.map((e) {
            final idx = e.key + 1;
            final r = e.value;
            // Map to UI item (basic icon/color by index)
            final icons = [Icons.info_outline, Icons.cleaning_services, Icons.people, Icons.rule];
            final colors = [Colors.blue, Colors.orange, Colors.pink, Colors.green];
            return RuleItem(
              icon: icons[idx % icons.length],
              iconColor: colors[idx % colors.length],
              number: idx.toString(),
              title: r.title,
              subtitle: r.subtitle,
              content: r.content,
              details: r.details,
              id: r.id,
            );
          }).toList();

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
              if (rules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Chưa có nội quy nào. Hãy thêm nội quy đầu tiên!'),
                )
              else
                ...rules.map((rule) => RuleItemWidget(
                      rule: rule,
                      onDelete: widget.houseId == null
                          ? null
                          : () async {
                              await BulletinService().deleteRule(widget.houseId!, rule.id!);
                            },
                      onEdit: widget.houseId == null
                          ? null
                          : () async {
                              final hr = _rules.firstWhere((r) => r.id == rule.id);
                              _showEditRuleDialog(
                                context,
                                initialTitle: hr.title,
                                initialSubtitle: hr.subtitle,
                                initialContent: hr.content,
                                onSubmit: (t, s, c) async {
                                  final updated = HouseRule(
                                    id: hr.id,
                                    title: t,
                                    subtitle: s,
                                    content: c,
                                    details: hr.details,
                                    createdBy: hr.createdBy,
                                    createdAt: hr.createdAt,
                                    updatedAt: DateTime.now(),
                                  );
                                  await BulletinService().updateRule(widget.houseId!, updated);
                                },
                              );
                            },
                    )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.houseId == null
                      ? null
                      : () {
                          _showAddRuleDialog(context, (title, content) async {
                            final rule = HouseRule(
                              id: '',
                              title: title,
                              subtitle: '',
                              content: content,
                              details: const [],
                              createdBy: AuthService().currentFirebaseUser?.uid,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            await BulletinService().addRule(widget.houseId!, rule);
                          });
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Đề xuất nội quy mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
  final String? id;

  RuleItem({
    required this.icon,
    required this.iconColor,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.details,
    this.id,
  });
}

class RuleItemWidget extends StatelessWidget {
  final RuleItem rule;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const RuleItemWidget({
    Key? key,
    required this.rule,
    this.onDelete,
    this.onEdit,
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
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa'),
                ),
              if (onDelete != null)
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              if (onEdit == null && onDelete == null)
                Row(
                  children: [
                    Icon(Icons.note_add, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 6),
                    Text('Đề xuất sửa đổi', style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

