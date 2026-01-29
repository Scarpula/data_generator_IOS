#!/bin/bash

echo "HDMS MQTT 가상 데이터 생성기 시작..."
echo

# 패키지 설치 확인
pip install -r requirements.txt

# 프로그램 실행
python3 mqtt_data_generator.py 