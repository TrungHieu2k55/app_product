class CloudinaryConfig {
  const CloudinaryConfig._();

  static const cloudName = 'hieudev';
  static const uploadPreset = 'giua_ki';

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  static Uri get uploadUri =>
      Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload');
}
