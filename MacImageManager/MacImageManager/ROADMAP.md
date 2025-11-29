# Development Roadmap

## FEATURES: app

- {OPTIONS}: e.g., sort folders first (BrowserModel > loadCurrentDirectory())
- {HIG/MAC} Ensure HIG compliance and ensure Accessability implementation/support exists

## FEATURES: file-browser

- add: image size options: Normal, Fit, Zoom
- add: multi-select filter: by image-type (ex: "GIF")

## FEATURES: file-browser: file-ops

- add: a new file menu item and functionality: create folder
- add: when an item is deleted, select the next one down (or up, or nothing)
- {BRANCH}: add multi-select of row items (as a precursor to planned file ops)
- {FEATURE}: mass-rename (fancy modal showing real results using actual internal code: e.g., "IMG001" > "Mastodon-001")

## FEATURES: viewers: gif-viewer

- option to view max size or normal size

## DEVOPS: QA/UAT

- add samples for: `["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg", "ico"]`
- add unit tests using Swift Testing to cover common cases (e.g., .jpg, .heic, .webp, and unknown extensions).

## FIXME

- clear currently shown image on search
