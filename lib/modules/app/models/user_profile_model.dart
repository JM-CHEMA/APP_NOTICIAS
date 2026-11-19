class UserProfileModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? imageUrl;
  const UserProfileModel({required this.uid, required this.name, required this.email,
    this.phone = '', this.imageUrl});

  factory UserProfileModel.fromJson(String uid, Map<String, dynamic> json) => UserProfileModel(
    uid: uid, name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(), phone: (json['phone'] ?? '').toString(),
    imageUrl: json['imageUrl']?.toString(),
  );
}
