//
//  MQTTConfig.swift
//  HDMSDataGenerator
//
//  MQTT 연결 설정 모델
//

import Foundation

// MARK: - Topic Preset
enum TopicPreset: String, CaseIterable, Identifiable {
    case production = "HS"
    case development = "AHS"
    case test = "THS"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .production: return "운영 (HS)"
        case .development: return "개발 (AHS)"
        case .test: return "테스트 (THS)"
        }
    }

    var description: String {
        switch self {
        case .production: return "운영 환경"
        case .development: return "개발 환경"
        case .test: return "테스트 환경"
        }
    }

    var color: String {
        switch self {
        case .production: return "presetGreen"
        case .development: return "presetBlue"
        case .test: return "presetOrange"
        }
    }
}

// MARK: - MQTT Configuration
struct MQTTConfig: Codable {
    var brokerAddress: String
    var port: Int
    var clientId: String
    var topicPrefix: String
    var publishInterval: Double

    init(
        brokerAddress: String = "139.150.72.51",
        port: Int = 1883,
        clientId: String = "hdms_ios_generator",
        topicPrefix: String = "HS",
        publishInterval: Double = 2.0
    ) {
        self.brokerAddress = brokerAddress
        self.port = port
        self.clientId = clientId
        self.topicPrefix = topicPrefix
        self.publishInterval = publishInterval
    }

    func topic(for sensorId: Int) -> String {
        return "\(topicPrefix)/\(sensorId)/data"
    }

    static let `default` = MQTTConfig()
}

// MARK: - Connection State
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error(String)

    var displayText: String {
        switch self {
        case .disconnected: return "연결 끊김"
        case .connecting: return "연결 중..."
        case .connected: return "연결됨"
        case .disconnecting: return "연결 해제 중..."
        case .error(let message): return "오류: \(message)"
        }
    }

    var icon: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        case .connected: return "wifi"
        case .disconnecting: return "wifi.exclamationmark"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .disconnected: return "statusRed"
        case .connecting: return "statusYellow"
        case .connected: return "statusGreen"
        case .disconnecting: return "statusYellow"
        case .error: return "statusRed"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// MARK: - Log Entry
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType

    enum LogType {
        case info
        case success
        case warning
        case error
        case send

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .send: return "paperplane.fill"
            }
        }

        var color: String {
            switch self {
            case .info: return "logBlue"
            case .success: return "logGreen"
            case .warning: return "logYellow"
            case .error: return "logRed"
            case .send: return "logPurple"
            }
        }
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
