import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary =
      CloudinaryPublic('gffogu82', 'deeptalks_preset', cache: false);

  // Upload any media file (image, GIF, video) to Cloudinary
  Future<String?> uploadMedia(String filePath) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Auto,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }
}
