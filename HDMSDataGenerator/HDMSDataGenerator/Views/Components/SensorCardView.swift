//
//  SensorCardView.swift
//  HDMSDataGenerator
//
//  센서 타입별 카드 뷰
//

#if canImport(UIKit)
import SwiftUI

struct SensorCardView: View {
    let sensorType: SensorType
    let sensors: [Sensor]
    @Binding var baseValue: Double
    let onUpdateValue: (Double) -> Void
    let onRemoveSensor: (Sensor) -> Void
    let onToggleSensor: (Sensor) -> Void

    @State private var inputValue: String = ""
    @State private var showValueEditor: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: sensorType.icon)
                    .font(.title2)
                    .foregroundColor(Color.sensorColor(for: sensorType))

                Text(sensorType.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("(Type \(sensorType.rawValue))")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                // Sensor count badge
                Text("\(sensors.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.sensorColor(for: sensorType))
                    )
            }

            Divider()
                .background(Color.sensorColor(for: sensorType).opacity(0.3))

            // Sensor List
            if sensors.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text("등록된 센서가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(sensors) { sensor in
                    SensorRowView(
                        sensor: sensor,
                        onToggle: { onToggleSensor(sensor) },
                        onRemove: { onRemoveSensor(sensor) }
                    )
                }
            }

            Divider()
                .background(Color.sensorColor(for: sensorType).opacity(0.3))

            // Value Settings
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Color.sensorColor(for: sensorType))
                    Text("기준값 설정")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                HStack(spacing: 12) {
                    // Value display
                    HStack {
                        Text(baseValue.formatted(for: sensorType))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color.sensorColor(for: sensorType))

                        Text(sensorType.unit)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Edit button
                    Button(action: {
                        inputValue = baseValue.formatted(for: sensorType)
                        showValueEditor = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.sensorColor(for: sensorType))
                    }
                }

                // Slider
                VStack(spacing: 4) {
                    Slider(
                        value: $baseValue,
                        in: sensorType.minValue...min(sensorType.maxValue, sensorType.defaultValue * 3),
                        step: sensorType.decimalPlaces == 2 ? 0.1 : 1.0
                    )
                    .accentColor(Color.sensorColor(for: sensorType))
                    .onChange(of: baseValue) { _, newValue in
                        onUpdateValue(newValue)
                    }

                    HStack {
                        Text(sensorType.minValue.formatted(for: sensorType))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(min(sensorType.maxValue, sensorType.defaultValue * 3).formatted(for: sensorType))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient.sensorGradient(for: sensorType))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.sensorColor(for: sensorType).opacity(0.3), lineWidth: 1)
                )
        )
        .alert("기준값 입력", isPresented: $showValueEditor) {
            TextField("값 입력", text: $inputValue)
                .keyboardType(.decimalPad)
            Button("취소", role: .cancel) { }
            Button("적용") {
                if let value = Double(inputValue) {
                    baseValue = min(max(value, sensorType.minValue), sensorType.maxValue)
                    onUpdateValue(baseValue)
                }
            }
        } message: {
            Text("\(sensorType.name) 기준값을 입력하세요 (\(sensorType.unit))")
        }
    }
}

// MARK: - Sensor Row View
struct SensorRowView: View {
    let sensor: Sensor
    let onToggle: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(sensor.isEnabled ? Color.statusGreen : Color.gray)
                .frame(width: 8, height: 8)

            // Sensor info
            VStack(alignment: .leading, spacing: 2) {
                Text("ID \(sensor.sensorId)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.sensorColor(for: sensor.type))

                Text(sensor.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            Spacer()

            // Toggle button
            Button(action: onToggle) {
                Image(systemName: sensor.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(sensor.isEnabled ? Color.statusGreen : Color.gray)
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "trash.circle.fill")
                    .foregroundColor(Color.statusRed.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    SensorCardView(
        sensorType: .current,
        sensors: [
            Sensor(sensorId: 21, name: "전류센서TEST", type: .current)
        ],
        baseValue: .constant(8.5),
        onUpdateValue: { _ in },
        onRemoveSensor: { _ in },
        onToggleSensor: { _ in }
    )
    .padding()
    .background(Color.black)
}
#endif
#endif
