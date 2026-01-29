# Xcode 프로젝트 설정 가이드

## 1. Xcode에서 새 프로젝트 생성

1. Xcode 실행
2. **File > New > Project** 선택
3. **iOS > App** 선택 후 Next
4. 다음 설정 입력:
   - **Product Name**: `HDMSDataGenerator`
   - **Team**: 본인의 Apple Developer Team 선택
   - **Organization Identifier**: `com.yourcompany` (원하는 값으로 변경)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None
   - ☑️ Use Core Data: 체크 해제
   - ☑️ Include Tests: 체크 해제 (선택사항)
5. 프로젝트 저장 위치 선택 후 Create

## 2. 기본 파일 삭제

생성된 프로젝트에서 다음 파일들을 삭제:
- `ContentView.swift`
- `HDMSDataGeneratorApp.swift` (기존 것)

## 3. 소스 파일 복사

이 폴더의 `HDMSDataGenerator` 디렉토리 내 모든 파일을 Xcode 프로젝트로 복사:

1. Finder에서 `HDMSDataGenerator/HDMSDataGenerator/` 폴더 내용 전체 선택
2. Xcode 프로젝트 네비게이터의 `HDMSDataGenerator` 그룹에 드래그 앤 드롭
3. **Copy items if needed** 체크
4. **Create groups** 선택
5. Finish 클릭

## 4. CocoaMQTT 패키지 추가

1. **File > Add Package Dependencies...** 선택
2. 검색창에 입력: `https://github.com/emqx/CocoaMQTT.git`
3. **Dependency Rule**: Up to Next Major Version
4. **Version**: 2.1.0
5. **Add Package** 클릭
6. `CocoaMQTT` 라이브러리가 타겟에 추가되었는지 확인

## 5. 프로젝트 설정

### General 탭
- **Deployment Info**:
  - iOS 16.0 이상 선택
  - Device: iPhone, iPad 모두 체크

### Signing & Capabilities 탭
- Team 선택
- Bundle Identifier 확인

### Info 탭 (또는 Info.plist)
다음 키 추가 (MQTT 비보안 연결 허용):
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 6. 빌드 및 실행

1. 시뮬레이터 또는 실제 기기 선택
2. **⌘ + R** 또는 Play 버튼 클릭
3. 앱이 정상적으로 빌드되고 실행되는지 확인

## 7. 문제 해결

### "No such module 'CocoaMQTT'" 오류
- Package Dependencies가 제대로 추가되었는지 확인
- **Product > Clean Build Folder** (⌘ + Shift + K) 후 다시 빌드

### 연결 실패
- `Info.plist`의 `NSAppTransportSecurity` 설정 확인
- MQTT 브로커 주소와 포트가 올바른지 확인
- 네트워크 연결 상태 확인

### UI가 제대로 표시되지 않음
- iOS 16.0 이상인지 확인
- 다크 모드로 설정되어 있는지 확인

## 8. 테스트

1. 앱 실행
2. "연결" 버튼 클릭하여 MQTT 브로커에 연결
3. "시작" 버튼 클릭하여 데이터 생성 시작
4. 로그 탭에서 전송 로그 확인
5. MQTT 클라이언트(예: MQTT Explorer)로 메시지 수신 확인

## 폴더 구조 참고

```
HDMSDataGenerator (Xcode Project)/
├── HDMSDataGenerator/
│   ├── HDMSDataGeneratorApp.swift
│   ├── Info.plist
│   ├── Models/
│   │   ├── Sensor.swift
│   │   └── MQTTConfig.swift
│   ├── Services/
│   │   └── MQTTService.swift
│   ├── ViewModels/
│   │   └── MainViewModel.swift
│   ├── Views/
│   │   ├── MainView.swift
│   │   ├── ConnectionSettingsView.swift
│   │   ├── SensorManagementView.swift
│   │   └── Components/
│   │       ├── SensorCardView.swift
│   │       ├── ConnectionStatusCard.swift
│   │       ├── ControlPanelView.swift
│   │       └── LogView.swift
│   ├── Utils/
│   │   ├── Theme.swift
│   │   └── DataGenerator.swift
│   └── Resources/
│       └── Assets.xcassets/
└── HDMSDataGenerator.xcodeproj
```
