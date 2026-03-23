class RegisterRequestDto {
  final String name;
  final String phoneNumber;
  final String address;
  final String password;

  const RegisterRequestDto({
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.password,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone_number': phoneNumber,
    'address': address,
    'password': password,
  };
}
