import 'package:flutter/material.dart';

/// Animated backgrounds used by the "live" themes.
enum LiveBg { aurora, waves, butterfly, goldfish }

enum AppThemePreset {
  pastelMint(
    id: 'pastelMint',
    displayName: 'Mint & Sage',
    bg: Color(0xFFEAF5ED),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFA5D6A7),
    headingDark: Color(0xFF1B4D3E),
    headingWhite: Color(0xFF0F382C),
    subtext: Color(0xFF4A7C59),
    gridLines: Color(0xFFC8E6C9),
    accent: Color(0xFF388E3C),
    border: Color(0xFFA5D6A7),
  ),
  pastelPeach(
    id: 'pastelPeach',
    displayName: 'Warm Peach',
    bg: Color(0xFFFFF3E0),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFCC80),
    headingDark: Color(0xFF4E2A00),
    headingWhite: Color(0xFF381D00),
    subtext: Color(0xFF8C5C26),
    gridLines: Color(0xFFFFE0B2),
    accent: Color(0xFFE65100),
    border: Color(0xFFFFB74D),
  ),
  pastelLavender(
    id: 'pastelLavender',
    displayName: 'Soft Lavender',
    bg: Color(0xFFF3E5F5),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFCE93D8),
    headingDark: Color(0xFF3A1C47),
    headingWhite: Color(0xFF281133),
    subtext: Color(0xFF6B437C),
    gridLines: Color(0xFFE1BEE7),
    accent: Color(0xFF7B1FA2),
    border: Color(0xFFBA68C8),
  ),
  pastelSky(
    id: 'pastelSky',
    displayName: 'Cloud Sky',
    bg: Color(0xFFE1F5FE),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF81D4FA),
    headingDark: Color(0xFF013A63),
    headingWhite: Color(0xFF012A4A),
    subtext: Color(0xFF2A6F97),
    gridLines: Color(0xFFB3E5FC),
    accent: Color(0xFF0288D1),
    border: Color(0xFF4FC3F7),
  ),
  pastelRose(
    id: 'pastelRose',
    displayName: 'Pastel Rose',
    bg: Color(0xFFFCE4EC),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFF48FB1),
    headingDark: Color(0xFF4A1525),
    headingWhite: Color(0xFF360C19),
    subtext: Color(0xFF883955),
    gridLines: Color(0xFFF8BBD0),
    accent: Color(0xFFC2185B),
    border: Color(0xFFF06292),
  ),
  pastelButter(
    id: 'pastelButter',
    displayName: 'Honey Butter',
    bg: Color(0xFFFFFDE7),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFE082),
    headingDark: Color(0xFF423800),
    headingWhite: Color(0xFF2D2600),
    subtext: Color(0xFF7A6A10),
    gridLines: Color(0xFFFFF59D),
    accent: Color(0xFFF57F17),
    border: Color(0xFFFFD54F),
  ),
  pastelCoral(
    id: 'pastelCoral',
    displayName: 'Sweet Coral',
    bg: Color(0xFFFFEBE6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFAB91),
    headingDark: Color(0xFF4D1C10),
    headingWhite: Color(0xFF38120A),
    subtext: Color(0xFF8D4434),
    gridLines: Color(0xFFFFCCBC),
    accent: Color(0xFFD84315),
    border: Color(0xFFFF8A65),
  ),
  pastelOcean(
    id: 'pastelOcean',
    displayName: 'Aqua Breeze',
    bg: Color(0xFFE0F2F1),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF80CBC4),
    headingDark: Color(0xFF00363A),
    headingWhite: Color(0xFF002528),
    subtext: Color(0xFF00695C),
    gridLines: Color(0xFFB2DFDB),
    accent: Color(0xFF00695C),
    border: Color(0xFF4DB6AC),
  ),
  obsidian(
    id: 'obsidian',
    displayName: 'Obsidian Dark',
    bg: Color(0xFF121212),
    surface: Color(0xFF1C1C1C),
    primary: Color(0xFF2D2D2D),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF121212),
    subtext: Color(0xFF888888),
    gridLines: Color(0xFF2D2D2D),
    accent: Color(0xFF81C784),
    border: Color(0x3DFFFFFF),
  ),
  lemonLime(
    id: 'lemonLime',
    displayName: 'Lemon Lime',
    bg: Color(0xFFF4FBE3),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFC5E1A5),
    headingDark: Color(0xFF2E4A0B),
    headingWhite: Color(0xFF1F3306),
    subtext: Color(0xFF5B7F2A),
    gridLines: Color(0xFFDCEDC8),
    accent: Color(0xFF689F38),
    border: Color(0xFFAED581),
  ),
  sandDune(
    id: 'sandDune',
    displayName: 'Sand Dune',
    bg: Color(0xFFF5EFE6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFD7C4A3),
    headingDark: Color(0xFF3E2F1C),
    headingWhite: Color(0xFF2A1F12),
    subtext: Color(0xFF7A6548),
    gridLines: Color(0xFFE6D9C3),
    accent: Color(0xFF8D6E3F),
    border: Color(0xFFC9B48F),
  ),
  midnight(
    id: 'midnight',
    displayName: 'Midnight Blue',
    bg: Color(0xFF0B1220),
    surface: Color(0xFF121B2E),
    primary: Color(0xFF1C2A44),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0B1220),
    subtext: Color(0xFF8FA3C4),
    gridLines: Color(0xFF1C2A44),
    accent: Color(0xFF4FC3F7),
    border: Color(0x3DFFFFFF),
  ),
  neonNight(
    id: 'neonNight',
    displayName: 'Neon Night',
    bg: Color(0xFF0D0221),
    surface: Color(0xFF1A0B38),
    primary: Color(0xFF2A1458),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0D0221),
    subtext: Color(0xFFA89BC9),
    gridLines: Color(0xFF2A1458),
    accent: Color(0xFFFF2E97),
    border: Color(0x3DFFFFFF),
  ),
  deepForest(
    id: 'deepForest',
    displayName: 'Deep Forest',
    bg: Color(0xFF0E1A14),
    surface: Color(0xFF16261D),
    primary: Color(0xFF1F3A2B),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0E1A14),
    subtext: Color(0xFF8DB09B),
    gridLines: Color(0xFF1F3A2B),
    accent: Color(0xFF66BB6A),
    border: Color(0x3DFFFFFF),
  ),
  crimsonDark(
    id: 'crimsonDark',
    displayName: 'Crimson Dark',
    bg: Color(0xFF1A0A0D),
    surface: Color(0xFF261015),
    primary: Color(0xFF3A1720),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF1A0A0D),
    subtext: Color(0xFFC99AA3),
    gridLines: Color(0xFF3A1720),
    accent: Color(0xFFFF5252),
    border: Color(0x3DFFFFFF),
  ),
  amoledGold(
    id: 'amoledGold',
    displayName: 'AMOLED Gold',
    bg: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    primary: Color(0xFF1A1A1A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF000000),
    subtext: Color(0xFF8A8A8A),
    gridLines: Color(0xFF1A1A1A),
    accent: Color(0xFFFFD54F),
    border: Color(0x3DFFFFFF),
  ),
  cottonCandy(
    id: 'cottonCandy',
    displayName: 'Cotton Candy',
    bg: Color(0xFFFDEBF7),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFF8BBE6),
    headingDark: Color(0xFF4A1B3F),
    headingWhite: Color(0xFF361030),
    subtext: Color(0xFF8A4A7B),
    gridLines: Color(0xFFF6CDEB),
    accent: Color(0xFFD81B9A),
    border: Color(0xFFF29BD4),
  ),
  blueberryMilk(
    id: 'blueberryMilk',
    displayName: 'Blueberry Milk',
    bg: Color(0xFFEEF1FF),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFB7C2FF),
    headingDark: Color(0xFF1E2A6B),
    headingWhite: Color(0xFF141D52),
    subtext: Color(0xFF4D5AA6),
    gridLines: Color(0xFFD3DAFF),
    accent: Color(0xFF3F51B5),
    border: Color(0xFF9FACF5),
  ),
  matcha(
    id: 'matcha',
    displayName: 'Matcha Latte',
    bg: Color(0xFFEFF5E3),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFC3D9A0),
    headingDark: Color(0xFF2F3E15),
    headingWhite: Color(0xFF202B0D),
    subtext: Color(0xFF65793A),
    gridLines: Color(0xFFDCE8C4),
    accent: Color(0xFF558B2F),
    border: Color(0xFFAECB7D),
  ),
  apricot(
    id: 'apricot',
    displayName: 'Apricot Cream',
    bg: Color(0xFFFFF1E6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFC9A3),
    headingDark: Color(0xFF5A2A0A),
    headingWhite: Color(0xFF401C05),
    subtext: Color(0xFF9A5B2F),
    gridLines: Color(0xFFFFDDC2),
    accent: Color(0xFFEF6C00),
    border: Color(0xFFFFB07A),
  ),
  lilacHaze(
    id: 'lilacHaze',
    displayName: 'Lilac Haze',
    bg: Color(0xFFF1EDFB),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFC9BBF0),
    headingDark: Color(0xFF2E1F5E),
    headingWhite: Color(0xFF1F1445),
    subtext: Color(0xFF6C57A8),
    gridLines: Color(0xFFDDD3F5),
    accent: Color(0xFF5E35B1),
    border: Color(0xFFB3A1E8),
  ),
  seashell(
    id: 'seashell',
    displayName: 'Seashell',
    bg: Color(0xFFFFF5F2),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFF7CFC4),
    headingDark: Color(0xFF5C2B22),
    headingWhite: Color(0xFF431D17),
    subtext: Color(0xFF9A5E52),
    gridLines: Color(0xFFFBE0D8),
    accent: Color(0xFFE64A19),
    border: Color(0xFFF0AE9E),
  ),
  iceBlue(
    id: 'iceBlue',
    displayName: 'Ice Blue',
    bg: Color(0xFFEAF7FB),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFA8DDEB),
    headingDark: Color(0xFF0B3A4A),
    headingWhite: Color(0xFF062A36),
    subtext: Color(0xFF3E7C8F),
    gridLines: Color(0xFFCBEBF3),
    accent: Color(0xFF00838F),
    border: Color(0xFF7CC9DB),
  ),
  sunnyDay(
    id: 'sunnyDay',
    displayName: 'Sunny Day',
    bg: Color(0xFFFFFBE0),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFE766),
    headingDark: Color(0xFF4A3F00),
    headingWhite: Color(0xFF352D00),
    subtext: Color(0xFF857400),
    gridLines: Color(0xFFFFF3A8),
    accent: Color(0xFFF9A825),
    border: Color(0xFFFFD83D),
  ),
  dracula(
    id: 'dracula',
    displayName: 'Dracula',
    bg: Color(0xFF1E1F29),
    surface: Color(0xFF282A36),
    primary: Color(0xFF44475A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF1E1F29),
    subtext: Color(0xFFB3B7D1),
    gridLines: Color(0xFF44475A),
    accent: Color(0xFFBD93F9),
    border: Color(0x3DFFFFFF),
  ),
  nordNight(
    id: 'nordNight',
    displayName: 'Nord Night',
    bg: Color(0xFF242933),
    surface: Color(0xFF2E3440),
    primary: Color(0xFF3B4252),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF242933),
    subtext: Color(0xFF9AA7BD),
    gridLines: Color(0xFF3B4252),
    accent: Color(0xFF88C0D0),
    border: Color(0x3DFFFFFF),
  ),
  cyberpunk(
    id: 'cyberpunk',
    displayName: 'Cyberpunk',
    bg: Color(0xFF0A0A12),
    surface: Color(0xFF14141F),
    primary: Color(0xFF22223A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0A0A12),
    subtext: Color(0xFF9A9AC0),
    gridLines: Color(0xFF22223A),
    accent: Color(0xFFFCEE0A),
    border: Color(0x3DFFFFFF),
  ),
  oceanAbyss(
    id: 'oceanAbyss',
    displayName: 'Ocean Abyss',
    bg: Color(0xFF04141F),
    surface: Color(0xFF0A2233),
    primary: Color(0xFF12364D),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF04141F),
    subtext: Color(0xFF7FA8C0),
    gridLines: Color(0xFF12364D),
    accent: Color(0xFF26C6DA),
    border: Color(0x3DFFFFFF),
  ),
  royalPurple(
    id: 'royalPurple',
    displayName: 'Royal Purple',
    bg: Color(0xFF160B26),
    surface: Color(0xFF21113A),
    primary: Color(0xFF33195A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF160B26),
    subtext: Color(0xFFB49CD6),
    gridLines: Color(0xFF33195A),
    accent: Color(0xFFB388FF),
    border: Color(0x3DFFFFFF),
  ),
  espresso(
    id: 'espresso',
    displayName: 'Espresso',
    bg: Color(0xFF1C1411),
    surface: Color(0xFF271C17),
    primary: Color(0xFF3A2A22),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF1C1411),
    subtext: Color(0xFFBFA595),
    gridLines: Color(0xFF3A2A22),
    accent: Color(0xFFD7A06B),
    border: Color(0x3DFFFFFF),
  ),
  emeraldDark(
    id: 'emeraldDark',
    displayName: 'Emerald Night',
    bg: Color(0xFF06180F),
    surface: Color(0xFF0D2519),
    primary: Color(0xFF173A28),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF06180F),
    subtext: Color(0xFF7FB59A),
    gridLines: Color(0xFF173A28),
    accent: Color(0xFF00E676),
    border: Color(0x3DFFFFFF),
  ),
  sunsetDark(
    id: 'sunsetDark',
    displayName: 'Sunset Dusk',
    bg: Color(0xFF1F0F14),
    surface: Color(0xFF2B1520),
    primary: Color(0xFF431F30),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF1F0F14),
    subtext: Color(0xFFD2A0B0),
    gridLines: Color(0xFF431F30),
    accent: Color(0xFFFF7043),
    border: Color(0x3DFFFFFF),
  ),
  peachLavender(
    id: 'peachLavender',
    displayName: 'Peach Lavender Mix',
    bg: Color(0xFFFFE5D0),
    bg2: Color(0xFFE6D5FF),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFB38A),
    headingDark: Color(0xFF4A2340),
    headingWhite: Color(0xFF361830),
    subtext: Color(0xFF8A5A7A),
    gridLines: Color(0xFFF3CBB8),
    accent: Color(0xFFE0457B),
    border: Color(0xFFE8B7C8),
  ),
  mintLagoon(
    id: 'mintLagoon',
    displayName: 'Mint Lagoon Mix',
    bg: Color(0xFFD9F7EC),
    bg2: Color(0xFFCFE8FF),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF8FD9C0),
    headingDark: Color(0xFF0F3D3A),
    headingWhite: Color(0xFF0A2D2B),
    subtext: Color(0xFF3F7F7A),
    gridLines: Color(0xFFBFE9DD),
    accent: Color(0xFF00A896),
    border: Color(0xFF9FD5CB),
  ),
  berryCream(
    id: 'berryCream',
    displayName: 'Berry Cream Mix',
    bg: Color(0xFFFFE0EC),
    bg2: Color(0xFFFFF3D6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFF59BBB),
    headingDark: Color(0xFF5A1B38),
    headingWhite: Color(0xFF40122A),
    subtext: Color(0xFF9A5870),
    gridLines: Color(0xFFF9C9DA),
    accent: Color(0xFFD81B60),
    border: Color(0xFFEFAFC6),
  ),
  goldenHour(
    id: 'goldenHour',
    displayName: 'Golden Hour Mix',
    bg: Color(0xFFFFF0B8),
    bg2: Color(0xFFFFC9A0),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFC94D),
    headingDark: Color(0xFF4D3000),
    headingWhite: Color(0xFF382300),
    subtext: Color(0xFF8A6420),
    gridLines: Color(0xFFFFE08A),
    accent: Color(0xFFE65100),
    border: Color(0xFFF2C96D),
  ),
  springMeadow(
    id: 'springMeadow',
    displayName: 'Spring Meadow Mix',
    bg: Color(0xFFDDF5C8),
    bg2: Color(0xFFFFF6B8),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFA5D66B),
    headingDark: Color(0xFF28400F),
    headingWhite: Color(0xFF1B2D0A),
    subtext: Color(0xFF5E7F35),
    gridLines: Color(0xFFCDEBAA),
    accent: Color(0xFF43A047),
    border: Color(0xFFB5D98C),
  ),
  neonDusk(
    id: 'neonDusk',
    displayName: 'Neon Dusk Mix',
    bg: Color(0xFF1B1040),
    bg2: Color(0xFF5B1A6B),
    surface: Color(0xFF2A1858),
    primary: Color(0xFF4A2A8A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF1B1040),
    subtext: Color(0xFFD3B8F0),
    gridLines: Color(0xFF4A2A8A),
    accent: Color(0xFFFF4FD8),
    border: Color(0x3DFFFFFF),
  ),
  oceanFire(
    id: 'oceanFire',
    displayName: 'Ocean & Fire Mix',
    bg: Color(0xFF061A33),
    bg2: Color(0xFF4A1A12),
    surface: Color(0xFF0E2A4A),
    primary: Color(0xFF15416E),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF061A33),
    subtext: Color(0xFFA8C4DE),
    gridLines: Color(0xFF15416E),
    accent: Color(0xFFFF7A33),
    border: Color(0x3DFFFFFF),
  ),
  galaxyMix(
    id: 'galaxyMix',
    displayName: 'Galaxy Mix',
    bg: Color(0xFF0D0B2E),
    bg2: Color(0xFF0B3A5C),
    surface: Color(0xFF171446),
    primary: Color(0xFF2A2570),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0D0B2E),
    subtext: Color(0xFFB3B0E8),
    gridLines: Color(0xFF2A2570),
    accent: Color(0xFF7DF9FF),
    border: Color(0x3DFFFFFF),
  ),
  emberNight(
    id: 'emberNight',
    displayName: 'Ember Night Mix',
    bg: Color(0xFF140A0A),
    bg2: Color(0xFF5A0F1E),
    surface: Color(0xFF241212),
    primary: Color(0xFF3C1A1A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF140A0A),
    subtext: Color(0xFFD9A8A8),
    gridLines: Color(0xFF3C1A1A),
    accent: Color(0xFFFF5252),
    border: Color(0x3DFFFFFF),
  ),
  forestAurora(
    id: 'forestAurora',
    displayName: 'Forest Aurora Mix',
    bg: Color(0xFF062418),
    bg2: Color(0xFF0A4D4A),
    surface: Color(0xFF0E3526),
    primary: Color(0xFF14503A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF062418),
    subtext: Color(0xFF9CD0BC),
    gridLines: Color(0xFF14503A),
    accent: Color(0xFF69F0AE),
    border: Color(0x3DFFFFFF),
  ),
  liveAurora(
    id: 'liveAurora',
    displayName: 'Live Aurora',
    bg: Color(0xFF08122B),
    bg2: Color(0xFF0B3B3F),
    surface: Color(0xFF0F1E3D),
    primary: Color(0xFF1B3A66),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF08122B),
    subtext: Color(0xFFA5C3E8),
    gridLines: Color(0xFF1B3A66),
    accent: Color(0xFF5CFFC4),
    border: Color(0x3DFFFFFF),
    live: LiveBg.aurora,
  ),
  liveWaves(
    id: 'liveWaves',
    displayName: 'Live Ocean Waves',
    bg: Color(0xFFE6F6FF),
    bg2: Color(0xFFBFE6FA),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF7CC8EE),
    headingDark: Color(0xFF0B3550),
    headingWhite: Color(0xFF072640),
    subtext: Color(0xFF3D7191),
    gridLines: Color(0xFFCBE9F8),
    accent: Color(0xFF0288D1),
    border: Color(0xFF98D3EE),
    live: LiveBg.waves,
  ),
  liveButterfly(
    id: 'liveButterfly',
    displayName: 'Live Butterfly',
    bg: Color(0xFF0A0B2A),
    bg2: Color(0xFF1C0B3F),
    surface: Color(0xFF17163F),
    primary: Color(0xFF2B2A66),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0A0B2A),
    subtext: Color(0xFFB7B5F0),
    gridLines: Color(0xFF2B2A66),
    accent: Color(0xFF4FC3F7),
    border: Color(0x3DFFFFFF),
    live: LiveBg.butterfly,
  ),
  liveGoldfish(
    id: 'liveGoldfish',
    displayName: 'Live Goldfish',
    bg: Color(0xFF06394A),
    bg2: Color(0xFF0B6E73),
    surface: Color(0xFF0B4A5C),
    primary: Color(0xFF14697A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF06394A),
    subtext: Color(0xFFA9DDE0),
    gridLines: Color(0xFF14697A),
    accent: Color(0xFFFFB300),
    border: Color(0x3DFFFFFF),
    live: LiveBg.goldfish,
  );

  const AppThemePreset({
    required this.id,
    required this.displayName,
    required this.bg,
    required this.surface,
    required this.primary,
    required this.headingDark,
    required this.headingWhite,
    required this.subtext,
    required this.gridLines,
    required this.accent,
    required this.border,
    this.bg2,
    this.live,
  });

  final String id;
  final String displayName;
  final Color bg;
  final Color surface;
  final Color primary;
  final Color headingDark;
  final Color headingWhite;
  final Color subtext;
  final Color gridLines;
  final Color accent;
  final Color border;

  /// Second colour: when set, the background is a gradient bg -> bg2.
  final Color? bg2;

  /// Set for the animated "live" themes.
  final LiveBg? live;

  /// True when a backdrop (gradient / animation) is drawn behind the pages.
  bool get hasBackdrop => bg2 != null || live != null;

  static AppThemePreset fromId(String? id) {
    return AppThemePreset.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AppThemePreset.pastelSky,
    );
  }

  bool get isDark => bg.computeLuminance() < 0.5;
}

