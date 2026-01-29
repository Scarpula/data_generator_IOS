//
//  DataGenerator.swift
//  HDMSDataGenerator
//
//  실제와 유사한 센서 데이터 생성 유틸리티
//

import Foundation

class DataGenerator {
    // 센서별 현재 트렌드 (상승/하강/유지)
    private var sensorTrends: [SensorType: Double] = [
        .current: 0.0,
        .temperature: 0.0,
        .humidity: 0.0
    ]

    // 센서별 기준 값
    private var sensorBaseValues: [SensorType: Double] = [:]

    init() {
        // 기본값 초기화
        for type in SensorType.allCases {
            sensorBaseValues[type] = type.defaultValue
        }
    }

    // MARK: - Value Generation

    /// 실제와 유사한 센서 값 생성
    func generateRealisticValue(for type: SensorType, baseValue: Double) -> Double {
        // 트렌드 변화 확률 체크
        if Double.random(in: 0...1) < type.trendProbability {
            // 새로운 트렌드 설정 (-0.3 ~ 0.3)
            let trendOptions: [Double] = [-0.3, -0.1, 0.0, 0.1, 0.3]
            sensorTrends[type] = trendOptions.randomElement() ?? 0.0
        }

        // 기본 랜덤 변동 (-range ~ +range)
        let randomVariation = Double.random(in: -type.variationRange...type.variationRange)

        // 트렌드 적용 (작은 값으로 지속적인 변화)
        let trend = sensorTrends[type] ?? 0.0
        let trendVariation = trend * type.variationRange * 0.1

        // 최종 값 계산
        var newValue = baseValue + randomVariation + trendVariation

        // 센서별 합리적인 범위 제한
        newValue = max(type.minValue, min(type.maxValue, newValue))

        return roundValue(newValue, decimalPlaces: type.decimalPlaces)
    }

    /// 센서 데이터 생성
    func generateSensorData(sensor: Sensor, baseValue: Double) -> SensorData {
        let value = generateRealisticValue(for: sensor.type, baseValue: baseValue)
        return SensorData(sensor: sensor, value: value)
    }

    // MARK: - Helper Methods

    private func roundValue(_ value: Double, decimalPlaces: Int) -> Double {
        let multiplier = pow(10.0, Double(decimalPlaces))
        return (value * multiplier).rounded() / multiplier
    }

    /// 트렌드 리셋
    func resetTrends() {
        for type in SensorType.allCases {
            sensorTrends[type] = 0.0
        }
    }
}

// MARK: - Formatters
extension Double {
    func formatted(for sensorType: SensorType) -> String {
        return String(format: "%.\(sensorType.decimalPlaces)f", self)
    }
}
