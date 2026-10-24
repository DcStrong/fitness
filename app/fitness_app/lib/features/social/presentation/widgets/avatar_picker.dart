import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../cubit/avatar_upload_cubit.dart';
import 'safe_network_image.dart';

/// Превью аватара с кнопками «Выбрать фото» / «Удалить». Состояние — в
/// [AvatarUploadCubit], который должен быть выше по дереву.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AvatarUploadCubit, AvatarUploadState>(
        builder: (context, state) {
          final cubit = context.read<AvatarUploadCubit>();
          final hasAvatar = state.avatarUrl?.isNotEmpty == true;
          return Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: SafeNetworkImage(
                      url: state.avatarUrl,
                      width: 96,
                      height: 96,
                    ),
                  ),
                  if (state.busy)
                    const SizedBox(
                      width: 96,
                      height: 96,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x66000000),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            key: Key('avatar-upload-progress'),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: state.busy ? null : cubit.pickAndUpload,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(hasAvatar ? 'Заменить фото' : 'Выбрать фото'),
                  ),
                  if (hasAvatar)
                    TextButton.icon(
                      onPressed: state.busy ? null : cubit.remove,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Удалить'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'JPEG, PNG или WebP, до 5 МБ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 6),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          );
        },
      );
}