enum AppLanguage {
  en('English', 'English'),
  si('සිංහල', 'සිංහල'),
  both('English + සිංහල', 'English + සිංහල');

  const AppLanguage(this.label, this.sinhala);
  final String label;
  final String sinhala;

  static AppLanguage fromName(String? name) {
    return AppLanguage.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppLanguage.both,
    );
  }
}

enum EmojiSpeed {
  slow('Slow', 'හෙමින්'),
  fast('Fast', 'හයියෙන්');

  const EmojiSpeed(this.label, this.sinhala);
  final String label;
  final String sinhala;

  static EmojiSpeed fromName(String? name) {
    return EmojiSpeed.values.firstWhere(
      (e) => e.name == name,
      orElse: () => EmojiSpeed.slow,
    );
  }
}

/// The 20 particle / screen effects drawn by `FxOverlay`.
enum FxKind {
  fireworks,
  sparkles,
  bubbles,
  snow,
  hearts,
  starBurst,
  balloons,
  coins,
  leaves,
  sakura,
  lightning,
  rainbow,
  ripples,
  spiral,
  meteors,
  fireflies,
  disco,
  matrix,
  bokeh,
  pulse,
  aurora,
  warp,
  rain,
  embers,
  lanterns,
  butterflies,
  lasers,
  sunrays,
  notes,
  glitch,
}

