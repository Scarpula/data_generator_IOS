//
//  ConnectionStatusCard.swift
//  HDMSDataGenerator
//
//  연결 상태 표시 카드
//

#if canImport(UIKit)
import SwiftUI

struct ConnectionStatusCard: View {
    let connectionState: ConnectionState
    let config: MQTTConfig
    let messageCount: Int
    let onSettingsTap: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Status Icon with animation
                ZStack {
                    Circle()
                        .fill(Color.statusColor(for: connectionState).opacity(0.2))
                        .frame(width: 50, height: 50)

                    if connectionState == .connecting {
                        Circle()
                            .stroke(Color.statusColor(for: connectionState), lineWidth: 2)
                            .frame(width: 50, height: 50)
                            .scaleEffect(isAnimating ? 1.3 : 1.0)
                            .opacity(isAnimating ? 0 : 1)
                            .animation(
                                Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }

                    Image(systemName: connectionState.icon)
                        .font(.title2)
                        .foregroundColor(Color.statusColor(for: connectionState))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("MQTT 연결 상태")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(connectionState.displayText)
                        .font(.headline)
                        .foregroundColor(Color.statusColor(for: connectionState))
                }

                Spacer()

                // Settings button
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }

            // Connection Info
            if connectionState.isConnected {
                Divider()
                    .background(Color.gray.opacity(0.3))

                HStack(spacing: 20) {
                    // Broker info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("브로커")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Text("\(config.brokerAddress):\(config.port)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }

                    Divider()
                        .frame(height: 30)
                        .background(Color.gray.opacity(0.3))

                    // Topic info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("토픽 형식")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Text("\(config.topicPrefix)/{id}/data")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.statusGreen)
                    }

                    Spacer()

                    // Message count
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("발행 메시지")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Text("\(messageCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.logPurple)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.statusColor(for: connectionState).opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        ConnectionStatusCard(
            connectionState: .connected,
            config: .default,
            messageCount: 42,
            onSettingsTap: { }
        )

        ConnectionStatusCard(
            connectionState: .connecting,
            config: .default,
            messageCount: 0,
            onSettingsTap: { }
        )

        ConnectionStatusCard(
            connectionState: .disconnected,
            config: .default,
            messageCount: 0,
            onSettingsTap: { }
        )
    }
    .padding()
    .background(Color.black)
}
#endif
#endif
