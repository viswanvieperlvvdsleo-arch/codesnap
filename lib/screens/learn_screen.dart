import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/learn_content.dart';
import '../utils/mock_data.dart';
import '../providers/theme_provider.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});
  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _LearnScreenState extends State<LearnScreen> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final learnList = MockData.learnContent;
    final currentLesson = learnList[_selectedDayIndex];
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget leftPanel() {
      return Container(
        width: 250,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: ListView.builder(
          itemCount: learnList.length,
          itemBuilder: (context, index) {
            final lesson = learnList[index];
            final isSelected = _selectedDayIndex == index;

            return ListTile(
              selected: isSelected,
              selectedTileColor: ThemeProvider.peachOffWhite.withOpacity(0.5),
              title: Text(
                'Day ${lesson.day}: ${lesson.title}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? ThemeProvider.deepPurple : ThemeProvider.darkBlack,
                ),
              ),
              subtitle: Text(
                lesson.category,
                style: const TextStyle(
                  fontSize: 11,
                  color: ThemeProvider.mauve,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedDayIndex = index;
                });
              },
            );
          },
        ),
      );
    }

    Widget contentBody() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Day, Category)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeProvider.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Day ${currentLesson.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeProvider.peachOffWhite,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentLesson.category,
                    style: const TextStyle(
                      color: ThemeProvider.deepPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lesson Title
            Text(
              currentLesson.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Section: Theory
            _sectionTitle('Theory & Concept'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: ThemeProvider.sand.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  currentLesson.theory,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: ThemeProvider.darkBlack,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Code Example
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Code Example'),
                IconButton(
                  icon: const Icon(LucideIcons.copy, size: 18, color: ThemeProvider.mauve),
                  tooltip: 'Copy Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: currentLesson.codeExample));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code example copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeProvider.darkBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                currentLesson.codeExample,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  color: Color(0xFFA8FFB2), // Soft lime-green syntax coloring
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Section: Mini Exercise / Task
            _sectionTitle('Daily Exercise'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeProvider.peachOffWhite.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ThemeProvider.sand, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.checkSquare,
                      color: ThemeProvider.deepPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Task:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeProvider.deepPurple,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentLesson.task,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: ThemeProvider.darkBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftPanel(),
          Expanded(child: contentBody()),
        ],
      );
    } else {
      // Mobile Top Selector + content layout
      return Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: learnList.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedDayIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: ChoiceChip(
                    label: Text(
                      'Day ${learnList[index].day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : ThemeProvider.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: ThemeProvider.deepPurple,
                    backgroundColor: ThemeProvider.peachOffWhite.withOpacity(0.5),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedDayIndex = index;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(child: contentBody()),
        ],
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: ThemeProvider.deepPurple,
        fontSize: 16,
      ),
    );
  }
}
