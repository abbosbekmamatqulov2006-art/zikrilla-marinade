import 'l10n.dart';

/// Mahsulot rasmi yoki videosi (admin paneldan yuklangan).
class MediaItem {
  final String type; // image | video
  final String url;
  const MediaItem(this.type, this.url);
  bool get isVideo => type == 'video';
}

/// Keshbek foizi — serverdagi sozlamadan yangilanadi (panel → Sozlamalar → Keshbek).
double cashbackPercent = 5;

class Product {
  final String id;
  final L name;
  final L subtitle;
  final L ingredients;
  final int price;
  final String image;
  final String category; // kategoriya kodi (panel → Sozlamalar → Kategoriyalar)
  final bool lowStock;
  final bool isExtra;
  final double rating;
  final int reviews;
  final int grillMinutes;
  final int batch;
  final String marinatedAt;
  final bool spicy;
  final bool weeklyDeal;
  final L? unit;
  final L? description;
  final List<MediaItem> media;

  const Product({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.ingredients,
    required this.price,
    required this.image,
    required this.category,
    this.lowStock = false,
    this.isExtra = false,
    this.rating = 4.8,
    this.reviews = 0,
    this.grillMinutes = 12,
    this.batch = 218,
    this.marinatedAt = '07:40',
    this.spicy = false,
    this.weeklyDeal = false,
    this.unit,
    this.description,
    this.media = const [],
  });

  /// Bitta dona uchun keshbek balli (sozlamadagi foiz bo'yicha).
  int get points => (price * cashbackPercent / 100).round();

  /// Galereya: avval yuklangan rasm/videolar, bo'lmasa asosiy rasm.
  List<MediaItem> get gallery => media.isNotEmpty ? media : [MediaItem('image', image)];
}

