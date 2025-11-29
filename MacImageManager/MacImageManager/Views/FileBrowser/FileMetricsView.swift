//
//  FileMetricsView.swift
//  MacImageManager
//
//  Created by Brent Ely on 11/29/25.
//

import SwiftUI
import Charts

struct FileMetricsView: View {
    @EnvironmentObject var browserModel: BrowserModel

    // Computed property for metrics data with percentages
    private var metricsWithPercentages: [(mediaType: MediaType, count: Int, totalSize: Int, percentage: Double)] {
        let data = browserModel.metricsDataWithSize
        let totalCount = data.reduce(0) { $0 + $1.count }
        guard totalCount > 0 else { return [] }

        return data.map { item in
            let percentage = Double(item.count) / Double(totalCount) * 100.0
            return (mediaType: item.mediaType, count: item.count, totalSize: item.totalSize, percentage: percentage)
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        }
        let kb = Double(bytes) / 1024.0
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

    var body: some View {
        if browserModel.showDetailedMetrics {
            detailedMetricsView
        } else {
            summaryMetricsView
        }
    }

    // Summary view (existing icon + count layout)
    private var summaryMetricsView: some View {
        HStack(spacing: 14) {
            Spacer()

            ForEach(browserModel.metricsData, id: \.mediaType) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.mediaType.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(item.mediaType.tintColor)
                    Text("\(item.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // Folders count
            if browserModel.folderCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: MediaType.directory.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(MediaType.directory.tintColor)
                    Text("\(browserModel.folderCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }

    // Detailed view with Swift Charts
    private var detailedMetricsView: some View {
        VStack(spacing: 8) {
            /* 20251129: WORKS! but unused for now
			// Legend
            HStack(spacing: 12) {
                ForEach(metricsWithPercentages, id: \.mediaType) { item in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.mediaType.tintColor)
                            .frame(width: 12, height: 12)
                        Text(item.mediaType.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 1)
			*/

            // Stacked bar chart
            Chart(metricsWithPercentages, id: \.mediaType) { item in
                BarMark(
                    x: .value("Count", item.count)
                )
                .foregroundStyle(item.mediaType.tintColor)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 18)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Details table
            VStack(spacing: 4) {
                ForEach(metricsWithPercentages, id: \.mediaType) { item in
                    HStack {
                        // Color dot + label
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.mediaType.tintColor)
                                .frame(width: 8, height: 8)
                            Text(item.mediaType.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Text("\(item.count)")
							.font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)

                        Text("(\(String(format: "%.1f", item.percentage))%)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text(formatFileSize(item.totalSize))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 12)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - MediaType Extensions

extension MediaType {
    var displayName: String {
        switch self {
        case .directory:    return "Folders"
        case .staticImage:  return "Images"
        case .animatedGif:  return "GIFs"
        case .video:        return "Videos"
        case .unknown:      return "Other"
        }
    }

    static func fromDisplayName(_ name: String) -> MediaType? {
        switch name {
        case "Folders":     return .directory
        case "Images":      return .staticImage
        case "GIFs":        return .animatedGif
        case "Videos":      return .video
        case "Other":       return .unknown
        default:            return nil
        }
    }
}

#Preview("Summary") {
    FileMetricsView()
        .environmentObject(BrowserModel.preview)
        .frame(width: 300, height: 60)
}

#Preview("Detailed") {
    FileMetricsView()
        .environmentObject({
            let model = BrowserModel.preview
            model.showDetailedMetrics = true
            return model
        }())
        .frame(width: 300, height: 250)
}
