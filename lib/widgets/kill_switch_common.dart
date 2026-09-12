import 'dart:async';

import 'package:flutter/material.dart';

/// The tappable "Device type" / "Brands" summary field that opens the
/// matching multi-select sheet. Shared by the Everything-B-Gone home screen
/// and the List screen so both present (and update) the exact same
/// selection.
class FilterField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const FilterField({super.key, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// "All" if [selected] is empty (the shared "All" convention), the single
/// name if exactly one is picked, otherwise a count.
String summaryForSelection(Set<String> selected) {
  if (selected.isEmpty) return 'All';
  if (selected.length == 1) return selected.first;
  return '${selected.length} selected';
}

/// The "All" + checkbox-list bottom sheet used to edit a Device Type or
/// Brand selection.
Future<Set<String>?> showFilterMultiSelectSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required Set<String> selected,
}) {
  Set<String> working = Set<String>.of(selected);
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final allSelected = working.isEmpty;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
                  ),
                  CheckboxListTile(
                    title: const Text('All'),
                    value: allSelected,
                    onChanged: (_) => setSheetState(() => working = <String>{}),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: options.map((option) {
                        final checked = working.contains(option);
                        return CheckboxListTile(
                          title: Text(option),
                          value: checked,
                          onChanged: (value) => setSheetState(() {
                            if (value == true) {
                              working.add(option);
                            } else {
                              working.remove(option);
                              if (working.isEmpty) working = <String>{};
                            }
                          }),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(working),
                        child: const Text('Done'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// The "Getting ready…" spinner shown while the Flipper-IRDB tree loads.
class KillSwitchLoadingBody extends StatelessWidget {
  const KillSwitchLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Getting ready…'),
        ],
      ),
    );
  }
}

/// The hard-stop error state (with Retry) shown when the initial tree fetch
/// fails outright.
class KillSwitchErrorBody extends StatelessWidget {
  final String message;
  final FutureOr<void> Function() onRetry;

  const KillSwitchErrorBody({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            const Text(
              "Couldn't load the device database",
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => unawaited(Future.sync(onRetry)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "no matches for this combination" empty state shown when the current
/// Device Type / Brand filter intersects to zero usable signals.
class NoMatchesMessage extends StatelessWidget {
  const NoMatchesMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_rounded,
              size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No matches for this combination — try selecting more brands or a different device type.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The "Plug in your IR dongle" banner shown at the top of a screen when no
/// transmitter is currently available.
class NoTransmitterBanner extends StatelessWidget {
  const NoTransmitterBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.usb_off_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Plug in your IR dongle to use Everything-B-Gone.',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
