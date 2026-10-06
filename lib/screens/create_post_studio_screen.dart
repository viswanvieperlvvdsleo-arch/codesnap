import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/theme_provider.dart';
import '../utils/feed_mock_data.dart';
import '../widgets/spring_button.dart';
import '../widgets/morphing_capsule.dart';

enum PostDestination { story, feed }

enum TextFontStyle { classic, modern, neon, handwriting, typewriter }

enum CropAspectRatio { free, square, feedPortrait, storyVertical, landscape }

enum AestheticFilter { none, goldenHour, cyberpunk, monochrome, cinematic, vintage, sepia }

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class TextOverlay {
  String text;
  Offset position;
  double fontSize;
  Color color;
  TextFontStyle style;
  bool hasBackground;

  TextOverlay({
    required this.text,
    required this.position,
    this.fontSize = 24.0,
    this.color = Colors.white,
    this.style = TextFontStyle.classic,
    this.hasBackground = true,
  });
}

class CreatePostStudioScreen extends StatefulWidget {
  final String mediaUrl;
  final bool isVideo;
  final PostDestination initialDestination;
  final Function({
    required PostDestination destination,
    required String mediaUrl,
    required String? caption,
    required String? title,
    required String? description,
    required String? location,
    required String? musicTitle,
  }) onPublish;

  const CreatePostStudioScreen({
    super.key,
    required this.mediaUrl,
    this.isVideo = false,
    this.initialDestination = PostDestination.story,
    required this.onPublish,
  });

  @override
  State<CreatePostStudioScreen> createState() => _CreatePostStudioScreenState();
}

class _CreatePostStudioScreenState extends State<CreatePostStudioScreen> {
  late PostDestination _destination;

  // Active Tool: 'none', 'crop', 'sketch', 'adjust', 'text', 'trim'
  String _activeTool = 'none';

  // Crop & Transform state
  CropAspectRatio _selectedCrop = CropAspectRatio.free;
  int _rotationQuarterTurns = 0;

  // Sketch state
  final List<DrawnLine> _drawnLines = [];
  DrawnLine? _currentLine;
  Color _sketchColor = const Color(0xFFFFD700);
  double _sketchStrokeWidth = 4.0;

  // Video Trimmer state
  double _videoStartSeconds = 0.0;
  double _videoEndSeconds = 15.0;
  final double _videoTotalDuration = 30.0;
  bool _isPlayingPreview = false;

  // Color adjustments & Filters
  double _brightness = 0.0; // -0.5 to 0.5
  double _contrast = 1.0;   // 0.5 to 1.5
  double _saturation = 1.0; // 0.0 to 2.0
  AestheticFilter _activeFilter = AestheticFilter.none;

  // Text Overlays
  final List<TextOverlay> _textOverlays = [];
  TextOverlay? _selectedOverlay;
  final TextEditingController _textInputCtrl = TextEditingController();

  // Story / Feed Metadata inputs
  final TextEditingController _storyCaptionCtrl = TextEditingController();
  final TextEditingController _feedTitleCtrl = TextEditingController();
  final TextEditingController _feedDescCtrl = TextEditingController();
  final TextEditingController _feedLocationCtrl = TextEditingController(text: 'San Francisco, CA');

  @override
  void initState() {
    super.initState();
    _destination = widget.initialDestination;
    if (_destination == PostDestination.story) {
      _selectedCrop = CropAspectRatio.storyVertical;
    } else {
      _selectedCrop = CropAspectRatio.feedPortrait;
    }
  }

  @override
  void dispose() {
    _textInputCtrl.dispose();
    _storyCaptionCtrl.dispose();
    _feedTitleCtrl.dispose();
    _feedDescCtrl.dispose();
    _feedLocationCtrl.dispose();
    super.dispose();
  }

