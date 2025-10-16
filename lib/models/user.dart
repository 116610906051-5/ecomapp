class AppUser {
  final String id;
  final String email;
  final String name;
  final String? displayName;
  final String? photoURL;
  final String? profileImageUrl;
  final String? phoneNumber;
  final List<Address> addresses;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.displayName,
    this.photoURL,
    this.profileImageUrl,
    this.phoneNumber,
    this.addresses = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      profileImageUrl: map['profileImageUrl'],
      phoneNumber: map['phoneNumber'],
      addresses: (map['addresses'] as List?)
          ?.map((address) => Address.fromMap(address))
          .toList() ?? [],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'displayName': displayName,
      'photoURL': photoURL,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'addresses': addresses.map((address) => address.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? displayName,
    String? photoURL,
    String? profileImageUrl,
    String? phoneNumber,
    List<Address>? addresses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Address {
  final String id;
  final String title;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  Address({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isDefault': isDefault,
    };
  }
}
