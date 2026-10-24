# Dynamotivation Software Hub

A multiplatform native desktop application built with **Haxe**, **HXCPP**, and **HaxeUI** (`haxeui-hxwidgets`), structured according to **Domain-Driven Design (DDD)** and Hexagonal (Ports & Adapters) principles.

---

## 🏛️ Architecture Overview

The codebase is organized into four decoupled layers:

```text
src/
├── domain/                      # 1. Pure Domain Layer (Entities, Value Objects, Ports)
│   ├── model/
│   │   ├── ItemId.hx            # Abstract zero-cost Value Object
│   │   ├── ItemStatus.hx        # Lifecycle Status Enum
│   │   └── HubItem.hx           # Aggregate Root with business invariants
│   ├── event/
│   │   └── HubItemEvent.hx      # Domain Events
│   └── port/
│       └── HubItemRepository.hx # Outbound Port Interface
│
├── application/                 # 2. Application Layer (Use Cases & DTOs)
│   ├── dto/
│   │   └── RegisterItemCommand.hx
│   └── usecase/
│       ├── RegisterItemUseCase.hx
│       └── ListItemsUseCase.hx
│
├── infrastructure/              # 3. Infrastructure Layer (Adapters)
│   └── persistence/
│       └── InMemoryHubItemRepository.hx # Initial In-Memory / Test Adapter
│
├── presentation/                # 4. Presentation Layer (HaxeUI / Widgets)
│   ├── style/
│   │   ├── PlatformType.hx          # OS Target Enum (Windows, Mac, Linux)
│   │   └── PlatformStyleManager.hx  # Platform Stylesheet & Quirk Engine
│   ├── viewmodel/
│   │   └── MainViewModel.hx         # Presentation State & Use Case Coordinator
│   └── view/
│       └── MainView.hx              # Declarative HaxeUI Component
│
└── Main.hx                      # Composition Root (Dependency Injection wiring)
```

---

## 🎨 Platform-Specific Styling & Widget Quirks

Different operating systems handle native widget metrics (margins, button heights, system fonts, padding) differently. To resolve platform-specific UI quirks cleanly without leaking platform logic into business rules:

1. **Base Stylesheet (`assets/styles/main.css`)**:
   * Declares default layout metrics, classes, and sizing used across all platforms.
2. **Platform Override Stylesheets (`assets/styles/platforms/*.css`)**:
   * `windows.css`: Accommodates Windows native metrics (tighter margins, Segoe UI, compact dialog padding).
   * `mac.css`: Accommodates macOS HIG metrics (generous breathing room, Apple system font, taller controls).
   * `linux.css`: Accommodates GTK3 conventions (Ubuntu/Cantarell fonts, standard GNOME padding).
3. **`PlatformStyleManager`**:
   * Automatically detects the host OS at compile-time and runtime.
   * Loads and parses the corresponding platform stylesheet into `haxe.ui.Toolkit.styleSheet`.
   * Injects root CSS classes (`.platform-windows`, `.platform-mac`, `.platform-linux`) for scoped CSS overrides.
   * Provides programmatic hooks (`applyWidgetQuirks()`) for wxWidgets properties that require native runtime adjustments.

---

## 🚀 Building & Running

### Prerequisites

1. **Haxe 4.3+**
2. **Haxelibs**:
   ```bash
   haxelib install hxcpp
   haxelib install haxeui-core
   haxelib install haxeui-hxwidgets
   haxelib install hxWidgets
   ```
3. **Platform C++ Compilers & wxWidgets**:
   * **Windows**: Visual Studio C++ Build Tools (MSVC) + wxWidgets 3.x (`WXWIN` environment variable).
   * **macOS**: Xcode Command Line Tools (`xcode-select --install`) + `brew install wxwidgets`.
   * **Linux**: `sudo apt install build-essential libwxgtk3.0-gtk3-dev libwxbase3.0-dev`.

### Compile

```bash
haxe build.hxml
```

The compiled native executable will be located in `bin/desktop/Main` (or `Main.exe` on Windows).
