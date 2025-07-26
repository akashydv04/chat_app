import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String gender;
  String profileImageUrl;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.profileImageUrl,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}
