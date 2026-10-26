import '../domain/software_package.dart';

/// Sample data until a real package discovery adapter exists.
List<SoftwarePackage> sampleCatalog() {
  return [
    SoftwarePackage(
      id: 'geo-background-generator',
      name: 'Geo Background Generator',
      subtitle:
          'Geometric pattern background generator with customizable gradients',
      description: 'Generate crisp, procedural low-poly and geometric pattern wallpapers. Fine-tune color palettes, gradient angles, cell density, and lighting to export desktop and mobile backgrounds.',
      currentVersion: '1.8.2',
      latestVersion: '2.0.0',
      iconAsset: 'assets/geo-background-generator.png',
      status: PackageInstallationStatus.updateAvailable,
      latestRelease: const ReleaseNote(
        version: '2.0.0',
        date: '2026-10-18',
        highlights: [
          'Major upgrade: brand-new procedural Delaunay triangulation engine',
          'Added multi-stop gradient editor with real-time lighting simulation',
          'Direct 4K, 5K, and ultrawide wallpaper export presets',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '1.8.2',
          date: '2026-06-11',
          highlights: [
            'Fixed color palette persistence when relaunching',
            'Added one-click hex color code clipboard copying',
          ],
        ),
        ReleaseNote(
          version: '1.8.0',
          date: '2026-02-04',
          highlights: [
            'Added 24 curated pastel and cyber-neon preset themes',
            'Sub-pixel smoothing for high-refresh-rate displays',
          ],
        ),
      ],
      availableVersions: const [
        'v2.0.0 (Latest)',
        'v1.8.2 (Installed)',
        'v1.8.0',
        'v1.0.0',
      ],
    ),
    SoftwarePackage(
      id: 'joins-the-battle-meme-generator',
      name: 'Joins the Battle Meme Generator',
      subtitle: 'Create authentic fighting game splash screens and memes',
      description: 'Create custom "Joins the Battle" splash screens, intro cards, and crossover reveals with authentic fonts, flares, and sound effect triggers.',
      currentVersion: '2.4.1',
      latestVersion: '2.4.1',
      iconAsset: 'assets/joins-the-battle.png',
      status: PackageInstallationStatus.installed,
      latestRelease: const ReleaseNote(
        version: '2.4.1',
        date: '2026-08-14',
        highlights: [
          'Added custom font outline and drop shadow styling',
          'New high-resolution PNG and animated GIF export options',
          'Expanded template roster with 8 classic character poses',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '2.3.0',
          date: '2026-03-22',
          highlights: [
            'Drag-and-drop character artwork directly onto the canvas',
            'Added alignment guidelines and snap-to-grid controls',
          ],
        ),
        ReleaseNote(
          version: '2.0.0',
          date: '2025-11-05',
          highlights: [
            'Complete UI overhaul with native high-DPI scaling',
            'Multi-layer editing support',
          ],
        ),
      ],
      availableVersions: const ['v2.4.1 (Latest)', 'v2.3.0', 'v2.0.0'],
    ),
    SoftwarePackage(
      id: 'stellenwerttafel-plus',
      name: 'Stellenwerttafel Plus',
      subtitle: 'Interactive place value chart for binary, decimal, and hex',
      description: 'Educational desktop place value visualizer supporting binary, decimal, octal, and hexadecimal number systems with live bundled tokens.',
      currentVersion: '1.3.0',
      latestVersion: '1.3.0',
      iconAsset: 'assets/stellenwerttafel-plus.png',
      status: PackageInstallationStatus.installed,
      latestRelease: const ReleaseNote(
        version: '1.3.0',
        date: '2026-07-29',
        highlights: [
          'Added hexadecimal numeral system support with interactive bundles',
          'Keyboard shortcuts for rapid number entry and grouping',
          'German and English curriculum-aligned exercises',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '1.2.0',
          date: '2026-01-15',
          highlights: [
            'Binary bit-toggle mode with powers-of-two visualizer',
            'Export exercise sheets as print-ready PDFs',
          ],
        ),
      ],
      availableVersions: const ['v1.3.0 (Latest)', 'v1.2.0', 'v1.0.0'],
    ),
    SoftwarePackage(
      id: 'benplaysgames-soundboard',
      name: 'BenPlaysGames Soundboard',
      subtitle: 'Soundboard app for YouTuber and Twitch streamer BenPlaysGames',
      description: 'Curated collection of stream alerts, funny soundbites, and reaction noises from BenPlaysGames broadcasts.',
      currentVersion: '1.1.0',
      latestVersion: '1.1.0',
      iconAsset: 'assets/benplaysgames-soundboard.png',
      status: PackageInstallationStatus.notInstalled,
      latestRelease: const ReleaseNote(
        version: '1.1.0',
        date: '2026-08-20',
        highlights: [
          'Added 28 new catchphrases and sound bites from recent livestreams',
          'Global hotkey support to trigger sounds during gaming',
          'Favorites bar with instant reordering',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '1.0.0',
          date: '2025-12-10',
          highlights: [
            'Initial community soundboard release with 40 classic clips',
            'Volume normalization across all recordings',
          ],
        ),
      ],
      availableVersions: const ['v1.1.0 (Latest)', 'v1.0.0'],
    ),
    SoftwarePackage(
      id: 'germemz',
      name: 'GerMemz',
      subtitle: 'German TV commercial meme soundboard with 45 iconic quotes',
      description: 'The definitive soundboard featuring legendary German television ads, viral video memes, and nostalgic voiceovers.',
      currentVersion: '1.0.3',
      latestVersion: '1.0.3',
      iconAsset: 'assets/germemz.png',
      status: PackageInstallationStatus.notInstalled,
      latestRelease: const ReleaseNote(
        version: '1.0.3',
        date: '2026-06-25',
        highlights: [
          'Added 12 iconic retro commercials from 90s and 2000s television',
          'Search and tag filtering by decade and product category',
          'Loop playback mode and sound pitching',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '1.0.0',
          date: '2026-01-20',
          highlights: ['Initial release with 33 cult classic quotes'],
        ),
      ],
      availableVersions: const ['v1.0.3 (Latest)', 'v1.0.0'],
    ),
    SoftwarePackage(
      id: 'oss-space-adventure',
      name: 'OSS Space Adventure',
      subtitle: 'Retro arcade space shooter \u2014 protect your planet from asteroids',
      description: 'High-intensity top-down 2D space shooter inspired by arcade classics, featuring procedural wave generation and weapon customization.',
      currentVersion: '1.2.4',
      latestVersion: '1.2.4',
      iconAsset: 'assets/oss-space-adventure.png',
      status: PackageInstallationStatus.downloading,
      downloadProgress: 0.65,
      latestRelease: const ReleaseNote(
        version: '1.2.4',
        date: '2026-09-30',
        highlights: [
          'Added three new boss battle phases and deep-space nebula arenas',
          'Gamepad and joystick deadzone configuration',
          'Global and local high-score leaderboards',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '1.1.0',
          date: '2026-03-08',
          highlights: [
            'Weapon upgrade tree: laser spread, plasma burst, and homing missiles',
            'Particle effects engine optimization',
          ],
        ),
      ],
      availableVersions: const ['v1.2.4 (Latest)', 'v1.1.0', 'v1.0.0'],
    ),
    SoftwarePackage(
      id: 'project-tortuga',
      name: 'Project Tortuga',
      subtitle:
          'Custom Call of Duty: Black Ops 3 Zombies map and GSC/CSC scripts',
      description: 'High seas pirate themed custom zombies experience with unique atmosphere, custom scripting, and boss encounters.',
      currentVersion: '1.0.0',
      latestVersion: '1.0.0',
      iconAsset: 'assets/project-tortuga.png',
      status: PackageInstallationStatus.notInstalled,
      latestRelease: const ReleaseNote(
        version: '1.0.0',
        date: '2026-07-04',
        highlights: [
          'Full release of the pirate island Zombies survival experience',
          'Custom cursed treasure Easter egg quest with cutscene',
          'Four unique wonder weapons and custom perk-a-cola machines',
        ],
      ),
      olderReleases: const [],
      availableVersions: const ['v1.0.0 (Latest)'],
    ),
    SoftwarePackage(
      id: 'unofficial-sonic-mania-mobile-prototype',
      name: 'Unofficial Sonic Mania Mobile Prototype',
      subtitle: 'Fan port prototype built with GameMaker: Studio and Sonic MAX',
      description: 'Technical demonstration showcasing high-speed platforming physics, loop mechanics, and responsive touch controls on mobile devices.',
      currentVersion: '0.4.2',
      latestVersion: '0.4.2',
      iconAsset: 'assets/sonic-mania-mobile.png',
      status: PackageInstallationStatus.notInstalled,
      latestRelease: const ReleaseNote(
        version: '0.4.2',
        date: '2026-05-18',
        highlights: [
          'Refined 360-degree loop physics and slope acceleration',
          'On-screen virtual D-pad and Bluetooth controller mapping',
          'Studiopolis Zone Act 1 performance improvements',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '0.3.0',
          date: '2025-10-12',
          highlights: [
            'Initial public tech prototype with Green Hill Zone Act 1',
            'Drop dash move support',
          ],
        ),
      ],
      availableVersions: const ['v0.4.2 (Latest)', 'v0.3.0'],
    ),
    SoftwarePackage(
      id: 'unofficial-super-mario-bros-misfit-pack',
      name: 'Unofficial Super Mario Bros. Misfit Pack',
      subtitle: 'Classic platformer collection with visual enhancements and widescreen',
      description: 'Preserved retro platformer engine enhanced for modern widescreen displays with optional orchestrations and quality-of-life adjustments.',
      currentVersion: '0.9.0',
      latestVersion: '0.9.0',
      iconAsset: 'assets/misfit-pack.svg',
      isSvgIcon: true,
      status: PackageInstallationStatus.notInstalled,
      latestRelease: const ReleaseNote(
        version: '0.9.0',
        date: '2026-09-02',
        highlights: [
          'Native 16:9 widescreen rendering with extended camera scroll',
          'Remastered 8-bit sound effects and optional stereo music',
          'Custom level selector and checkpoint system',
        ],
      ),
      olderReleases: const [
        ReleaseNote(
          version: '0.8.2',
          date: '2026-04-19',
          highlights: [
            'Fixed jump momentum collision glitch on moving platforms',
            'Game controller rumble feedback support',
          ],
        ),
      ],
      availableVersions: const ['v0.9.0 (Latest)', 'v0.8.2'],
    ),
  ];
}
