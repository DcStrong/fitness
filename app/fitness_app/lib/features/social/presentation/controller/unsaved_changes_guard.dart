import 'package:flutter/material.dart';

/// Выбор пользователя в диалоге «Есть несохранённые изменения».
enum UnsavedChangesChoice { save, discard, stay }

/// Общий «сторож» формы: знает, есть ли несохранённые изменения, умеет
/// сохранить их и спросить пользователя перед уходом с экрана.
///
/// Форма вызывает [attach]/[detach] и [setDirty]; маршрут (`GoRoute.onExit`) и
/// `PopScope` вызывают [confirmLeave].
class UnsavedChangesGuard extends ChangeNotifier {
  bool _dirty = false;
  bool _saving = false;
  Future<bool> Function()? _save;

  bool get dirty => _dirty;
  bool get saving => _saving;

  /// Есть что сохранять и форма подключена.
  bool get canSave => _dirty && _save != null && !_saving;

  void attach({required Future<bool> Function() save}) {
    _save = save;
  }

  void detach() {
    _save = null;
    _setDirtyQuiet(false);
  }

  void setDirty(bool value) {
    if (_dirty == value) return;
    _dirty = value;
    notifyListeners();
  }

  void _setDirtyQuiet(bool value) {
    _dirty = value;
    _saving = false;
  }

  /// Сохраняет форму; `true`, если сохранено (или сохранять нечего).
  Future<bool> save() async {
    final callback = _save;
    if (callback == null || _saving) return !_dirty;
    _saving = true;
    notifyListeners();
    try {
      return await callback();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Можно ли уйти с экрана. При несохранённых изменениях показывает диалог.
  Future<bool> confirmLeave(BuildContext context) async {
    if (!_dirty || _save == null) return true;
    final choice = await showDialog<UnsavedChangesChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UnsavedChangesDialog(),
    );
    switch (choice) {
      case UnsavedChangesChoice.save:
        return save();
      case UnsavedChangesChoice.discard:
        setDirty(false);
        return true;
      case UnsavedChangesChoice.stay:
      case null:
        return false;
    }
  }
}

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Есть несохранённые изменения'),
    content: const Text('Сохранить их перед уходом или отменить?'),
    actionsOverflowDirection: VerticalDirection.down,
    actionsOverflowButtonSpacing: 4,
    actions: [
      FilledButton(
        key: const Key('unsaved-save'),
        onPressed: () => Navigator.of(context).pop(UnsavedChangesChoice.save),
        child: const Text('Сохранить'),
      ),
      TextButton(
        key: const Key('unsaved-discard'),
        onPressed: () =>
            Navigator.of(context).pop(UnsavedChangesChoice.discard),
        child: const Text('Отменить и перейти'),
      ),
      TextButton(
        key: const Key('unsaved-stay'),
        onPressed: () => Navigator.of(context).pop(UnsavedChangesChoice.stay),
        child: const Text('Остаться'),
      ),
    ],
  );
}

/// Прокручивает к первому полю формы с ошибкой валидации.
void scrollToFirstFormError(BuildContext formContext) {
  FormFieldState<dynamic>? first;
  void visit(Element element) {
    if (first != null) return;
    if (element is StatefulElement && element.state is FormFieldState) {
      final state = element.state as FormFieldState<dynamic>;
      if (state.hasError) {
        first = state;
        return;
      }
    }
    element.visitChildren(visit);
  }

  (formContext as Element).visitChildren(visit);
  final target = first?.context;
  if (target != null) {
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      alignment: 0.2,
    );
  }
}