  // --- Aesthetic Filter Color Matrices ---
  List<double> _getColorFilterMatrix() {
    // Basic brightness, contrast & saturation matrix
    // Combine with preset filter
    double b = _brightness * 255.0;
    double c = _contrast;
    double s = _saturation;

    // Saturation luminance constants
    const double rw = 0.3086;
    const double gw = 0.6094;
    const double bw = 0.0820;

    double invSat = 1.0 - s;
    double r1 = invSat * rw + s;
    double r2 = invSat * rw;
    double r3 = invSat * rw;

    double g1 = invSat * gw;
    double g2 = invSat * gw + s;
    double g3 = invSat * gw;

    double b1 = invSat * bw;
    double b2 = invSat * bw;
    double b3 = invSat * bw + s;

    // Base matrix
    List<double> m = [
      c * r1, c * g1, c * b1, 0, b,
      c * r2, c * g2, c * b2, 0, b,
      c * r3, c * g3, c * b3, 0, b,
      0,      0,      0,      1, 0,
    ];

    switch (_activeFilter) {
      case AestheticFilter.goldenHour:
        m[0] *= 1.15; // Red tint
        m[6] *= 1.05; // Warm green
        m[12] *= 0.85; // Cool blue lowered
        m[4] += 15;
        break;
      case AestheticFilter.cyberpunk:
        m[0] *= 1.25; // Boost violet/magenta
        m[6] *= 0.85;
        m[12] *= 1.35; // Boost cyan/blue
        break;
      case AestheticFilter.monochrome:
        return [
          0.299, 0.587, 0.114, 0, b,
          0.299, 0.587, 0.114, 0, b,
          0.299, 0.587, 0.114, 0, b,
          0,     0,     0,     1, 0,
        ];
      case AestheticFilter.cinematic:
        m[0] *= 1.1;
        m[6] *= 1.05;
        m[12] *= 1.2;
        m[4] += 10;
        m[14] += 10;
        break;
      case AestheticFilter.vintage:
        m[0] *= 1.1;
        m[6] *= 0.95;
        m[12] *= 0.8;
        m[4] += 20;
        m[9] += 15;
        break;
      case AestheticFilter.sepia:
        return [
          0.393, 0.769, 0.189, 0, b,
          0.349, 0.686, 0.168, 0, b,
          0.272, 0.534, 0.131, 0, b,
          0,     0,     0,     1, 0,
        ];
      case AestheticFilter.none:
      default:
        break;
    }

    return m;
  }

