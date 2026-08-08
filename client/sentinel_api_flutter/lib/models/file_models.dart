class FileMetadataDto {
  final String id;
  final String originalFileName;
  final String storedFileName;
  final String contentType;
  final int fileSizeBytes;
  final String sha256Hash;
  final String uploadedAt;
  final bool isEncrypted;

  FileMetadataDto({
    required this.id,
    required this.originalFileName,
    required this.storedFileName,
    required this.contentType,
    required this.fileSizeBytes,
    required this.sha256Hash,
    required this.uploadedAt,
    required this.isEncrypted,
  });

  factory FileMetadataDto.fromJson(Map<String, dynamic> json) {
    return FileMetadataDto(
      id: json['id']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString() ?? '',
      storedFileName: json['storedFileName']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      fileSizeBytes: json['fileSizeBytes'] is int ? json['fileSizeBytes'] : int.tryParse(json['fileSizeBytes']?.toString() ?? '0') ?? 0,
      sha256Hash: json['sha256Hash']?.toString() ?? '',
      uploadedAt: json['uploadedAt']?.toString() ?? '',
      isEncrypted: json['isEncrypted'] == true,
    );
  }
}
