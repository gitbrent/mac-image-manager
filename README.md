# Mac Image Manager

A modern, native macOS application for viewing and managing images, built with SwiftUI.

## Features

- **Split-View Interface**: File browser on the left, image viewer on the right
- **Image Viewer**:
  - Supports common image formats (JPG, JPEG, PNG, GIF, BMP, TIFF, HEIC, WEBP, SVG, ICO)
  - Automatic aspect ratio fitting
  - Smooth scrolling for large images
  - Loading indicators for better UX
- **File Browser**:
  - Easy directory navigation
  - Starts in user's Documents, Desktop, or Home directory
  - Adjustable sidebar width (200-400px)
  - File system integration

## Requirements

- macOS (built with SwiftUI)
- Xcode 15+ for development

## Project Structure

```swift
MacImageManager/
├── ContentView.swift         # Main split view layout
├── MacImageManagerApp.swift  # App entry point
├── Models/
│   └── DirectoryBrowserModel.swift  # File system operations
└── Views/
    ├── FileBrowserRowView.swift     # File list item view
    ├── PaneFileBrowserView.swift    # Left sidebar browser
    └── PaneImageViewer.swift        # Right pane image viewer
```

## Development

This project is actively under development. Planned features include:

- File operations (move, copy)
- Drag-and-drop support
- Context menus for file operations
- Keyboard shortcuts

I'm basically looking to update my old [EOSIM App](https://eosim.sourceforge.net).

## Repository

- GitHub: [https://github.com/gitbrent/mac-image-manager](https://github.com/gitbrent/mac-image-manager)

## License

See [LICENSE](LICENSE) for details.
