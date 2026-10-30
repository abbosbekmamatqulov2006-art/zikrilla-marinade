import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/backend.dart';
import 'api/models.dart';
import 'data.dart';
import 'location.dart';
import 'site.dart';

enum AuthStatus { loading, chooseLanguage, loggedOut, needsProfile, ready }

class AppState extends ChangeNotifier {
  AppState({Backend? backend}) : backend = backend ?? Backend.create() {
    final device = ui.PlatformDispatcher.instance.locale.languageCode;
    lang = const ['uz', 'ru', 'en'].contains(device) ? device : 'uz';
    _init();
  }

  final Backend backend;
  static const _secure = FlutterSecureStorage();

  // ---------- auth ----------
  AuthStatus status = AuthStatus.loading;
  User? user;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('lang');
    if (savedLang != null) lang = savedLang;
    selectedStoreId = prefs.getString('store');

    String? token;
    if (kIsWeb) {
      token = prefs.getString('token');
    } else {
      try {
        token = await _secure.read(key: 'token');
      } catch (_) {}
    }
    final rawSite = prefs.getString('site');
    if (rawSite != null) {
      try {
        _applySite(jsonDecode(rawSite) as Map<String, dynamic>);
      } catch (_) {}
    }
    final rawUser = prefs.getString('user');
    if (rawUser != null) user = User.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);

    if (token == null) {
      status = savedLang == null ? AuthStatus.chooseLanguage : AuthStatus.loggedOut;
    } else {
      backend.token = token;
      status = user?.registered == true ? AuthStatus.ready : AuthStatus.needsProfile;
    }
    notifyListeners();
    unawaited(loadSite());
    unawaited(loadStores().then((_) => locateIfPermitted()));
    unawaited(loadProducts());
    if (status == AuthStatus.ready) {
      unawaited(refreshMe());
      unawaited(loadOrders());
    }
  }

  Future<void> chooseLanguage(String value) async {
    await setLang(value);
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<SendCodeResult> sendCode(String phone) => backend.sendCode(phone);

  Future<void> verifyCode(String phone, String code) async {
    final r = await backend.verify(phone, code);
    backend.token = r.token;
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).setString('token', r.token);
    } else {
      try {
        await _secure.write(key: 'token', value: r.token);
      } catch (_) {}
    }
    if (r.registered && r.user != null) {
      await _setUser(r.user!);
      status = AuthStatus.ready;
      unawaited(refreshMe());
      unawaited(loadOrders());
    } else {
      await _setUser(User(id: '', phone: phone));
      status = AuthStatus.needsProfile;
    }
    notifyListeners();
  }

  Future<void> register(RegisterData data) async {
    await _setUser(await backend.register(data));
    status = AuthStatus.ready;
    notifyListeners();
    unawaited(refreshMe());
    unawaited(locateIfPermitted());
  }

  Future<void> updateProfile(RegisterData data) async {
    await _setUser(await backend.updateMe(data));
    notifyListeners();
  }

  Future<void> _setUser(User u) async {
    user = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(u.toJson()));
  }

  Future<void> logout() async {
    backend.token = null;
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).remove('token');
    } else {
      try {
        await _secure.delete(key: 'token');
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    user = null;
    cart.clear();
    history = [];
    activeOrder = null;
    _orderPoll?.cancel();
    tab = 0;
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  /// Pulls profile + iiko loyalty balance.
  Future<void> refreshMe() async {
    try {
      final (u, loyalty) = await backend.me();
      await _setUser(u);
      points = loyalty.balance;
      tier = loyalty.tier;
      lifetime = loyalty.lifetime;
      loyaltyUpdatedAt = DateTime.now();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.code == 'unauthorized') await logout();
    }
  }

  // ---------- sozlamalar (admin panel) ----------
  SiteConfig site = SiteConfig.empty();

  void _applySite(Map<String, dynamic> raw) {
    site = SiteConfig(raw);
    cashbackPercent = site.cashbackPercent;
  }

  /// Panel → Sozlamalar / Ilova dagi hamma narsa. Oxirgi nusxa telefonda saqlanadi (internet bo'lmasa ham ishlaydi).
  Future<void> loadSite() async {
    if (backend.isMock) return;
    try {
      final raw = await backend.settings();
      if (raw.isEmpty) return;
      _applySite(raw);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('site', jsonEncode(raw));
    } catch (_) {}
  }

  /// Hammasini serverdan qayta yuklash (pastga tortib yangilash).
  Future<void> refreshAll() async {
    await Future.wait([
      loadSite(),
      loadProducts(),
      loadStores(),
      if (status == AuthStatus.ready) refreshMe(),
    ]);
  }

  // ---------- language ----------
  late String lang;

  Future<void> setLang(String value) async {
    lang = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', value);
  }

  // ---------- navigation ----------
  int tab = 0;
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  // ---------- stores & location ----------
  List<Store> stores = const [];
  String? selectedStoreId;
  GeoPoint? myLocation;

  /// Katalog va narxlarni serverdan oladi (admin paneldagi o'zgarishlar shu orqali keladi).
  Future<void> loadProducts() async {
    if (backend.isMock) return;
    try {
      final list = await backend.products();
      if (list.isNotEmpty) {
        products = list;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadStores() async {
    try {
      stores = await backend.stores();
      if (selectedStoreId != null && !stores.any((s) => s.id == selectedStoreId)) selectedStoreId = null;
      notifyListeners();
    } on ApiException catch (_) {}
  }

  /// Gets the phone's location; selects the nearest store if none chosen yet. Throws [LocationException].
  Future<GeoPoint> locate() async {
    final p = await LocationService.current();
    myLocation = p;
    if (selectedStoreId == null && stores.isNotEmpty) await selectStore(nearestStore!.id);
    notifyListeners();
    return p;
  }

  /// Silently refreshes location (and default store) when permission is already granted.
  Future<void> locateIfPermitted() async {
    try {
      if (await LocationService.hasPermission()) await locate();
    } catch (_) {}
  }

  Store? get selectedStore => stores.where((s) => s.id == selectedStoreId).firstOrNull;

  Store? get nearestStore {
    if (stores.isEmpty || myLocation == null) return null;
    return (List.of(stores)..sort((a, b) => distanceTo(a)!.compareTo(distanceTo(b)!))).first;
  }

  double? distanceTo(Store s) => myLocation == null ? null : LocationService.distance(myLocation!, s.lat, s.lng);

  Future<void> selectStore(String id) async {
    selectedStoreId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store', id);
  }

  // ---------- cart ----------
  final Map<String, int> cart = {};

  int qty(String id) => cart[id] ?? 0;
  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  int get cartSubtotal => cart.entries.fold(0, (s, e) => s + productById(e.key).price * e.value);

  void add(String id, [int n = 1]) {
    cart[id] = qty(id) + n;
    notifyListeners();
  }

  void setQty(String id, int n) {
    if (n <= 0) {
      cart.remove(id);
    } else {
      cart[id] = n;
    }
    notifyListeners();
  }

  void addAll(Map<String, int> items) {
    items.forEach((k, v) => cart[k] = qty(k) + v);
    notifyListeners();
  }

  bool delivery = false;
  int slot = 1;
  int pointsToUse = 0;
  static const slots = ['17:00-18:00', '18:00-19:00', '19:00-20:00'];

  /// Delivery address for the current cart; defaults to the profile address.
  Address? deliveryAddress;
  Address? get effectiveDeliveryAddress => deliveryAddress ?? user?.address;

  void setDeliveryAddress(Address a) {
    deliveryAddress = a;
    notifyListeners();
  }

  void setDelivery(bool v) {
    delivery = v;
    notifyListeners();
  }

  void setSlot(int v) {
    slot = v;
    notifyListeners();
  }

  int get deliveryFee => delivery && !plus ? 15000 : 0;
  int get maxPoints {
    final cap = (cartSubtotal * site.maxShare / 100).floor();
    return (cap < points ? cap : points) ~/ 1000 * 1000;
  }

  int get usedPoints => pointsToUse > maxPoints ? maxPoints : pointsToUse;
  int get cartTotal => cartSubtotal + deliveryFee - usedPoints;

  void setPointsToUse(int v) {
    pointsToUse = v;
    notifyListeners();
  }

  // ---------- loyalty ----------
  int points = 0;
  int lifetime = 0;
  String tier = 'bronze';
  DateTime? loyaltyUpdatedAt;
  bool plus = false;

  void togglePlus() {
    plus = !plus;
    notifyListeners();
  }

  // ---------- orders ----------
  OrderInfo? activeOrder;
  Timer? _orderPoll;

  int? get orderStage => activeOrder?.stage;

  List<PastOrder> history = [];

  Map<String, int>? get lastOrder => history.isEmpty ? null : history.first.items;

  bool get orderInProgress => activeOrder != null && activeOrder!.stage < 3;

  Future<void> loadOrders() async {
    try {
      final list = await backend.orders();
      history = [
        for (final o in list) PastOrder(_ddmm(o.createdAt), o.items, id: o.id, status: o.status, serverTotal: o.total),
      ];
      final inProgress = list.where((o) => o.stage < 3).firstOrNull;
      if (inProgress != null) _trackOrder(inProgress);
      notifyListeners();
    } on ApiException catch (_) {}
  }

  String _ddmm(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  /// Sends the cart to the server (→ iiko + amoCRM). Throws [ApiException].
  Future<OrderInfo> placeOrder() async {
    final req = OrderRequest(
      storeId: selectedStoreId!,
      delivery: delivery,
      items: [for (final e in cart.entries) OrderItem(e.key, e.value)],
      slot: slots[slot],
      pointsToUse: usedPoints,
      address: delivery ? effectiveDeliveryAddress : null,
    );
    final order = await backend.createOrder(req);
    history.insert(
      0,
      PastOrder(_ddmm(order.createdAt), Map.of(cart), id: order.id, status: order.status, serverTotal: order.total),
    );
    points -= usedPoints;
    cart.clear();
    pointsToUse = 0;
    _trackOrder(order);
    notifyListeners();
    return order;
  }

  int earnedPointsFor(Map<String, int> items) =>
      items.entries.fold<int>(0, (s, e) => s + productById(e.key).points * e.value);

  void _trackOrder(OrderInfo order) {
    activeOrder = order;
    _orderPoll?.cancel();
    _orderPoll = Timer.periodic(Duration(seconds: backend.isMock ? 5 : 20), (t) async {
      try {
        final fresh = await backend.order(order.id);
        activeOrder = fresh;
        final i = history.indexWhere((h) => h.id == fresh.id);
        if (i >= 0) {
          history[i] = PastOrder(
            history[i].date,
            history[i].items,
            id: fresh.id,
            status: fresh.status,
            serverTotal: fresh.total,
          );
        }
        if (fresh.stage >= 3) {
          t.cancel();
          unawaited(refreshMe()); // cashback is credited on the iiko side
        }
        notifyListeners();
      } on ApiException catch (_) {}
    });
  }

  // ---------- school ----------
  bool guideSaved = false;
  void toggleGuideSaved() {
    guideSaved = !guideSaved;
    notifyListeners();
  }

  final Set<int> likedRecipes = {};
  void toggleLike(int i) {
    likedRecipes.contains(i) ? likedRecipes.remove(i) : likedRecipes.add(i);
    notifyListeners();
  }

  // ---------- ideas ----------
  final List<Idea> ideas = [
    Idea(
      id: 'i1',
      title: 'i1_t',
      desc: 'i1_d',
      author: 'Kamola R.',
      date: '08.09',
      status: IdeaStatus.voting,
      votes: 342,
    ),
    Idea(
      id: 'i2',
      title: 'i2_t',
      desc: 'i2_d',
      author: 'Jasur N.',
      date: '02.09',
      status: IdeaStatus.review,
      votes: 187,
    ),
    Idea(id: 'i3', title: 'i3_t', desc: 'i3_d', author: 'Malika T.', date: '28.08', status: IdeaStatus.done, votes: 95),
  ];
  final Set<String> voted = {};

  void vote(Idea idea) {
    if (voted.contains(idea.id)) {
      voted.remove(idea.id);
      idea.votes--;
    } else {
      voted.add(idea.id);
      idea.votes++;
    }
    notifyListeners();
  }

  void addIdea(String title, String desc, String author, String date) {
    final id = 'u${ideas.length}';
    ideas.insert(
      0,
      Idea(
        id: id,
        title: title,
        desc: desc,
        author: author,
        date: date,
        status: IdeaStatus.voting,
        votes: 1,
        custom: true,
      ),
    );
    voted.add(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _orderPoll?.cancel();
    super.dispose();
  }
}
