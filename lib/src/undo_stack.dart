import 'dart:async';
import 'dart:collection';

class ChangeStack {
  /// Changes to keep track of
  ChangeStack({this.limit});

  /// Limit changes to store in the history
  int limit;

  final Queue<List<Change>> _history = ListQueue();
  final Queue<List<Change>> _redos = ListQueue();

  /// Can redo the previous change
  bool get canRedo => _redos.isNotEmpty;

  /// Can undo the previous change
  bool get canUndo => _history.isNotEmpty;

  /// Add New Change and Clear Redo Stack
  FutureOr<void> add<T>(Change<T> change) async {
    await change.execute();
    _history.addLast([change]);
    await _moveForward();
  }

  FutureOr<void> _moveForward() async {
    _redos.clear();

    if (limit != null && _history.length > limit + 1) {
      _history.removeFirst();
    }
  }

  /// Add New Group of Changes and Clear Redo Stack
  FutureOr<void> addGroup<T>(List<Change<T>> changes) async {
    await _applyChanges(changes);
    _history.addLast(changes);
    await _moveForward();
  }

  FutureOr<void> _applyChanges(List<Change> changes) async {
    for (final change in changes) {
      await change.execute();
    }
  }

  /// Clear Undo History
  @deprecated
  void clear() => clearHistory();

  /// Clear Undo History
  void clearHistory() {
    _history.clear();
    _redos.clear();
  }

  /// Redo Previous Undo
  FutureOr<void> redo() async {
    if (canRedo) {
      final changes = _redos.removeFirst();
      await _applyChanges(changes);
      _history.addLast(changes);
    }
  }

  /// Undo Last Change
  FutureOr<void> undo() async {
    if (canUndo) {
      final changes = _history.removeLast();
      for (final change in changes) {
        await change.undo();
      }
      _redos.addFirst(changes);
    }
  }
}

class Change<T> {
  Change(
    this._oldValue,
    this._execute(),
    this._undo(T oldValue), {
    this.description,
  });

  final String description;

  final FutureOr<void> Function() _execute;
  final T _oldValue;

  final FutureOr<void> Function(T oldValue) _undo;

  FutureOr<void> execute() async {
    await _execute();
  }

  FutureOr<void> undo() async {
    await _undo(_oldValue);
  }
}