  void _addNewTextOverlay() {
    _textInputCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        TextFontStyle selectedStyle = TextFontStyle.classic;
        Color selectedColor = Colors.white;
        bool hasBg = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF141620).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Text',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.check, color: Color(0xFFFFD700)),
                        onPressed: () {
                          final text = _textInputCtrl.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _textOverlays.add(
                                TextOverlay(
                                  text: text,
                                  position: const Offset(60, 140),
                                  style: selectedStyle,
                                  color: selectedColor,
                                  hasBackground: hasBg,
                                ),
                              );
                            });
                          }
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textInputCtrl,
                    autofocus: true,
                    style: _getTextStyle(selectedStyle, 20, selectedColor),
                    cursorColor: const Color(0xFFFFD700),
                    decoration: InputDecoration(
                      hintText: 'Type something...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Font style selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TextFontStyle.values.map((style) {
                        final isSel = selectedStyle == style;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              _getFontStyleName(style),
                              style: TextStyle(
                                color: isSel ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFFFFD700),
                            backgroundColor: Colors.white.withOpacity(0.1),
                            onSelected: (_) => setModalState(() => selectedStyle = style),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Color selector & background toggle
                  Row(
                    children: [
                      ...[
                        Colors.white,
                        const Color(0xFFFFD700),
                        const Color(0xFF00E5FF),
                        const Color(0xFFFF2D55),
                        const Color(0xFF00E676),
                        Colors.black,
                      ].map((c) => GestureDetector(
                            onTap: () => setModalState(() => selectedColor = c),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == c ? Colors.white : Colors.white24,
                                  width: selectedColor == c ? 2.5 : 1,
                                ),
                              ),
                            ),
                          )),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Toggle Background Pill',
                        icon: Icon(
                          hasBg ? LucideIcons.badgePercent : LucideIcons.type,
                          color: hasBg ? const Color(0xFFFFD700) : Colors.white60,
                        ),
                        onPressed: () => setModalState(() => hasBg = !hasBg),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  TextStyle _getTextStyle(TextFontStyle style, double size, Color color) {
    switch (style) {
      case TextFontStyle.modern:
        return GoogleFonts.playfairDisplay(
          fontSize: size,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: color,
        );
      case TextFontStyle.neon:
        return GoogleFonts.orbitron(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: color,
          shadows: [
            Shadow(color: color.withOpacity(0.9), blurRadius: 16),
            Shadow(color: color.withOpacity(0.6), blurRadius: 24),
          ],
        );
      case TextFontStyle.handwriting:
        return GoogleFonts.caveat(
          fontSize: size + 4,
          fontWeight: FontWeight.bold,
          color: color,
        );
      case TextFontStyle.typewriter:
        return GoogleFonts.spaceMono(
          fontSize: size - 2,
          fontWeight: FontWeight.bold,
          color: color,
        );
      case TextFontStyle.classic:
      default:
        return GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
        );
    }
  }

  String _getFontStyleName(TextFontStyle style) {
    switch (style) {
      case TextFontStyle.classic: return 'Classic';
      case TextFontStyle.modern: return 'Modern';
      case TextFontStyle.neon: return 'Neon';
      case TextFontStyle.handwriting: return 'Script';
      case TextFontStyle.typewriter: return 'Typewriter';
    }
  }

  double? _getAspectRatioValue() {
    switch (_selectedCrop) {
      case CropAspectRatio.square: return 1.0;
      case CropAspectRatio.feedPortrait: return 4.0 / 5.0;
      case CropAspectRatio.storyVertical: return 9.0 / 16.0;
      case CropAspectRatio.landscape: return 16.0 / 9.0;
      case CropAspectRatio.free: return null;
    }
  }

  void _handlePublish() {
    final caption = _destination == PostDestination.story ? _storyCaptionCtrl.text.trim() : null;
    final title = _destination == PostDestination.feed ? _feedTitleCtrl.text.trim() : null;
    final description = _destination == PostDestination.feed ? _feedDescCtrl.text.trim() : null;
    final location = _destination == PostDestination.feed ? _feedLocationCtrl.text.trim() : null;

    widget.onPublish(
      destination: _destination,
      mediaUrl: widget.mediaUrl,
      caption: caption?.isNotEmpty == true ? caption : 'Moments captured',
      title: title?.isNotEmpty == true ? title : 'New Post',
      description: description?.isNotEmpty == true ? description : 'Check out this fresh update!',
      location: location,
      musicTitle: 'Original Audio · You',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Close, Target Destination Toggle, Publish Button
            _buildTopBar(),

            // Main Interactive Editing Canvas
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: _buildCanvasArea(),
                  ),

                  // Metadata floating card according to Destination (Story Caption vs Feed Description)
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: _buildMetadataInputOverlay(),
                  ),
                ],
              ),
            ),

            // Bottom Tool Palette / Active Drawer
            _buildBottomToolsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF090A0F),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white70, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Destination Pill Switcher: Story vs Feed
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDestinationOption(
                  dest: PostDestination.story,
                  label: 'Story',
                  icon: LucideIcons.circleDot,
                ),
                _buildDestinationOption(
                  dest: PostDestination.feed,
                  label: 'Feed',
                  icon: LucideIcons.layoutGrid,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Publish Button
          SpringButton(
            onTap: _handlePublish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _destination == PostDestination.story ? 'Post Story' : 'Post Feed',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.arrowRight, size: 14, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationOption({
    required PostDestination dest,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _destination == dest;
    return GestureDetector(
      onTap: () {
        setState(() {
          _destination = dest;
          if (dest == PostDestination.story) {
            _selectedCrop = CropAspectRatio.storyVertical;
          } else {
            _selectedCrop = CropAspectRatio.feedPortrait;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasArea() {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final double? ar = _getAspectRatioValue();
        double w = constraints.maxWidth;
        double h = constraints.maxHeight;

        if (ar != null) {
          if (w / h > ar) {
            w = h * ar;
          } else {
            h = w / ar;
          }
        }

        return RotatedBox(
          quarterTurns: _rotationQuarterTurns,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                // Base Image with Real-time Color Filter Matrix
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(_getColorFilterMatrix()),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E2028),
                        child: const Center(
                          child: Icon(LucideIcons.image, size: 48, color: Colors.white30),
                        ),
                      ),
                    ),
                  ),
                ),

                // Video Trim Overlay / Badge if Video
                if (widget.isVideo)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.video, size: 12, color: Color(0xFFFFD700)),
                          const SizedBox(width: 4),
                          Text(
                            '${(_videoEndSeconds - _videoStartSeconds).toStringAsFixed(1)}s',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Freehand Sketch Painter & Gesture Layer
                GestureDetector(
                  behavior: _activeTool == 'sketch' ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                  onPanStart: (details) {
                    if (_activeTool != 'sketch') return;
                    setState(() {
                      _currentLine = DrawnLine(
                        points: [details.localPosition],
                        color: _sketchColor,
                        strokeWidth: _sketchStrokeWidth,
                      );
                      _drawnLines.add(_currentLine!);
                    });
                  },
                  onPanUpdate: (details) {
                    if (_activeTool != 'sketch' || _currentLine == null) return;
                    setState(() {
                      _currentLine!.points.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) {
                    if (_activeTool != 'sketch') return;
                    _currentLine = null;
                  },
                  child: CustomPaint(
                    painter: _SketchPainter(lines: _drawnLines),
                    child: Container(),
                  ),
                ),

                // Movable & Sizable Text Overlays
                ..._textOverlays.map((overlay) => _buildMovableTextOverlay(overlay, w, h)),
              ],
            ),
          ),
        );
      },
    );

    return content;
  }

  Widget _buildMovableTextOverlay(TextOverlay overlay, double canvasWidth, double canvasHeight) {
    return Positioned(
      left: overlay.position.dx.clamp(0.0, (canvasWidth - 80).clamp(0.0, canvasWidth)),
      top: overlay.position.dy.clamp(0.0, (canvasHeight - 40).clamp(0.0, canvasHeight)),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            overlay.position += details.delta;
          });
        },
        onTap: () {
          setState(() {
            _selectedOverlay = overlay;
          });
          _showEditOverlaySheet(overlay);
        },
        child: Container(
          padding: overlay.hasBackground
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : EdgeInsets.zero,
          decoration: overlay.hasBackground
              ? BoxDecoration(
                  color: Colors.black.withOpacity(0.68),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: overlay == _selectedOverlay
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                )
              : null,
          child: Text(
            overlay.text,
            style: _getTextStyle(overlay.style, overlay.fontSize, overlay.color),
          ),
        ),
      ),
    );
  }

  void _showEditOverlaySheet(TextOverlay overlay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141620).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Text Sticker',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF5252), size: 18),
                    onPressed: () {
                      setState(() {
                        _textOverlays.remove(overlay);
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setSheetState) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          const Text('Size', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Expanded(
                            child: Slider(
                              value: overlay.fontSize,
                              min: 14,
                              max: 54,
                              activeColor: const Color(0xFFFFD700),
                              onChanged: (val) {
                                setSheetState(() => overlay.fontSize = val);
                                setState(() {});
                              },
                            ),
                          ),
                          Text('${overlay.fontSize.toInt()}pt', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Background Box', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Switch(
                            value: overlay.hasBackground,
                            activeColor: const Color(0xFFFFD700),
                            onChanged: (val) {
                              setSheetState(() => overlay.hasBackground = val);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataInputOverlay() {
    if (_activeTool != 'none') return const SizedBox.shrink();

    if (_destination == PostDestination.story) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _storyCaptionCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add a story caption...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Feed Destination: Title & Description
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _feedTitleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Post Headline / Title...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.12), height: 10),
              TextField(
                controller: _feedDescCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Write description for feed ("instead of caption keep descriptions")...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 12, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _feedLocationCtrl,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
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
  }

  Widget _buildBottomToolsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // If a tool drawer is open, show its specific controls
          if (_activeTool == 'crop') _buildCropDrawer(),
          if (_activeTool == 'sketch') _buildSketchDrawer(),
          if (_activeTool == 'adjust') _buildAdjustDrawer(),
          if (_activeTool == 'trim') _buildTrimmerDrawer(),

          // Main horizontal toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildToolButton(
                  id: 'crop',
                  icon: LucideIcons.crop,
                  label: 'Crop',
                ),
                _buildToolButton(
                  id: 'sketch',
                  icon: LucideIcons.pencil,
                  label: 'Sketch',
                ),
                _buildToolButton(
                  id: 'adjust',
                  icon: LucideIcons.slidersHorizontal,
                  label: 'Colors',
                ),
                _buildToolButton(
                  id: 'text',
                  icon: LucideIcons.type,
                  label: 'Add Text',
                  onTap: _addNewTextOverlay,
                ),
                if (widget.isVideo)
                  _buildToolButton(
                    id: 'trim',
                    icon: LucideIcons.scissors,
                    label: 'Trim',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required String id,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isActive = _activeTool == id;
    return GestureDetector(
      onTap: onTap ??
          () {
            setState(() {
              _activeTool = _activeTool == id ? 'none' : id;
            });
          },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD700).withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFFFFD700) : Colors.white70,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFFFD700) : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropDrawer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aspect Ratio Crop', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
              IconButton(
                tooltip: 'Rotate 90°',
                icon: const Icon(LucideIcons.rotateCw, color: Color(0xFFFFD700), size: 16),
                onPressed: () => setState(() => _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCropChip(CropAspectRatio.free, 'Free'),
                _buildCropChip(CropAspectRatio.square, '1:1 Square'),
                _buildCropChip(CropAspectRatio.feedPortrait, '4:5 Feed'),
                _buildCropChip(CropAspectRatio.storyVertical, '9:16 Story'),
                _buildCropChip(CropAspectRatio.landscape, '16:9 Wide'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropChip(CropAspectRatio ar, String label) {
    final isSel = _selectedCrop == ar;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.black : Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        selected: isSel,
        selectedColor: const Color(0xFFFFD700),
        backgroundColor: Colors.white.withOpacity(0.08),
        onSelected: (_) => setState(() => _selectedCrop = ar),
      ),
    );
  }

  Widget _buildSketchDrawer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          ...[
            const Color(0xFFFFD700),
            Colors.white,
            const Color(0xFF00E5FF),
            const Color(0xFFFF2D55),
            const Color(0xFF00E676),
            const Color(0xFFFF6D00),
            Colors.black,
          ].map((c) => GestureDetector(
                onTap: () => setState(() => _sketchColor = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _sketchColor == c ? Colors.white : Colors.white24,
                      width: _sketchColor == c ? 2.5 : 1,
                    ),
                  ),
                ),
              )),
          const Spacer(),
          IconButton(
            tooltip: 'Undo last stroke',
            icon: const Icon(LucideIcons.undo2, color: Colors.white70, size: 16),
            onPressed: _drawnLines.isEmpty
                ? null
                : () => setState(() => _drawnLines.removeLast()),
          ),
          IconButton(
            tooltip: 'Clear sketch',
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF5252), size: 16),
            onPressed: _drawnLines.isEmpty
                ? null
                : () => setState(() => _drawnLines.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustDrawer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AestheticFilter.values.map((f) {
                final isSel = _activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      _getFilterName(f),
                      style: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFFFFD700),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    onSelected: (_) => setState(() => _activeFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Sliders: Brightness, Contrast, Saturation
          Row(
            children: [
              const Text('Light', style: TextStyle(color: Colors.white60, fontSize: 11)),
              Expanded(
                child: Slider(
                  value: _brightness,
                  min: -0.4,
                  max: 0.4,
                  activeColor: const Color(0xFFFFD700),
                  onChanged: (v) => setState(() => _brightness = v),
                ),
              ),
              const Text('Vivid', style: TextStyle(color: Colors.white60, fontSize: 11)),
              Expanded(
                child: Slider(
                  value: _saturation,
                  min: 0.0,
                  max: 2.0,
                  activeColor: const Color(0xFFFFD700),
                  onChanged: (v) => setState(() => _saturation = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterName(AestheticFilter f) {
    switch (f) {
      case AestheticFilter.none: return 'Original';
      case AestheticFilter.goldenHour: return 'Golden';
      case AestheticFilter.cyberpunk: return 'Cyberpunk';
      case AestheticFilter.monochrome: return 'B&W';
      case AestheticFilter.cinematic: return 'Cinematic';
      case AestheticFilter.vintage: return 'Vintage';
      case AestheticFilter.sepia: return 'Sepia';
    }
  }

  Widget _buildTrimmerDrawer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Video Length: ${(_videoEndSeconds - _videoStartSeconds).toStringAsFixed(1)}s (from ${_videoStartSeconds.toInt()}s to ${_videoEndSeconds.toInt()}s)',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => setState(() => _isPlayingPreview = !_isPlayingPreview),
                child: Icon(
                  _isPlayingPreview ? LucideIcons.pause : LucideIcons.play,
                  color: const Color(0xFFFFD700),
                  size: 16,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_videoStartSeconds, _videoEndSeconds),
            min: 0.0,
            max: _videoTotalDuration,
            divisions: 30,
            activeColor: const Color(0xFFFFD700),
            inactiveColor: Colors.white24,
            labels: RangeLabels(
              '${_videoStartSeconds.toInt()}s',
              '${_videoEndSeconds.toInt()}s',
            ),
            onChanged: (values) {
              setState(() {
                _videoStartSeconds = values.start;
                _videoEndSeconds = values.end;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<DrawnLine> lines;

  _SketchPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.points.length < 2) continue;
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(line.points.first.dx, line.points.first.dy);
      for (int i = 1; i < line.points.length; i++) {
        path.lineTo(line.points[i].dx, line.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}
