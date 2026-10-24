import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/fy_info_banner.dart';
import '../../../../core/widgets/fy_primary_button.dart';
import '../../../../core/widgets/fy_top_bar.dart';
import '../../data/social_repository.dart';
import '../widgets/portfolio_photo_picker.dart';
import '../widgets/safe_network_image.dart';

const maxPortfolioPhotos = 5;

/// Экран создания/редактирования работы портфолио. Закрывается с `true`,
/// если работа сохранена.
class PortfolioEditorScreen extends StatefulWidget {
  const PortfolioEditorScreen({
    this.itemId,
    this.photoPicker = const StubPortfolioPhotoPicker(),
    super.key,
  });

  final String? itemId;
  final PortfolioPhotoPicker photoPicker;

  @override
  State<PortfolioEditorScreen> createState() => _PortfolioEditorScreenState();
}

class _PortfolioEditorScreenState extends State<PortfolioEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final List<String> _photos = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) _load();
  }

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
    final url = await widget.photoPicker.pickPhoto(context);
    if (!mounted) return;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Загрузка фото с устройства скоро будет доступна'),
        ),
      );
      return;
    }
    setState(() => _photos.add(url));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = context.read<SocialRepository>();
      // Бэкенд пока хранит одно изображение на работу — берём первое фото.
      final imageUrl = _photos.firstOrNull ?? '';
      final id = widget.itemId;
      if (id != null) {
        await repository.updatePortfolioItem(
          id: id,
          title: _title.text.trim(),
          description: _description.text,
          imageUrl: imageUrl,
        );
      } else {
        await repository.createPortfolioItem(
          title: _title.text.trim(),
          description: _description.text,
          imageUrl: imageUrl,
        );
      }
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
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
                      'Фото (${_photos.length}/$maxPortfolioPhotos)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PhotoGrid(
                      photos: _photos,
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
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < maxPortfolioPhotos;
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
        if (canAdd)
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
