//
//  FileItemTheme.swift
//  MacImageManager
//
//  Created by Brent Ely on 10/21/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// Utility namespace for file item theming and visual presentation
enum FileItemTheme {

    /// Returns the appropriate tint color for a given file item
    /// - Parameter item: The FileItem to determine color for
    /// - Returns: A SwiftUI Color appropriate for the file type
    static func tintColor(for item: FileItem) -> Color {
        // Use mediaType for consistent theming with icon
        switch item.mediaType {
        case .directory:
            return .blue
        case .staticImage:
            // Check for specific image types for specialized colors
            guard let type = item.uti else { return .cyan }
            if type == .livePhoto { return .yellow }
            if type == .svg { return .green }
            if type.conforms(to: .rawImage) { return .indigo }
            if type == .heic || type == .heif { return .orange }
            return .cyan
        case .animatedGif:
            return .purple
        case .video:
            return .pink
        case .unknown:
            guard let type = item.uti else { return .secondary }
            if type == .pdf { return .brown }
            if type.conforms(to: .archive) { return .brown }
            if type.conforms(to: .audio) { return .mint }
            if type.conforms(to: .json) { return .cyan }
            if type.conforms(to: .sourceCode) { return .gray }
            if type.conforms(to: .plainText) { return .gray }
            return .secondary
        }
    }

    /// Returns the appropriate tint color for a media type
    /// - Parameter mediaType: The MediaType to determine color for
    /// - Returns: A SwiftUI Color appropriate for the media type
    static func tintColor(for mediaType: MediaType) -> Color {
        switch mediaType {
        case .directory:
            return .blue
        case .staticImage:
            return .cyan
        case .animatedGif:
            return .purple
        case .video:
            return .pink
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Convenience Extensions

extension FileItem {
    /// The tint color for this file item
    var tintColor: Color {
        FileItemTheme.tintColor(for: self)
    }
}

extension MediaType {
    /// The tint color for this media type
    var tintColor: Color {
        FileItemTheme.tintColor(for: self)
    }
}
