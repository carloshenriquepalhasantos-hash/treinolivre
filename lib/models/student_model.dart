class Student {
  final int? id;
  final String name;
  final String nickname;
  final String password;
  final double weight;
  final String objective;
  final double waterGoalMl;
  double waterConsumedToday;
  final int totalWorkouts;
  final bool isExpired;
  final DateTime startDate;
  final DateTime? endDate;
  final String? profileImageUrl;

  Student({
    this.id,
    required this.name,
    required this.nickname,
    required this.password,
    required this.weight,
    required this.objective,
    this.waterGoalMl = 2030.0,
    this.waterConsumedToday = 0.0,
    this.totalWorkouts = 4,
    this.isExpired = false,
    required this.startDate,
    this.endDate,
    this.profileImageUrl,
  });

  Student copyWith({
    int? id,
    String? name,
    String? nickname,
    String? password,
    double? weight,
    String? objective,
    double? waterGoalMl,
    double? waterConsumedToday,
    int? totalWorkouts,
    bool? isExpired,
    DateTime? startDate,
    DateTime? endDate,
    String? profileImageUrl,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      password: password ?? this.password,
      weight: weight ?? this.weight,
      objective: objective ?? this.objective,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      waterConsumedToday: waterConsumedToday ?? this.waterConsumedToday,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      isExpired: isExpired ?? this.isExpired,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      name: map['name'] ?? '',
      nickname: map['nickname'] ?? '',
      password: map['password'] ?? '',
      weight: double.tryParse(map['weight'].toString()) ?? 70.0,
      objective: map['objective'] ?? 'Hipertrofia',
      waterGoalMl:
          double.tryParse(map['water_goal_ml']?.toString() ?? '') ?? 2030.0,
      waterConsumedToday:
          double.tryParse(map['water_consumed_today']?.toString() ?? '') ?? 0.0,
      totalWorkouts: int.tryParse(map['total_workouts']?.toString() ?? '') ?? 4,
      isExpired: map['is_expired'] == 1 || map['is_expired'] == true,
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toString()),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      profileImageUrl: map['profile_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'password': password,
      'weight': weight,
      'objective': objective,
      'water_goal_ml': waterGoalMl,
      'water_consumed_today': waterConsumedToday,
      'total_workouts': totalWorkouts,
      'is_expired': isExpired ? 1 : 0,
      'profile_image_url': profileImageUrl,
    };
  }
}
