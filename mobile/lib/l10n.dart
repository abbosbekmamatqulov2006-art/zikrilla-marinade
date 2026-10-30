import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'l10n_uz.dart';
import 'state.dart';

/// Simple map-based localization: Uzbek (l10n_uz.dart), Russian and English.
const Map<String, Map<String, String>> _strings = {
  // ---------- common ----------
  'currency': {'ru': 'сум', 'en': 'UZS'},
  'points': {'ru': 'баллов', 'en': 'points'},
  'points_short': {'ru': 'баллов', 'en': 'pts'},
  'pcs': {'ru': 'шт', 'en': 'pcs'},
  'see_all': {'ru': 'Все', 'en': 'See all'},
  'back': {'ru': 'Назад', 'en': 'Back'},
  'demo_note': {'ru': 'Демо-режим: действие симулировано', 'en': 'Demo mode: action simulated'},
  'added_to_cart': {'ru': 'Добавлено в корзину', 'en': 'Added to cart'},
  'minutes_short': {'ru': 'мин', 'en': 'min'},
  'grams_piece': {'ru': 'шт · 80–85 г', 'en': 'pc · 80–85 g'},
  'one_piece_grams': {'ru': '1 шт · 80–85 г', 'en': '1 pc · 80–85 g'},

  // ---------- tabs ----------
  'tab_home': {'ru': 'Главная', 'en': 'Home'},
  'tab_catalog': {'ru': 'Каталог', 'en': 'Catalog'},
  'tab_cart': {'ru': 'Корзина', 'en': 'Cart'},
  'tab_cashback': {'ru': 'Кешбэк', 'en': 'Cashback'},
  'tab_profile': {'ru': 'Профиль', 'en': 'Profile'},

  // ---------- home ----------
  'hero_title': {'ru': 'Для семейного\nдастархана', 'en': 'For the family\nfeast'},
  'hero_sub': {'ru': 'Маринады на шампурах · штука 80–85 г', 'en': 'Skewered marinades · 80–85 g per piece'},
  'order_preparing': {'ru': 'Ваш заказ готовится', 'en': 'Your order is being prepared'},
  'order_ready_title': {'ru': 'Заказ готов — ждём вас', 'en': 'Order is ready — see you soon'},
  'st_accepted': {'ru': 'Принят', 'en': 'Accepted'},
  'st_preparing': {'ru': 'Готовится', 'en': 'Preparing'},
  'st_ready': {'ru': 'Готов', 'en': 'Ready'},
  'st_done': {'ru': 'Выдан', 'en': 'Picked up'},
  'repeat_last': {'ru': 'Повторить последний заказ', 'en': 'Repeat last order'},
  'calc_label': {'ru': 'Посчитаем за вас', 'en': 'We\'ll do the math'},
  'calc_q': {'ru': 'Едете на природу?', 'en': 'Heading out for a picnic?'},
  'people': {'ru': 'Человек', 'en': 'People'},
  'hours': {'ru': 'Часов', 'en': 'Hours'},
  'recommend': {'ru': 'Рекомендация', 'en': 'Recommended'},
  'kg_coal': {'ru': 'кг угля', 'en': 'kg coal'},
  'sauces': {'ru': 'соуса', 'en': 'sauces'},
  'skewers_word': {'ru': 'шампуров', 'en': 'skewers'},
  'week_deals': {'ru': 'Выгодно на этой неделе', 'en': 'Deals of the week'},
  'services': {'ru': 'Сервисы', 'en': 'Services'},
  'svc_calc': {'ru': 'Калькулятор', 'en': 'Calculator'},
  'svc_school': {'ru': 'Школа', 'en': 'School'},
  'svc_group': {'ru': 'Заказ с друзьями', 'en': 'Group order'},
  'svc_ideas': {'ru': 'Предложения', 'en': 'Ideas'},

  // ---------- catalog ----------
  'catalog': {'ru': 'Каталог', 'en': 'Catalog'},
  'search_hint': {'ru': 'Продукт или состав', 'en': 'Product or ingredient'},
  'cat_all': {'ru': 'Все', 'en': 'All'},
  'cat_skewers': {'ru': 'Шашлык', 'en': 'Skewers'},
  'cat_minced': {'ru': 'Фарш', 'en': 'Minced'},
  'cat_chicken': {'ru': 'Курица', 'en': 'Chicken'},
  'cat_fish': {'ru': 'Рыба', 'en': 'Fish'},
  'cat_sets': {'ru': 'Наборы', 'en': 'Sets'},
  'cat_extras': {'ru': 'Уголь и соусы', 'en': 'Coal & sauces'},
  'filter_meat': {'ru': 'Вид мяса', 'en': 'Meat type'},
  'filter_spicy': {'ru': 'Острое', 'en': 'Spicy'},
  'tag_in_stock': {'ru': 'Есть', 'en': 'In stock'},
  'tag_low': {'ru': 'Мало', 'en': 'Low stock'},
  'nothing_found': {'ru': 'Ничего не найдено', 'en': 'Nothing found'},
  'set_banner_title': {'ru': 'Дастархан на 4 персоны', 'en': 'Feast set for 4'},
  'set_banner_sub': {'ru': '24 шампура, соус, уголь', 'en': '24 skewers, sauce, coal'},

  // ---------- product ----------
  'reviews': {'ru': 'отзывов', 'en': 'reviews'},
  'per_piece': {'ru': '/ 1 шт', 'en': '/ 1 pc'},
  'points_back': {'ru': 'С каждой штуки вернётся {n} баллов', 'en': '{n} points back for every piece'},
  'pcs_per_person': {'ru': '4 шт ≈ 1 человек', 'en': '4 pcs ≈ 1 person'},
  'grill_min': {'ru': 'Мангал {n} мин', 'en': 'Grill {n} min'},
  'ingredients': {'ru': 'Состав', 'en': 'Ingredients'},
  'no_preservatives': {'ru': 'Без консервантов', 'en': 'No preservatives'},
  'marinated': {'ru': 'Замаринован', 'en': 'Marinated'},
  'today_at': {'ru': 'Сегодня {t}', 'en': 'Today {t}'},
  'batch': {'ru': 'Партия', 'en': 'Batch'},
  'to_cart': {'ru': 'В корзину', 'en': 'Add to cart'},

  // ---------- cart ----------
  'cart': {'ru': 'Корзина', 'en': 'Cart'},
  'cart_empty': {'ru': 'Корзина пуста', 'en': 'Your cart is empty'},
  'cart_empty_sub': {
    'ru': 'Добавьте шашлык из каталога или посчитайте количество в калькуляторе',
    'en': 'Add skewers from the catalog or let the calculator pick for you',
  },
  'go_catalog': {'ru': 'В каталог', 'en': 'Open catalog'},
  'add_coal_q': {'ru': 'Добавить уголь?', 'en': 'Add some coal?'},
  'pickup': {'ru': 'Самовывоз', 'en': 'Pickup'},
  'delivery': {'ru': 'Доставка', 'en': 'Delivery'},
  'use_points': {'ru': 'Оплатить баллами', 'en': 'Pay with points'},
  'points_limit': {'ru': 'До 30% чека · баланс {n}', 'en': 'Up to 30% of total · balance {n}'},
  'products': {'ru': 'Товары', 'en': 'Products'},
  'delivery_fee': {'ru': 'Доставка', 'en': 'Delivery'},
  'free': {'ru': 'Бесплатно', 'en': 'Free'},
  'points_line': {'ru': 'Баллы', 'en': 'Points'},
  'total': {'ru': 'Итого', 'en': 'Total'},
  'confirm_order': {'ru': 'Подтвердить заказ', 'en': 'Place order'},
  'order_placed': {'ru': 'Заказ принят!', 'en': 'Order placed!'},
  'order_placed_sub': {
    'ru': 'Мы начали готовить. Вы получите {n} баллов после выдачи.',
    'en': 'We\'ve started preparing it. You\'ll earn {n} points after pickup.',
  },
  'great': {'ru': 'Отлично', 'en': 'Great'},
  'slot_unavailable': {'ru': 'Этот слот уже занят', 'en': 'This slot is fully booked'},

  // ---------- cashback ----------
  'cashback': {'ru': 'Кешбэк', 'en': 'Cashback'},
  'balance': {'ru': 'Баланс', 'en': 'Balance'},
  'expire_note': {'ru': '12 000 баллов сгорят 5 октября', 'en': '12,000 points expire on October 5'},
  'tier_bronze': {'ru': 'Бронза', 'en': 'Bronze'},
  'tier_silver': {'ru': 'Серебро', 'en': 'Silver'},
  'tier_gold': {'ru': 'Золото', 'en': 'Gold'},
  'tier_note': {
    'ru': 'До Золота осталось 180 000 сум · затем 7% кешбэк',
    'en': '180,000 UZS to Gold · then 7% cashback',
  },
  'qr_title': {'ru': 'Покажите код на кассе', 'en': 'Show this code at checkout'},
  'qr_sub': {'ru': 'Баллы начислятся даже при оплате наличными', 'en': 'Earn points even when paying cash'},
  'tasks': {'ru': 'Задания', 'en': 'Challenges'},
  'task_weeks': {'ru': '3 недели заказов подряд', 'en': 'Order 3 weeks in a row'},
  'task_weeks_bonus': {'ru': '2x баллы', 'en': '2x points'},
  'done_of': {'ru': '{a} / {b} выполнено', 'en': '{a} / {b} done'},
  'task_review': {'ru': 'Оставьте 3 отзыва', 'en': 'Leave 3 reviews'},
  'plus_sub': {'ru': 'Постоянный 7% кешбэк · бесплатная доставка', 'en': 'Permanent 7% cashback · free delivery'},
  'per_month': {'ru': 'сум/мес', 'en': 'UZS/mo'},
  'subscribe': {'ru': 'Подписка', 'en': 'Subscribe'},
  'subscribed': {'ru': 'Активна', 'en': 'Active'},
  'plus_activated': {'ru': 'Zikrilla Plus подключён', 'en': 'Zikrilla Plus activated'},
  'history': {'ru': 'История баллов', 'en': 'Points history'},

  // ---------- profile ----------
  'profile': {'ru': 'Профиль', 'en': 'Profile'},
  'order_history': {'ru': 'История заказов', 'en': 'Order history'},
  'repeat': {'ru': 'Повторить', 'en': 'Repeat'},
  'status_done': {'ru': 'Выдан', 'en': 'Completed'},
  'addresses': {'ru': 'Мои адреса', 'en': 'My addresses'},
  'manage_sub': {'ru': 'Управление подпиской', 'en': 'Manage subscription'},
  'active': {'ru': 'Активна', 'en': 'Active'},
  'inactive': {'ru': 'Не активна', 'en': 'Inactive'},
  'notifications': {'ru': 'Уведомления', 'en': 'Notifications'},
  'language': {'ru': 'Язык', 'en': 'Language'},
  'support': {'ru': 'Чат поддержки', 'en': 'Support chat'},
  'lang_name': {'ru': 'Русский', 'en': 'English'},
  'choose_language': {'ru': 'Выберите язык', 'en': 'Choose language'},
  'more': {'ru': 'Ещё', 'en': 'More'},
  'repeat_added': {'ru': 'Заказ добавлен в корзину', 'en': 'Order added to cart'},

  // ---------- school ----------
  'school_title': {'ru': 'Школа Zikrilla', 'en': 'Zikrilla School'},
  'school_sub': {'ru': 'Нанизывание, жарка, рецепты и лайфхаки', 'en': 'Skewering, grilling, recipes and tips'},
  'badge_main_guide': {'ru': 'Главное руководство', 'en': 'Main guide'},
  'badge_video': {'ru': 'Видео', 'en': 'Video'},
  'badge_guide': {'ru': 'Руководство', 'en': 'Guide'},
  'badge_tip': {'ru': 'Лайфхак', 'en': 'Tip'},
  'guide_title': {'ru': 'Как правильно нанизывать шашлык', 'en': 'How to skewer meat properly'},
  'guide_meta': {'ru': '4 шага · 4 минуты чтения', 'en': '4 steps · 4 min read'},
  'guide_meta2': {'ru': '4 шага · легко · 4 минуты', 'en': '4 steps · easy · 4 minutes'},
  'card_coal': {'ru': 'Как разжечь уголь', 'en': 'Lighting the coal right'},
  'card_coal_meta': {'ru': '5 минут · видео', 'en': '5 minutes · video'},
  'card_meat': {'ru': 'Сколько нужно мяса?', 'en': 'How much meat do I need?'},
  'card_meat_meta': {'ru': 'С калькулятором', 'en': 'With calculator'},
  'card_store': {'ru': 'Сколько хранится маринад', 'en': 'How long marinade keeps'},
  'card_store_meta': {'ru': 'Правила хранения', 'en': 'Storage rules'},
  'card_chef': {'ru': '8 советов от шефа', 'en': '8 tips from the chef'},
  'card_chef_meta': {'ru': 'Видеосерия', 'en': 'Video series'},
  'f_all': {'ru': 'Все', 'en': 'All'},
  'f_videos': {'ru': 'Видео', 'en': 'Videos'},
  'f_tips': {'ru': 'Лайфхаки', 'en': 'Tips'},
  'f_recipes': {'ru': 'Рецепты', 'en': 'Recipes'},
  'tip_label': {'ru': 'Лайфхак · 30 секунд', 'en': 'Tip · 30 seconds'},
  'tip1': {'ru': 'Замочите шампуры — мясо не пригорит', 'en': 'Soak wooden skewers — the meat won\'t burn'},
  'tip2': {'ru': 'Солите в конце, чтобы мясо осталось сочным', 'en': 'Salt at the end to keep meat juicy'},
  'tip3': {'ru': 'Угли готовы, когда покрылись белым пеплом', 'en': 'Coals are ready once covered in white ash'},
  'community': {'ru': 'Рецепты сообщества', 'en': 'Community recipes'},
  'community_sub': {'ru': 'Рецепты, которыми поделились клиенты', 'en': 'Recipes shared by our customers'},
  'ideas': {'ru': 'Предложения', 'en': 'Ideas'},
  'ideas_sub': {'ru': 'Что нам выпустить? Решаете вы', 'en': 'What should we make next? You decide'},

  // ---------- guide ----------
  'important': {'ru': 'Важно', 'en': 'Important'},
  'guide_important': {
    'ru': 'Оставляйте 2–3 мм между кусочками — так мясо прожарится внутри.',
    'en': 'Leave 2–3 mm between pieces so the meat cooks through.',
  },
  'step1_t': {'ru': 'Замочите шампуры', 'en': 'Soak the skewers'},
  'step1_d': {
    'ru': 'Деревянные шампуры держите 20 минут в воде — на мангале не сгорят.',
    'en': 'Keep wooden skewers in water for 20 minutes so they don\'t burn on the grill.',
  },
  'step2_t': {'ru': 'Нанизывайте поперёк волокон', 'en': 'Skewer across the grain'},
  'step2_d': {
    'ru': 'Если шампур проходит поперёк волокон, мясо не развалится при жарке.',
    'en': 'Piercing across the grain keeps pieces from falling apart while cooking.',
  },
  'step3_t': {'ru': 'Чередуйте с курдюком', 'en': 'Alternate with fat'},
  'step3_d': {
    'ru': 'После каждых 2 кусочков мяса — 1 кусочек курдюка, сок останется внутри.',
    'en': 'After every 2 pieces of meat add 1 piece of fat to keep the juices in.',
  },
  'step4_t': {'ru': 'Не переворачивайте часто', 'en': 'Don\'t flip too often'},
  'step4_d': {
    'ru': 'Переворачивайте каждые 2–3 минуты, всего 12 минут на мангале.',
    'en': 'Turn every 2–3 minutes, 12 minutes total on the grill.',
  },
  'fits_guide': {'ru': 'Подходит к руководству', 'en': 'Goes with this guide'},
  'save': {'ru': 'Сохранить', 'en': 'Save'},
  'saved': {'ru': 'Сохранено', 'en': 'Saved'},
  'start_timer': {'ru': 'Запустить таймер', 'en': 'Start timer'},
  'timer_title': {'ru': 'Таймер мангала', 'en': 'Grill timer'},
  'timer_flip': {'ru': 'Переверните через', 'en': 'Flip in'},
  'stop': {'ru': 'Стоп', 'en': 'Stop'},
  'pause': {'ru': 'Пауза', 'en': 'Pause'},
  'resume': {'ru': 'Продолжить', 'en': 'Resume'},
  'timer_done': {'ru': 'Готово! Снимайте с огня', 'en': 'Done! Take it off the heat'},

  // ---------- community ----------
  'c_popular': {'ru': 'Популярные', 'en': 'Popular'},
  'c_new': {'ru': 'Новые', 'en': 'New'},
  'c_grill': {'ru': 'Мангал', 'en': 'Grill'},
  'c_kazan': {'ru': 'Казан', 'en': 'Kazan'},
  'r1_t': {'ru': 'Бараний шашлык — маринад с гранатом', 'en': 'Lamb skewers — pomegranate marinade'},
  'r2_t': {'ru': 'Куриное бедро — чесночный соус', 'en': 'Chicken thigh — garlic sauce'},
  'r3_t': {'ru': 'Вырезка — с чёрным перцем', 'en': 'Tenderloin — black pepper cut'},
  'r4_t': {'ru': 'Плов в казане на углях', 'en': 'Kazan plov over coals'},
  'minutes': {'ru': '{n} минут', 'en': '{n} minutes'},
  'for_people': {'ru': 'на {n} человек', 'en': 'serves {n}'},
  'share_too': {'ru': 'Поделитесь и вы', 'en': 'Share yours too'},
  'share_reward': {'ru': 'Опубликуем рецепт — 20 000 баллов', 'en': 'Recipe published — 20,000 points'},
  'share_desc': {
    'ru': 'Фото, состав и шаги. После модерации рецепт увидит всё сообщество.',
    'en': 'Photo, ingredients and steps. After moderation the whole community will see it.',
  },
  'upload_recipe': {'ru': 'Загрузить рецепт', 'en': 'Upload recipe'},

  // ---------- upload ----------
  'add_media': {'ru': 'Добавьте фото или видео', 'en': 'Add a photo or video'},
  'add_media_sub': {'ru': 'Минимум 1 фото · видео до 60 секунд', 'en': 'At least 1 photo · video up to 60 seconds'},
  'media_added': {'ru': 'Фото добавлено', 'en': 'Photo added'},
  'recipe_name': {'ru': 'Название рецепта', 'en': 'Recipe name'},
  'recipe_name_hint': {'ru': 'Бараний шашлык — маринад с гранатом', 'en': 'Lamb skewers — pomegranate marinade'},
  'which_product': {'ru': 'Из какого продукта', 'en': 'Which product'},
  'cook_time': {'ru': 'Время приготовления', 'en': 'Cooking time'},
  'cook_time_hint': {'ru': 'Например: 40 минут', 'en': 'e.g. 40 minutes'},
  'composition': {'ru': 'Состав', 'en': 'Ingredients'},
  'composition_hint': {'ru': 'По одному ингредиенту в строке', 'en': 'One ingredient per line'},
  'steps': {'ru': 'Шаги', 'en': 'Steps'},
  'step_hint': {'ru': 'Что нужно сделать?', 'en': 'What should be done?'},
  'add_step': {'ru': 'Добавить шаг', 'en': 'Add step'},
  'moderation_note': {'ru': 'Модерация длится до 24 часов', 'en': 'Moderation takes up to 24 hours'},
  'send': {'ru': 'Отправить', 'en': 'Submit'},
  'fill_required': {'ru': 'Добавьте фото и название', 'en': 'Add a photo and a name'},
  'recipe_sent': {'ru': 'Рецепт отправлен', 'en': 'Recipe submitted'},
  'recipe_sent_sub': {
    'ru': 'Мы проверим его в течение 24 часов и начислим 20 000 баллов после публикации.',
    'en': 'We\'ll review it within 24 hours and credit 20,000 points once it\'s published.',
  },

  // ---------- ideas ----------
  'ideas_banner': {
    'ru': 'Если ваше предложение выпустят — 100 000 баллов',
    'en': 'If we make your idea — 100,000 points',
  },
  'ideas_banner_sub': {
    'ru': 'В этом году 3 продукта появились по идеям клиентов',
    'en': '3 products this year came from customer ideas',
  },
  'suggest': {'ru': 'Предложить', 'en': 'Suggest'},
  's_voting': {'ru': 'Голосование', 'en': 'Voting'},
  's_review': {'ru': 'На рассмотрении', 'en': 'Under review'},
  's_accepted': {'ru': 'Принято', 'en': 'Accepted'},
  's_done': {'ru': 'Выполнено', 'en': 'Done'},
  'i1_t': {'ru': 'Острый вариант маринада', 'en': 'Spicy marinade option'},
  'i1_d': {'ru': 'С аджикой, для любителей острого', 'en': 'With adjika, for spice lovers'},
  'i2_t': {'ru': 'Маленькая упаковка — 4 шт', 'en': 'Small pack — 4 pcs'},
  'i2_d': {'ru': 'Небольшой набор для тех, кто живёт один', 'en': 'A small set for people living alone'},
  'i3_t': {'ru': 'Ассортимент рыбного шашлыка', 'en': 'More fish skewers'},
  'i3_d': {'ru': 'Сейчас есть только один вид', 'en': 'Only one kind is available now'},
  'your_idea': {'ru': 'Ваше предложение', 'en': 'Your idea'},
  'idea_title_hint': {'ru': 'Коротко: что выпустить?', 'en': 'In short: what should we make?'},
  'idea_desc_hint': {'ru': 'Для кого и почему это нужно', 'en': 'Who is it for and why'},
  'idea_sent': {'ru': 'Спасибо! Предложение опубликовано', 'en': 'Thanks! Your idea is published'},
  'you': {'ru': 'Вы', 'en': 'You'},
  'today': {'ru': 'сегодня', 'en': 'today'},

  // ---------- calculator ----------
  'calculator': {'ru': 'Калькулятор', 'en': 'Calculator'},
  'calc_sub': {'ru': 'Подскажем, сколько взять', 'en': 'We\'ll tell you how much to get'},
  'by_amount': {'ru': 'Количество', 'en': 'Amount'},
  'by_budget': {'ru': 'Бюджет', 'en': 'Budget'},
  'event_type': {'ru': 'Тип мероприятия', 'en': 'Event type'},
  'ev_picnic': {'ru': 'Пикник', 'en': 'Picnic'},
  'ev_friends': {'ru': 'С друзьями', 'en': 'With friends'},
  'ev_rest': {'ru': 'Отдых', 'en': 'Getaway'},
  'ev_family': {'ru': 'Семейный', 'en': 'Family'},
  'ev_wedding': {'ru': 'Свадьба', 'en': 'Wedding'},
  'ev_office': {'ru': 'Офис', 'en': 'Office'},
  'ev_catering': {'ru': 'Кейтеринг', 'en': 'Catering'},
  'guests': {'ru': 'Гости', 'en': 'Guests'},
  'adults': {'ru': 'Взрослые', 'en': 'Adults'},
  'kids': {'ru': 'Дети', 'en': 'Kids'},
  'appetite': {'ru': 'Аппетит', 'en': 'Appetite'},
  'app_low': {'ru': 'Мало', 'en': 'Light'},
  'app_mid': {'ru': 'Средний', 'en': 'Normal'},
  'app_high': {'ru': 'Много', 'en': 'Hearty'},
  'what_to_have': {'ru': 'Что будет', 'en': 'What to have'},
  'budget_sum': {'ru': 'Бюджет, сум', 'en': 'Budget, UZS'},
  'calc_basis': {'ru': 'Основа расчёта', 'en': 'How we calculate'},
  'calc_basis_text': {
    'ru': 'Взрослому 4 шт (≈330 г), ребёнку 2 шт. Дольше 4 часов — +15%. Уголь: 1 кг на 12 шампуров.',
    'en': '4 pcs per adult (≈330 g), 2 per child. Over 4 hours — +15%. Coal: 1 kg per 12 skewers.',
  },
  'calc_basis_budget': {
    'ru': 'Делим бюджет на выбранные продукты поровну, оставляя 10% на уголь и соус.',
    'en': 'We split the budget evenly across chosen products, keeping 10% for coal and sauce.',
  },
  'total_recommend': {'ru': 'Итого рекомендуем', 'en': 'We recommend'},
  'pcs_skewers': {'ru': '{n} шт шашлыка', 'en': '{n} skewers'},
  'see_result': {'ru': 'Посмотреть результат', 'en': 'See result'},
  'choose_one': {'ru': 'Выберите хотя бы один продукт', 'en': 'Choose at least one product'},

  // ---------- calc result ----------
  'recommendation': {'ru': 'Рекомендация', 'en': 'Recommendation'},
  'res_head': {'ru': '{p} человек · {e} · {h} ч', 'en': '{p} people · {e} · {h} h'},
  'res_pcs': {'ru': '{n} шт', 'en': '{n} pcs'},
  'res_sub': {'ru': '≈ {kg} кг мяса · {pp} сум на человека', 'en': '≈ {kg} kg meat · {pp} UZS per person'},
  'sec_skewers': {'ru': 'Шашлык', 'en': 'Skewers'},
  'sec_extras': {'ru': 'Дополнительно', 'en': 'Extras'},
  'coal_line': {'ru': '{n} кг · 1 кг на 12 шампуров', 'en': '{n} kg · 1 kg per 12 skewers'},
  'sauce_line': {'ru': '{n} шт · 30 г на человека', 'en': '{n} pcs · 30 g per person'},
  'reminder': {'ru': 'Напоминание', 'en': 'Reminder'},
  'reminder_text': {
    'ru': 'Закажите до 20:00 — будет готово завтра с 10:00',
    'en': 'Order before 20:00 — ready tomorrow from 10:00',
  },
  'to_list': {'ru': 'В список', 'en': 'Save list'},
  'all_to_cart': {'ru': 'Всё в корзину', 'en': 'All to cart'},
  'list_saved': {'ru': 'Список сохранён', 'en': 'List saved'},

  // ---------- group order ----------
  'group_title': {'ru': 'Заказ с друзьями', 'en': 'Group order'},
  'group_when': {'ru': 'Суббота · 18:00 · Чиланзар', 'en': 'Saturday · 18:00 · Chilanzar'},
  'group_joined': {'ru': 'Присоединились {n} человек', 'en': '{n} friends joined'},
  'send_telegram': {'ru': 'Отправить ссылку в Telegram', 'en': 'Send link via Telegram'},
  'link_copied': {'ru': 'Ссылка скопирована', 'en': 'Link copied'},
  'deadline': {'ru': 'Срок', 'en': 'Deadline'},
  'deadline_text': {'ru': 'Присоединиться можно до 20:00 сегодня', 'en': 'Joining closes today at 20:00'},
  'who_added': {'ru': 'Кто что добавил', 'en': 'Who added what'},
  'organizer': {'ru': '(организатор)', 'en': '(organizer)'},
  'paid': {'ru': 'Оплатил', 'en': 'Paid'},
  'waiting': {'ru': 'Ожидается', 'en': 'Pending'},
  'payment_method': {'ru': 'Способ оплаты', 'en': 'Payment method'},
  'each_pays': {'ru': 'Каждый сам', 'en': 'Split'},
  'i_pay': {'ru': 'Плачу я', 'en': 'I\'ll pay'},
  'remind': {'ru': 'Напомнить', 'en': 'Remind'},
  'close_order': {'ru': 'Закрыть заказ', 'en': 'Close order'},
  'reminded': {'ru': 'Напоминание отправлено 2 участникам', 'en': 'Reminder sent to 2 participants'},
  'group_total': {'ru': 'Общая сумма', 'en': 'Group total'},
  'g1_items': {'ru': '8 шт баранины, уголь', 'en': '8 lamb skewers, coal'},
  'g2_items': {'ru': '6 шт куриного бедра', 'en': '6 chicken thighs'},
  'g3_items': {'ru': '4 шт люля, соус', 'en': '4 minced kebabs, sauce'},
  'g4_items': {'ru': '6 шт вырезки', 'en': '6 tenderloin skewers'},
  // ---------- auth ----------
  'continue': {'ru': 'Продолжить', 'en': 'Continue'},
  'welcome_title': {'ru': 'Добро пожаловать', 'en': 'Welcome'},
  'login_title': {'ru': 'Вход', 'en': 'Sign in'},
  'login_sub': {
    'ru': 'Введите номер телефона — мы отправим SMS с кодом',
    'en': 'Enter your phone number — we\'ll text you a code',
  },
  'phone_label': {'ru': 'Номер телефона', 'en': 'Phone number'},
  'get_code': {'ru': 'Получить код', 'en': 'Get code'},
  'terms_note': {
    'ru': 'Продолжая, вы соглашаетесь с условиями использования и политикой конфиденциальности',
    'en': 'By continuing you agree to the Terms of Use and Privacy Policy',
  },
  'invalid_phone': {'ru': 'Введите номер полностью', 'en': 'Enter the full phone number'},
  'otp_title': {'ru': 'Код из SMS', 'en': 'SMS code'},
  'otp_sub': {'ru': 'Отправили код на {phone}', 'en': 'We sent a code to {phone}'},
  'change_number': {'ru': 'Изменить номер', 'en': 'Change number'},
  'resend_in': {'ru': 'Отправить снова через {s} с', 'en': 'Resend in {s}s'},
  'resend': {'ru': 'Отправить код снова', 'en': 'Resend code'},
  'code_sent': {'ru': 'Код отправлен', 'en': 'Code sent'},
  'wrong_code': {'ru': 'Неверный код', 'en': 'Wrong code'},
  'code_expired': {'ru': 'Срок кода истёк, запросите новый', 'en': 'The code expired, request a new one'},
  'too_many': {'ru': 'Слишком много попыток. Попробуйте через {s} с', 'en': 'Too many attempts. Try again in {s}s'},
  'test_mode_code': {'ru': 'Тестовый режим: код {code}', 'en': 'Test mode: code {code}'},
  'network_error': {
    'ru': 'Нет связи с сервером. Проверьте интернет',
    'en': 'Can\'t reach the server. Check your connection',
  },
  'unknown_error': {'ru': 'Что-то пошло не так', 'en': 'Something went wrong'},

  // ---------- register ----------
  'reg_title': {'ru': 'Регистрация', 'en': 'Sign up'},
  'reg_sub': {'ru': 'Эти данные нужны для заказов и кешбэка', 'en': 'We need these details for orders and cashback'},
  'first_name': {'ru': 'Имя', 'en': 'First name'},
  'last_name': {'ru': 'Фамилия', 'en': 'Last name'},
  'birth_date': {'ru': 'Дата рождения', 'en': 'Date of birth'},
  'choose_date': {'ru': 'Выберите дату', 'en': 'Choose date'},
  'age_years': {'ru': '{n} лет', 'en': '{n} years old'},
  'gender': {'ru': 'Пол', 'en': 'Gender'},
  'male': {'ru': 'Мужской', 'en': 'Male'},
  'female': {'ru': 'Женский', 'en': 'Female'},
  'address': {'ru': 'Адрес проживания', 'en': 'Home address'},
  'address_hint': {'ru': 'Район, улица, дом', 'en': 'District, street, house'},
  'detect_location': {'ru': 'Определить по геолокации', 'en': 'Use my location'},
  'locating': {'ru': 'Определяем…', 'en': 'Locating…'},
  'location_set': {'ru': 'Геолокация сохранена', 'en': 'Location saved'},
  'email_optional': {'ru': 'Email (необязательно)', 'en': 'Email (optional)'},
  'consent': {'ru': 'Согласен на обработку персональных данных', 'en': 'I agree to the processing of my personal data'},
  'finish_reg': {'ru': 'Зарегистрироваться', 'en': 'Sign up'},
  'required_field': {'ru': 'Заполните поле', 'en': 'Required'},
  'age_invalid': {'ru': 'Возраст должен быть от 14 лет', 'en': 'You must be at least 14'},
  'need_consent': {'ru': 'Нужно согласие на обработку данных', 'en': 'Please accept the data processing consent'},
  'save_changes': {'ru': 'Сохранить', 'en': 'Save'},
  'personal_data': {'ru': 'Личные данные', 'en': 'Personal details'},
  'profile_saved': {'ru': 'Данные сохранены', 'en': 'Details saved'},
  'loc_denied': {
    'ru': 'Нет доступа к геолокации. Разрешите в настройках',
    'en': 'Location access denied. Allow it in Settings',
  },
  'loc_disabled': {'ru': 'Включите геолокацию (GPS) на телефоне', 'en': 'Turn on location services (GPS)'},
  'open_settings': {'ru': 'Настройки', 'en': 'Settings'},

  // ---------- stores ----------
  'stores': {'ru': 'Магазины', 'en': 'Stores'},
  'stores_sub': {'ru': 'Из какого магазина заберёте заказ?', 'en': 'Which store will you order from?'},
  'nearest': {'ru': 'Ближайший', 'en': 'Nearest'},
  'km_away': {'ru': '{d} км', 'en': '{d} km'},
  'm_away': {'ru': '{d} м', 'en': '{d} m'},
  'open_24h': {'ru': 'Круглосуточно', 'en': 'Open 24 hours'},
  'open_until': {'ru': 'Открыто до {t}', 'en': 'Open until {t}'},
  'closed_opens': {'ru': 'Закрыто · откроется в {t}', 'en': 'Closed · opens at {t}'},
  'order_here': {'ru': 'Заказать здесь', 'en': 'Order here'},
  'selected': {'ru': 'Выбран', 'en': 'Selected'},
  'route': {'ru': 'Маршрут', 'en': 'Directions'},
  'call': {'ru': 'Позвонить', 'en': 'Call'},
  'list_view': {'ru': 'Список', 'en': 'List'},
  'map_view': {'ru': 'Карта', 'en': 'Map'},
  'find_nearest': {'ru': 'Найти ближайший', 'en': 'Find nearest'},
  'store_selected': {'ru': 'Выбран магазин: {name}', 'en': 'Store selected: {name}'},
  'sample_stores_note': {'ru': 'Адреса магазинов пока примерные', 'en': 'Store addresses are sample data for now'},
  'choose_store': {'ru': 'Выберите магазин', 'en': 'Choose a store'},
  'store_label': {'ru': 'Магазин', 'en': 'Store'},
  'change': {'ru': 'Изменить', 'en': 'Change'},
  'delivery_address': {'ru': 'Адрес доставки', 'en': 'Delivery address'},
  'send_location': {'ru': 'Отправить геолокацию', 'en': 'Send my location'},
  'location_attached': {'ru': 'Геолокация прикреплена', 'en': 'Location attached'},
  'address_required': {'ru': 'Укажите адрес доставки', 'en': 'Enter a delivery address'},
  'order_number': {'ru': 'Заказ №{n}', 'en': 'Order #{n}'},
  'synced_iiko': {'ru': 'Баланс из iiko · обновлено в {t}', 'en': 'Balance from iiko · updated {t}'},
  'logout': {'ru': 'Выйти', 'en': 'Log out'},
  'logout_q': {'ru': 'Выйти из аккаунта?', 'en': 'Log out of your account?'},
  'cancel': {'ru': 'Отмена', 'en': 'Cancel'},
  'hello': {'ru': 'Привет, {name}!', 'en': 'Hi, {name}!'},
};

