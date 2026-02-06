import 'package:flutter/material.dart';

class ProgressSlider extends StatelessWidget {
  const ProgressSlider({
    super.key,
    required this.progressLabel,
    required this.distanceLabel,
    required this.value,
    required this.onChanged,
  });

  final String progressLabel;
  final String distanceLabel;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: theme.textTheme.labelMedium),
            Text(
              '$progressLabel · $distanceLabel',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        SliderTheme(
          data: sliderTheme,
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
