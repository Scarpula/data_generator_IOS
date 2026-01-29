//
//  Theme.swift
//  HDMSDataGenerator
//
//  앱 테마 및 색상 정의
//

#if canImport(UIKit)
import SwiftUI

// MARK: - App Colors
extension Color {
    // Primary Colors
    static let appPrimary = Color(red: 0.3, green: 0.6, blue: 1.0)
    static let appSecondary = Color(red: 0.5, green: 0.4, blue: 0.9)
    static let appBackground = Color(red: 0.05, green: 0.05, blue: 0.15)
    static let appCardBackground = Color(red: 0.12, green: 0.12, blue: 0.2)

    // Sensor Colors
    static let sensorYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let sensorOrange = Color(red: 1.0, green: 0.5, blue: 0.2)
    static let sensorBlue = Color(red: 0.2, green: 0.6, blue: 1.0)

    // Status Colors
    static let statusGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let statusRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let statusYellow = Color(red: 1.0, green: 0.8, blue: 0.0)

    // Log Colors
    static let logBlue = Color(red: 0.3, green: 0.6, blue: 1.0)
    static let logGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let logYellow = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let logRed = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let logPurple = Color(red: 0.7, green: 0.4, blue: 1.0)

    // Preset Colors
    static let presetGreen = Color(red: 0.2, green: 0.7, blue: 0.4)
    static let presetBlue = Color(red: 0.3, green: 0.5, blue: 0.9)
    static let presetOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    // Helper to get color by name
    static func sensorColor(for type: SensorType) -> Color {
        switch type {
        case .current: return .sensorYellow
        case .temperature: return .sensorOrange
        case .humidity: return .sensorBlue
        }
    }

    static func statusColor(for state: ConnectionState) -> Color {
        switch state {
        case .connected: return .statusGreen
        case .connecting, .disconnecting: return .statusYellow
        case .disconnected, .error: return .statusRed
        }
    }

    static func logColor(for type: LogEntry.LogType) -> Color {
        switch type {
        case .info: return .logBlue
        case .success: return .logGreen
        case .warning: return .logYellow
        case .error: return .logRed
        case .send: return .logPurple
        }
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.1, green: 0.1, blue: 0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.15, blue: 0.25),
            Color(red: 0.1, green: 0.1, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func sensorGradient(for type: SensorType) -> LinearGradient {
        switch type {
        case .current:
            return LinearGradient(
                colors: [Color.sensorYellow.opacity(0.3), Color.sensorYellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .temperature:
            return LinearGradient(
                colors: [Color.sensorOrange.opacity(0.3), Color.sensorOrange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .humidity:
            return LinearGradient(
                colors: [Color.sensorBlue.opacity(0.3), Color.sensorBlue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.12))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
    }
}

struct GlassCardStyle: ViewModifier {
    var color: Color = .white

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func glassCard(color: Color = .white) -> some View {
        modifier(GlassCardStyle(color: color))
    }

    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .blue
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? color : Color.gray)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var color: Color = .blue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(12)
            .background(
                Circle()
                    .fill(color.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
#endif