/// All keys defined for ru/en (used by tests to check Uzbek coverage).
Iterable<String> get allStringKeys => _strings.keys;

String _lookup(String key, String lang) =>
    (lang == 'uz' ? uzStrings[key] : _strings[key]?[lang]) ?? _strings[key]?['en'] ?? key;

String _lang(BuildContext context, {bool listen = true}) => Provider.of<AppState>(context, listen: listen).lang;

extension Tr on BuildContext {
  /// Translate a key, optionally substituting {placeholders}.
  String t(String key, [Map<String, Object>? args]) {
    final lang = _lang(this);
    var s = _lookup(key, lang);
    args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// Translate without subscribing to rebuilds (for callbacks).
  String tr(String key, [Map<String, Object>? args]) {
    final lang = _lang(this, listen: false);
    var s = _lookup(key, lang);
    args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// Current UI language. Reads the app Locale (safe in callbacks, unlike a listening Provider lookup).
  String get lang => Localizations.localeOf(this).languageCode;
}

/// Localized value picked from a {ru, en, uz} triple.
class L {
  final String ru;
  final String en;
  final String uz;
  const L(this.ru, this.en, this.uz);

  factory L.fromJson(Map<String, dynamic> j) =>
      L(j['ru'] as String? ?? '', j['en'] as String? ?? '', j['uz'] as String? ?? '');

  String of(BuildContext context) => byLang(context.lang);
  String byLang(String lang) => switch (lang) {
    'ru' => ru,
    'uz' => uz,
    _ => en,
  };
}
