import 'package:flutter/material.dart';

/// E-learning workspace menu based on the web UserWorkArea cards.
///
/// Connect each card to its destination by providing [onCardTap].
class UserWorkAreaScreen extends StatelessWidget {
  const UserWorkAreaScreen({
    super.key,
    this.onCardTap,
  });

  final ValueChanged<WorkAreaItem>? onCardTap;

  static const List<WorkAreaItem> _items = [
    WorkAreaItem('Assignments', 'assignment', Icons.assignment_outlined, Color(0xFF6750A4)),
    WorkAreaItem('Tests & Exam', 'testcreation', Icons.school_outlined, Color(0xFF2878C7)),
    WorkAreaItem('Question Bank', 'questionbank', Icons.storage_outlined, Color(0xFF0D9488)),
    WorkAreaItem('Online Classes', 'onlineclass', Icons.videocam_outlined, Color(0xFFDB7C26)),
    WorkAreaItem('Evaluations', 'evaluation', Icons.star_outline_rounded, Color(0xFFB7791F)),
    WorkAreaItem('Gradebook', 'gradebook', Icons.bar_chart_rounded, Color(0xFF3976B9)),
    WorkAreaItem('Teaching Plan', 'teachingplan', Icons.menu_book_outlined, Color(0xFF258A75)),
    WorkAreaItem('Announcements', 'annoucement', Icons.campaign_outlined, Color(0xFFB65C8B)),
    WorkAreaItem('Discussion Forum', 'DiscussionForum', Icons.forum_outlined, Color(0xFF6B69C8)),
    WorkAreaItem('Test Troubleshoot', 'TestTroubleShoot', Icons.fact_check_outlined, Color(0xFF4B8B55)),
    WorkAreaItem('E Resources Upload', 'eResourcesUpload', Icons.file_upload_outlined, Color(0xFF327C9B)),
    WorkAreaItem('Reports and Analytics', 'eReportsandanalytics', Icons.trending_up_rounded, Color(0xFF8A65B8)),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : width >= 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'E-Learning Workspace',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 28.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Area',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a section to manage your e-learning activities.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final rowCount =
                          (_items.length / crossAxisCount).ceil();
                      return Column(
                        children: List.generate(rowCount, (rowIndex) {
                          final start = rowIndex * crossAxisCount;
                          final end =
                              (start + crossAxisCount).clamp(0, _items.length);
                          final rowItems = _items.sublist(start, end);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: rowIndex == rowCount - 1 ? 0 : 12,
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < crossAxisCount; i++) ...[
                                    if (i > 0) const SizedBox(width: 12),
                                    Expanded(
                                      child: i < rowItems.length
                                          ? _WorkAreaCard(
                                              item: rowItems[i],
                                              onTap: () =>
                                                  onCardTap?.call(rowItems[i]),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkAreaCard extends StatelessWidget {
  const _WorkAreaCard({
    required this.item,
    required this.onTap,
  });

  final WorkAreaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D172033),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.color, size: 23),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkAreaItem {
  const WorkAreaItem(this.title, this.page, this.icon, this.color);

  final String title;
  final String page;
  final IconData icon;
  final Color color;
}