/// Ilova ichidagi zaxira katalog; ishga tushganda serverdagisi bilan almashtiriladi.
List<Product> products = <Product>[
  Product(
    id: 'lamb',
    name: L('Бараний шашлык', 'Lamb skewer', 'Qo‘y six'),
    subtitle: L(
      'Классический маринад · штука 80–85 г',
      'Classic marinade · 80–85 g per piece',
      'Jaydari marinad · donasi 80–85 gr',
    ),
    ingredients: L(
      'Баранина, лук, зира, чёрный перец, соль',
      'Lamb, onion, cumin, black pepper, salt',
      'Qo‘y go‘shti, piyoz, zira, qora qalampir, tuz',
    ),
    price: 16000,
    image: 'assets/img/lamb.jpg',
    category: 'skewers',
    lowStock: true,
    rating: 4.8,
    reviews: 132,
    weeklyDeal: true,
  ),
  Product(
    id: 'chicken',
    name: L('Куриное бедро', 'Chicken thigh', 'Tovuq bedro'),
    subtitle: L(
      'Сливочно-чесночный маринад · штука 80–85 г',
      'Creamy garlic marinade · 80–85 g per piece',
      'Qaymoqli-sarimsoqli marinad · donasi 80–85 gr',
    ),
    ingredients: L(
      'Куриное бедро, чеснок, йогурт, паприка, соль',
      'Chicken thigh, garlic, yogurt, paprika, salt',
      'Tovuq bedro, sarimsoq, qatiq, paprika, tuz',
    ),
    price: 8000,
    image: 'assets/img/chicken.jpg',
    category: 'chicken',
    rating: 4.7,
    reviews: 98,
    grillMinutes: 15,
    batch: 219,
    marinatedAt: '08:10',
    weeklyDeal: true,
  ),
  Product(
    id: 'qiyma',
    name: L('Люля гиждуван', 'Gijduvon kebab', 'Qiyma g‘ijduvon'),
    subtitle: L(
      'Рубленое мясо по-гиждувански · штука 80–85 г',
      'Gijduvon-style minced meat · 80–85 g per piece',
      'G‘ijduvoncha qiyma · donasi 80–85 gr',
    ),
    ingredients: L(
      'Говядина, курдюк, лук, зира, кориандр, соль',
      'Beef, lamb fat, onion, cumin, coriander, salt',
      'Mol go‘shti, dumba, piyoz, zira, kashnich, tuz',
    ),
    price: 10000,
    image: 'assets/img/qiyma.jpg',
    category: 'minced',
    rating: 4.9,
    reviews: 210,
    grillMinutes: 10,
    batch: 216,
    marinatedAt: '06:55',
    weeklyDeal: true,
  ),
  Product(
    id: 'virezka',
    name: L('Вырезка', 'Tenderloin', 'Virezka'),
    subtitle: L(
      'Говяжья вырезка с перцем · штука 80–85 г',
      'Peppered beef tenderloin · 80–85 g per piece',
      'Qalampirli mol virezkasi · donasi 80–85 gr',
    ),
    ingredients: L(
      'Говяжья вырезка, чёрный перец, лук, соль',
      'Beef tenderloin, black pepper, onion, salt',
      'Mol virezkasi, qora qalampir, piyoz, tuz',
    ),
    price: 17000,
    image: 'assets/img/chef.jpg',
    category: 'skewers',
    rating: 4.9,
    reviews: 76,
    grillMinutes: 9,
    batch: 220,
    spicy: true,
  ),
  Product(
    id: 'kofta',
    name: L('Люля острое', 'Spicy kofta', 'Achchiq qiyma'),
    subtitle: L(
      'С аджикой и перцем · штука 80–85 г',
      'With adjika and chili · 80–85 g per piece',
      'Adjika va qalampir bilan · donasi 80–85 gr',
    ),
    ingredients: L(
      'Говядина, аджика, красный перец, лук, соль',
      'Beef, adjika, red pepper, onion, salt',
      'Mol go‘shti, adjika, qizil qalampir, piyoz, tuz',
    ),
    price: 11000,
    image: 'assets/img/qiyma_tray.jpg',
    category: 'minced',
    rating: 4.6,
    reviews: 54,
    grillMinutes: 10,
    batch: 217,
    spicy: true,
  ),
  Product(
    id: 'fish',
    name: L('Шашлык из сёмги', 'Salmon skewer', 'Losos six'),
    subtitle: L(
      'Лимон и укроп · штука 80–85 г',
      'Lemon and dill · 80–85 g per piece',
      'Limon va ukrop bilan · donasi 80–85 gr',
    ),
    ingredients: L(
      'Сёмга, лимон, укроп, оливковое масло, соль',
      'Salmon, lemon, dill, olive oil, salt',
      'Losos, limon, ukrop, zaytun moyi, tuz',
    ),
    price: 19000,
    image: 'assets/img/grill_man.jpg',
    category: 'fish',
    lowStock: true,
    rating: 4.5,
    reviews: 31,
    grillMinutes: 7,
    batch: 214,
  ),
  Product(
    id: 'coal',
    name: L('Уголь 3 кг', 'Coal 3 kg', 'Ko‘mir 3 kg'),
    subtitle: L('Берёзовый уголь для мангала', 'Birch charcoal for the grill', 'Mangal uchun qayin ko‘miri'),
    ingredients: L('Берёзовый древесный уголь', 'Birch wood charcoal', 'Qayin daraxti ko‘miri'),
    price: 32000,
    image: 'assets/img/coal.jpg',
    category: 'extras',
    isExtra: true,
    reviews: 40,
    unit: L('упаковка', 'pack', 'qadoq'),
  ),
  Product(
    id: 'sauce',
    name: L('Соус', 'Sauce', 'Sous'),
    subtitle: L('Томатный соус с зеленью · 250 г', 'Tomato herb sauce · 250 g', 'Ko‘katli pomidor sousi · 250 gr'),
    ingredients: L(
      'Томаты, чеснок, кинза, перец, соль',
      'Tomatoes, garlic, cilantro, pepper, salt',
      'Pomidor, sarimsoq, kashnich, qalampir, tuz',
    ),
    price: 12000,
    image: 'assets/img/sauce.jpg',
    category: 'extras',
    isExtra: true,
    reviews: 62,
    unit: L('шт', 'pc', 'dona'),
  ),
  Product(
    id: 'skewer',
    name: L('Шампуры', 'Skewers', 'Shampur'),
    subtitle: L('Набор из 10 стальных шампуров', 'Set of 10 steel skewers', '10 ta po‘lat shampur to‘plami'),
    ingredients: L('Нержавеющая сталь', 'Stainless steel', 'Zanglamas po‘lat'),
    price: 18000,
    image: 'assets/img/skewer.jpg',
    category: 'extras',
    isExtra: true,
    reviews: 22,
    unit: L('набор', 'set', 'to‘plam'),
  ),
];

