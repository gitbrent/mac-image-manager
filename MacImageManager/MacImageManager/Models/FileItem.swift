//
//  FileItem.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/27/25.
//

import Foundation
import UniformTypeIdentifiers
import AVFoundation
import ImageIO

// Media type enum for better type management
enum MediaType {
    case directory
    case staticImage
    case animatedGif
    case video
    case unknown

    var iconName: String {
        switch self {
        case .directory:    return "folder.fill"
        case .staticImage:  return "photo"
        case .animatedGif: return "rectangle.stack.badge.play"
        case .video:       return "film"
        case .unknown:     return "questionmark.square.dashed"
        }
    }
}

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let iconName: String
    let isDirectory: Bool
    let fileSize: Int
    let modificationDate: Date
    let uti: UTType?

    // Enhanced media properties
    let mediaType: MediaType
    let videoDuration: TimeInterval?    // For videos only
    let videoResolution: CGSize?        // For videos and images
    let gifFrameCount: Int?            // For GIFs only
    let gifFrameRate: Float?           // For GIFs only

    // Computed properties
    var isAnimatedGif: Bool { mediaType == .animatedGif }
    var isVideo: Bool { mediaType == .video }
    var isStaticImage: Bool { mediaType == .staticImage }

    // Formatted duration string for videos
    var formattedDuration: String? {
        guard let duration = videoDuration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // Formatted resolution string
    var formattedResolution: String? {
        guard let size = videoResolution else { return nil }
        return String(format: "%.0f × %.0f", size.width, size.height)
    }

    var formattedFileSize: String {
        if fileSize < 1024 {
            return "\(fileSize) B"
        }
        let kb = Double(fileSize) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024.0
        if mb < 1024 {
            return String(format: "%.1f MB", mb)
        }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }

    // Static function to determine icon name from UTType
    static func iconName(for uti: UTType?) -> String {
        guard let uti = uti else { return "photo" }

        if uti == .livePhoto {
            return "livephoto"
        } else if uti.conforms(to: .gif) {
            return "rectangle.stack.badge.play"
        } else if uti == .svg {
            return "square.on.square.squareshape.controlhandles"
        } else if uti.conforms(to: .rawImage) {
            return "camera.aperture"
        } else if uti == .heic || uti == .heif {
            return "photo"
        } else if uti.conforms(to: UTType.rawImage) || uti.conforms(to: UTType.image) {
            return "photo"
        } else if uti.conforms(to: UTType.movie) {
            return "film"
        }
        return "questionmark.square.dashed"
    }

    // Custom initializer with media metadata extraction
    init(url: URL, name: String, isDirectory: Bool, fileSize: Int, modificationDate: Date, uti: UTType?) async {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.fileSize = fileSize
        self.modificationDate = modificationDate
        self.uti = uti

        // Determine media type and extract metadata
        if isDirectory {
            self.mediaType = .directory
            self.iconName = MediaType.directory.iconName
            self.videoDuration = nil
            self.videoResolution = nil
            self.gifFrameCount = nil
            self.gifFrameRate = nil
        } else if let type = uti {
            if type.conforms(to: .movie) {
                self.mediaType = .video
                self.iconName = FileItem.iconName(for: type)

                // Extract video metadata
                let asset = AVURLAsset(url: url)
                self.videoDuration = try? await asset.load(.duration).seconds
                if let track = try? await asset.loadTracks(withMediaType: .video).first {
                    let size = try? await track.load(.naturalSize)
                    self.videoResolution = size
                } else {
                    self.videoResolution = nil
                }
                self.gifFrameCount = nil
                self.gifFrameRate = nil

            } else if type.conforms(to: .gif) {
                // Check if it's an animated GIF
                if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
                    let frameCount = CGImageSourceGetCount(source)
                    if frameCount > 1 {
                        self.mediaType = .animatedGif
                        self.iconName = FileItem.iconName(for: type)
                        self.gifFrameCount = frameCount

                        // Calculate frame rate from GIF metadata
                        if let properties = CGImageSourceCopyProperties(source, nil) as? [String: Any],
                           let gifProps = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                           let delayTime = gifProps[kCGImagePropertyGIFDelayTime as String] as? Float {
                            self.gifFrameRate = 1.0 / delayTime
                        } else {
                            self.gifFrameRate = 10.0 // Default to 10 fps
                        }

                        // Get resolution from first frame
                        if let imgProps = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                            let width = (imgProps[kCGImagePropertyPixelWidth as String] as? CGFloat) ?? 0
                            let height = (imgProps[kCGImagePropertyPixelHeight as String] as? CGFloat) ?? 0
                            self.videoResolution = CGSize(width: width, height: height)
                        } else {
                            self.videoResolution = nil
                        }
                    } else {
                        // Single frame GIF, treat as static image
                        self.mediaType = .staticImage
                        self.iconName = FileItem.iconName(for: type)
                        self.gifFrameCount = nil
                        self.gifFrameRate = nil
                        self.videoResolution = nil
                    }
                } else {
                    // Failed to read GIF, treat as unknown
                    self.mediaType = .unknown
                    self.iconName = MediaType.unknown.iconName
                    self.gifFrameCount = nil
                    self.gifFrameRate = nil
                    self.videoResolution = nil
                }
                self.videoDuration = nil

            } else if type.conforms(to: .image) {
                self.mediaType = .staticImage
                self.iconName = FileItem.iconName(for: type)

                // Get image resolution if possible
                if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                   let imgProps = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                    let width = (imgProps[kCGImagePropertyPixelWidth as String] as? CGFloat) ?? 0
                    let height = (imgProps[kCGImagePropertyPixelHeight as String] as? CGFloat) ?? 0
                    self.videoResolution = CGSize(width: width, height: height)
                } else {
                    self.videoResolution = nil
                }

                self.videoDuration = nil
                self.gifFrameCount = nil
                self.gifFrameRate = nil
            } else {
                self.mediaType = .unknown
                self.iconName = MediaType.unknown.iconName
                self.videoDuration = nil
                self.videoResolution = nil
                self.gifFrameCount = nil
                self.gifFrameRate = nil
            }
        } else {
            self.mediaType = .unknown
            self.iconName = MediaType.unknown.iconName
            self.videoDuration = nil
            self.videoResolution = nil
            self.gifFrameCount = nil
            self.gifFrameRate = nil
        }
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Equatable conformance
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
}
