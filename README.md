# Restaurant Tracker

An iOS app (SwiftUI + SwiftData + MapKit) for keeping track of the restaurants you've visited and rating them out of five stars.

## Features

- **Map** – every restaurant you've rated is pinned on a map, coloured by rating. Filter to 3★+, 4★+ or 5★ places, tap a pin for details.
- **Visited list** – searchable list with quick stats (places visited, average rating, number of 5★ spots), sortable by most recent, highest rated or name. Swipe to delete.
- **Add / edit** – search Apple Maps for the place, pick a cuisine, the date you went, a 1–5 star rating and notes.
- **Detail** – change the rating in place, see the spot on a map and open it in Apple Maps for directions.

## Project layout

```
Restaurant Tracker/
  Restaurant Tracker.xcodeproj
  Restaurant Tracker/
    App/            App entry point & SwiftData container
    Models/         Restaurant (SwiftData model), Cuisine
    Features/       Map, list, detail and add/edit screens
    Services/       Apple Maps place search
    Shared/         Design system (star rating, pins, tiles) and preview sample data
  Restaurant TrackerTests/
    SnapshotTests.swift
snapshots/          Auto-generated screenshots of every #Preview (committed by CI)
```

## UI snapshots

The [`Generate UI Snapshots`](.github/workflows/generate-snapshots.yml) workflow runs on every push to `main` (or manually from the Actions tab). It uses [SnapshotPreviews](https://github.com/getsentry/SnapshotPreviews) to render every `#Preview` in the app on an iPhone simulator and commits the PNGs to [`snapshots/`](snapshots).

To get a new screen into the snapshots, just add a `#Preview` for it. Previews use `SampleData.makeContainer()` (an in-memory SwiftData store with fixed sample data) so the screenshots stay stable between runs.

## Installing on your phone (TestFlight)

The [`Upload to TestFlight`](.github/workflows/testflight.yml) workflow builds a signed Release `.ipa` on a macOS runner, uploads it to TestFlight and also attaches the `.ipa` to the run. Signing is automatic via an App Store Connect API key, so no certificates or provisioning profiles need to be exported.

One-time setup:

1. **App record** – in [App Store Connect](https://appstoreconnect.apple.com) go to *Apps → + → New App* and use bundle ID `indi.Restaurant-Tracker` (register it under *Certificates, Identifiers & Profiles → Identifiers* first if it isn't listed).
2. **API key** – *Users and Access → Integrations → App Store Connect API → Team Keys → +*, role **Admin** (needed for cloud-managed signing). Download the `.p8` file (it can only be downloaded once) and note the **Key ID** and **Issuer ID**.
3. **GitHub secrets** – in the repo's *Settings → Secrets and variables → Actions*, add:
   - `ASC_KEY_ID` – the Key ID
   - `ASC_ISSUER_ID` – the Issuer ID
   - `ASC_KEY_P8` – the full contents of the `.p8` file, including the `BEGIN`/`END` lines

To ship a build, run the workflow from the Actions tab (*Upload to TestFlight → Run workflow*). The build number is the workflow run number. After Apple finishes processing (usually 5–15 minutes) the build appears in the TestFlight app on any device signed in as a tester on the app — you're automatically an internal tester as the account owner.

Requires Xcode 26 or later (iOS 18 deployment target).
