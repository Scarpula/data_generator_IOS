//
//  MainViewModel.swift
//  HDMSDataGenerator
//
//  메인 화면 ViewModel
//

import Foundation
import Combine
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties

    // Connection
    @Published var config: MQTTConfig = .default
    @Published var connectionState: ConnectionState = .disconnected

    // Sensors
    @Published var sensors: [Sensor] = []
    @Published var sensorBaseValues: [SensorType: Double] = [:]

    // Generation State
    @Published var isGenerating: Bool = false
    @Published var publishInterval: Double = 2.0
    @Published var messageCount: Int = 0

    // Logs
    @Published var logs: [LogEntry] = []
    @Published var showLogs: Bool = true

    // UI State
    @Published var showConnectionSettings: Bool = false
    @Published var showSensorSettings: Bool = false
    @Published var showAddSensor: Bool = false
    @Published var selectedSensorType: SensorType = .current

    // MARK: - Private Properties

    private let mqttService: MQTTService
    private let dataGenerator: DataGenerator
    private var generatorTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.mqttService = MQTTService()
        self.dataGenerator = DataGenerator()

        setupBindings()
        loadDefaultSensors()
        initializeBaseValues()
    }

    private func setupBindings() {
        mqttService.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)

        mqttService.onLog = { [weak self] message, type in
            self?.addLog(message, type: type)
        }

        mqttService.onMessagePublished = { [weak self] _ in
            Task { @MainActor in
                self?.messageCount += 1
            }
        }
    }

    private func loadDefaultSensors() {
        sensors = [
            Sensor(sensorId: 21, name: "전류센서TEST", type: .current),
            Sensor(sensorId: 25, name: "온도센서TEST", type: .temperature),
            Sensor(sensorId: 26, name: "습도센서TEST", type: .humidity)
        ]
    }

    private func initializeBaseValues() {
        for type in SensorType.allCases {
            sensorBaseValues[type] = type.defaultValue
        }
    }

    // MARK: - Connection Methods

    func connect() {
        mqttService.connect(config: config)
    }

    func disconnect() {
        stopGeneration()
        mqttService.disconnect()
    }

    func applyTopicPreset(_ preset: TopicPreset) {
        config.topicPrefix = preset.rawValue
        addLog("토픽 프리픽스 변경: \(preset.displayName)", type: .info)
    }

    // MARK: - Generation Methods

    func startGeneration() {
        guard connectionState.isConnected else {
            addLog("먼저 MQTT 브로커에 연결하세요.", type: .warning)
            return
        }

        isGenerating = true
        addLog("데이터 생성을 시작합니다.", type: .success)

        generatorTask = Task {
            while !Task.isCancelled && isGenerating {
                await sendAllSensorData()
                try? await Task.sleep(nanoseconds: UInt64(publishInterval * 1_000_000_000))
            }
        }
    }

    func stopGeneration() {
        isGenerating = false
        generatorTask?.cancel()
        generatorTask = nil
        addLog("데이터 생성을 중지합니다.", type: .info)
    }

    func sendSingleData() {
        guard connectionState.isConnected else {
            addLog("먼저 MQTT 브로커에 연결하세요.", type: .warning)
            return
        }

        Task {
            await sendAllSensorData()
        }
    }

    private func sendAllSensorData() async {
        for sensor in sensors where sensor.isEnabled {
            let baseValue = sensorBaseValues[sensor.type] ?? sensor.type.defaultValue
            let sensorData = dataGenerator.generateSensorData(sensor: sensor, baseValue: baseValue)

            mqttService.publishSensorData(sensorData, topicPrefix: config.topicPrefix)

            let icon = sensor.type.icon
            let valueStr = sensorData.value.formatted(for: sensor.type)
            addLog("전송: \(config.topic(for: sensor.sensorId)) -> \(sensor.name) (\(valueStr)\(sensor.type.unit))", type: .send)
        }
    }

    // MARK: - Sensor Management

    func addSensor(sensorId: Int, name: String, type: SensorType) {
        // 중복 ID 체크
        if sensors.contains(where: { $0.sensorId == sensorId && $0.type == type }) {
            addLog("센서 ID \(sensorId)는 이미 존재합니다.", type: .error)
            return
        }

        let newSensor = Sensor(sensorId: sensorId, name: name, type: type)
        sensors.append(newSensor)
        addLog("\(type.name) 추가됨: ID \(sensorId), 이름 '\(name)'", type: .success)
    }

    func removeSensor(_ sensor: Sensor) {
        sensors.removeAll { $0.id == sensor.id }
        addLog("\(sensor.type.name) 삭제됨: ID \(sensor.sensorId)", type: .info)
    }

    func toggleSensor(_ sensor: Sensor) {
        if let index = sensors.firstIndex(where: { $0.id == sensor.id }) {
            sensors[index].isEnabled.toggle()
        }
    }

    func updateBaseValue(for type: SensorType, value: Double) {
        sensorBaseValues[type] = value
        addLog("\(type.name) 기준값 업데이트: \(value.formatted(for: type))\(type.unit)", type: .info)
    }

    func sensors(for type: SensorType) -> [Sensor] {
        sensors.filter { $0.type == type }
    }

    // MARK: - Logging

    func addLog(_ message: String, type: LogEntry.LogType) {
        let entry = LogEntry(timestamp: Date(), message: message, type: type)
        logs.insert(entry, at: 0)

        // 로그 최대 100개 유지
        if logs.count > 100 {
            logs.removeLast()
        }
    }

    func clearLogs() {
        logs.removeAll()
    }

    // MARK: - Computed Properties

    var canStartGeneration: Bool {
        connectionState.isConnected && !isGenerating
    }

    var canStopGeneration: Bool {
        isGenerating
    }

    var topicFormat: String {
        "\(config.topicPrefix)/{sensor_id}/data"
    }
}
