class DevAccount {
  const DevAccount({
    required this.label,
    required this.email,
    required this.password,
    required this.roleLabel,
  });

  final String label;
  final String email;
  final String password;
  final String roleLabel;
}

/// Local-only presets for quick login during development.
abstract final class DevAccounts {
  static const List<DevAccount> all = [
    DevAccount(
      label: 'Тренер',
      email: 'test@mail.ru',
      password: 'fjghdk12',
      roleLabel: 'trainer',
    ),
    DevAccount(
      label: 'Участник',
      email: 'test2@mail.ru',
      password: 'fjghdk12',
      roleLabel: 'student',
    ),
  ];
}