/// What plays when a level is completed.
enum GameEffect {
  emoji('Emoji rain', 'Emoji වැස්ස', '🎉'),
  confetti('Confetti', 'කොන්ෆෙටි', '🎊'),
  both('Both', 'දෙකම', '✨'),
  off('Off', 'නැහැ', '🚫'),
  fireworks('Fireworks', 'ගිනි කෙළි', '🎆', FxKind.fireworks),
  sparkles('Sparkles', 'දිලිසෙන තරු', '✨', FxKind.sparkles),
  bubbles('Bubbles', 'බුබුළු', '🫧', FxKind.bubbles),
  snow('Snow', 'හිම', '❄️', FxKind.snow),
  hearts('Hearts', 'හදවත්', '💖', FxKind.hearts),
  starBurst('Star burst', 'තරු පිපිරීම', '🌟', FxKind.starBurst),
  balloons('Balloons', 'බැලූන්', '🎈', FxKind.balloons),
  coins('Gold coins', 'රන් කාසි', '🪙', FxKind.coins),
  leaves('Leaves', 'කොළ', '🍃', FxKind.leaves),
  sakura('Sakura', 'සකුරා', '🌸', FxKind.sakura),
  lightning('Lightning', 'කෙටීම', '⚡', FxKind.lightning),
  rainbow('Rainbow', 'දේදුන්න', '🌈', FxKind.rainbow),
  ripples('Ripples', 'රැල්ල', '💧', FxKind.ripples),
  spiral('Spiral', 'සර්පිලාකාර', '🌀', FxKind.spiral),
  meteors('Meteors', 'උල්කා', '☄️', FxKind.meteors),
  fireflies('Fireflies', 'දිලුකුරු', '🌙', FxKind.fireflies),
  disco('Disco', 'ඩිස්කෝ', '🕺', FxKind.disco),
  matrix('Matrix', 'මැට්‍රික්ස්', '💻', FxKind.matrix),
  bokeh('Bokeh glow', 'දීප්තිය', '🔮', FxKind.bokeh),
  pulse('Glow pulse', 'දීප්ත රැළි', '💫', FxKind.pulse),
  aurora('Aurora', 'ඕරෝරා', '🌌', FxKind.aurora),
  warp('Warp speed', 'වාර්ප් වේගය', '🚀', FxKind.warp),
  rain('Rain', 'වැස්ස', '🌧️', FxKind.rain),
  embers('Embers', 'ගිනි පුපුරු', '🔥', FxKind.embers),
  lanterns('Lanterns', 'පහන් කූඩු', '🏮', FxKind.lanterns),
  butterflies('Butterflies', 'සමනලුන්', '🦋', FxKind.butterflies),
  lasers('Lasers', 'ලේසර්', '🔦', FxKind.lasers),
  sunrays('Sun rays', 'සූර්ය කිරණ', '☀️', FxKind.sunrays),
  notes('Music notes', 'සංගීත සටහන්', '🎵', FxKind.notes),
  glitch('Glitch', 'ග්ලිච්', '📺', FxKind.glitch);

