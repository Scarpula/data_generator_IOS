//
//  LogView.swift
//  HDMSDataGenerator
//
//  로그 출력 뷰
//

import SwiftUI

struct LogView: View {
    let logs: [LogEntry]
    let onClear: () -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.white)

                    Text("로그")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Log count badge
                    Text("\(logs.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.logBlue)
                        )

                    // Clear button
                    Button(action: onClear) {
                        Image(systemName: "trash")
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)

                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
            }
            .padding(16)

            if isExpanded {
                Divider()
                    .background(Color.gray.opacity(0.3))

                if logs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))

                        Text("로그가 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(logs) { entry in
                                LogEntryRow(entry: entry)
                            }
                        }
                        .padding(16)
                    }
                    .frame(maxHeight: 250)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Log Entry Row
struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Timestamp
            Text(entry.formattedTimestamp)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)

            // Type icon
            Image(systemName: entry.type.icon)
                .font(.caption)
                .foregroundColor(Color.logColor(for: entry.type))

            // Message
            Text(entry.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compact Log View (for smaller screens)
struct CompactLogView: View {
    let logs: [LogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(logs.prefix(5)) { entry in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.logColor(for: entry.type))
                        .frame(width: 6, height: 6)

                    Text(entry.message)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    VStack {
        LogView(
            logs: [
                LogEntry(timestamp: Date(), message: "MQTT 브로커에 연결되었습니다.", type: .success),
                LogEntry(timestamp: Date(), message: "전송: HS/21/data -> 전류센서TEST (8.52A)", type: .send),
                LogEntry(timestamp: Date(), message: "연결 시도 중...", type: .info),
                LogEntry(timestamp: Date(), message: "연결 실패: timeout", type: .error)
            ],
            onClear: { }
        )
    }
    .padding()
    .background(Color.black)
}
