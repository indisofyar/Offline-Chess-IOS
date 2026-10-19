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

Requires Xcode 26 or later (iOS 18 deployment target).
