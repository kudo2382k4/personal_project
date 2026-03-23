class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String? googleUid;

  const User({required this.id, required this.name, required this.phoneNumber, this.googleUid});
}
