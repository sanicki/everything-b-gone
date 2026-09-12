import 'package:flutter/material.dart';

import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_service.dart';

/// Settings > Flipper-IRDB data: shows when the device-type tree and each
/// Device Type's file cache were last refreshed, with individual and
/// full-tree "Refresh" actions.
class FlipperDataCard extends StatefulWidget {
  const FlipperDataCard({super.key});

  @override
  State<FlipperDataCard> createState() => _FlipperDataCardState();
}

class _FlipperDataCardState extends State<FlipperDataCard> {
  final FlipperIrdbService _service = FlipperIrdbService();

  bool _loading = true;
  String? _error;
  FlipperIrdbTree? _tree;
  DateTime? _treeCachedAt;
  final Map<String, DateTime?> _typeCachedAt = <String, DateTime?>{};
  final Set<String> _refreshing = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tree = await _service.fetchTree();
      final cachedAt = await _service.treeCachedAt();
      final perType = <String, DateTime?>{};
      for (final type in tree.deviceTypes) {
        perType[type] = await _service.deviceTypeCachedAt(type);
      }
      if (!mounted) return;
      setState(() {
        _tree = tree;
        _treeCachedAt = cachedAt;
        _typeCachedAt
          ..clear()
          ..addAll(perType);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshType(String type) async {
    final tree = _tree;
    if (tree == null) return;
    setState(() => _refreshing.add(type));
    try {
      await _service.fetchDeviceTypeFiles(type, tree, forceRefresh: true);
      final cachedAt = await _service.deviceTypeCachedAt(type);
      if (!mounted) return;
      setState(() => _typeCachedAt[type] = cachedAt);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh $type: $e')),
      );
    } finally {
      if (mounted) setState(() => _refreshing.remove(type));
    }
  }

  Future<void> _refreshAll() async {
    setState(() => _refreshing.add('*'));
    try {
      final tree = await _service.fetchTree(forceRefresh: true);
      for (final type in tree.deviceTypes) {
        await _service.fetchDeviceTypeFiles(type, tree, forceRefresh: true);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh Flipper-IRDB: $e')),
      );
    } finally {
      if (mounted) setState(() => _refreshing.remove('*'));
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'not cached';
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      return 'cached today at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'cached ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not load: $_error'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final tree = _tree!;
    return Column(
      children: [
        ListTile(
          dense: true,
          title: const Text('Device type tree'),
          subtitle: Text(_formatDate(_treeCachedAt)),
        ),
        const Divider(height: 1),
        for (final type in tree.deviceTypes)
          ListTile(
            dense: true,
            title: Text(type),
            subtitle: Text(_formatDate(_typeCachedAt[type])),
            trailing: _refreshing.contains(type)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh $type',
                    onPressed: () => _refreshType(type),
                  ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _refreshing.contains('*') ? null : _refreshAll,
              icon: _refreshing.contains('*')
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: const Text('Refresh all data'),
            ),
          ),
        ),
      ],
    );
  }
}
