import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/stationery_theme.dart';
import 'stationery_3d_models.dart';

class Stationery3DPencilBox extends StatefulWidget {
  final StationeryTheme theme;
  final Function(String toolKey)? onToolSelected;

  const Stationery3DPencilBox({
    super.key,
    required this.theme,
    this.onToolSelected,
  });

  @override
  State<Stationery3DPencilBox> createState() => _Stationery3DPencilBoxState();
}

class _Stationery3DPencilBoxState extends State<Stationery3DPencilBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _boxController;
  late Animation<double> _openAnimation;
  bool _isOpen = true;

  @override
  void initState() {
    super.initState();
    _boxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _openAnimation = CurvedAnimation(
      parent: _boxController,
      curve: Curves.easeOutBack,
    );
    _boxController.value = 1.0; // Open by default
  }

  @override
  void dispose() {
    _boxController.dispose();
    super.dispose();
  }

  void _toggleBox() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _boxController.forward();
      } else {
        _boxController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _openAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleBox,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A5298), // Metallic Geometry Box Navy/Cyan
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E3C72), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 10),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  // Box Top Cover with 3D embossed geometry case logo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "TOOLER STATIONERY KIT",
                              style: widget.theme.fontDisplay(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isOpen ? "TAP TO CLOSE" : "TAP TO OPEN",
                            style: widget.theme.fontMono(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Interior Stationery Tray (Revealed when open)
                  if (_openAnimation.value > 0.05)
                    Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX((1.0 - _openAnimation.value) * -math.pi / 2.5),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFFE8ECEF), // Plastic tray inside tin box
                        child: Column(
                          children: [
                            // 3D Wooden Ruler inside tray
                            InkWell(
                              onTap: () => widget.onToolSelected?.call('sizer'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: SizedBox(
                                  height: 44,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: Stationery3DRulerPainter(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Row with 3D Pencil, Divider, Eraser
                            Row(
                              children: [
                                // 3D Yellow Pencil
                                Expanded(
                                  flex: 3,
                                  child: InkWell(
                                    onTap: () => widget.onToolSelected?.call('calc'),
                                    child: SizedBox(
                                      height: 24,
                                      child: CustomPaint(
                                        painter: Stationery3DPencilPainter(
                                          pencilColor: const Color(0xFFFFB300),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // 3D Blue Pencil
                                Expanded(
                                  flex: 3,
                                  child: InkWell(
                                    onTap: () => widget.onToolSelected?.call('tasks'),
                                    child: SizedBox(
                                      height: 24,
                                      child: CustomPaint(
                                        painter: Stationery3DPencilPainter(
                                          pencilColor: const Color(0xFF00A8FF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Eraser Block
                                InkWell(
                                  onTap: () => widget.onToolSelected?.call('passGen'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F6FA),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF2F3542), width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xFF718093),
                                          offset: Offset(2, 2),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "ERASER",
                                      style: widget.theme.fontMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2F3542),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
