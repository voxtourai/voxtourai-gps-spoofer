import 'package:flutter/material.dart';

class UniformTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const UniformTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? sliderTheme.activeTrackColor ?? Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = trackHeight;

    final y = trackRect.center.dy;
    context.canvas.drawLine(
      Offset(trackRect.left, y),
      Offset(trackRect.right, y),
      paint,
    );
  }
}
