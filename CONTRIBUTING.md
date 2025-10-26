# Mac Image Manager - Development Guidelines

> Last updated: October 2025

## 📋 Overview

This document provides comprehensive development guidelines for Mac Image Manager, a native macOS application built with SwiftUI. These guidelines ensure code consistency, maintainability, and adherence to Apple's Human Interface Guidelines.

## 🎯 Core Principles

### 1. Always Follow Apple Human Interface Guidelines (HIG)

- Prioritize native macOS UI patterns and behaviors
- Use system-provided controls and layouts whenever possible
- Ensure accessibility compliance with VoiceOver and other assistive technologies
- Follow Apple's visual design principles for spacing, typography, and color

### 2. Modern Swift & SwiftUI (2025 Standards)

- Use Swift 6.0+ language features and concurrency model
- Leverage SwiftUI 6.0+ framework capabilities
- Implement `@MainActor` isolation for UI-related code
- Use structured concurrency (`async/await`, `Task`) over legacy completion handlers
- Prefer value types (structs) over reference types (classes) when appropriate

### 3. Code Organization & Architecture

- Follow MVVM (Model-View-ViewModel) architecture pattern
- Use `@ObservableObject` and `@Published` for state management
- Organize code into logical directories: `Models/`, `Views/`, `ViewModels/` (if needed)
- Separate concerns: UI logic in Views, business logic in Models
- Use extensions to organize code by functionality

## 🏗️ Project Structure

### File Organization

```text
MacImageManager/
├── Models/           # Data models and business logic
├── Views/            # SwiftUI views and UI components
├── ViewModels/       # View models (if MVVM pattern requires)
├── Utilities/        # Helper functions and extensions
├── Resources/        # Assets, strings, configuration files
└── Tests/            # Unit and UI tests
```

### Naming Conventions

- **Files**: Use PascalCase (e.g., `BrowserModel.swift`, `PaneImageViewer.swift`)
- **Classes/Structs**: PascalCase (e.g., `FileItem`, `BrowserModel`)
- **Properties/Methods**: camelCase (e.g., `selectedImage`, `loadCurrentDirectory()`)
- **Constants**: camelCase for instance properties, SCREAMING_SNAKE_CASE for static constants
- **Enums**: PascalCase for type, camelCase for cases (e.g., `MediaType.staticImage`)

## 🎨 SwiftUI Best Practices

### View Structure

```swift
struct ExampleView: View {
    // MARK: - Properties
    @EnvironmentObject private var model: BrowserModel
    @State private var localState = ""
    @FocusState private var isFocused: Bool

    // MARK: - Computed Properties
    private var computedValue: String {
        // Implementation
    }

    // MARK: - Body
    var body: some View {
        // Implementation
    }

    // MARK: - Private Methods
    private func helperMethod() {
        // Implementation
    }
}

// MARK: - Preview
#Preview {
    ExampleView()
        .environmentObject(BrowserModel.preview)
}
```

### State Management Guidelines

- Use `@State` for local view state that doesn't need to be shared
- Use `@StateObject` for creating and owning observable objects
- Use `@ObservedObject` when the object is owned elsewhere
- Use `@EnvironmentObject` for app-wide shared state
- Use `@FocusState` for keyboard focus management
- Prefer `@Binding` for two-way data flow between parent and child views

### View Composition

- Keep views small and focused on a single responsibility
- Extract complex UI into separate view structs
- Use `@ViewBuilder` for conditional view building
- Prefer composition over inheritance
- Use view modifiers for reusable styling

## 📱 macOS-Specific Guidelines

### Window Management

- Set appropriate minimum window sizes using `.frame(minWidth:minHeight:)`
- Use `.windowResizability()` to control resize behavior
- Handle window lifecycle events appropriately
- Disable automatic window tabbing when inappropriate: `NSWindow.allowsAutomaticWindowTabbing = false`

### Menu Bar Integration

- Use `CommandGroup` to customize menu structure
- Provide keyboard shortcuts for common actions
- Follow macOS menu organization conventions
- Use `.keyboardShortcut()` modifiers consistently

### Keyboard Navigation

- Implement comprehensive keyboard navigation using `@FocusState`
- Use `.onKeyPress()` for custom key handling
- Support standard macOS keyboard shortcuts (⌘C, ⌘V, ⌘A, etc.)
- Ensure all interactive elements are keyboard accessible

### File System Integration

- Use `FileManager` for file operations
- Implement proper file access permissions and sandboxing
- Use `fileImporter`/`fileExporter` for user file selection
- Handle file system errors gracefully
- Support drag-and-drop operations where appropriate

