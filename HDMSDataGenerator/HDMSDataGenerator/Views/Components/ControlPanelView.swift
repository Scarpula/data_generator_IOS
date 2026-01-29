//
//  ControlPanelView.swift
//  HDMSDataGenerator
//
//  데이터 생성 컨트롤 패널
//

import SwiftUI

struct ControlPanelView: View {
    @Binding var isGenerating: Bool
    @Binding var publishInterval: Double
    let isConnected: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onSendSingle: () -> Void
    let onConnect: () -> Void
    let onDisconnect: () -> Void

    @State private var showIntervalPicker = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.white)
                Text("데이터 생성 제어")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            // Connection Buttons
            HStack(spacing: 12) {
                // Connect Button
                Button(action: onConnect) {
                    HStack {
                        Image(systemName: "link")
                        Text("연결")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: .statusGreen, isEnabled: !isConnected))
                .disabled(isConnected)

                // Disconnect Button
                Button(action: onDisconnect) {
                    HStack {
                        Image(systemName: "link.badge.plus")
                            .symbolRenderingMode(.hierarchical)
                        Text("연결해제")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: .statusRed, isEnabled: isConnected))
                .disabled(!isConnected)
            }

            Divider()
                .background(Color.gray.opacity(0.3))

            // Interval Setting
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.gray)

                Text("발행 주기:")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Button(action: { showIntervalPicker = true }) {
                    HStack {
                        Text("\(String(format: "%.1f", publishInterval))초")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }

                Spacer()
            }

            // Generation Control Buttons
            HStack(spacing: 12) {
                // Start Button
                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("시작")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(
                    color: Color.statusGreen,
                    isEnabled: isConnected && !isGenerating
                ))
                .disabled(!isConnected || isGenerating)

                // Stop Button
                Button(action: onStop) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                        Text("중지")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(
                    color: Color.statusRed,
                    isEnabled: isGenerating
                ))
                .disabled(!isGenerating)

                // Single Send Button
                Button(action: onSendSingle) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("단발")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(
                    color: Color.logPurple,
                    isEnabled: isConnected
                ))
                .disabled(!isConnected)
            }

            // Generation Status
            if isGenerating {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .statusGreen))
                        .scaleEffect(0.8)

                    Text("데이터 생성 중...")
                        .font(.subheadline)
                        .foregroundColor(.statusGreen)

                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showIntervalPicker) {
            IntervalPickerView(interval: $publishInterval, isPresented: $showIntervalPicker)
                .presentationDetents([.height(300)])
        }
    }
}

// MARK: - Interval Picker View
struct IntervalPickerView: View {
    @Binding var interval: Double
    @Binding var isPresented: Bool

    let intervals: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0, 10.0, 30.0, 60.0]

    var body: some View {
        NavigationView {
            List {
                ForEach(intervals, id: \.self) { value in
                    Button(action: {
                        interval = value
                        isPresented = false
                    }) {
                        HStack {
                            Text(formatInterval(value))
                                .foregroundColor(.primary)

                            Spacer()

                            if interval == value {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("발행 주기 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func formatInterval(_ value: Double) -> String {
        if value >= 60 {
            return "\(Int(value / 60))분"
        } else if value == floor(value) {
            return "\(Int(value))초"
        } else {
            return "\(String(format: "%.1f", value))초"
        }
    }
}

#Preview {
    ControlPanelView(
        isGenerating: .constant(false),
        publishInterval: .constant(2.0),
        isConnected: true,
        onStart: { },
        onStop: { },
        onSendSingle: { },
        onConnect: { },
        onDisconnect: { }
    )
    .padding()
    .background(Color.black)
}
