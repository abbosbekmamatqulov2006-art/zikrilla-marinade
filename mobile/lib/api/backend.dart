import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data.dart';
import '../data.dart' as data;
import '../l10n.dart';
import 'models.dart';

/// Server base URL, e.g. `flutter run --dart-define=API_URL=https://api.zikrilla.uz/api/v1`.
/// When empty the app runs against [MockBackend] (SMS code 1111).
const apiUrl = String.fromEnvironment('API_URL');

class ApiException implements Exception {
  final String code; // backend `error` code, or network | unauthorized | unknown
  final String? message;
  final int? retryIn;
  const ApiException(this.code, {this.message, this.retryIn});
  @override
  String toString() => 'ApiException($code, $message)';
}

class SendCodeResult {
  final int resendIn;
  final String? devCode;
  const SendCodeResult(this.resendIn, this.devCode);
}

class VerifyResult {
  final String token;
  final bool registered;
  final User? user;
  const VerifyResult(this.token, this.registered, this.user);
}

abstract class Backend {
  bool get isMock;
  set token(String? value);

  Future<SendCodeResult> sendCode(String phone);
  Future<VerifyResult> verify(String phone, String code);
  Future<User> register(RegisterData data);
  Future<User> updateMe(RegisterData data);
  Future<(User, Loyalty)> me();
  Future<List<Store>> stores();
  Future<List<Product>> products();
  Future<OrderInfo> createOrder(OrderRequest req);
  Future<List<OrderInfo>> orders();
  Future<OrderInfo> order(String id);

  /// Sayt va ilova sozlamalari (admin panel → Sozlamalar / Ilova).
  Future<Map<String, dynamic>> settings();

  static Backend create() => apiUrl.isEmpty ? MockBackend() : HttpBackend(apiUrl);
}

// =====================================================================
// HTTP
// =====================================================================
class HttpBackend implements Backend {
  final String baseUrl;
  HttpBackend(this.baseUrl);

  @override
  bool get isMock => false;

  @override
  String? token;

