//
//  Sensor.swift
//  HDMSDataGenerator
//
//  HDMS MQTT 센서 데이터 생성기 - iOS
//

import Foundation

// MARK: - Sensor Type
enum SensorType: Int, CaseIterable, Codable, Identifiable {
    case current = 1
    case temperature = 2
    case humidity = 3

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .current: return "전류센서"
        case .temperature: return "온도센서"
        case .humidity: return "습도센서"
        }
    }

    var icon: String {
        switch self {
        case .current: return "bolt.fill"
        case .temperature: return "thermometer.medium"
        case .humidity: return "drop.fill"
        }
    }

    var unit: String {
        switch self {
        case .current: return "A"
        case .temperature: return "°C"
        case .humidity: return "%"
        }
    }

    var color: String {
        switch self {
        case .current: return "sensorYellow"
        case .temperature: return "sensorOrange"
        case .humidity: return "sensorBlue"
        }
    }

    var defaultValue: Double {
        switch self {
        case .current: return 8.5
        case .temperature: return 25.0
        case .humidity: return 55.0
        }
    }

    var variationRange: Double {
        switch self {
        case .current: return 0.5
        case .temperature: return 2.0
        case .humidity: return 3.0
        }
    }

    var trendProbability: Double {
        switch self {
        case .current: return 0.1
        case .temperature: return 0.05
        case .humidity: return 0.08
        }
    }

    var minValue: Double {
        switch self {
        case .current: return 0.0
        case .temperature: return -50.0
        case .humidity: return 0.0
        }
    }

    var maxValue: Double {
        switch self {
        case .current: return 999.0
        case .temperature: return 300.0
        case .humidity: return 100.0
        }
    }

    var decimalPlaces: Int {
        switch self {
        case .current: return 2
        case .temperature: return 1
        case .humidity: return 1
        }
    }
}

// MARK: - Sensor Model
struct Sensor: Identifiable, Codable, Equatable {
    let id: UUID
    var sensorId: Int
    var name: String
    var type: SensorType
    var isEnabled: Bool

    init(sensorId: Int, name: String, type: SensorType, isEnabled: Bool = true) {
        self.id = UUID()
        self.sensorId = sensorId
        self.name = name
        self.type = type
        self.isEnabled = isEnabled
    }

    static func == (lhs: Sensor, rhs: Sensor) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sensor Data (Published to MQTT)
struct SensorData: Codable {
    let sensorId: Int
    let sensorType: Int
    let sensorName: String
    let timestamp: String
    let isConnected: Bool
    let status: String
    let value: Double
    let unit: String

    // Sensor-specific fields
    var current: Double?
    var temperature: Double?
    var humidity: Double?

    enum CodingKeys: String, CodingKey {
        case sensorId = "sensor_id"
        case sensorType = "sensor_type"
        case sensorName = "sensor_name"
        case timestamp
        case isConnected = "is_connected"
        case status
        case value
        case unit
        case current
        case temperature
        case humidity
    }

    init(sensor: Sensor, value: Double) {
        self.sensorId = sensor.sensorId
        self.sensorType = sensor.type.rawValue
        self.sensorName = sensor.name
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.isConnected = true
        self.status = "normal"
        self.value = value
        self.unit = sensor.type.unit

        switch sensor.type {
        case .current:
            self.current = value
        case .temperature:
            self.temperature = value
        case .humidity:
            self.humidity = value
        }
    }
}

// MARK: - Sensor Value State
struct SensorValueState {
    var baseValue: Double
    var currentTrend: Double = 0.0

    init(type: SensorType) {
        self.baseValue = type.defaultValue
    }
}
