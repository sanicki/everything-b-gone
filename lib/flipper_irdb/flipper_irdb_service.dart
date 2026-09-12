import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'flipper_ir_parser.dart';
import 'flipper_irdb_models.dart';
import 'signal_matching.dart';

class FlipperIrdbException implements Exception {
  final String message;
  const FlipperIrdbException(this.message);

  @override
  String toString() => message;
}

/// Headless client for the Flipper-IRDB community `.ir` file database,
/// permanently pointed at https://github.com/Lucaslhm/Flipper-IRDB — no
/// user-facing "browse any repo" UI, unlike the upstream GitHub Store this
/// was repurposed from.
///
/// Two-tier persistent cache, both stored as JSON files under the app's
/// support directory (rather than SharedPreferences, since the tree index
/// is meant to persist indefinitely until explicitly refreshed, not expire
/// on a short TTL like casual-browse caching would):
///  1. The full Device Type -> Brand -> file-path tree, fetched once via a
///     single recursive git-tree API call (not one request per folder,
///     which would blow through GitHub's unauthenticated rate limit on a
///     repo with this many brand folders).
///  2. Per-Device-Type parsed file contents, fetched lazily the first time
///     that type is needed, via raw.githubusercontent.com (which isn't
///     subject to the API rate limit) rather than the contents API.
class FlipperIrdbService {
  static const String owner = 'Lucaslhm';
  static const String repo = 'Flipper-IRDB';
  static const String userAgent = 'EverythingBGone/1.0';

  String? _cachedDefaultBranch;

  Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/flipper_irdb_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _treeCacheFile(Directory dir) => File('${dir.path}/tree.json');

  File _typeCacheFile(Directory dir, String deviceType) =>
      File('${dir.path}/type_${_sanitizeForFilename(deviceType)}.json');

  File _qualificationCacheFile(Directory dir) =>
      File('${dir.path}/qualification.json');

  String _sanitizeForFilename(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  Future<String> _resolveDefaultBranch() async {
    final cached = _cachedDefaultBranch;
    if (cached != null) return cached;
    final res = await _get(Uri.https('api.github.com', '/repos/$owner/$repo'));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final branch = (body['default_branch'] as String?) ?? 'master';
    _cachedDefaultBranch = branch;
    return branch;
  }

  Future<http.Response> _get(Uri uri, {bool asJson = true}) async {
    late final http.Response res;
    try {
      res = await http.get(uri, headers: <String, String>{
        'User-Agent': userAgent,
        if (asJson) 'Accept': 'application/vnd.github+json',
      });
    } on SocketException {
      throw const FlipperIrdbException(
        'No network connection. Check your connection and try again.',
      );
    } catch (e) {
      throw FlipperIrdbException(e.toString());
    }

    if (res.statusCode == 403) {
      throw const FlipperIrdbException(
        'GitHub is rate-limiting requests right now. Try again in a few minutes.',
      );
    }
    if (res.statusCode == 404) {
      throw const FlipperIrdbException(
        'The Flipper-IRDB repository or file could not be found.',
      );
    }
    if (res.statusCode != 200) {
      throw FlipperIrdbException('GitHub returned ${res.statusCode}.');
    }
    return res;
  }

  /// The full Device Type / Brand / file-path tree, from cache unless
  /// [forceRefresh] or no cache exists yet.
  Future<FlipperIrdbTree> fetchTree({bool forceRefresh = false}) async {
    final dir = await _cacheDir();
    final cacheFile = _treeCacheFile(dir);

    if (!forceRefresh && await cacheFile.exists()) {
      final cached = await _tryReadTreeCache(cacheFile);
      if (cached != null) return cached;
    }

    final branch = await _resolveDefaultBranch();
    final res = await _get(Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/git/trees/$branch',
      <String, String>{'recursive': '1'},
    ));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final entries = (body['tree'] as List?) ?? const <dynamic>[];

    final tree = <String, Map<String, List<String>>>{};
    for (final entry in entries) {
      if (entry is! Map) continue;
      if (entry['type'] != 'blob') continue;
      final path = (entry['path'] ?? '').toString();
      if (!path.toLowerCase().endsWith('.ir')) continue;
      final parts = path.split('/');
      if (parts.length < 3) continue; // expect DeviceType/Brand/file.ir
      final deviceType = parts[0];
      final brand = parts[1];
      tree
          .putIfAbsent(deviceType, () => <String, List<String>>{})
          .putIfAbsent(brand, () => <String>[])
          .add(path);
    }

    if (tree.isEmpty) {
      throw const FlipperIrdbException(
        'Flipper-IRDB returned no device files.',
      );
    }

    final result = FlipperIrdbTree(
      deviceTypeToBrandToPaths: tree,
      fetchedAt: DateTime.now(),
    );
    await cacheFile.writeAsString(jsonEncode(result.toJson()));
    return result;
  }

