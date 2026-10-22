# Offline Chess

An iOS app (SwiftUI) for playing chess and analyzing your games — fully on-device, no wifi required.

*Chess and chess analysis without wifi.*

## Features

- **1-player vs bot** – play Stockfish at six selectable strengths, from Beginner (~800) through Master (~2200), similar to chess.com's bot picker.
- **2-player pass-and-play** – a full local two-player game on one device.
- **Full legal chess rules** – check, checkmate, stalemate, draws (fifty-move, insufficient material, threefold repetition, stalemate), castling, en passant and promotion, powered by [ChessKit](https://github.com/chesskit-app/chesskit-swift).
- **Post-game analysis** – a real on-device Stockfish engine ([ChessKitEngine](https://github.com/chesskit-app/chesskit-engine)) classifies every move (Brilliant/Best/Excellent/Good/Inaccuracy/Mistake/Blunder) and computes an overall accuracy percentage per side. Free users get one analysis per day; Premium is unlimited.
- **Board skins** – several light/dark square palettes (Classic Green, Walnut, Ocean, Midnight, Coral), plus a **Pixel** skin drawn from a pixel-art sprite pack (board and pieces) and a **Cartoon** skin with image pieces by VerzatileDev, applied consistently across the board.
- **One-time purchase** – a single non-consumable in-app purchase (`indi.OfflineChess.unlockPro`) removes the ad placeholder and unlocks unlimited analysis.

## Project layout

```
Offline Chess/
  Offline Chess.xcodeproj
  Offline Chess/
    App/            App entry point
    Models/         ChessGame (wraps ChessKit's Board), BotDifficulty, BoardSkin, GameMode, AppState
    Engine/         EngineManager (Stockfish UCI lifecycle), BotPlayer, AnalysisService
    Services/       AnalysisUsageTracker, PurchaseManager (StoreKit 2), ad placeholder
    Features/       Home, Game, Board, Difficulty/Skin pickers, Analysis, Paywall, Settings
    Shared/         Design system (colors, reusable components)
    Resources/      Stockfish NNUE network files
  Offline ChessTests/
    SnapshotTests.swift
snapshots/          Auto-generated screenshots of every #Preview (committed by CI)
```

## UI snapshots

The [`Generate UI Snapshots`](.github/workflows/generate-snapshots.yml) workflow runs on every push to `main` (or manually from the Actions tab). It uses [SnapshotPreviews](https://github.com/getsentry/SnapshotPreviews) to render every `#Preview` in the app on an iPhone simulator and commits the PNGs to [`snapshots/`](snapshots).

To get a new screen into the snapshots, just add a `#Preview` for it.

## Installing on your phone (TestFlight)

The [`Upload to TestFlight`](.github/workflows/testflight.yml) workflow builds a signed Release `.ipa` on a macOS runner, uploads it to TestFlight and also attaches the `.ipa` to the run. Signing is automatic via an App Store Connect API key, so no certificates or provisioning profiles need to be exported.

One-time setup:

1. **App record** – in [App Store Connect](https://appstoreconnect.apple.com) go to *Apps → + → New App* and use bundle ID `indi.OfflineChess` (register it under *Certificates, Identifiers & Profiles → Identifiers* first if it isn't listed).
2. **API key** – *Users and Access → Integrations → App Store Connect API → Team Keys → +*, role **Admin** (needed for cloud-managed signing). Download the `.p8` file (it can only be downloaded once) and note the **Key ID** and **Issuer ID**.
3. **GitHub secrets** – in the repo's *Settings → Secrets and variables → Actions*, add:
   - `ASC_KEY_ID` – the Key ID
   - `ASC_ISSUER_ID` – the Issuer ID
   - `ASC_KEY_P8` – the full contents of the `.p8` file, including the `BEGIN`/`END` lines

To ship a build, run the workflow from the Actions tab (*Upload to TestFlight → Run workflow*). The build number is the workflow run number. After Apple finishes processing (usually 5–15 minutes) the build appears in the TestFlight app on any device signed in as a tester on the app — you're automatically an internal tester as the account owner.

## In-app purchase setup

Before the "unlock pro" purchase will resolve in the app, create a **non-consumable** in-app purchase in App Store Connect with product ID `indi.OfflineChess.unlockPro` (e.g. priced at £6). Until that product exists, `PaywallView` will show its "couldn't load the store item" state — the StoreKit 2 code itself is already wired up and will work as soon as the product is created.

Requires Xcode 26 or later (iOS 18 deployment target).
