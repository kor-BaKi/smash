import 'package:flutter/material.dart';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.danger),
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
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text(widget.activityLabel)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? const Center(
              child: Text(
                '등록된 사진이 없습니다.',
                style: TextStyle(color: AppColors.textTertiary),
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
                            color: AppColors.neutralBg,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.textTertiary,
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
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              photo.createdAt.substring(0, 10),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
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
        backgroundColor: AppColors.primary,
        onPressed: _uploadPhotos,
        child: const Icon(Icons.add_photo_alternate, color: Colors.white),
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  final ActivityPhotoInfo photo;

  const _FullScreenPhoto({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          photo.createdAt,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            photo.url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
}
