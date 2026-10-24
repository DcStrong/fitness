import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/device_image_picker.dart';
import '../../data/social_repository.dart';
import '../helper/image_upload.helper.dart';

enum AvatarUploadStatus { idle, picking, uploading }

class AvatarUploadState extends Equatable {
  const AvatarUploadState({
    this.status = AvatarUploadStatus.idle,
    this.avatarUrl,
    this.error,
  });

  final AvatarUploadStatus status;
  final String? avatarUrl;
  final String? error;

  bool get busy => status != AvatarUploadStatus.idle;

  @override
  List<Object?> get props => [status, avatarUrl, error];
}

/// Выбор фото аватара, проверка лимитов на клиенте и загрузка на бэкенд.
class AvatarUploadCubit extends Cubit<AvatarUploadState> {
  AvatarUploadCubit({
    required SocialRepository repository,
    required DeviceImagePicker picker,
    String? initialUrl,
  }) : _repository = repository,
       _picker = picker,
       super(AvatarUploadState(avatarUrl: initialUrl));

  final SocialRepository _repository;
  final DeviceImagePicker _picker;

  Future<void> pickAndUpload() async {
    if (state.busy) return;
    emit(
      AvatarUploadState(
        status: AvatarUploadStatus.picking,
        avatarUrl: state.avatarUrl,
      ),
    );
    try {
      final images = await _picker.pick();
      if (images.isEmpty) {
        emit(AvatarUploadState(avatarUrl: state.avatarUrl));
        return;
      }
      final problem = validateImages(images);
      if (problem != null) {
        emit(AvatarUploadState(avatarUrl: state.avatarUrl, error: problem));
        return;
      }
      emit(
        AvatarUploadState(
          status: AvatarUploadStatus.uploading,
          avatarUrl: state.avatarUrl,
        ),
      );
      final uploaded = await _repository.uploadAvatar(images.first);
      emit(AvatarUploadState(avatarUrl: uploaded.url));
    } catch (error) {
      emit(
        AvatarUploadState(
          avatarUrl: state.avatarUrl,
          error: uploadErrorMessage(error),
        ),
      );
    }
  }

  void remove() {
    if (state.busy) return;
    emit(const AvatarUploadState());
  }
}
