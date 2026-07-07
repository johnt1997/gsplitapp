// Badge-Definitionen als Code-Konstante — kein Firestore-Seeding nötig.
// Die Unlock-Logik lebt in Badge.checkUnlock() (models.dart).
import '../models/models.dart';

final List<Badge> badgesCatalog = [
  // ---------- PASSPORT (besuchte Pubs) ----------
  Badge(
    id: 'passport_explorer',
    name: 'Pub Explorer',
    description: 'Bewerte Pints in 3 verschiedenen Pubs.',
    iconPath: 'explore',
    colorArgb: 0xFFD4AF37,
    tier: 1,
    type: BadgeType.PASSPORT,
    requirement: {'requiredPubs': 3},
  ),
  Badge(
    id: 'passport_pilgrim',
    name: 'Pub Pilgrim',
    description: 'Bewerte Pints in 10 verschiedenen Pubs.',
    iconPath: 'explore',
    colorArgb: 0xFF50C878,
    tier: 2,
    type: BadgeType.PASSPORT,
    requirement: {'requiredPubs': 10},
  ),
  Badge(
    id: 'passport_legend',
    name: 'Pub Legend',
    description: 'Bewerte Pints in 25 verschiedenen Pubs. Absolute Legende.',
    iconPath: 'explore',
    colorArgb: 0xFFF5E6D3,
    tier: 3,
    type: BadgeType.PASSPORT,
    requirement: {'requiredPubs': 25},
  ),

  // ---------- VARIETY (verschiedene Guinness-Typen) ----------
  Badge(
    id: 'variety_scholar',
    name: 'Stout Scholar',
    description: 'Probiere 3 verschiedene Guinness-Typen.',
    iconPath: 'variety',
    colorArgb: 0xFFD4AF37,
    tier: 1,
    type: BadgeType.VARIETY,
    requirement: {'requiredTypes': 3},
  ),
  Badge(
    id: 'variety_professor',
    name: 'Stout Professor',
    description: 'Probiere 5 verschiedene Guinness-Typen.',
    iconPath: 'variety',
    colorArgb: 0xFF50C878,
    tier: 2,
    type: BadgeType.VARIETY,
    requirement: {'requiredTypes': 5},
  ),

  // ---------- QUALITY ----------
  Badge(
    id: 'quality_connoisseur',
    name: 'Connoisseur',
    description: 'Dein Durchschnitts-Rating liegt bei 8.0 oder höher.',
    iconPath: 'quality',
    colorArgb: 0xFF50C878,
    tier: 2,
    type: BadgeType.QUALITY,
    requirement: {},
  ),
  Badge(
    id: 'quality_critic',
    name: 'Critic',
    description: 'Dein Durchschnitts-Rating liegt unter 5.0 — harter Hund.',
    iconPath: 'quality',
    colorArgb: 0xFFB0413E,
    tier: 1,
    type: BadgeType.QUALITY,
    requirement: {},
  ),
  Badge(
    id: 'quality_perfect_pour_master',
    name: 'Perfect Pour Master',
    description: 'Sammle 5 Perfect Pours (AI-Score 8.5+).',
    iconPath: 'quality',
    colorArgb: 0xFFF5E6D3,
    tier: 3,
    type: BadgeType.QUALITY,
    requirement: {'count': 5},
  ),

  // ---------- TIMING ----------
  Badge(
    id: 'timing_early_bird',
    name: 'Early Bird',
    description: '3 Reviews vor 12 Uhr mittags. Respekt? Sorge?',
    iconPath: 'timing',
    colorArgb: 0xFFD4AF37,
    tier: 1,
    type: BadgeType.TIMING,
    requirement: {'count': 3},
  ),
  Badge(
    id: 'timing_night_owl',
    name: 'Night Owl',
    description: '3 Reviews nach 22 Uhr.',
    iconPath: 'timing',
    colorArgb: 0xFF4B0082,
    tier: 1,
    type: BadgeType.TIMING,
    requirement: {'count': 3},
  ),
  Badge(
    id: 'timing_streak_master',
    name: 'Streak Master',
    description: 'Bewerte an 3 Tagen in Folge ein Pint.',
    iconPath: 'timing',
    colorArgb: 0xFF50C878,
    tier: 2,
    type: BadgeType.TIMING,
    requirement: {'days': 3},
  ),
  Badge(
    // "Streak Master" muss im Namen stehen (checkUnlock matcht per Substring)
    id: 'timing_streak_master_2',
    name: 'Streak Master II',
    description: 'Eine ganze Woche: 7 Tage in Folge ein Pint bewerten.',
    iconPath: 'timing',
    colorArgb: 0xFFF5E6D3,
    tier: 3,
    type: BadgeType.TIMING,
    requirement: {'days': 7},
  ),
];
