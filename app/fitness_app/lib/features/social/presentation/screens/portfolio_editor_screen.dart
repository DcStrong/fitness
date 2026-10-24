import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_top_bar.dart';
import '../../data/device_image_picker.dart';
import '../../data/social_repository.dart';
import '../controller/unsaved_changes_guard.dart';
import '../helper/image_upload.helper.dart';
import '../widgets/portfolio_photo_picker.dart';
import '../widgets/safe_network_image.dart';

/// Экран создания/редактирования работы портфолио: одна запись — название,
/// описание и до 5 фото (лимит 5 фото считается по всему портфолио).
/// Закрывается с `true`, если работа сохранена.
class PortfolioEditorScreen extends StatefulWidget {
  const PortfolioEditorScreen({
    this.itemId,
    this.photoPicker,
    this.guard,
    super.key,
  });

  final String? itemId;
  final PortfolioPhotoPicker? photoPicker;

  /// Сторож несохранённых изменений (его же использует `GoRoute.onExit`).
  final UnsavedChangesGuard? guard;

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
  int _otherPhotos = 0;
  String _baseline = '';
  String? _error;
  late final UnsavedChangesGuard _guard = widget.guard ?? UnsavedChangesGuard();

  bool get _isNew => widget.itemId == null;

  /// Сколько фото ещё можно добавить: лимит считается по сумме фото всего
  /// портфолио (в других записях уже [_otherPhotos]).
  int get _freeSlots => (maxPortfolioPhotos - _otherPhotos - _photos.length)
      .clamp(0, maxPortfolioPhotos);

  @override
  void initState() {
    super.initState();
    _title.addListener(_recompute);
    _description.addListener(_recompute);
    _guard.attach(save: _save);
    _load();
  }

  @override
  void dispose() {
    _guard.detach();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  String _snapshot() =>
      [_title.text.trim(), _description.text.trim(), ..._photos].join('\u0001');

  void _recompute() {
    if (_loading) return;
    _guard.setDirty(_snapshot() != _baseline);
  }

  void _markClean() {
    _baseline = _snapshot();
    _guard.setDirty(false);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<SocialRepository>().getOwnProfile();
      _otherPhotos = profile.portfolio
          .where((entry) => entry.id != widget.itemId)
          .fold(0, (sum, entry) => sum + entry.imageUrls.length);
      final item = _isNew
          ? null
          : profile.portfolio
                .where((entry) => entry.id == widget.itemId)
                .firstOrNull;
      if (!mounted) return;
      if (!_isNew && item == null) {
        setState(() {
          _loading = false;
          _error = 'Работа не найдена';
        });
        return;
      }
      if (item != null) {
        _title.text = item.title;
        _description.text = item.description ?? '';
        _photos
          ..clear()
          ..addAll(item.imageUrls);
      }
      setState(() => _loading = false);
      _markClean();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _addPhotos() async {
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
      _recompute();
    } on PhotoPickException catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = error.message;
      });
    }
  }

  Future<bool> _save() async {
    if (!_formKey.currentState!.validate()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scrollToFirstFormError(_formKey.currentContext!);
      });
      return false;
    }
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
          imageUrls: [..._photos],
        );
      } else {
        await repository.createPortfolioItem(
          title: _title.text.trim(),
          description: _description.text,
          imageUrls: [..._photos],
        );
      }
      if (!mounted) return true;
      _markClean();
      context.pop(true);
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _error = uploadErrorMessage(error);
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _guard,
    builder: (context, _) => PopScope(
      canPop: !_guard.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _guard.confirmLeave(context) && context.mounted) {
          context.pop();
        }
      },
      child: _buildScaffold(context),
    ),
  );

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: FyTopBar(title: _isNew ? 'Новая работа' : 'Изменить работу'),
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
                      'Фото (${_photos.length}, можно ещё $_freeSlots)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Лимит 5 фото на всё портфолио. JPEG, PNG или WebP, '
                      'до 5 МБ каждое, до 25 МБ за раз.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PhotoGrid(
                      photos: _photos,
                      canAdd: _freeSlots > 0,
                      uploading: _uploading,
                      onAdd: _addPhotos,
                      onRemove: (index) {
                        setState(() => _photos.removeAt(index));
                        _recompute();
                      },
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
            key: ValueKey('portfolio-photo-$index'),
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
            key: const Key('portfolio-add-photo'),
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
