import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/task.dart';
import '../providers/theme_provider.dart';
import 'spring_button.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<String> onOpenInWorkspace;
  final ValueChanged<Task>? onOpenShowdown;
  final ValueChanged<Task>? onOpenDetail;

  const TaskCard({
    super.key,
    required this.task,
    required this.onOpenInWorkspace,
    this.onOpenShowdown,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineDate = DateTime.tryParse(task.deadline);
    final now = DateTime.now();
    final isPastDue = deadlineDate != null && deadlineDate.isBefore(now);

    String timeRemaining = 'Ended';
    if (deadlineDate != null && !isPastDue) {
      final diff = deadlineDate.difference(now);
      if (diff.inDays > 0) {
        timeRemaining = '${diff.inDays}d ${diff.inHours % 24}h left';
      } else if (diff.inHours > 0) {
        timeRemaining = '${diff.inHours}h ${diff.inMinutes % 60}m left';
      } else {
        timeRemaining = '${diff.inMinutes}m left';
      }
    }

    // Status colors
    final isLive = task.status == 'LIVE';
    final isVoting = task.status == 'VOTING';
    final statusColor = isLive
        ? const Color(0xFF00E676)
        : isVoting
            ? const Color(0xFFB388FF)
            : const Color(0xFFFFB300);

    final cardWidget = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (isLive)
            BoxShadow(
              color: const Color(0xFF54C5F8).withOpacity(0.06),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Content Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Event Type Badge, Status Pill, and Prize Pool Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Event Type
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: _eventTypeBg(task.eventType),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: _eventTypeBorder(task.eventType),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _eventTypeIcon(task.eventType),
                                      size: 11,
                                      color: _eventTypeColor(task.eventType),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.eventType.toUpperCase(),
                                      style: TextStyle(
                                        color: _eventTypeColor(task.eventType),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Status Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withOpacity(0.8),
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      task.status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Prize Pool Callout
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFD700).withOpacity(0.2),
                                const Color(0xFFFFA000).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.trophy,
                                size: 13,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.prizePool,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tech Tags Row (take up to 4 tags to prevent vertical wrap bloat)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: task.tags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Showdown Competing Teams Section (if teams exist)
                if (task.teams.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.swords,
                                    size: 12,
                                    color: Color(0xFF54C5F8),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'COMMUNITY SHOWDOWN',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withOpacity(0.8),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${task.totalVotes} Votes',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF54C5F8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Competing teams bar
                        Row(
                          children: [
                            // Team 1
                            Expanded(
                              child: Text(
                                task.teams.first.teamName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              ' VS ',
                              style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            // Team 2 (or second team)
                            Expanded(
                              child: Text(
                                task.teams.length > 1 ? task.teams[1].teamName : 'Challengers',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Vote percentage progress bar
                        _buildVoteProgressBar(task),
                      ],
                    ),
                  ),
                ],

                // Footer Section
                Column(
                  children: [
                    Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Deadline countdown indicator
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 13,
                                color: isPastDue ? Colors.redAccent : const Color(0xFF54C5F8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  timeRemaining,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isPastDue ? Colors.redAccent : Colors.white70,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                LucideIcons.users,
                                size: 13,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${task.teamsCount}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (task.teams.isNotEmpty && onOpenShowdown != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: OutlinedButton.icon(
                                  onPressed: () => onOpenShowdown!(task),
                                  icon: const Icon(LucideIcons.vote, size: 13, color: Color(0xFF54C5F8)),
                                  label: const Text('Vote'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF54C5F8),
                                    side: BorderSide(color: const Color(0xFF54C5F8).withOpacity(0.4)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                            // Open in Workspace button
                            ElevatedButton.icon(
                              onPressed: () => onOpenInWorkspace(task.id),
                              icon: const Icon(LucideIcons.code, size: 13, color: Colors.black),
                              label: const Text('Workspace'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF54C5F8),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onOpenDetail != null) {
      return SpringButton(
        onTap: () => onOpenDetail!(task),
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  Widget _buildVoteProgressBar(Task task) {
    if (task.teams.isEmpty) return const SizedBox.shrink();

    final votes1 = task.teams.first.votes;
    final votes2 = task.teams.length > 1 ? task.teams[1].votes : 1;
    final total = (votes1 + votes2).clamp(1, 999999);
    final ratio1 = votes1 / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Expanded(
              flex: (ratio1 * 100).toInt().clamp(5, 95),
              child: Container(
                color: const Color(0xFF54C5F8),
              ),
            ),
            Expanded(
              flex: ((1 - ratio1) * 100).toInt().clamp(5, 95),
              child: Container(
                color: const Color(0xFFFF5252),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _eventTypeBg(String type) {
    switch (type.toLowerCase()) {
      case 'bounty':
        return const Color(0xFFFF9100).withOpacity(0.12);
      case 'challenge':
        return const Color(0xFFE040FB).withOpacity(0.12);
      default:
        return const Color(0xFF00E5FF).withOpacity(0.12);
    }
  }

  Color _eventTypeBorder(String type) {
    switch (type.toLowerCase()) {
      case 'bounty':
        return const Color(0xFFFF9100).withOpacity(0.35);
      case 'challenge':
        return const Color(0xFFE040FB).withOpacity(0.35);
      default:
        return const Color(0xFF00E5FF).withOpacity(0.35);
    }
  }

  Color _eventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bounty':
        return const Color(0xFFFF9100);
      case 'challenge':
        return const Color(0xFFE040FB);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  IconData _eventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bounty':
        return LucideIcons.coins;
      case 'challenge':
        return LucideIcons.flame;
      default:
        return LucideIcons.rocket;
    }
  }
}
