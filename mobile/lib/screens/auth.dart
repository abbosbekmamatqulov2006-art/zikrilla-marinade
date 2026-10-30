import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/backend.dart';
import '../api/models.dart';
import '../l10n.dart';
import '../location.dart';
import '../state.dart';
import '../ui.dart';
import 'language.dart';

/// Localized message for a backend error.
String apiErrorText(BuildContext context, Object e) {
  if (e is! ApiException) return context.tr('unknown_error');
  return switch (e.code) {
    'network' => context.tr('network_error'),
    'invalid_phone' => context.tr('invalid_phone'),
    'invalid_code' => context.tr('wrong_code'),
    'code_expired' => context.tr('code_expired'),
    'too_many_requests' || 'too_many_attempts' => context.tr('too_many', {'s': e.retryIn ?? 60}),
    _ => e.message ?? context.tr('unknown_error'),
  };
}

// ============================================================
// Phone
// ============================================================

/// Formats the 9 local digits as "90 123 45 67".
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('998') && d.length > 9) d = d.substring(3);
    if (d.length > 9) d = d.substring(0, 9);
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 5 || i == 7) b.write(' ');
      b.write(d[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});
  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final controller = TextEditingController();
  bool loading = false;
  String? error;

  String get digits => controller.text.replaceAll(' ', '');
  bool get valid => digits.length == 9;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!valid) {
      setState(() => error = context.tr('invalid_phone'));
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    final phone = '998$digits';
    try {
      final r = await context.read<AppState>().sendCode(phone);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone, first: r),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => error = apiErrorText(context, e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 12, kSide, 24),
          children: [
            Row(
              children: [
                const Logo(height: 34),
                const Spacer(),
                AppChip('🌐 ${context.t('lang_name')}', dense: true, onTap: () => showLanguageSheet(context)),
              ],
            ),
            const SizedBox(height: 48),
            Text(context.t('login_title'), style: tsx(34, w: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              context.t('login_sub'),
              style: tsx(15.5, w: FontWeight.w500, c: C.text2, h: 1.4),
            ),
            const SizedBox(height: 28),
            SectionLabel(context.t('phone_label')),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [_PhoneFormatter()],
              onChanged: (_) => setState(() => error = null),
              onSubmitted: (_) => _submit(),
              style: tsx(22, w: FontWeight.w800, ls: 0.5),
              decoration: fieldDecoration('90 123 45 67', error: error).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text('+998', style: tsx(22, w: FontWeight.w800)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(context.t('get_code'), loading: loading, onTap: valid ? _submit : null),
            const SizedBox(height: 16),
            Text(
              context.t('terms_note'),
              textAlign: TextAlign.center,
              style: tsx(12.5, w: FontWeight.w500, c: C.text3),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OTP
// ============================================================
class OtpScreen extends StatefulWidget {
  final String phone;
  final SendCodeResult first;
  const OtpScreen({super.key, required this.phone, required this.first});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const length = 4;
  final controller = TextEditingController();
  final focus = FocusNode();
  bool loading = false;
  String? error;
  late int resendIn = widget.first.resendIn;
  late String? devCode = widget.first.devCode;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendIn <= 0) return t.cancel();
      setState(() => resendIn--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (controller.text.length != length || loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    final nav = Navigator.of(context);
    try {
      await context.read<AppState>().verifyCode(widget.phone, controller.text);
      nav.popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        error = apiErrorText(context, e);
        controller.clear();
      });
      focus.requestFocus();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      final r = await context.read<AppState>().sendCode(widget.phone);
      if (!mounted) return;
      setState(() {
        resendIn = r.resendIn;
        devCode = r.devCode;
        error = null;
      });
      _startTimer();
      toast(context, context.tr('code_sent'));
    } catch (e) {
      if (mounted) setState(() => error = apiErrorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 12, kSide, 24),
          children: [
            const Align(alignment: Alignment.centerLeft, child: CircleBackButton()),
            const SizedBox(height: 28),
            Text(context.t('otp_title'), style: tsx(34, w: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              context.t('otp_sub', {'phone': formatPhone(widget.phone)}),
              style: tsx(15.5, w: FontWeight.w500, c: C.text2, h: 1.4),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.t('change_number'),
                  style: tsx(15, w: FontWeight.w800, c: C.red),
                ),
              ),
            ),
            if (devCode != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: C.amberSoft, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: C.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.t('test_mode_code', {'code': devCode!}),
                      style: tsx(14, w: FontWeight.w800, c: C.amber),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            // Invisible field drives the 4 boxes (supports SMS autofill).
            Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: length,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      setState(() => error = null);
                      if (v.length == length) _verify();
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () => focus.requestFocus(),
                  child: Row(
                    children: [
                      for (var i = 0; i < length; i++) ...[
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 68,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: C.soft,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: error != null
                                    ? C.red
                                    : (i == code.length && focus.hasFocus ? C.black : Colors.transparent),
                                width: 2,
                              ),
                            ),
                            child: Text(i < code.length ? code[i] : '', style: tsx(30, w: FontWeight.w900)),
                          ),
                        ),
                        if (i < length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: tsx(14, w: FontWeight.w700, c: C.red),
              ),
            ],
            const SizedBox(height: 24),
            if (loading)
              const Center(child: CircularProgressIndicator(color: C.red))
            else
              Center(
                child: resendIn > 0
                    ? Text(
                        context.t('resend_in', {'s': resendIn}),
                        style: tsx(15, w: FontWeight.w600, c: C.text3),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: Text(
                          context.t('resend'),
                          style: tsx(15, w: FontWeight.w900, c: C.red),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Registration / profile edit
// ============================================================
class RegisterScreen extends StatefulWidget {
  /// Edit mode: prefilled from the current user, no consent, pops on save.
  final bool edit;
  const RegisterScreen({super.key, this.edit = false});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final address = TextEditingController();
  final email = TextEditingController();
  DateTime? birth;
  String? gender;
  GeoPoint? coords;
  bool consent = false;
  bool locating = false;
  bool saving = false;
  bool showErrors = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    if (u != null) {
      first.text = u.firstName;
      last.text = u.lastName;
      address.text = u.address?.text ?? '';
      email.text = u.email ?? '';
      birth = u.birthDate == null ? null : DateTime.tryParse(u.birthDate!);
      gender = u.gender;
      if (u.address?.hasCoords == true) coords = GeoPoint(u.address!.lat!, u.address!.lng!);
    }
  }

  @override
  void dispose() {
    for (final c in [first, last, address, email]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get age {
    if (birth == null) return null;
    final now = DateTime.now();
    var a = now.year - birth!.year;
    if (now.month < birth!.month || (now.month == birth!.month && now.day < birth!.day)) a--;
    return a;
  }

  String? _err(String key, bool bad) => showErrors && bad ? context.t(key) : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birth ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      locale: Locale(context.read<AppState>().lang),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: C.red)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => birth = picked);
  }

  Future<void> _locate() async {
    final s = context.read<AppState>();
    setState(() => locating = true);
    try {
      final p = await s.locate();
      final text = await LocationService.addressFor(p, s.lang);
      if (!mounted) return;
      setState(() {
        coords = p;
        if (text != null) address.text = text;
      });
      toast(context, context.tr('location_set'));
    } catch (e) {
      if (mounted) showLocationError(context, e);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _submit() async {
    setState(() => showErrors = true);
    final a = age;
    if (first.text.trim().isEmpty ||
        last.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        a == null ||
        a < 14 ||
        a > 100) {
      return;
    }
    if (!widget.edit && !consent) {
      toast(context, context.tr('need_consent'));
      return;
    }
    final s = context.read<AppState>();
    final data = RegisterData(
      firstName: first.text.trim(),
      lastName: last.text.trim(),
      birthDate:
          '${birth!.year.toString().padLeft(4, '0')}-${birth!.month.toString().padLeft(2, '0')}-${birth!.day.toString().padLeft(2, '0')}',
      gender: gender,
      address: Address(address.text.trim(), lat: coords?.lat, lng: coords?.lng),
      email: email.text.trim().isEmpty ? null : email.text.trim(),
      language: s.lang,
    );
    setState(() => saving = true);
    try {
      if (widget.edit) {
        await s.updateProfile(data);
        if (!mounted) return;
        toast(context, context.tr('profile_saved'));
        Navigator.of(context).pop();
      } else {
        await s.register(data);
      }
    } catch (e) {
      if (mounted) toast(context, apiErrorText(context, e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = age;
    final dateText = birth == null
        ? context.t('choose_date')
        : '${birth!.day.toString().padLeft(2, '0')}.${birth!.month.toString().padLeft(2, '0')}.${birth!.year}'
              ' · ${context.t('age_years', {'n': a!})}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(kSide, 12, kSide, 24),
          children: [
            Row(
              children: [
                if (widget.edit) const CircleBackButton() else const Logo(height: 30),
                const Spacer(),
                if (!widget.edit)
                  TextButton(
                    onPressed: s.logout,
                    child: Text(
                      context.t('change_number'),
                      style: tsx(14, w: FontWeight.w800, c: C.red),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(context.t(widget.edit ? 'personal_data' : 'reg_title'), style: tTitle),
            const SizedBox(height: 6),
            Text(
              context.t('reg_sub'),
              style: tsx(15, w: FontWeight.w500, c: C.text2),
            ),
            const SizedBox(height: 10),
            if (s.user != null)
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(s.user!.phonePretty, kind: BadgeKind.grey),
              ),
            const SizedBox(height: 20),
            SectionLabel(context.t('first_name')),
            const SizedBox(height: 8),
            TextField(
              controller: first,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              style: tsx(16, w: FontWeight.w700),
              onChanged: (_) => setState(() {}),
              decoration: fieldDecoration('Aziz', error: _err('required_field', first.text.trim().isEmpty)),
            ),
            const SizedBox(height: 16),
            SectionLabel(context.t('last_name')),
            const SizedBox(height: 8),
            TextField(
              controller: last,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              style: tsx(16, w: FontWeight.w700),
              onChanged: (_) => setState(() {}),
              decoration: fieldDecoration('Karimov', error: _err('required_field', last.text.trim().isEmpty)),
            ),
            const SizedBox(height: 16),
            SectionLabel(context.t('birth_date')),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: fieldDecoration(
                  '',
                  error: showErrors && a == null
                      ? context.t('required_field')
                      : (showErrors && a != null && a < 14 ? context.t('age_invalid') : null),
                  suffix: const Icon(Icons.calendar_month_rounded, color: C.text2),
                ),
                child: Text(
                  dateText,
                  style: tsx(16, w: FontWeight.w700, c: birth == null ? C.text3 : C.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionLabel(context.t('gender')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                AppChip(context.t('male'), selected: gender == 'male', onTap: () => setState(() => gender = 'male')),
                AppChip(
                  context.t('female'),
                  selected: gender == 'female',
                  onTap: () => setState(() => gender = 'female'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionLabel(context.t('address')),
            const SizedBox(height: 8),
            TextField(
              controller: address,
              minLines: 1,
              maxLines: 3,
              autofillHints: const [AutofillHints.fullStreetAddress],
              style: tsx(16, w: FontWeight.w700),
              onChanged: (_) => setState(() {}),
              decoration: fieldDecoration(
                context.t('address_hint'),
                error: _err('required_field', address.text.trim().isEmpty),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: locating ? null : _locate,
                  icon: locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: C.red),
                        )
                      : const Icon(Icons.my_location_rounded, color: C.red),
                  label: Text(
                    context.t(locating ? 'locating' : 'detect_location'),
                    style: tsx(14.5, w: FontWeight.w900, c: C.red),
                  ),
                ),
                const Spacer(),
                if (coords != null) const Icon(Icons.check_circle_rounded, color: C.green, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            SectionLabel(context.t('email_optional')),
            const SizedBox(height: 8),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: tsx(16, w: FontWeight.w700),
              decoration: fieldDecoration('name@mail.uz'),
            ),
            if (!widget.edit) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => consent = !consent),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: consent ? C.red : C.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: consent ? C.red : C.border, width: 2),
                        ),
                        child: consent ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(context.t('consent'), style: tsx(14, w: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: PrimaryButton(context.t(widget.edit ? 'save_changes' : 'finish_reg'), loading: saving, onTap: _submit),
      ),
    );
  }
}
