import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/mock_location_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.mockController,
    required this.onSelect,
    required this.onLog,
  });

  final MockLocationController mockController;
  final void Function(LatLng location, double zoom) onSelect;
  final void Function(String message) onLog;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<_GeocodeResult> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final response = await widget.mockController.geocodeAddress(trimmed, maxResults: 8);
      if (!mounted) {
        return;
      }
      final parsed = <_GeocodeResult>[];
      for (final entry in response) {
        final lat = entry['lat'];
        final lng = entry['lng'];
        if (lat is! num || lng is! num) {
          continue;
        }
        final address = entry['address']?.toString() ?? 'Unknown location';
        parsed.add(
          _GeocodeResult(
            address: address,
            location: LatLng(lat.toDouble(), lng.toDouble()),
            country: entry['country']?.toString(),
            adminArea: entry['adminArea']?.toString(),
            locality: entry['locality']?.toString(),
            subLocality: entry['subLocality']?.toString(),
            thoroughfare: entry['thoroughfare']?.toString(),
            subThoroughfare: entry['subThoroughfare']?.toString(),
          ),
        );
      }
      setState(() {
        _searching = false;
        _results = parsed;
        _error = parsed.isEmpty ? 'No results found.' : null;
      });
      widget.onLog('Geocode "$trimmed": ${parsed.length} results');
    } on PlatformException catch (errorValue) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = false;
        _results = [];
        _error = errorValue.message ?? 'Search failed.';
      });
      widget.onLog('Geocode error: ${errorValue.code}');
    } catch (errorValue) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = false;
        _results = [];
        _error = 'Search failed: $errorValue';
      });
      widget.onLog('Geocode exception: $errorValue');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search places',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _runSearch(_controller.text),
                        ),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => _runSearch(value),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              ),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results yet.'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return ListTile(
                          title: Text(item.address),
                          onTap: () {
                            widget.onSelect(item.location, item.suggestedZoom);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeocodeResult {
  final String address;
  final LatLng location;
  final String? country;
  final String? adminArea;
  final String? locality;
  final String? subLocality;
  final String? thoroughfare;
  final String? subThoroughfare;

  const _GeocodeResult({
    required this.address,
    required this.location,
    this.country,
    this.adminArea,
    this.locality,
    this.subLocality,
    this.thoroughfare,
    this.subThoroughfare,
  });

  double get suggestedZoom {
    if (_hasValue(subThoroughfare) || _hasValue(thoroughfare)) {
      return 17;
    }
    if (_hasValue(locality) || _hasValue(subLocality)) {
      return 12;
    }
    if (_hasValue(adminArea)) {
      return 8;
    }
    if (_hasValue(country)) {
      return 4.5;
    }
    return 10;
  }

  static bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