  Future<FlipperIrdbTree?> _tryReadTreeCache(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return FlipperIrdbTree.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> treeCachedAt() async {
    final tree = await _tryReadTreeCache(_treeCacheFile(await _cacheDir()));
    return tree?.fetchedAt;
  }

  /// Every parsed `.ir` file under [deviceType], from cache unless
  /// [forceRefresh] or nothing is cached yet for this type.
  Future<List<FlipperIrFile>> fetchDeviceTypeFiles(
    String deviceType,
    FlipperIrdbTree tree, {
    bool forceRefresh = false,
  }) async {
    final dir = await _cacheDir();
    final cacheFile = _typeCacheFile(dir, deviceType);

    if (!forceRefresh && await cacheFile.exists()) {
      final cached = await _tryReadTypeCache(cacheFile);
      if (cached != null) return cached;
    }

    final branch = await _resolveDefaultBranch();
    final brandToPaths =
        tree.deviceTypeToBrandToPaths[deviceType] ?? const <String, List<String>>{};

    final results = <FlipperIrFile>[];
    for (final entry in brandToPaths.entries) {
      final brand = entry.key;
      for (final path in entry.value) {
        String content;
        try {
          content = await _fetchRaw(branch, path);
        } catch (_) {
          continue; // skip a single bad file rather than failing the whole type
        }
        final signals = parseFlipperIrFile(content);
        if (signals.isEmpty) continue;
        results.add(FlipperIrFile(
          deviceType: deviceType,
          brand: brand,
          fileName: path.split('/').last,
          path: path,
          signals: signals,
        ));
      }
    }

    await cacheFile.writeAsString(jsonEncode(<String, dynamic>{
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
      'files': results.map((f) => f.toJson()).toList(growable: false),
    }));
    return results;
  }

  Future<List<FlipperIrFile>?> _tryReadTypeCache(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final items = (decoded['files'] as List?) ?? const <dynamic>[];
      return items
          .whereType<Map>()
          .map((m) => FlipperIrFile.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> deviceTypeCachedAt(String deviceType) async {
    final dir = await _cacheDir();
    final file = _typeCacheFile(dir, deviceType);
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final ms = decoded['fetchedAt'] as int?;
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  Future<String> _fetchRaw(String branch, String path) async {
    final res = await _get(
      Uri.https('raw.githubusercontent.com', '/$owner/$repo/$branch/$path'),
      asJson: false,
    );
    return res.body;
  }

  Future<FlipperQualification?> loadQualification() async {
    final file = _qualificationCacheFile(await _cacheDir());
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return FlipperQualification.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveQualification(FlipperQualification qualification) async {
    final file = _qualificationCacheFile(await _cacheDir());
    await file.writeAsString(jsonEncode(qualification.toJson()));
  }

  /// Determines which Device Types / Brands have at least one qualifying
  /// power/off/mute signal, merging into any previously-saved result.
  /// Meant to run as a low-priority task after the default device type has
  /// already loaded — [skip] lets the caller avoid redundantly re-fetching
  /// the type it just loaded synchronously.
  Future<FlipperQualification> runQualificationScan(
    FlipperIrdbTree tree, {
    String? skip,
    List<FlipperIrFile>? skipFiles,
  }) async {
    final existing = await loadQualification();
    final merged = <String, Set<String>>{
      if (existing != null) ...existing.qualifyingBrandsByDeviceType,
    };

    for (final deviceType in tree.deviceTypes) {
      final List<FlipperIrFile> files;
      if (deviceType == skip && skipFiles != null) {
        files = skipFiles;
      } else {
        files = await fetchDeviceTypeFiles(deviceType, tree);
      }
      final qualifyingBrands = <String>{};
      for (final f in files) {
        final hasPower = powerOrOffSignalFor(f) != null;
        final hasMute = muteSignalFor(f) != null;
        if (hasPower || hasMute) qualifyingBrands.add(f.brand);
      }
      merged[deviceType] = qualifyingBrands;
    }

    final result = FlipperQualification(
      qualifyingBrandsByDeviceType: merged,
      scannedAt: DateTime.now(),
    );
    await saveQualification(result);
    return result;
  }
}
