class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? maslak;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.maslak,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      name: data['name'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      maslak: data['maslak'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'maslak': maslak,
    };
  }
}
