class UserDto {
  final String id;
  final String name;
  final String phoneNumber;
  final String? googleUid;

  const UserDto({required this.id, required this.name, required this.phoneNumber, this.googleUid});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      googleUid: json['google_uid']?.toString(),
    );
  }

  factory UserDto.fromMap(Map<String, dynamic> map) {
    return UserDto(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      phoneNumber: (map['phone_number'] ?? '').toString(),
      googleUid: map['google_uid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    if (googleUid != null) 'google_uid': googleUid,
  };
}