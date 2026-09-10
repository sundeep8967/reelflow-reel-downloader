import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/reel_item.dart';

class HistorySheet extends StatelessWidget {
  final List<ReelItem> history;
  final VoidCallback onClear;
  final Function(ReelItem) onSelect;

  const HistorySheet({
    super.key,
    required this.history,
    required this.onClear,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemGroupedBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: history.isEmpty ? null : onClear,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: history.isEmpty
                          ? CupertinoColors.tertiaryLabel
                          : CupertinoColors.destructiveRed,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Text(
                  'Downloaded Reels',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.square_arrow_down,
                          size: 48,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No downloaded reels yet',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (context, index) => const Divider(indent: 72, height: 1),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return CupertinoListTile(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leadingSize: 48,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.thumbnailUrl.isNotEmpty
                              ? Image.network(
                                  item.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: CupertinoColors.systemGrey4,
                                    child: const Icon(CupertinoIcons.play_circle),
                                  ),
                                )
                              : Container(
                                  color: CupertinoColors.systemGrey4,
                                  child: const Icon(CupertinoIcons.play_circle),
                                ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '@${item.author} • ${item.duration}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        trailing: const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelect(item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
