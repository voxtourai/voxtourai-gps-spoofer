import 'package:flutter/material.dart';

class UniformSlider extends StatelessWidget {
  const UniformSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.theme,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final SliderThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final baseTheme = theme ?? SliderTheme.of(context);
    final sliderTheme = baseTheme.copyWith(
      trackShape: const _UniformTrackShape(),
    );

    return SliderTheme(
      data: sliderTheme,
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

class _UniformTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _UniformTrackShape();

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
