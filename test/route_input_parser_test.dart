import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/service/route_input_parser.dart';

void main() {
  group('extractPolylineFromInput', () {
    test('returns null for empty input', () {
      expect(extractPolylineFromInput('   '), isNull);
    });

    test('returns raw polyline input as-is after trimming', () {
      const polyline = 'abc123_polyline';
      expect(extractPolylineFromInput('  $polyline  '), polyline);
    });

    test('strips surrounding quotes from plain polyline input', () {
      expect(extractPolylineFromInput('"quoted_polyline"'), 'quoted_polyline');
      expect(extractPolylineFromInput("'single_quoted'"), 'single_quoted');
    });

    test('extracts nested encoded polyline from Routes API json', () {
      const jsonInput =
          '{"routes":[{"polyline":{"encodedPolyline":"nested_polyline"}}]}';

      expect(extractPolylineFromInput(jsonInput), 'nested_polyline');
    });

    test('extracts direct encodedPolyline value from json', () {
      expect(
        extractPolylineFromInput('{"encodedPolyline":"direct_polyline"}'),
        'direct_polyline',
      );
    });

    test('extracts routePolyline alias from json', () {
      expect(
        extractPolylineFromInput('{"routePolyline":"alias_polyline"}'),
        'alias_polyline',
      );
    });

    test('extracts first polyline from a json array payload', () {
      const jsonInput =
          '[{"ignored":true},{"polyline":{"encodedPolyline":"array_polyline"}}]';

      expect(extractPolylineFromInput(jsonInput), 'array_polyline');
    });

    test('falls back to regex extraction for malformed json fragments', () {
      const malformed =
          '{"routes":[{"polyline":{"encodedPolyline":"regex_polyline"}}';

      expect(extractPolylineFromInput(malformed), 'regex_polyline');
    });

    test('returns original json-like input when no polyline is found', () {
      const input = '{"routes":[]}';

      expect(extractPolylineFromInput(input), input);
    });
  });
}