  Future<Map<String, dynamic>> _req(String method, String path, [Object? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    http.Response res;
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 20)));
    } on TimeoutException {
      throw const ApiException('network');
    } on http.ClientException {
      throw const ApiException('network');
    } catch (_) {
      throw const ApiException('network');
    }
    Map<String, dynamic> json = const {};
    if (res.body.isNotEmpty) {
      try {
        json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    if (res.statusCode == 401) throw const ApiException('unauthorized');
    throw ApiException(
      json['error'] as String? ?? 'unknown',
      message: json['message'] as String?,
      retryIn: (json['retryIn'] as num?)?.toInt(),
    );
  }

  @override
  Future<SendCodeResult> sendCode(String phone) async {
    final j = await _req('POST', '/auth/send-code', {'phone': phone});
    return SendCodeResult((j['resendIn'] as num? ?? 60).toInt(), j['devCode'] as String?);
  }

  @override
  Future<VerifyResult> verify(String phone, String code) async {
    final j = await _req('POST', '/auth/verify', {'phone': phone, 'code': code});
    return VerifyResult(
      j['token'] as String,
      j['registered'] as bool? ?? false,
      j['user'] == null ? null : User.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<User> register(RegisterData data) async =>
      User.fromJson((await _req('POST', '/auth/register', data.toJson()))['user'] as Map<String, dynamic>);

  @override
  Future<User> updateMe(RegisterData data) async =>
      User.fromJson((await _req('PATCH', '/me', data.toJson()))['user'] as Map<String, dynamic>);

  @override
  Future<(User, Loyalty)> me() async {
    final j = await _req('GET', '/me');
    return (
      User.fromJson(j['user'] as Map<String, dynamic>),
      Loyalty.fromJson(j['loyalty'] as Map<String, dynamic>? ?? const {}),
    );
  }

  @override
  Future<List<Store>> stores() async => [
    for (final s in (await _req('GET', '/stores'))['stores'] as List) Store.fromJson(s as Map<String, dynamic>),
  ];

  @override
  Future<List<Product>> products() async => [
    for (final p in (await _req('GET', '/products'))['products'] as List) productFromJson(p as Map<String, dynamic>),
  ];

  @override
  Future<Map<String, dynamic>> settings() async =>
      (await _req('GET', '/settings'))['settings'] as Map<String, dynamic>? ?? const {};

  @override
  Future<OrderInfo> createOrder(OrderRequest req) async =>
      OrderInfo.fromJson((await _req('POST', '/orders', req.toJson()))['order'] as Map<String, dynamic>);

  @override
  Future<List<OrderInfo>> orders() async => [
    for (final o in (await _req('GET', '/orders'))['orders'] as List) OrderInfo.fromJson(o as Map<String, dynamic>),
  ];

  @override
  Future<OrderInfo> order(String id) async =>
      OrderInfo.fromJson((await _req('GET', '/orders/$id'))['order'] as Map<String, dynamic>);
}

// =====================================================================
// Mock (no server yet) — same contract, local data, SMS code 1111
// =====================================================================
class MockBackend implements Backend {
  static const devCode = '1111';

  @override
  bool get isMock => true;

  @override
  String? token;

  final _orders = <OrderInfo>[];

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<SendCodeResult> sendCode(String phone) async {
    await _delay();
    if (!RegExp(r'^998\d{9}$').hasMatch(phone)) throw const ApiException('invalid_phone');
    return const SendCodeResult(60, devCode);
  }

  @override
  Future<VerifyResult> verify(String phone, String code) async {
    await _delay();
    if (code != devCode) throw const ApiException('invalid_code');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mock_user_$phone');
    final user = raw == null
        ? User(id: 'u_$phone', phone: phone)
        : User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return VerifyResult('mock-token-$phone', user.registered, user.registered ? user : null);
  }

  String get _phone => (token ?? '').replaceFirst('mock-token-', '');

  Future<User> _save(RegisterData d) async {
    final user = User(
      id: 'u_$_phone',
      phone: _phone,
      firstName: d.firstName,
      lastName: d.lastName,
      birthDate: d.birthDate,
      gender: d.gender,
      address: d.address,
      email: d.email,
      language: d.language,
      registered: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_user_$_phone', jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<User> register(RegisterData data) async {
    await _delay();
    return _save(data);
  }

  @override
  Future<User> updateMe(RegisterData data) async {
    await _delay();
    return _save(data);
  }

  @override
  Future<(User, Loyalty)> me() async {
    await _delay();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mock_user_$_phone');
    if (raw == null) throw const ApiException('unauthorized');
    final points = prefs.getInt('mock_points_$_phone') ?? 47000;
    return (
      User.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      Loyalty(balance: points, tier: 'silver', iikoCustomerId: null),
    );
  }

  @override
  Future<List<Store>> stores() async {
    await _delay();
    return sampleStores;
  }

  @override
  Future<List<Product>> products() async => data.products;

  @override
  Future<Map<String, dynamic>> settings() async => const {};

  @override
  Future<OrderInfo> createOrder(OrderRequest req) async {
    await _delay();
    final subtotal = req.items.fold(0, (s, i) => s + productById(i.productId).price * i.qty);
    final total = subtotal + (req.delivery ? 15000 : 0) - req.pointsToUse;
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt('mock_points_$_phone') ?? 47000;
    await prefs.setInt('mock_points_$_phone', points - req.pointsToUse);
    final o = OrderInfo(
      id: 'o${1001 + _orders.length}',
      number: 1001 + _orders.length,
      status: 'accepted',
      storeId: req.storeId,
      items: {for (final i in req.items) i.productId: i.qty},
      total: total,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, o);
    return o;
  }

  OrderInfo _withStatus(OrderInfo o) {
    final s = DateTime.now().difference(o.createdAt).inSeconds;
    final status = s < 10 ? 'accepted' : (s < 30 ? 'preparing' : (s < 60 ? 'ready' : 'done'));
    return OrderInfo(
      id: o.id,
      number: o.number,
      status: status,
      storeId: o.storeId,
      items: o.items,
      total: o.total,
      createdAt: o.createdAt,
    );
  }

  @override
  Future<List<OrderInfo>> orders() async => _orders.map(_withStatus).toList();

  @override
  Future<OrderInfo> order(String id) async => _withStatus(_orders.firstWhere((o) => o.id == id));
}

/// Real Zikrilla branches (coordinates from Yandex Maps, 2026-09-17). Keep in sync with backend/data/stores.json.
const sampleStores = <Store>[
  Store(
    id: 'beshqayragoch',
    name: L('Zikrilla Бешкайрагач', 'Zikrilla Beshkairagach', 'Zikrilla Beshqayrag‘och'),
    address: L(
      'Учтепинский район, 1-й проезд Назарбек, 48',
      'Uchtepa district, Nazarbek 1st lane, 48',
      'Uchtepa tumani, Nazarbek 1-tor ko‘chasi, 48',
    ),
    lat: 41.307336,
    lng: 69.161724,
    phone: '+998783337272',
    open: '08:00',
    close: '01:00',
  ),
  Store(
    id: 'kokcha',
    name: L('Zikrilla Кукча', 'Zikrilla Kukcha', 'Zikrilla Ko‘kcha'),
    address: L(
      'Шайхантахурский район, ул. Шерози, 4',
      'Shaykhantakhur district, Sherozi st., 4',
      'Shayxontohur tumani, Sheroziy ko‘chasi, 4',
    ),
    lat: 41.321684,
    lng: 69.210333,
    phone: '+998783337272',
    open: '00:00',
    close: '00:00',
  ),
  Store(
    id: 'allon',
    name: L('Zikrilla Аллон', 'Zikrilla Allon', 'Zikrilla Allon'),
    address: L(
      'Алмазарский район, ул. Фараби, 291Б',
      'Almazar district, Farobiy st., 291B',
      'Olmazor tumani, Farobiy ko‘chasi, 291B',
    ),
    lat: 41.340704,
    lng: 69.215234,
    phone: '+998783337272',
    open: '08:00',
    close: '23:00',
  ),
  Store(
    id: 'sulola',
    name: L('Zikrilla Сулола', 'Zikrilla Sulola', 'Zikrilla Sulola'),
    address: L(
      'Алмазарский район, Келесское шоссе, 46Б',
      'Almazar district, Keles road, 46B',
      'Olmazor tumani, Keles yo‘li ko‘chasi, 46B',
    ),
    lat: 41.369175,
    lng: 69.225361,
    phone: '+998783337272',
    open: '08:00',
    close: '23:00',
  ),
  Store(
    id: 'yunusobod',
    name: L('Zikrilla Юнусабад', 'Zikrilla Yunusabad', 'Zikrilla Yunusobod'),
    address: L(
      'Юнусабадский район, ул. Богишамол, 215',
      'Yunusabad district, Bogishamol st., 215',
      'Yunusobod tumani, Bog‘ishamol ko‘chasi, 215',
    ),
    lat: 41.350853,
    lng: 69.323591,
    phone: '+998783337272',
    open: '08:00',
    close: '23:00',
  ),
  Store(
    id: 'humson',
    name: L('Zikrilla Хумсан', 'Zikrilla Khumsan', 'Zikrilla Humson'),
    address: L(
      'Бостанлыкский р-н, пос. Чарвак, массив Фазогир, 2',
      'Bostanlyk district, Charvak, Fazogir area, 2',
      'Bo‘stonliq tumani, Chorvoq shaharchasi, Fazogir massivi, 2',
    ),
    lat: 41.629762,
    lng: 69.939205,
    phone: '+998783337272',
    open: '10:00',
    close: '23:00',
  ),
];
