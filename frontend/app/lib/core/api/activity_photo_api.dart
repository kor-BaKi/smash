import 'package:dio/dio.dart';

import 'api_client.dart';

class ActivityPhotoApi {
  static final Dio _dio = ApiClient.instance;

  // 사진 목록 조회
  static Future<List<dynamic>> getPhotos(int activityId) async {
    final response = await _dio.get(
      '/admin/activities/$activityId/photos',
    );
    return response.data['data'];
  }

  // 사진 업로드
  static Future<List<dynamic>> uploadPhotos(
    int activityId,
    List<String> filePaths,
  ) async {
    final formData = FormData();
    for (final path in filePaths) {
      formData.files.add(
        MapEntry('files', await MultipartFile.fromFile(path)),
      );
    }
    final response = await _dio.post(
      '/admin/activities/$activityId/photos',
      data: formData,
    );
    return response.data['data'];
  }

  // 사진 삭제
  static Future<void> deletePhoto(int photoId) async {
    await _dio.delete('/admin/activities/photos/$photoId');
  }
}
