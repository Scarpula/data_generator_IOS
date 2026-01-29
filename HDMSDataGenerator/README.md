# HDMS MQTT 센서 데이터 생성기 - iOS

Python Tkinter 버전 `mqtt_data_generator_v2.py`를 iOS 앱으로 변환한 버전입니다.

## 기능

### 원본과 동일한 기능
- **MQTT 연결 관리**: 브로커 주소, 포트, 클라이언트 ID 설정
- **토픽 프리픽스**: 운영(HS), 개발(AHS), 테스트(THS) 환경 지원
- **3가지 센서 타입 지원**:
  - ⚡ 전류센서 (Type 1): A 단위
  - 🌡️ 온도센서 (Type 2): °C 단위
  - 💧 습도센서 (Type 3): % 단위
- **센서 관리**: 동적 센서 추가/삭제
- **데이터 생성**: 실제와 유사한 변동값 생성 (트렌드 + 랜덤)
- **발행 제어**: 자동 발행 (주기 설정) / 단발 전송
- **로그 기록**: 모든 이벤트 로깅

### iOS 버전 개선 사항
- **모던 UI**: SwiftUI 기반 다크 테마 디자인
- **탭 기반 네비게이션**: 대시보드, 센서, 로그 탭
- **실시간 시각화**: 연결 상태 애니메이션
- **슬라이더 컨트롤**: 센서 기준값 직관적 조절
- **그라데이션 카드 UI**: 센서 타입별 색상 구분

## 프로젝트 구조

```
HDMSDataGenerator/
├── HDMSDataGenerator/
│   ├── HDMSDataGeneratorApp.swift    # 앱 엔트리 포인트
│   ├── Info.plist                     # 앱 설정
│   │
│   ├── Models/
│   │   ├── Sensor.swift               # 센서 모델
│   │   └── MQTTConfig.swift           # MQTT 설정 모델
│   │
│   ├── Services/
│   │   └── MQTTService.swift          # MQTT 클라이언트 서비스
│   │
│   ├── ViewModels/
│   │   └── MainViewModel.swift        # 메인 ViewModel
│   │
│   ├── Views/
│   │   ├── MainView.swift             # 메인 화면
│   │   ├── ConnectionSettingsView.swift  # 연결 설정
│   │   ├── SensorManagementView.swift    # 센서 관리
│   │   │
│   │   └── Components/
│   │       ├── SensorCardView.swift       # 센서 카드
│   │       ├── ConnectionStatusCard.swift # 연결 상태
│   │       ├── ControlPanelView.swift     # 컨트롤 패널
│   │       └── LogView.swift              # 로그 뷰
│   │
│   ├── Utils/
│   │   ├── Theme.swift                # 테마 및 색상
│   │   └── DataGenerator.swift        # 데이터 생성기
│   │
│   └── Resources/
│       └── Assets.xcassets/           # 이미지 리소스
│
├── Package.swift                      # SPM 의존성
└── README.md
```

## 빌드 방법

### 요구 사항
- macOS 13.0+
- Xcode 15.0+
- iOS 16.0+ (배포 대상)

### Xcode 프로젝트 생성

1. **Xcode에서 새 프로젝트 생성**:
   - File > New > Project
   - iOS > App 선택
   - Product Name: `HDMSDataGenerator`
   - Interface: SwiftUI
   - Language: Swift

2. **소스 파일 추가**:
   - 기존 그룹 삭제 후 `HDMSDataGenerator` 폴더 전체를 프로젝트에 드래그

3. **Swift Package Manager 의존성 추가**:
   - File > Add Package Dependencies
   - URL 입력: `https://github.com/emqx/CocoaMQTT.git`
   - Version Rule: Up to Next Major Version (2.1.0)

4. **빌드 설정**:
   - Deployment Target: iOS 16.0
   - Info.plist의 NSAppTransportSecurity 설정 확인 (비보안 연결 허용)

### 또는 Swift Package로 빌드

```bash
cd HDMSDataGenerator
swift build
```

## MQTT 메시지 형식

### 토픽 형식
```
{토픽프리픽스}/{센서ID}/data
```
예: `HS/21/data`, `AHS/25/data`, `THS/26/data`

### 메시지 페이로드 (JSON)

#### 전류센서 (Type 1)
```json
{
  "sensor_id": 21,
  "sensor_type": 1,
  "sensor_name": "전류센서TEST",
  "timestamp": "2024-01-15T10:30:00+09:00",
  "is_connected": true,
  "status": "normal",
  "current": 8.52,
  "value": 8.52,
  "unit": "A"
}
```

#### 온도센서 (Type 2)
```json
{
  "sensor_id": 25,
  "sensor_type": 2,
  "sensor_name": "온도센서TEST",
  "timestamp": "2024-01-15T10:30:00+09:00",
  "is_connected": true,
  "status": "normal",
  "temperature": 25.3,
  "value": 25.3,
  "unit": "°C"
}
```

#### 습도센서 (Type 3)
```json
{
  "sensor_id": 26,
  "sensor_type": 3,
  "sensor_name": "습도센서TEST",
  "timestamp": "2024-01-15T10:30:00+09:00",
  "is_connected": true,
  "status": "normal",
  "humidity": 55.2,
  "value": 55.2,
  "unit": "%"
}
```

## 데이터 생성 알고리즘

원본 Python 버전과 동일한 알고리즘을 사용합니다:

- **변동 범위**:
  - 전류: ±0.5A
  - 온도: ±2.0°C
  - 습도: ±3.0%

- **트렌드 확률**:
  - 전류: 10%
  - 온도: 5%
  - 습도: 8%

- **값 범위**:
  - 전류: 0 ~ 999A
  - 온도: -50 ~ 300°C
  - 습도: 0 ~ 100%

## 스크린샷

(iOS 시뮬레이터 또는 실제 기기에서 앱 실행 후 스크린샷 추가)

## 라이선스

MIT License
