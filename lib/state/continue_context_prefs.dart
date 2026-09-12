import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:everythingbgone/utils/remote.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<int> continueContextsRevision = ValueNotifier<int>(0);

void notifyContinueContextsChanged() {
  continueContextsRevision.value = continueContextsRevision.value + 1;
}

class ContinueContextsPrefs {
  ContinueContextsPrefs._();

  static const String _remoteKey = 'continue.last_remote.v1';

  static Future<ContinueContextsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ContinueContextsSnapshot(
      remote: _decodeRemote(prefs.getString(_remoteKey)),
    );
  }

  static Future<void> saveLastRemote(Remote remote) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _remoteKey,
      jsonEncode(
        LastRemoteContext(
          remoteId: remote.id,
          remoteName: remote.name,
          buttonCount: remote.buttons.length,
          savedAt: DateTime.now(),
        ).toJson(),
      ),
    );
    notifyContinueContextsChanged();
  }

  static LastRemoteContext? _decodeRemote(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return LastRemoteContext.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }
}

class ContinueContextsSnapshot {
  final LastRemoteContext? remote;

  const ContinueContextsSnapshot({
    required this.remote,
  });

  bool get isEmpty => remote == null;
}

class LastRemoteContext {
  final int remoteId;
  final String remoteName;
  final int buttonCount;
  final DateTime savedAt;

  const LastRemoteContext({
    required this.remoteId,
    required this.remoteName,
    required this.buttonCount,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'remoteId': remoteId,
        'remoteName': remoteName,
        'buttonCount': buttonCount,
        'savedAt': savedAt.toIso8601String(),
      };

  factory LastRemoteContext.fromJson(Map<String, dynamic> json) {
    return LastRemoteContext(
      remoteId: json['remoteId'] is int
          ? json['remoteId'] as int
          : int.tryParse('${json['remoteId']}') ?? 0,
      remoteName: (json['remoteName'] as String?) ?? '',
      buttonCount: json['buttonCount'] is int
          ? json['buttonCount'] as int
          : int.tryParse('${json['buttonCount']}') ?? 0,
      savedAt: DateTime.tryParse((json['savedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
