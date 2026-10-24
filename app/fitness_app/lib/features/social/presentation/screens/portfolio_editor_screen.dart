import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_top_bar.dart';
import '../../data/social_repository.dart';
import '../../data/device_image_picker.dart';
import '../helper/image_upload.helper.dart';
import '../widgets/portfolio_photo_picker.dart';
import '../widgets/safe_network_image.dart';

/// Экран создания/редактирования работы портфолио. Закрывается с `true`,
/// если работа сохранена.
class PortfolioEditorScreen extends StatefulWidget {
  const PortfolioEditorScreen({this.itemId, this.photoPicker, super.key});

  final String? itemId;
  final PortfolioPhotoPicker? photoPicker;

  @override
  State<PortfolioEditorScreen> createState() => _PortfolioEditorScreenState();
}

class _PortfolioEditorScreenState extends State<PortfolioEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final List<String> _photos = [];
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  int _existingCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isNew => widget.itemId == null;

  /// Сколько фото ещё можно добавить: у новой работы — свободные места в
  /// портфолио (каждое фото станет отдельной работой), у существующей — одно.
  int get _freeSlots => _isNew
      ? (maxPortfolioPhotos - _existingCount - _photos.length).clamp(
          0,
          maxPortfolioPhotos,
        )
      : (1 - _photos.length).clamp(0, 1);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<SocialRepository>().getOwnProfile();
      _existingCount = profile.portfolio.length;
      if (_isNew) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final item = profile.portfolio
          .where((entry) => entry.id == widget.itemId)
          .firstOrNull;
      if (!mounted) return;
      if (item == null) {
        setState(() {
          _loading = false;
          _error = 'Работа не найдена';
        });
        return;
      }
      _title.text = item.title;
      _description.text = item.description ?? '';
      _photos
        ..clear()
        ..addAll([if (item.imageUrl?.isNotEmpty == true) item.imageUrl!]);
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _addPhoto() async {
    if (_uploading) return;
    final picker =
        widget.photoPicker ??
        DevicePortfolioPhotoPicker(
          repository: context.read<SocialRepository>(),
          picker: const ImagePickerDeviceImagePicker(),
        );
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final urls = await picker.pickPhotos(context, maxCount: _freeSlots);
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _photos.addAll(urls);
      });
    } on PhotoPickException catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = context.read<SocialRepository>();
      final id = widget.itemId;
      if (id != null) {
        await repository.updatePortfolioItem(
          id: id,
          title: _title.text.trim(),
          description: _description.text,
          imageUrl: _photos.firstOrNull ?? '',
        );
      } else {
        // На бэкенде одна работа — одно фото: каждое выбранное фото
        // сохраняется отдельной работой с общими названием и описанием.
        final urls = _photos.isEmpty ? <String?>[null] : [..._photos];
        for (final url in urls) {
          await repository.createPortfolioItem(
            title: _title.text.trim(),
            description: _description.text,
            imageUrl: url,
          );
          if (url != null) _photos.remove(url);
          _existingCount++;
        }
      }
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = uploadErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: FyTopBar(
        title: widget.itemId == null ? 'Новая работа' : 'Изменить работу',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Text(
                      _isNew
                          ? 'Фото (${_photos.length}, можно ещё $_freeSlots)'
                          : 'Фото',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isNew && _photos.length > 1) ...[
                      const Text(
                        'Каждое фото сохранится отдельной работой '
                        'с этим названием и описанием.',
                      ),
                      const SizedBox(height: 10),
                    ],
                    _PhotoGrid(
                      photos: _photos,
                      canAdd: _freeSlots > 0,
                      uploading: _uploading,
                      onAdd: _addPhoto,
                      onRemove: (index) =>
                          setState(() => _photos.removeAt(index)),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _title,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Название'),
                      validator: (value) => value?.trim().isNotEmpty == true
                          ? null
                          : 'Укажите название',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _description,
                      maxLength: 1000,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      FyInfoBanner(
                        message: _error!,
                        icon: Icons.error_outline_rounded,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FyPrimaryButton(
                      label: 'Сохранить',
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.canAdd,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final bool canAdd;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final (index, url) in photos.indexed)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeNetworkImage(url: url, icon: Icons.image_outlined),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton.filledTonal(
                  tooltip: 'Убрать фото',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ],
          ),
        if (uploading)
          const Center(child: CircularProgressIndicator())
        else if (canAdd)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined),
                  SizedBox(height: 4),
                  Text('Добавить фото', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
