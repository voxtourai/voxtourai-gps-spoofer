import 'package:flutter/material.dart';

import 'progress_slider.dart';
import 'uniform_slider.dart';

class ControlsPanel extends StatelessWidget {
  const ControlsPanel({
    super.key,
    required this.showSetupBar,
    required this.setupLabel,
    required this.onRunSetupChecks,
    required this.progressLabel,
    required this.distanceLabel,
    required this.progress,
    required this.onProgressChanged,
    required this.speedMps,
    required this.onSpeedChanged,
    required this.mockError,
  });

  final bool showSetupBar;
  final String setupLabel;
  final VoidCallback onRunSetupChecks;
  final String progressLabel;
  final String distanceLabel;
  final double progress;
  final ValueChanged<double>? onProgressChanged;
  final double speedMps;
  final ValueChanged<double> onSpeedChanged;
  final String? mockError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speedSliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      activeTrackColor: theme.colorScheme.outlineVariant,
      inactiveTrackColor: theme.colorScheme.outlineVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            if (showSetupBar)
              OutlinedButton.icon(
                onPressed: onRunSetupChecks,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(setupLabel),
              ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressSlider(
                  progressLabel: progressLabel,
                  distanceLabel: distanceLabel,
                  value: progress,
                  onChanged: onProgressChanged,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Speed', style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      '${speedMps.toStringAsFixed(0)} m/s',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                UniformSlider(
                  theme: speedSliderTheme,
                  value: speedMps,
                  min: -200,
                  max: 200,
                  divisions: 200,
                  onChanged: onSpeedChanged,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (mockError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  mockError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
