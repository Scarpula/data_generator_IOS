//
//  SensorManagementView.swift
//  HDMSDataGenerator
//
//  센서 관리 화면
//

#if canImport(UIKit)
import SwiftUI

struct SensorManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sensors: [Sensor]
    let onAddSensor: (Int, String, SensorType) -> Void
    let onRemoveSensor: (Sensor) -> Void

    @State private var showAddSensor = false
    @State private var selectedType: SensorType = .current

    var body: some View {
        NavigationView {
            List {
                // Add Sensor Section
                Section {
                    Button(action: { showAddSensor = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("새 센서 추가")
                                .foregroundColor(.primary)
                        }
                    }
                }

                // Sensors by Type
                ForEach(SensorType.allCases) { type in
                    Section {
                        let typeSensors = sensors.filter { $0.type == type }

                        if typeSensors.isEmpty {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.gray)
                                Text("등록된 센서가 없습니다")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            ForEach(typeSensors) { sensor in
                                SensorListRow(sensor: sensor)
                            }
                            .onDelete { indexSet in
                                deleteSensors(at: indexSet, type: type)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(Color.sensorColor(for: type))
                            Text("\(type.name) (Type \(type.rawValue))")
                        }
                    }
                }
            }
            .navigationTitle("센서 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddSensor) {
                AddSensorView(
                    onAdd: { sensorId, name, type in
                        onAddSensor(sensorId, name, type)
                        showAddSensor = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func deleteSensors(at offsets: IndexSet, type: SensorType) {
        let typeSensors = sensors.filter { $0.type == type }
        for index in offsets {
            if index < typeSensors.count {
                onRemoveSensor(typeSensors[index])
            }
        }
    }
}

// MARK: - Sensor List Row
struct SensorListRow: View {
    let sensor: Sensor

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(sensor.isEnabled ? Color.statusGreen : Color.gray)
                .frame(width: 10, height: 10)

            // Sensor info
            VStack(alignment: .leading, spacing: 4) {
                Text(sensor.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text("ID: \(sensor.sensorId)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Type badge
            Text(sensor.type.unit)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.sensorColor(for: sensor.type))
                )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Sensor View
struct AddSensorView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Int, String, SensorType) -> Void

    @State private var sensorId: String = ""
    @State private var sensorName: String = ""
    @State private var selectedType: SensorType = .current

    @FocusState private var focusedField: Field?

    enum Field {
        case id, name
    }

    var body: some View {
        NavigationView {
            Form {
                // Sensor Type Selection
                Section {
                    Picker("센서 타입", selection: $selectedType) {
                        ForEach(SensorType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.name)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("센서 타입 선택")
                }

                // Sensor Info
                Section {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(Color.sensorColor(for: selectedType))
                            .frame(width: 30)

                        TextField("센서 ID (숫자)", text: $sensorId)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .id)
                    }

                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(Color.sensorColor(for: selectedType))
                            .frame(width: 30)

                        TextField("센서 이름", text: $sensorName)
                            .focused($focusedField, equals: .name)
                    }
                } header: {
                    Text("센서 정보")
                } footer: {
                    Text("센서 ID는 고유한 숫자여야 합니다.")
                }

                // Preview
                Section {
                    HStack {
                        Image(systemName: selectedType.icon)
                            .font(.title2)
                            .foregroundColor(Color.sensorColor(for: selectedType))

                        VStack(alignment: .leading) {
                            Text(sensorName.isEmpty ? "센서 이름" : sensorName)
                                .fontWeight(.medium)
                            Text("ID: \(sensorId.isEmpty ? "0" : sensorId)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text(selectedType.unit)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.sensorColor(for: selectedType))
                            )
                    }
                } header: {
                    Text("미리보기")
                }
            }
            .navigationTitle("센서 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        addSensor()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                focusedField = .id
            }
        }
    }

    private var isValid: Bool {
        guard let id = Int(sensorId), id > 0 else { return false }
        return !sensorName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addSensor() {
        guard let id = Int(sensorId) else { return }
        let name = sensorName.trimmingCharacters(in: .whitespaces)
        onAdd(id, name, selectedType)
    }
}

#if DEBUG
#Preview {
    SensorManagementView(
        sensors: .constant([
            Sensor(sensorId: 21, name: "전류센서TEST", type: .current),
            Sensor(sensorId: 25, name: "온도센서TEST", type: .temperature)
        ]),
        onAddSensor: { _, _, _ in },
        onRemoveSensor: { _ in }
    )
}
#endif
#endif
