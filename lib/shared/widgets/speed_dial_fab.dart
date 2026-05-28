import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// ── Data class for each speed-dial child ─────────────────────────────────────

class SpeedDialChild {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SpeedDialChild({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// ── Speed Dial FAB ────────────────────────────────────────────────────────────

class SpeedDialFab extends StatefulWidget {
  final List<SpeedDialChild> children;

  const SpeedDialFab({super.key, required this.children});

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  // Main FAB rotation: 0 → -0.125 turns (= -45°, CCW on expand)
  late final Animation<double> _rotationAnim;

  // Color tween: black → babyBlue
  late final Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationAnim = Tween<double>(begin: 0, end: -0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnim = ColorTween(
      begin: const Color(0xFF1A1A1A), // near-black (from AppTheme)
      end: AppTheme.babyBlue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        // Dismiss overlay when open
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(color: Colors.transparent),
            ),
          ),

        // Mini FABs (rendered bottom-to-top so they stack correctly)
        ..._buildMiniFabs(),

        // Main FAB
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FloatingActionButton(
              backgroundColor: _colorAnim.value,
              onPressed: _toggle,
              child: RotationTransition(
                turns: _rotationAnim,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildMiniFabs() {
    // Stagger intervals: slot 0 (bottom) = 0.0–0.8, slot 1 (top) = 0.15–1.0
    const intervals = [
      Interval(0.0, 0.8, curve: Curves.easeInOut),
      Interval(0.15, 1.0, curve: Curves.easeInOut),
    ];

    // Bottom offsets above main FAB (56px FAB + 8px gap + 48px per slot)
    const bottomOffsets = [72.0, 136.0];

    return List.generate(widget.children.length, (index) {
      final child = widget.children[index];
      final interval = index < intervals.length
          ? intervals[index]
          : intervals.last;
      final bottomOffset = index < bottomOffsets.length
          ? bottomOffsets[index]
          : bottomOffsets.last + (index - bottomOffsets.length + 1) * 64.0;

      final curvedAnim = CurvedAnimation(parent: _controller, curve: interval);
      final slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(curvedAnim);

      return Positioned(
        bottom: bottomOffset,
        right: 0,
        child: FadeTransition(
          opacity: curvedAnim,
          child: SlideTransition(
            position: slideAnim,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    child.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mini FAB
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FloatingActionButton.small(
                    heroTag: 'speed_dial_$index',
                    onPressed: () {
                      _toggle();
                      child.onTap();
                    },
                    child: Icon(child.icon),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
