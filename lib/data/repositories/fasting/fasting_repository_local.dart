import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../domain/models/fast.dart';
import '../../../domain/models/fasting_protocol.dart';
import '../../../utils/result.dart';
import '../../services/database/local_database.dart';
import '../../services/notifications/notification_service.dart';
import 'fasting_repository.dart';

typedef NotificationCopyProvider = ({String title, String body}) Function();

class FastingRepositoryLocal extends FastingRepository {
  FastingRepositoryLocal({
    required LocalDatabase database,
    required NotificationService notifications,
    required NotificationCopyProvider notificationCopyProvider,
  })  : _localDb = database,
        _notifications = notifications,
        _notificationCopy = notificationCopyProvider {
    _bootstrap();
  }

  final LocalDatabase _localDb;
  final NotificationService _notifications;
  final NotificationCopyProvider _notificationCopy;

  static const _selectedProtocolKey = 'selected_protocol_id';

  Fast? _activeFast;
  FastingProtocol _selectedProtocol = FastingProtocol.defaultProtocol;
  bool _isInitialized = false;

  // Cache + broadcast pra histórico. Cache permite que assinantes
  // novos recebam o estado atual imediatamente (replay-on-subscribe);
  // controller dispara apenas quando um jejum é encerrado.
  final StreamController<List<Fast>> _completedFastsCtrl =
      StreamController<List<Fast>>.broadcast();
  List<Fast> _completedFastsCache = const [];

  @override
  Fast? get activeFast => _activeFast;

  @override
  FastingProtocol get selectedProtocol => _selectedProtocol;

  @override
  bool get isInitialized => _isInitialized;

  Future<void> _bootstrap() async {
    try {
      final db = await _localDb.database;
      _selectedProtocol = await _readSelectedProtocol(db);
      _activeFast = await _readActiveFast(db);
      await _refreshCompletedFasts(db);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<FastingProtocol> _readSelectedProtocol(Database db) async {
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_selectedProtocolKey],
      limit: 1,
    );
    if (rows.isEmpty) return FastingProtocol.defaultProtocol;
    final value = rows.first['value'] as String?;
    return value == null
        ? FastingProtocol.defaultProtocol
        : FastingProtocol.parseId(value);
  }

  Future<Fast?> _readActiveFast(Database db) async {
    final rows = await db.query(
      'fasts',
      where: 'end_at IS NULL',
      orderBy: 'start_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fastFromRow(rows.first);
  }

  Future<void> _refreshCompletedFasts(Database db) async {
    final rows = await db.query(
      'fasts',
      where: 'end_at IS NOT NULL',
      orderBy: 'start_at DESC',
    );
    _completedFastsCache =
        List.unmodifiable(rows.map(_fastFromRow));
    if (!_completedFastsCtrl.isClosed) {
      _completedFastsCtrl.add(_completedFastsCache);
    }
  }

  @override
  Future<Result<Fast>> startFast() async {
    if (_activeFast != null) {
      return Result.error(
        const FastingException('Já existe um jejum ativo.'),
      );
    }
    try {
      final now = DateTime.now();
      final db = await _localDb.database;
      final id = await db.insert('fasts', {
        'start_at': now.millisecondsSinceEpoch,
        'end_at': null,
        'target_hours': _selectedProtocol.fastingHours,
        'eating_hours': _selectedProtocol.eatingHours,
        'completed': 0,
      });
      final fast = Fast(
        id: id,
        startAt: now,
        endAt: null,
        targetHours: _selectedProtocol.fastingHours,
        eatingHours: _selectedProtocol.eatingHours,
        completed: false,
      );
      _activeFast = fast;
      notifyListeners();

      // Permissão + agendamento são best-effort — falhas não impedem o jejum.
      final granted = await _notifications.requestPermissionIfNeeded();
      if (granted) {
        try {
          final copy = _notificationCopy();
          await _notifications.scheduleFastEnd(
            endAt: fast.plannedEndAt,
            title: copy.title,
            body: copy.body,
          );
        } catch (_) {/* schedule é best-effort */}
      }

      return Result.ok(fast);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<Fast>> endFast() async {
    final current = _activeFast;
    if (current == null) {
      return Result.error(
        const FastingException('Nenhum jejum ativo para encerrar.'),
      );
    }
    try {
      final now = DateTime.now();
      final db = await _localDb.database;
      final completed = !now.isBefore(current.plannedEndAt);
      await db.update(
        'fasts',
        {
          'end_at': now.millisecondsSinceEpoch,
          'completed': completed ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [current.id],
      );
      await _notifications.cancelFastEnd();

      final ended = Fast(
        id: current.id,
        startAt: current.startAt,
        endAt: now,
        targetHours: current.targetHours,
        eatingHours: current.eatingHours,
        completed: completed,
      );
      _activeFast = null;
      await _refreshCompletedFasts(db);
      notifyListeners();
      return Result.ok(ended);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<void> setProtocol(FastingProtocol protocol) async {
    if (_selectedProtocol == protocol) return;
    final db = await _localDb.database;
    await db.insert(
      'settings',
      {'key': _selectedProtocolKey, 'value': protocol.id},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _selectedProtocol = protocol;
    notifyListeners();
  }

  @override
  Stream<List<Fast>> watchCompletedFasts() async* {
    yield _completedFastsCache;
    yield* _completedFastsCtrl.stream;
  }

  @override
  Future<List<Fast>> getFastsBetween(DateTime start, DateTime end) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'fasts',
      where: 'end_at IS NOT NULL AND end_at >= ? AND end_at < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'end_at DESC',
    );
    return List.unmodifiable(rows.map(_fastFromRow));
  }

  @override
  void dispose() {
    _completedFastsCtrl.close();
    super.dispose();
  }

  Fast _fastFromRow(Map<String, Object?> row) {
    return Fast(
      id: row['id'] as int,
      startAt: DateTime.fromMillisecondsSinceEpoch(row['start_at'] as int),
      endAt: row['end_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['end_at'] as int),
      targetHours: row['target_hours'] as int,
      eatingHours: row['eating_hours'] as int,
      completed: (row['completed'] as int) == 1,
    );
  }
}
