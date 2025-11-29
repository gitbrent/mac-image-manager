//
//  VolumeManager.swift
//  MacImageManager
//
//  Created by Brent Ely on 10/5/25.
//

import Foundation
import SwiftUI
import Combine

enum VolumeType {
    case internalDrive
    case externalDrive
    case network
    case icloud
    case trash
    case user

    var icon: String {
        switch self {
        case .internalDrive:
            return "internaldrive"
        case .externalDrive:
            return "externaldrive"
        case .network:
            return "network"
        case .icloud:
            return "icloud"
        case .trash:
            return "trash"
        case .user:
            return "house"
        }
    }

    var displayName: String {
        switch self {
        case .internalDrive:
            return "Internal Drive"
        case .externalDrive:
            return "External Drive"
        case .network:
            return "Network"
        case .icloud:
            return "iCloud Drive"
        case .trash:
            return "Trash"
        case .user:
            return "Home"
        }
    }
}

struct VolumeInfo {
    let url: URL
    let name: String
    let type: VolumeType
    let isAvailable: Bool
    let freeSpace: Int64?
    let totalSpace: Int64?

    var icon: String {
        return type.icon
    }
}

struct PathComponent {
    let url: URL
    let name: String
    let icon: String
    let isVolume: Bool
    let volumeType: VolumeType?
    let isClickable: Bool

    init(url: URL, name: String, icon: String = "folder", isVolume: Bool = false, volumeType: VolumeType? = nil, isClickable: Bool = true) {
        self.url = url
        self.name = name
        self.icon = icon
        self.isVolume = isVolume
        self.volumeType = volumeType
        self.isClickable = isClickable
    }
}

@MainActor
class VolumeManager: ObservableObject {
    @Published var volumes: [VolumeInfo] = []
    @Published var iCloudDriveURL: URL?

    private let fileManager = FileManager.default

    init() {
        Task {
            await refreshVolumes()
        }
    }

