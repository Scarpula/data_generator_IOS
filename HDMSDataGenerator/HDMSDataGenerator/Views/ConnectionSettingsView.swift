//
//  ConnectionSettingsView.swift
//  HDMSDataGenerator
//
//  MQTT 연결 설정 화면
//

#if canImport(UIKit)
import SwiftUI

struct ConnectionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var config: MQTTConfig
    let onApplyPreset: (TopicPreset) -> Void

    @State private var brokerAddress: String = ""
    @State private var port: String = ""
    @State private var clientId: String = ""
    @State private var topicPrefix: String = ""

    var body: some View {
        NavigationView {
            Form {
                // Broker Settings Section
                Section {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        TextField("브로커 주소", text: $brokerAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                    }

                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        TextField("포트", text: $port)
                            .keyboardType(.numberPad)
                    }

                    HStack {
                        Image(systemName: "person.badge.key")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        TextField("클라이언트 ID", text: $clientId)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                } header: {
                    Text("MQTT 브로커 설정")
                } footer: {
                    Text("MQTT 브로커 연결 정보를 입력하세요.")
                }

                // Topic Settings Section
                Section {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.green)
                            .frame(width: 30)

                        TextField("토픽 프리픽스", text: $topicPrefix)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                    }

                    // Preview
                    HStack {
                        Text("토픽 형식:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(topicPrefix.isEmpty ? "HS" : topicPrefix)/{sensor_id}/data")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("토픽 설정")
                } footer: {
                    Text("운영: HS, 개발: AHS, 테스트: THS")
                }

                // Preset Buttons Section
                Section {
                    ForEach(TopicPreset.allCases) { preset in
                        Button(action: {
                            topicPrefix = preset.rawValue
                            onApplyPreset(preset)
                        }) {
                            HStack {
                                Circle()
                                    .fill(presetColor(for: preset))
                                    .frame(width: 12, height: 12)

                                Text(preset.displayName)
                                    .foregroundColor(.primary)

                                Spacer()

                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                if topicPrefix == preset.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("환경별 프리셋")
                }

                // Default Values Section
                Section {
                    Button(action: resetToDefaults) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("기본값으로 초기화")
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("연결 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveConfig()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadConfig()
            }
        }
    }

    // MARK: - Helper Methods

    private func loadConfig() {
        brokerAddress = config.brokerAddress
        port = String(config.port)
        clientId = config.clientId
        topicPrefix = config.topicPrefix
    }

    private func saveConfig() {
        config.brokerAddress = brokerAddress.trimmingCharacters(in: .whitespaces)
        config.port = Int(port) ?? 1883
        config.clientId = clientId.trimmingCharacters(in: .whitespaces)
        config.topicPrefix = topicPrefix.trimmingCharacters(in: .whitespaces)
    }

    private func resetToDefaults() {
        let defaults = MQTTConfig.default
        brokerAddress = defaults.brokerAddress
        port = String(defaults.port)
        clientId = defaults.clientId
        topicPrefix = defaults.topicPrefix
    }

    private func presetColor(for preset: TopicPreset) -> Color {
        switch preset {
        case .production: return .green
        case .development: return .blue
        case .test: return .orange
        }
    }
}

#if DEBUG
#Preview {
    ConnectionSettingsView(
        config: .constant(.default),
        onApplyPreset: { _ in }
    )
}
#endif
#endif