Product productById(String id) =>
    products.firstWhere((p) => p.id == id, orElse: () => _missingProduct(id));

Product _missingProduct(String id) => Product(
  id: id,
  name: L(id, id, id),
  subtitle: const L('', '', ''),
  ingredients: const L('', '', ''),
  price: 0,
  image: 'assets/img/logo.png',
  category: 'extras',
  isExtra: true,
);

L _l(dynamic j) {
  final m = (j is Map) ? j : const {};
  return L(m['ru'] as String? ?? '', m['en'] as String? ?? '', m['uz'] as String? ?? '');
}

/// Server /products javobidan mahsulot.
Product productFromJson(Map<String, dynamic> j) => Product(
  id: j['id'] as String,
  name: _l(j['name']),
  subtitle: _l(j['subtitle']),
  ingredients: _l(j['ingredients']),
  price: (j['price'] as num? ?? 0).round(),
  image: (j['image'] as String?)?.isNotEmpty == true ? j['image'] as String : 'assets/img/logo.png',
  category: (j['category'] as String?) ?? 'extras',
  lowStock: j['lowStock'] as bool? ?? false,
  isExtra: j['isExtra'] as bool? ?? (j['category'] == 'extras'),
  rating: (j['rating'] as num? ?? 4.8).toDouble(),
  reviews: (j['reviews'] as num? ?? 0).toInt(),
  grillMinutes: (j['grillMinutes'] as num? ?? 12).toInt(),
  spicy: j['spicy'] as bool? ?? false,
  weeklyDeal: j['weeklyDeal'] as bool? ?? false,
  unit: j['unit'] == null ? null : _l(j['unit']),
  description: j['description'] == null ? null : _l(j['description']),
  media: [
    if (j['media'] is List)
      for (final m in j['media'] as List)
        if (m is Map && (m['url'] as String?)?.isNotEmpty == true)
          MediaItem(m['type'] == 'video' ? 'video' : 'image', m['url'] as String),
  ],
);

class PastOrder {
  final String date;
  final Map<String, int> items;
  final String? id;
  final String status; // accepted | preparing | ready | done | cancelled
  final int? serverTotal;
  const PastOrder(this.date, this.items, {this.id, this.status = 'done', this.serverTotal});

  int get total => serverTotal ?? items.entries.fold(0, (s, e) => s + productById(e.key).price * e.value);
}

enum IdeaStatus { voting, review, done }

class Idea {
  final String id;
  final String title; // l10n key or raw text
  final String desc;
  final String author;
  final String date;
  final IdeaStatus status;
  final bool custom;
  int votes;
  Idea({
    required this.id,
    required this.title,
    required this.desc,
    required this.author,
    required this.date,
    required this.status,
    required this.votes,
    this.custom = false,
  });
}

class Recipe {
  final String titleKey;
  final String image;
  final String author;
  final String initials;
  final int minutes;
  final int people;
  final int likes;
  final double rating;
  final String type; // grill | kazan
  final bool isNew;
  const Recipe(
    this.titleKey,
    this.image,
    this.author,
    this.initials,
    this.minutes,
    this.people,
    this.likes,
    this.rating,
    this.type,
    this.isNew,
  );
}

const recipes = <Recipe>[
  Recipe('r1_t', 'assets/img/plov_big.jpg', 'Dilshod S. · Chilanzar', 'DS', 40, 6, 214, 4.9, 'grill', false),
  Recipe('r2_t', 'assets/img/grill_man.jpg', 'Nigora A.', 'NA', 25, 4, 138, 4.7, 'grill', true),
  Recipe('r3_t', 'assets/img/chef_sq.jpg', 'Sardor T.', 'ST', 30, 4, 96, 4.6, 'grill', false),
  Recipe('r4_t', 'assets/img/plov.jpg', 'Kamola R.', 'KR', 90, 8, 71, 4.8, 'kazan', true),
];
