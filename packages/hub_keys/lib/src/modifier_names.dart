/// What the modifier keys are called for the user typing on a given keyboard.
///
/// The names follow the *keyboard layout* the user is typing with, not the
/// OS display language: someone on a German keyboard under an English
/// Windows still has "Strg" printed on the key.
class ModifierNames {
  final String ctrl;
  final String alt;
  final String shift;
  final String meta;

  const ModifierNames({
    this.ctrl = 'Ctrl',
    this.alt = 'Alt',
    this.shift = 'Shift',
    this.meta = 'Win',
  });

  static const international = ModifierNames();

  /// Windows primary language id (low 10 bits of the layout's LANGID) to
  /// names. Only layouts whose conventional labels differ from the English
  /// ones are listed; everything else falls back to [international].
  ///
  /// Provenance:
  ///  * German "Strg" (Steuerung) is printed on German, Austrian and Swiss
  ///    keycaps and used by Windows' own German UI. Confirmed by several
  ///    independent sources.
  ///  * French "Maj", Spanish "Mayús" and Italian "Maiusc" are the Windows
  ///    UI names for Shift; the keycaps of those layouts carry only a ⇧
  ///    arrow, so these are UI conventions rather than keycap text. Ctrl is
  ///    "Ctrl" in all three.
  ///  * Other layouts (Nordic, Slavic, Turkish, Greek, CJK, Hebrew, Arabic,
  ///    Dutch, Portuguese, ...) print "Ctrl"; this was not checked against
  ///    an authoritative per-language table, so add overrides here if a user
  ///    reports a different keycap.
  static const byPrimaryLanguage = <int, ModifierNames>{
    0x07: ModifierNames(ctrl: 'Strg', shift: 'Umschalt'), // German
    0x0C: ModifierNames(shift: 'Maj'), // French
    0x0A: ModifierNames(shift: 'Mayús'), // Spanish
    0x10: ModifierNames(shift: 'Maiusc'), // Italian
  };

  static ModifierNames forPrimaryLanguage(int? primaryLangId) =>
      byPrimaryLanguage[primaryLangId] ?? international;
}