## 🧬 Code Quality Standards

### Swift Language Features

```swift
// ✅ Good: Use modern Swift concurrency
@MainActor
class BrowserModel: ObservableObject {
    @Published var items: [FileItem] = []

    func loadDirectory() async {
        // Implementation using async/await
    }
}

// ✅ Good: Use proper access control
private func helperMethod() { }
internal var publicProperty: String = ""

// ✅ Good: Use type inference when clear
let items = [FileItem]()
let url = URL(fileURLWithPath: path)

// ✅ Good: Use guard statements for early returns
guard let url = selectedFile?.url else { return }
```

### Error Handling

- Use `Result` types for functions that can fail
- Throw specific, meaningful errors
- Handle errors gracefully in the UI
- Log errors appropriately for debugging
- Provide user-friendly error messages

### Performance Considerations

- Use lazy loading for large datasets
- Implement proper image caching for media files
- Use `Task` for background processing
- Cache expensive computations
- Optimize List and ScrollView performance with proper ID management

## 🎭 UI/UX Guidelines

### Visual Design

- Use system colors and semantic color roles
- Implement proper dark mode support
- Use SF Symbols for icons consistently
- Follow macOS spacing and sizing conventions
- Ensure proper contrast ratios for accessibility

### Animation & Transitions

- Use SwiftUI's built-in animations with `.animation()` modifier
- Keep animations subtle and purposeful
- Use appropriate animation curves (`.easeInOut`, `.spring()`)
- Ensure animations don't interfere with accessibility

### Loading States

- Show progress indicators for long-running operations
- Use skeleton loading states when appropriate
- Provide cancellation options for lengthy operations
- Display meaningful loading messages

## 🧪 Testing Guidelines

### Unit Testing

- Write tests for business logic in Models
- Test edge cases and error conditions
- Use dependency injection for testability
- Mock external dependencies (file system, network)

### UI Testing

- Create UI tests for critical user workflows
- Test keyboard navigation and accessibility
- Verify proper state management across views
- Test error handling and recovery scenarios

### Preview Testing

- Provide comprehensive SwiftUI previews
- Include different states and edge cases in previews
- Use preview data for consistent testing
- Test both light and dark mode appearances

## 📝 Documentation Standards

### Code Comments

```swift
/// Loads the current directory contents asynchronously
/// - Returns: Array of FileItem objects representing directory contents
/// - Throws: FileSystemError if directory cannot be accessed
@MainActor
func loadCurrentDirectory() async throws -> [FileItem] {
    // Implementation
}
```

### README and Documentation

- Keep README.md updated with current features
- Document API changes and breaking changes
- Provide setup and build instructions
- Include screenshots and usage examples

## 🔧 Development Tools & Workflow

### Xcode Configuration

- Use SwiftFormat or similar for code formatting
- Enable all relevant compiler warnings
- Use Xcode's built-in accessibility inspector
- Configure proper code signing for distribution

### Git Workflow

- Use descriptive commit messages
- Create feature branches for new development
- Use pull requests for code review
- Tag releases appropriately

### Dependencies

- Minimize external dependencies
- Prefer Apple frameworks over third-party solutions
- Document all dependencies and their purposes
- Keep dependencies updated and secure

## 🚀 Performance & Optimization

### Memory Management

- Use weak references to prevent retain cycles
- Implement proper cleanup in `onDisappear`
- Monitor memory usage in Instruments
- Cache frequently accessed data appropriately

### File Operations

- Perform file I/O operations on background queues
- Use proper file system caching
- Handle large files efficiently
- Implement progressive loading for large directories

## 🛡️ Security & Privacy

### Sandboxing

- Follow App Sandbox guidelines
- Request minimal necessary entitlements
- Handle security-scoped bookmarks properly
- Implement proper file access patterns

### User Privacy

- Request permissions before accessing user data
- Provide clear explanations for permission requests
- Respect user privacy preferences
- Implement proper data handling practices

## 📋 Code Review Checklist

Before submitting code for review, ensure:

- [ ] Code follows naming conventions and organization patterns
- [ ] SwiftUI views are properly structured and focused
- [ ] Accessibility is considered and implemented
- [ ] Error handling is comprehensive and user-friendly
- [ ] Performance implications are considered
- [ ] Code is properly documented
- [ ] Tests are written and passing
- [ ] Preview code is included and functional
- [ ] Memory management is proper (no retain cycles)
- [ ] File operations are secure and efficient

---

*This document should be updated as the project evolves and new patterns emerge. All team members should review and follow these guidelines to ensure consistent, high-quality code.*
