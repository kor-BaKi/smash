import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/activity_photo_api.dart';
import '../../../core/theme/app_theme.dart';
import '../model/activity_photo_model.dart';

class ActivityPhotoPage extends StatefulWidget {
  final int activityId;
  final String activityLabel;

  const ActivityPhotoPage({
    super.key,
    required this.activityId,
    required this.activityLabel,
  });

  @override
  State<ActivityPhotoPage> createState() => _ActivityPhotoPageState();
}

class _ActivityPhotoPageState extends State<ActivityPhotoPage> {
  List<ActivityPhotoInfo> _photos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final data = await ActivityPhotoApi.getPhotos(widget.activityId);
      setState(() {
        _photos = data.map((e) => ActivityPhotoInfo.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhotos() async {
    final picked = await _picker.pickMultiImage(imageQuality: 100);
    if (picked.isEmpty) return;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진을 업로드 중입니다...')));
      await ActivityPhotoApi.uploadPhotos(
        widget.activityId,
        picked.map((e) => e.path).toList(),
      );
      await _loadPhotos();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('업로드되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('업로드에 실패했습니다.')));
      }
    }
  }

  Future<void> _deletePhoto(int photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '사진 삭제',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          '이 사진을 삭제할까요?',
          style: TextStyle(color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.gray),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ActivityPhotoApi.deletePhoto(photoId);
        await _loadPhotos();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
        }
      }
    }
  }

  void _showFullScreen(ActivityPhotoInfo photo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullScreenPhoto(photo: photo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.activityLabel)),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lime),
            )
          : _photos.isEmpty
          ? const Center(
              child: Text(
                '등록된 사진이 없습니다.',
                style: TextStyle(color: AppColors.gray),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return GestureDetector(
                  onTap: () => _showFullScreen(photo),
                  onLongPress: () => _deletePhoto(photo.id),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photo.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.card2,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.overlay.withValues(
                                alpha: 0x8A / 0xFF,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              photo.createdAt.substring(0, 10),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.lime,
        onPressed: _uploadPhotos,
        child: const Icon(
          Icons.add_photo_alternate,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

class _FullScreenPhoto extends StatefulWidget {
  final ActivityPhotoInfo photo;

  const _FullScreenPhoto({required this.photo});

  @override
  State<_FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<_FullScreenPhoto> {
  bool _isSaving = false;

  // 원본 바이트를 내려받아 갤러리에 저장
  Future<void> _savePhoto() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final response = await Dio().get<List<int>>(
        widget.photo.url,
        options: Options(responseType: ResponseType.bytes),
      );
      await Gal.putImageBytes(
        Uint8List.fromList(response.data!),
        album: 'SMASH',
      );
      _showMessage('갤러리에 저장되었습니다.');
    } on GalException catch (e) {
      _showMessage(
        e.type == GalExceptionType.accessDenied
            ? '사진 저장 권한이 필요합니다. 설정에서 허용해 주세요.'
            : '저장에 실패했습니다.',
      );
    } catch (_) {
      _showMessage('저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.overlay,
      appBar: AppBar(
        backgroundColor: AppColors.overlay,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          widget.photo.createdAt,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: '갤러리에 저장',
                  onPressed: _savePhoto,
                ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            widget.photo.url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: AppColors.white,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
}
