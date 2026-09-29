import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pastel tints handed out to projects, cycling every four.
class ProjectTints extends ThemeExtension<ProjectTints> {
  const ProjectTints({required this.tints, required this.ink});

  final List<Color> tints;

  /// Text and icon colour that sits on top of a tint.
  final Color ink;

  Color forIndex(int i) => tints[i % tints.length];

  @override
  ProjectTints copyWith({List<Color>? tints, Color? ink}) =>
      ProjectTints(tints: tints ?? this.tints, ink: ink ?? this.ink);

  @override
  ProjectTints lerp(ProjectTints? other, double t) {
    if (other == null) return this;
    return ProjectTints(
      tints: List.generate(tints.length, (i) => Color.lerp(tints[i], other.tints[i], t)!),
      ink: Color.lerp(ink, other.ink, t)!,
    );
  }
}

const _accent = Color(0xFF0088B0);
const _accentDark = Color(0xFF62C5EE);
const _magenta = Color(0xFFD6006C);

/// Builds the light or dark theme. Pass `webFonts: false` to skip the
/// Plus Jakarta Sans download (used by tests, which have no network).
ThemeData buildTheme(Brightness brightness, {bool webFonts = true}) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? const Color(0xFF141516) : const Color(0xFFF3F2F2);
  final surface = dark ? const Color(0xFF1F2123) : const Color(0xFFEAE9E9);
  final text = dark ? const Color(0xFFF2F1EF) : const Color(0xFF201E1D);
  final muted = dark ? const Color(0xFFBCBEC0) : const Color(0xFF6E6B6A);
  final faint = dark ? const Color(0xFF7D7F81) : const Color(0xFF9B9797);
  final accent = dark ? _accentDark : _accent;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: bg,
    secondary: _magenta,
    onSecondary: Colors.white,
    error: _magenta,
    onError: Colors.white,
    surface: bg,
    onSurface: text,
    surfaceContainer: surface,
    onSurfaceVariant: muted,
    outline: faint,
    outlineVariant: dark ? const Color(0xFF343638) : const Color(0xFFD9D7D6),
  );

  final base = ThemeData(brightness: brightness).textTheme;
  final fontTheme = webFonts ? GoogleFonts.plusJakartaSansTextTheme(base) : base;
  final textTheme = fontTheme.apply(bodyColor: text, displayColor: text);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: textTheme.labelMedium?.copyWith(color: accent),
      ),
    ),
    extensions: [
      ProjectTints(
        tints: dark
            ? const [Color(0xFF16333D), Color(0xFF3B1A29), Color(0xFF3A3218), Color(0xFF2A2B2D)]
            : const [Color(0xFFDFF3FA), Color(0xFFFBE3EC), Color(0xFFF7EFD2), Color(0xFFE6E4E1)],
        ink: text,
      ),
    ],
  );
}
