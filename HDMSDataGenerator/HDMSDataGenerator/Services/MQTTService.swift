//
//  MQTTService.swift
//  HDMSDataGenerator
//
//  MQTT 클라이언트 서비스 (CocoaMQTT 기반)
//

#if canImport(UIKit)
import Foundation
import Combine
import CocoaMQTT

// MARK: - MQTT Service Protocol
protocol MQTTServiceProtocol {
    var connectionState: ConnectionState { get }
    var connectionStatePublisher: Published<ConnectionState>.Publisher { get }

    func connect(config: MQTTConfig)
    func disconnect()
    func publish(topic: String, message: String, qos: CocoaMQTTQoS)
}

// MARK: - MQTT Service Implementation
class MQTTService: NSObject, ObservableObject, MQTTServiceProtocol {
    @Published private(set) var connectionState: ConnectionState = .disconnected
    var connectionStatePublisher: Published<ConnectionState>.Publisher { $connectionState }

    private var mqttClient: CocoaMQTT?
    private var currentConfig: MQTTConfig?

    var onMessagePublished: ((Int) -> Void)?
    var onLog: ((String, LogEntry.LogType) -> Void)?

    override init() {
        super.init()
    }

    // MARK: - Connection Methods

    func connect(config: MQTTConfig) {
        guard connectionState != .connected && connectionState != .connecting else {
            onLog?("이미 연결되어 있거나 연결 중입니다.", .warning)
            return
        }

        currentConfig = config
        connectionState = .connecting

        // Create unique client ID with timestamp
        let uniqueClientId = "\(config.clientId)_\(Int(Date().timeIntervalSince1970))"

        mqttClient = CocoaMQTT(clientID: uniqueClientId, host: config.brokerAddress, port: UInt16(config.port))

        guard let client = mqttClient else {
            connectionState = .error("클라이언트 생성 실패")
            return
        }

        client.keepAlive = 60
        client.autoReconnect = false
        client.cleanSession = true
        client.delegate = self

        onLog?("MQTT 브로커 연결 시도: \(config.brokerAddress):\(config.port)", .info)

        let success = client.connect()
        if !success {
            connectionState = .error("연결 시작 실패")
            onLog?("MQTT 연결 시작 실패", .error)
        }
    }

    func disconnect() {
        guard connectionState == .connected else { return }

        connectionState = .disconnecting
        mqttClient?.disconnect()
    }

    func publish(topic: String, message: String, qos: CocoaMQTTQoS = .qos1) {
        guard connectionState == .connected, let client = mqttClient else {
            onLog?("연결되지 않은 상태에서 발행 시도", .warning)
            return
        }

        client.publish(topic, withString: message, qos: qos, retained: false)
    }

    // MARK: - Helper Methods

    func publishSensorData(_ data: SensorData, topicPrefix: String) {
        let topic = "\(topicPrefix)/\(data.sensorId)/data"

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let jsonData = try encoder.encode(data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                publish(topic: topic, message: jsonString, qos: .qos1)
            }
        } catch {
            onLog?("JSON 인코딩 오류: \(error.localizedDescription)", .error)
        }
    }
}

// MARK: - CocoaMQTTDelegate
extension MQTTService: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        DispatchQueue.main.async { [weak self] in
            if ack == .accept {
                self?.connectionState = .connected
                self?.onLog?("MQTT 브로커에 연결되었습니다.", .success)
            } else {
                self?.connectionState = .error("연결 거부: \(ack)")
                self?.onLog?("MQTT 연결 거부: \(ack)", .error)
            }
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        DispatchQueue.main.async { [weak self] in
            self?.onMessagePublished?(Int(id))
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        // Message acknowledged
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        // Not used in this app (publisher only)
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        // Not used in this app
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        // Not used in this app
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        // Ping sent
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        // Pong received
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = err {
                self?.connectionState = .error(error.localizedDescription)
                self?.onLog?("MQTT 연결 해제 (오류): \(error.localizedDescription)", .error)
            } else {
                self?.connectionState = .disconnected
                self?.onLog?("MQTT 브로커 연결이 해제되었습니다.", .info)
            }
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connecting:
                self?.connectionState = .connecting
            case .connected:
                // Handled in didConnectAck
                break
            case .disconnected:
                if self?.connectionState != .error("") {
                    self?.connectionState = .disconnected
                }
            @unknown default:
                break
            }
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}
#endif
