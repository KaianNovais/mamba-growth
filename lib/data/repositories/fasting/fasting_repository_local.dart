import 'package:sqflite/sqflite.dart';

import '../../../domain/models/fast.dart';
import '../../../domain/models/fasting_protocol.dart';
import '../../../utils/result.dart';
import '../../services/database/local_database.dart';
import '../../services/notifications/notification_service.dart';
import 'fasting_repository.dart';

class FastingRepositoryLocal extends FastingRepository {
  FastingRepositoryLocal({
    required LocalDatabase database,
    required NotificationService notifications,
    required String notificationTitle,
    required String notificationBody,
  })  : _localDb = database,
        _notifications = notifications,
        _notificationTitle = notificationTitle,
        _notificationBody = notificationBody {
    _bootstrap();
  }

  final LocalDatabase _localDb;
  final NotificationService _notifications;
  final String _notificationTitle;
  final String _notificationBody;

  static const _selectedProtocolKey = 'selected_protocol_id';

  Fast? _activeFast;
  FastingProtocol _selectedProtocol = FastingProtocol.defaultProtocol;
  bool _isInitialized = false;

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
          await _notifications.scheduleFastEnd(
            endAt: fast.plannedEndAt,
            title: _notificationTitle,
            body: _notificationBody,
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