  const GameEffect(this.label, this.sinhala, this.icon, [this.fx]);
  final String label;
  final String sinhala;
  final String icon;

  /// Set for the 20 particle effects, null for the classic ones.
  final FxKind? fx;

  bool get hasEmoji => this == GameEffect.emoji || this == GameEffect.both;
  bool get hasConfetti => this == GameEffect.confetti || this == GameEffect.both;

  static GameEffect fromName(String? name) {
    return GameEffect.values.firstWhere(
      (e) => e.name == name,
      orElse: () => GameEffect.both,
    );
  }
}

/// Quality used when a YouTube link is downloaded as audio.
/// Smaller files download much faster.
enum AudioQuality {
  fast('Fast', 'වේගවත්', '~48 kbps'),
  normal('Normal', 'සාමාන්‍ය', '~128 kbps'),
  high('High', 'උසස්', 'best');

  const AudioQuality(this.label, this.sinhala, this.hint);
  final String label;
  final String sinhala;
  final String hint;

  static AudioQuality fromName(String? name) {
    return AudioQuality.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AudioQuality.normal,
    );
  }
}

class EmojiPack {
  const EmojiPack(this.id, this.name, this.emojis);
  final String id;
  final String name;
  final List<String> emojis;

  static const List<EmojiPack> all = [
    EmojiPack('water', 'Water 💧', ['💧', '🌊', '💦', '🫧', '💙']),
    EmojiPack('love', 'Love ❤️', ['❤️', '💖', '💕', '💗', '😍']),
    EmojiPack('party', 'Party 🎉', ['🎉', '🎊', '✨', '🥳', '🎈']),
    EmojiPack('stars', 'Stars ⭐', ['⭐', '🌟', '✨', '💫', '🌠']),
    EmojiPack('fun', 'Fun 😂', ['😂', '🤩', '😎', '🥰', '😜']),
    EmojiPack('fruit', 'Fruit 🍓', ['🍓', '🍉', '🍒', '🍍', '🍊']),
  ];

