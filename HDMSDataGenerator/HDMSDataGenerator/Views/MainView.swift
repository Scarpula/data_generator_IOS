//
//  MainView.swift
//  HDMSDataGenerator
//
//  메인 화면
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.appBackground
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardView(viewModel: viewModel)
                    .tabItem {
                        Label("대시보드", systemImage: "gauge.with.dots.needle.33percent")
                    }
                    .tag(0)

                // Sensors Tab
                SensorsView(viewModel: viewModel)
                    .tabItem {
                        Label("센서", systemImage: "sensor.fill")
                    }
                    .tag(1)

                // Logs Tab
                LogsView(viewModel: viewModel)
                    .tabItem {
                        Label("로그", systemImage: "doc.text.fill")
                    }
                    .tag(2)
            }
            .accentColor(.blue)
        }
        .sheet(isPresented: $viewModel.showConnectionSettings) {
            ConnectionSettingsView(
                config: $viewModel.config,
                onApplyPreset: { preset in
                    viewModel.applyTopicPreset(preset)
                }
            )
        }
        .sheet(isPresented: $viewModel.showSensorSettings) {
            SensorManagementView(
                sensors: $viewModel.sensors,
                onAddSensor: { id, name, type in
                    viewModel.addSensor(sensorId: id, name: name, type: type)
                },
                onRemoveSensor: { sensor in
                    viewModel.removeSensor(sensor)
                }
            )
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status Card
                    ConnectionStatusCard(
                        connectionState: viewModel.connectionState,
                        config: viewModel.config,
                        messageCount: viewModel.messageCount,
                        onSettingsTap: { viewModel.showConnectionSettings = true }
                    )

                    // Control Panel
                    ControlPanelView(
                        isGenerating: $viewModel.isGenerating,
                        publishInterval: $viewModel.publishInterval,
                        isConnected: viewModel.connectionState.isConnected,
                        onStart: { viewModel.startGeneration() },
                        onStop: { viewModel.stopGeneration() },
                        onSendSingle: { viewModel.sendSingleData() },
                        onConnect: { viewModel.connect() },
                        onDisconnect: { viewModel.disconnect() }
                    )

                    // Quick Stats
                    QuickStatsView(viewModel: viewModel)

                    // Recent Logs (Compact)
                    if !viewModel.logs.isEmpty {
                        RecentLogsCard(logs: viewModel.logs)
                    }
                }
                .padding()
            }
            .navigationTitle("HDMS 데이터 생성기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showSensorSettings = true }) {
                        Image(systemName: "sensor.fill")
                    }
                }
            }
        }
    }
}

// MARK: - Quick Stats View
struct QuickStatsView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        HStack(spacing: 12) {
            ForEach(SensorType.allCases) { type in
                StatCard(
                    type: type,
                    count: viewModel.sensors(for: type).count,
                    value: viewModel.sensorBaseValues[type] ?? type.defaultValue
                )
            }
        }
    }
}

struct StatCard: View {
    let type: SensorType
    let count: Int
    let value: Double

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(Color.sensorColor(for: type))

            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(type.name)
                .font(.caption2)
                .foregroundColor(.gray)

            Text("\(value.formatted(for: type))\(type.unit)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.sensorColor(for: type))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.sensorColor(for: type).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.sensorColor(for: type).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Recent Logs Card
struct RecentLogsCard: View {
    let logs: [LogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.gray)
                Text("최근 로그")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                Spacer()
            }

            CompactLogView(logs: Array(logs.prefix(5)))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.08))
        )
    }
}

// MARK: - Sensors View
struct SensorsView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(SensorType.allCases) { type in
                        SensorCardView(
                            sensorType: type,
                            sensors: viewModel.sensors(for: type),
                            baseValue: Binding(
                                get: { viewModel.sensorBaseValues[type] ?? type.defaultValue },
                                set: { viewModel.updateBaseValue(for: type, value: $0) }
                            ),
                            onUpdateValue: { value in
                                viewModel.updateBaseValue(for: type, value: value)
                            },
                            onRemoveSensor: { sensor in
                                viewModel.removeSensor(sensor)
                            },
                            onToggleSensor: { sensor in
                                viewModel.toggleSensor(sensor)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("센서 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showSensorSettings = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}

// MARK: - Logs View
struct LogsView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.appBackground
                    .ignoresSafeArea()

                VStack {
                    LogView(
                        logs: viewModel.logs,
                        onClear: { viewModel.clearLogs() }
                    )
                    .padding()
                }
            }
            .navigationTitle("로그")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.clearLogs() }) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

#Preview {
    MainView()
        .preferredColorScheme(.dark)
}
