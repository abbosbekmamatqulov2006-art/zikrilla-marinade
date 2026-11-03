import '../l10n.dart';

class Address {
  final String text;
  final double? lat;
  final double? lng;
  const Address(this.text, {this.lat, this.lng});

  bool get hasCoords => lat != null && lng != null;

  factory Address.fromJson(Map<String, dynamic> j) =>
      Address(j['text'] as String? ?? '', lat: (j['lat'] as num?)?.toDouble(), lng: (j['lng'] as num?)?.toDouble());

  Map<String, dynamic> toJson() => {'text': text, 'lat': lat, 'lng': lng};
}

class User {
  final String id;
  final String phone; // 998XXXXXXXXX
  final String firstName;
  final String lastName;
  final String? birthDate; // YYYY-MM-DD
  final String? gender; // male | female
  final Address? address;
  final String? email;
  final String language;
  final bool registered;

  const User({
    required this.id,
    required this.phone,
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.gender,
    this.address,
    this.email,
    this.language = 'uz',
    this.registered = false,
  });

  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    final s = '$a$b'.toUpperCase();
    return s.isEmpty ? 'Z' : s;
  }

  String get fullName => '$firstName $lastName'.trim();

  /// "+998 90 123 45 67"
  String get phonePretty => formatPhone(phone);

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String,
    phone: j['phone'] as String,
    firstName: j['firstName'] as String? ?? '',
    lastName: j['lastName'] as String? ?? '',
    birthDate: j['birthDate'] as String?,
    gender: j['gender'] as String?,
    address: j['address'] == null ? null : Address.fromJson(j['address'] as Map<String, dynamic>),
    email: j['email'] as String?,
    language: j['language'] as String? ?? 'uz',
    registered: j['registered'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': birthDate,
    'gender': gender,
    'address': address?.toJson(),
    'email': email,
    'language': language,
    'registered': registered,
  };
}

String formatPhone(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  if (d.length != 12) return '+$d';
  return '+${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
}

class RegisterData {
  final String firstName;
  final String lastName;
  final String birthDate;
  final String? gender;
  final Address address;
  final String? email;
  final String language;
  const RegisterData({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    required this.address,
    required this.email,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': birthDate,
    'gender': gender,
    'address': address.toJson(),
    if (email != null && email!.isNotEmpty) 'email': email,
    'language': language,
  };
}

class Loyalty {
  final int balance;
  final String tier; // sozlamalardagi daraja kodi (bronze | silver | gold | ...)
  final String? iikoCustomerId;
  final int lifetime; // jami yig'ilgan ball
  const Loyalty({required this.balance, required this.tier, this.iikoCustomerId, this.lifetime = 0});

  factory Loyalty.fromJson(Map<String, dynamic> j) => Loyalty(
    balance: (j['balance'] as num? ?? 0).round(),
    tier: j['tier'] as String? ?? 'bronze',
    iikoCustomerId: j['iikoCustomerId'] as String?,
    lifetime: (j['lifetime'] as num? ?? 0).round(),
  );
}

class Store {
  final String id;
  final L name;
  final L address;
  final double lat;
  final double lng;
  final String phone;
  final String open; // "09:00"
  final String close; // "22:00"
  final bool sample;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.open,
    required this.close,
    this.sample = false,
  });

  factory Store.fromJson(Map<String, dynamic> j) => Store(
    id: j['id'] as String,
    name: L.fromJson(j['name'] as Map<String, dynamic>),
    address: L.fromJson(j['address'] as Map<String, dynamic>),
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    phone: j['phone'] as String? ?? '',
    open: (j['hours'] as Map?)?['open'] as String? ?? '09:00',
    close: (j['hours'] as Map?)?['close'] as String? ?? '22:00',
    sample: j['sample'] as bool? ?? false,
  );

  int _mins(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  bool get is24h => open == close;

  bool isOpenAt(DateTime t) {
    if (is24h) return true;
    final now = t.hour * 60 + t.minute;
    final o = _mins(open), c = _mins(close);
    return c > o ? now >= o && now < c : now >= o || now < c; // handles past-midnight hours
  }
}

class OrderItem {
  final String productId;
  final int qty;
  const OrderItem(this.productId, this.qty);
  Map<String, dynamic> toJson() => {'productId': productId, 'qty': qty};
}

class OrderRequest {
  final String storeId;
  final bool delivery;
  final List<OrderItem> items;
  final String slot;
  final int pointsToUse;
  final Address? address;
  const OrderRequest({
    required this.storeId,
    required this.delivery,
    required this.items,
    required this.slot,
    required this.pointsToUse,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'storeId': storeId,
    'type': delivery ? 'delivery' : 'pickup',
    'items': items.map((e) => e.toJson()).toList(),
    'slot': slot,
    'pointsToUse': pointsToUse,
    if (address != null) 'address': address!.toJson(),
  };
}

class OrderInfo {
  final String id;
  final int number;
  final String status; // accepted | preparing | ready | done | cancelled
  final String storeId;
  final Map<String, int> items;
  final int total;
  final DateTime createdAt;
  const OrderInfo({
    required this.id,
    required this.number,
    required this.status,
    required this.storeId,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  int get stage => switch (status) {
    'accepted' => 0,
    'preparing' => 1,
    'ready' => 2,
    _ => 3,
  };

  factory OrderInfo.fromJson(Map<String, dynamic> j) => OrderInfo(
    id: j['id'] as String,
    number: (j['number'] as num).toInt(),
    status: j['status'] as String? ?? 'accepted',
    storeId: j['storeId'] as String? ?? '',
    items: {
      for (final i in (j['items'] as List? ?? const [])) (i as Map)['productId'] as String: (i['qty'] as num).toInt(),
    },
    total: (j['total'] as num? ?? 0).round(),
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Xabar (bildirishnoma): aksiya, yangi mahsulot, yangi filial yoki baho so'rovi.
class AppNotification {
  final int id;
  final String kind; // promo | product | store | feedback | system
  final L title;
  final L body;
  final String image;
  final String link; // catalog | cat:<kod> | product:<id> | url:<manzil> | stores | feedback:<id>
  final DateTime createdAt;
  final bool unread;
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.image,
    required this.link,
    required this.createdAt,
    required this.unread,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: (j['id'] as num).toInt(),
    kind: j['kind'] as String? ?? 'promo',
    title: L.fromJson(j['title'] as Map<String, dynamic>? ?? const {}),
    body: L.fromJson(j['body'] as Map<String, dynamic>? ?? const {}),
    image: j['image'] as String? ?? '',
    link: j['link'] as String? ?? '',
    createdAt: (DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now()).toLocal(),
    unread: j['unread'] as bool? ?? false,
  );
}

/// Xariddan keyin baho so'rovi.
class FeedbackAsk {
  final int id;
  final String? storeId;
  final L? store;
  final int amount;
  final DateTime purchasedAt;
  const FeedbackAsk({required this.id, this.storeId, this.store, required this.amount, required this.purchasedAt});

  factory FeedbackAsk.fromJson(Map<String, dynamic> j) => FeedbackAsk(
    id: (j['id'] as num).toInt(),
    storeId: j['storeId'] as String?,
    store: j['store'] == null ? null : L.fromJson(j['store'] as Map<String, dynamic>),
    amount: (j['amount'] as num? ?? 0).round(),
    purchasedAt: (DateTime.tryParse(j['purchasedAt'] as String? ?? '') ?? DateTime.now()).toLocal(),
  );
}
