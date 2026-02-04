/// User Model - Phản ánh bảng Users trong database HeathCare
class User {
  final int userId;
  final String username;
  final String email;
  final String? fullName;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;
  final String? goal;
  final String? bodyGoals;
  final String? activityLevel;
  final int preferredLanguageId;
  final bool onboardingCompleted;
  final DateTime? createdAt;

  User({
    required this.userId,
    required this.username,
    required this.email,
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.goal,
    this.bodyGoals,
    this.activityLevel,
    this.preferredLanguageId = 1,
    this.onboardingCompleted = false,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth:
          json['date_of_birth'] != null
              ? DateTime.tryParse(json['date_of_birth'].toString())
              : null,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      goal: json['goal'] as String?,
      bodyGoals: json['body_goals'] as String?,
      activityLevel: json['activity_level'] as String?,
      preferredLanguageId: json['preferred_language_id'] as int? ?? 1,
      onboardingCompleted:
          json['onboarding_completed'] == true ||
          json['onboarding_completed'] == 1,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'email': email,
    'full_name': fullName,
    'gender': gender,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'height': height,
    'weight': weight,
    'goal': goal,
    'body_goals': bodyGoals,
    'activity_level': activityLevel,
    'preferred_language_id': preferredLanguageId,
    'onboarding_completed': onboardingCompleted,
    'created_at': createdAt?.toIso8601String(),
  };

  /// Tính BMI
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// Tính tuổi
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Tên hiển thị (ưu tiên fullName, fallback về email)
  String get displayName => fullName ?? email.split('@')[0];

  User copyWith({
    int? userId,
    String? username,
    String? email,
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? goal,
    String? bodyGoals,
    String? activityLevel,
    int? preferredLanguageId,
    bool? onboardingCompleted,
    DateTime? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      bodyGoals: bodyGoals ?? this.bodyGoals,
      activityLevel: activityLevel ?? this.activityLevel,
      preferredLanguageId: preferredLanguageId ?? this.preferredLanguageId,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Language Model - Phản ánh bảng Languages
class Language {
  final int languageId;
  final String code;
  final String name;
  final bool isDefault;
  final DateTime? createdAt;

  Language({
    required this.languageId,
    required this.code,
    required this.name,
    this.isDefault = false,
    this.createdAt,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      languageId: json['language_id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'language_id': languageId,
    'code': code,
    'name': name,
    'is_default': isDefault,
    'created_at': createdAt?.toIso8601String(),
  };
}

/// Notification Model - Phản ánh bảng Notifications
class AppNotification {
  final int notificationId;
  final int userId;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.notificationId,
    required this.userId,
    required this.message,
    this.type = 'system',
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notification_id'] as int,
      userId: json['user_id'] as int,
      message: json['message'] as String,
      type: json['type'] as String? ?? 'system',
      createdAt: DateTime.parse(json['created_at'].toString()),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'notification_id': notificationId,
    'user_id': userId,
    'message': message,
    'type': type,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
  };
}

/// Friendship Model - Phản ánh bảng Friendships
class Friendship {
  final int userId;
  final int friendId;
  final String status;

  Friendship({
    required this.userId,
    required this.friendId,
    required this.status,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      userId: json['user_id'] as int,
      friendId: json['friend_id'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'friend_id': friendId,
    'status': status,
  };
}
