# Development Roadmap

## FEATURES: app

- OPTIONS: e.g., sort folders first (BrowserModel > loadCurrentDirectory())

## FEATURES: browser

- add: filter by type (ex: "GIF")
- add: filter by search field ("one piece flag")
- add: a new file menu item and functionality: create folder
- add: locations (e.g., "iCloud" or USB drives)
- BRANCH: add miulti-select of row items (as a precursor to planned file ops)
- FEATURE: mass-rename (fancy modal showing real results using same funcgtion call. e.g., "IMG001" > "Mastodon-001")

## FEATURES: gif viewer

- option to view max size or normal size

## QA/DEV

- add samples for: `["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg", "ico"]`
- add unit tests using Swift Testing to cover common cases (e.g., .jpg, .heic, .webp, and unknown extensions).

## FIXME

- add: more menu items/keyboard shortcuts like {space} for Play/Pause of gif/video
  - space only kinda works sometimes for play/pause
