import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SpooferDebugPanel extends StatelessWidget {
  const SpooferDebugPanel({
    super.key,
    required this.lastInjectedPosition,
    required this.status,
    required this.isMockLocationApp,
    required this.selectedMockApp,
    required this.debugLog,
    required this.onRefreshMockStatus,
    this.expanded = false,
    this.showTitle = true,
  });

  final LatLng? lastInjectedPosition;
  final Map<String, Object?>? status;
  final bool? isMockLocationApp;
  final String? selectedMockApp;
  final List<String> debugLog;
  final VoidCallback onRefreshMockStatus;
  final bool expanded;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logCard = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: debugLog.isEmpty
          ? Text('No debug events yet.', style: theme.textTheme.bodySmall)
          : SingleChildScrollView(
              child: SelectableText(
                debugLog.join('\n'),
                style: theme.textTheme.bodySmall,
              ),
            ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text('Debug', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
        ],
        _buildSummarySection(context),
        const SizedBox(height: 12),
        _buildStatusSection(context),
        const SizedBox(height: 12),
        Text('Log', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        if (expanded)
          Expanded(child: logCard)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: logCard,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRefreshMockStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh mock status'),
          ),
        ),
      ],
    );

    if (!expanded) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildSummarySection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Summary', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          _buildKeyValueRow(
            context,
            'Injected',
            lastInjectedPosition == null
                ? '—'
                : '${lastInjectedPosition!.latitude.toStringAsFixed(6)}, ${lastInjectedPosition!.longitude.toStringAsFixed(6)}',
          ),
          _buildKeyValueRow(
            context,
            'Mock app selected',
            isMockLocationApp == null
                ? '—'
                : isMockLocationApp == true
                ? 'YES'
                : 'NO',
          ),
          _buildKeyValueRow(
            context,
            'Selected package',
            selectedMockApp ?? '—',
          ),
          _buildKeyValueRow(
            context,
            'Sequence',
            _formatValue(status?['sequence']) ?? '—',
          ),
          _buildKeyValueRow(
            context,
            'Since last mock',
            _formatDurationMillis(status?['sinceLastMockMs']),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _statusEntries();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Status', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text('No mock status yet.', style: theme.textTheme.bodySmall)
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildKeyValueRow(context, entry.$1, entry.$2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 124,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(value, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }

  List<(String, String)> _statusEntries() {
    final current = status;
    if (current == null) {
      return const <(String, String)>[];
    }

    final entries = <(String, String)>[];
    void add(String label, Object? value) {
      final formatted = _formatValue(value);
      if (formatted != null && formatted.isNotEmpty) {
        entries.add((label, formatted));
      }
    }

    add('Requested at', _formatTimestamp(current['requestedAtMs']));
    add('Requested location', current['requestedLocation']);
    add('GPS applied', current['gpsApplied']);
    add('Fused applied', current['fusedApplied']);
    add('GPS cleared', current['gpsCleared']);
    add('Fused cleared', current['fusedCleared']);
    add('Fused mock mode', current['fusedMockEnabled']);
    add('Enabled providers', current['enabledProviders']);
    add('Test providers ready', current['testProvidersReady']);
    add('GPS readback', current['gpsReadbackAfter']);
    add('Best readback', current['bestReadbackAfter']);
    add('GPS error', current['gpsError']);
    add('Fused error', current['fusedError']);
    add(
      'addTestProvider',
      _joinOutcome(current['addProviderResult'], current['addProviderError']),
    );
    add(
      'setTestProviderEnabled',
      _joinOutcome(
        current['enableProviderResult'],
        current['enableProviderError'],
      ),
    );
    add(
      'setTestProviderStatus',
      _joinOutcome(
        current['statusProviderResult'],
        current['statusProviderError'],
      ),
    );
    add(
      'removeTestProvider',
      _joinOutcome(
        current['removeProviderResult'],
        current['removeProviderError'],
      ),
    );
    add('Mock app selected', current['mockAppSelected']);
    add('Mock app package', current['selectedMockApp']);
    return entries;
  }

  String? _joinOutcome(Object? result, Object? error) {
    final resultText = _formatValue(result);
    final errorText = _formatValue(error);
    if ((resultText == null || resultText.isEmpty) &&
        (errorText == null || errorText.isEmpty)) {
      return null;
    }
    return [
      resultText,
      errorText,
    ].whereType<String>().where((e) => e.isNotEmpty).join('  ');
  }

  String _formatDurationMillis(Object? value) {
    if (value is num) {
      return '${value.toInt()} ms';
    }
    return '—';
  }

  String? _formatTimestamp(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      ).toLocal().toIso8601String();
    }
    return null;
  }

  String? _formatValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value ? 'YES' : 'NO';
    }
    if (value is Map) {
      final map = value.map((key, val) => MapEntry(key.toString(), val));
      if (map.containsKey('latitude') && map.containsKey('longitude')) {
        final lat = map['latitude'];
        final lng = map['longitude'];
        final provider = map['provider'];
        final accuracy = map['accuracy'];
        final providerText = provider == null ? '' : ' ${provider.toString()}';
        final accuracyText = accuracy == null
            ? ''
            : ' acc=${accuracy.toString()}';
        return '${lat.toString()}, ${lng.toString()}$providerText$accuracyText'
            .trim();
      }
      final pairs = map.entries
          .map((entry) => '${entry.key}=${_formatValue(entry.value) ?? '—'}')
          .toList();
      return pairs.join(', ');
    }
    if (value is Iterable) {
      return value.map(_formatValue).whereType<String>().join(', ');
    }
    return value.toString();
  }
}
