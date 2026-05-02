enum UserRole { client, therapist, receptionist, admin }

extension UserRoleX on UserRole {
  static UserRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'therapist':
        return UserRole.therapist;
      case 'receptionist':
        return UserRole.receptionist;
      default:
        return UserRole.client;
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isTherapist => this == UserRole.therapist;
  bool get isReceptionist => this == UserRole.receptionist;
  bool get isClient => this == UserRole.client;
}

class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final String? specialty;
  final String? bio;
  final bool isActive;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.specialty,
    this.bio,
    required this.isActive,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    return UserProfile(
      id:         m['id'] as String,
      fullName:   m['full_name'] as String? ?? '',
      phone:      m['phone'] as String?,
      avatarUrl:  m['avatar_url'] as String?,
      role:       UserRoleX.fromString(m['role'] as String?),
      specialty:  m['specialty'] as String?,
      bio:        m['bio'] as String?,
      isActive:   m['is_active'] as bool? ?? true,
      fcmToken:   m['fcm_token'] as String?,
      createdAt:  DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt:  DateTime.tryParse(m['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