    func refreshVolumes() async {
        var detectedVolumes: [VolumeInfo] = []

        // Get mounted volumes
        let mountedVolumeURLs = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeAvailableCapacityKey,
            .volumeTotalCapacityKey,
            .volumeIsLocalKey
        ], options: [.skipHiddenVolumes])

        for volumeURL in mountedVolumeURLs ?? [] {
            do {
                let resourceValues = try volumeURL.resourceValues(forKeys: [
                    .volumeNameKey,
                    .volumeIsRemovableKey,
                    .volumeIsEjectableKey,
                    .volumeAvailableCapacityKey,
                    .volumeTotalCapacityKey,
                    .volumeIsLocalKey
                ])

                let volumeName = resourceValues.volumeName ?? volumeURL.lastPathComponent
                let isRemovable = resourceValues.volumeIsRemovable ?? false
                let isLocal = resourceValues.volumeIsLocal ?? true
                let freeSpace = resourceValues.volumeAvailableCapacity.map { Int64($0) }
                let totalSpace = resourceValues.volumeTotalCapacity.map { Int64($0) }

                let volumeType: VolumeType
                if !isLocal {
                    volumeType = .network
                } else if isRemovable {
                    volumeType = .externalDrive
                } else {
                    volumeType = .internalDrive
                }

                let volumeInfo = VolumeInfo(
                    url: volumeURL,
                    name: volumeName,
                    type: volumeType,
                    isAvailable: true,
                    freeSpace: freeSpace,
                    totalSpace: totalSpace
                )

                detectedVolumes.append(volumeInfo)
            } catch {
                print("Error reading volume info for \(volumeURL): \(error)")
            }
        }

        // Add iCloud Drive if available
        await detectiCloudDrive()

        if let iCloudURL = iCloudDriveURL {
            let iCloudVolume = VolumeInfo(
                url: iCloudURL,
                name: "iCloud Drive",
                type: .icloud,
                isAvailable: true,
                freeSpace: nil,
                totalSpace: nil
            )
            detectedVolumes.append(iCloudVolume)
        }

        // Sort volumes: internal first, then external, then network, then iCloud
        detectedVolumes.sort { volume1, volume2 in
            let priority1 = volumeTypePriority(volume1.type)
            let priority2 = volumeTypePriority(volume2.type)

            if priority1 != priority2 {
                return priority1 < priority2
            }

            return volume1.name.localizedCaseInsensitiveCompare(volume2.name) == .orderedAscending
        }

        self.volumes = detectedVolumes
    }

    private func volumeTypePriority(_ type: VolumeType) -> Int {
        switch type {
        case .internalDrive: return 0
        case .externalDrive: return 1
        case .network: return 2
        case .icloud: return 3
        case .trash: return 4
        case .user: return 5
        }
    }

    private func detectiCloudDrive() async {
        // Try to find iCloud Drive location
        let iCloudContainerURL = fileManager.url(forUbiquityContainerIdentifier: nil)
        if let iCloudURL = iCloudContainerURL?.appendingPathComponent("Documents") {
            // Check if iCloud Drive is actually available
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: iCloudURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                self.iCloudDriveURL = iCloudURL
                return
            }
        }

        // Fallback: try the standard iCloud Drive location
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let standardiCloudURL = homeURL.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: standardiCloudURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            self.iCloudDriveURL = standardiCloudURL
        }
    }

    func getVolumeInfo(for url: URL) -> VolumeInfo? {
        // Normalize paths by resolving symlinks and standardizing
        let normalizedPath = url.resolvingSymlinksInPath().standardized.path

        // Find the volume with the longest matching prefix (most specific)
        var bestMatch: VolumeInfo? = nil
        var longestPrefixLength = 0

        for volume in volumes {
            let volumePath = volume.url.resolvingSymlinksInPath().standardized.path

            if normalizedPath.hasPrefix(volumePath) {
                let prefixLength = volumePath.count
                if prefixLength > longestPrefixLength {
                    bestMatch = volume
                    longestPrefixLength = prefixLength
                }
            }
        }

        return bestMatch
    }

    func generatePathComponents(for currentURL: URL) -> [PathComponent] {
        var components: [PathComponent] = []

        // Normalize the current URL by resolving symlinks
        let normalizedURL = currentURL.resolvingSymlinksInPath().standardized

        // Find the volume this path belongs to
        let volumeInfo = getVolumeInfo(for: normalizedURL)

        if let volume = volumeInfo {
            // Add the volume as the first component
            components.append(PathComponent(
                url: volume.url,
                name: volume.name,
                icon: volume.icon,
                isVolume: true,
                volumeType: volume.type
            ))

            // Get path components relative to the volume
            let normalizedVolumePath = volume.url.resolvingSymlinksInPath().standardized.path
            let normalizedCurrentPath = normalizedURL.path
            let relativePath = String(normalizedCurrentPath.dropFirst(normalizedVolumePath.count))
            let pathParts = relativePath.split(separator: "/").map(String.init)

            var buildingURL = volume.url
            for pathPart in pathParts {
                buildingURL = buildingURL.appendingPathComponent(pathPart)

                // Special handling for user directories
                let icon: String
                if buildingURL.lastPathComponent == "Desktop" {
                    icon = "desktopcomputer"
                } else if buildingURL.lastPathComponent == "Documents" {
                    icon = "doc"
                } else if buildingURL.lastPathComponent == "Downloads" {
                    icon = "arrow.down.circle"
                } else if buildingURL.lastPathComponent == "Pictures" {
                    icon = "photo"
                } else if buildingURL.lastPathComponent == "Movies" {
                    icon = "video"
                } else if buildingURL.lastPathComponent == "Music" {
                    icon = "music.note"
                } else {
                    icon = "folder"
                }

                components.append(PathComponent(
                    url: buildingURL,
                    name: pathPart,
                    icon: icon
                ))
            }
        } else {
            // Fallback: create components from the full path
            let pathParts = normalizedURL.pathComponents.dropFirst() // Remove the leading "/"
            var buildingURL = URL(fileURLWithPath: "/")

            for pathPart in pathParts {
                buildingURL = buildingURL.appendingPathComponent(pathPart)
                components.append(PathComponent(
                    url: buildingURL,
                    name: pathPart,
                    icon: "folder"
                ))
            }
        }

        return components
    }

    func getSiblingDirectories(for url: URL) async -> [FileItem] {
        let parentURL = url.deletingLastPathComponent()

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isReadableKey],
                options: [.skipsHiddenFiles]
            )

            var siblings: [FileItem] = []

            for siblingURL in contents {
                let resourceValues = try siblingURL.resourceValues(forKeys: [.isDirectoryKey, .isReadableKey])

                guard let isDirectory = resourceValues.isDirectory,
                      let isReadable = resourceValues.isReadable,
                      isDirectory && isReadable else {
                    continue
                }

                let fileItem = await FileItem(
                    url: siblingURL,
                    name: siblingURL.lastPathComponent,
                    isDirectory: true,
                    fileSize: 0,
                    modificationDate: Date(),
                    uti: nil
                )

                siblings.append(fileItem)
            }

            siblings.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return siblings

        } catch {
            print("Error getting sibling directories for \(url): \(error)")
            return []
        }
    }
}