  static EmojiPack fromId(String? id) {
    return all.firstWhere((e) => e.id == id, orElse: () => all.first);
  }
}

@immutable
class AppSettings {
  const AppSettings({
    this.isHintEnabled = false,
    this.theme = AppThemePreset.pastelSky,
    this.emojiSpeed = EmojiSpeed.slow,
    this.emojiPackId = 'water',
    this.autoPlayMusic = false,
    this.language = AppLanguage.both,
    this.effect = GameEffect.both,
    this.haptics = true,
    this.audioQuality = AudioQuality.normal,
  });

  final bool isHintEnabled;
  final AppThemePreset theme;
  final EmojiSpeed emojiSpeed;
  final String emojiPackId;
  final bool autoPlayMusic;
  final AppLanguage language;
  final GameEffect effect;
  final bool haptics;
  final AudioQuality audioQuality;

  EmojiPack get emojiPack => EmojiPack.fromId(emojiPackId);

  AppSettings copyWith({
    bool? isHintEnabled,
    AppThemePreset? theme,
    EmojiSpeed? emojiSpeed,
    String? emojiPackId,
    bool? autoPlayMusic,
    AppLanguage? language,
    GameEffect? effect,
    bool? haptics,
    AudioQuality? audioQuality,
  }) {
    return AppSettings(
      isHintEnabled: isHintEnabled ?? this.isHintEnabled,
      theme: theme ?? this.theme,
      emojiSpeed: emojiSpeed ?? this.emojiSpeed,
      emojiPackId: emojiPackId ?? this.emojiPackId,
      autoPlayMusic: autoPlayMusic ?? this.autoPlayMusic,
      language: language ?? this.language,
      effect: effect ?? this.effect,
      haptics: haptics ?? this.haptics,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }
}
