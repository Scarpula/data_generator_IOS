#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import paho.mqtt.client as mqtt
import json
import threading
import time
import random
import datetime
from typing import Dict, Any, Optional

class MqttDataGenerator:
    def __init__(self, root):
        self.root = root
        self.root.title("SolHavi MQTT 가상 데이터 생성기")
        self.root.geometry("800x600")
        
        # MQTT 설정
        self.mqtt_client: Optional[mqtt.Client] = None
        self.is_connected = False
        self.is_running = False
        self.generator_thread: Optional[threading.Thread] = None
        
        # 센서 이전 값 저장 (안정적인 변화를 위해)
        self.sensor_last_values = {}
        
        # 실제 데이터베이스 기반 테스트 데이터 (단순화)
        self.sensors = [
            {"id": 17, "type": 2, "name": "온도센서TEST"},
            {"id": 19, "type": 1, "name": "전류센서TEST"},  
            {"id": 21, "type": 1, "name": "전류센서TEST2"},
            {"id": 22, "type": 3, "name": "습도센서TEST"},
            {"id": 23, "type": 3, "name": "습도센서TEST2"},
            {"id": 24, "type": 2, "name": "온도센서TEST2"}
        ]
        
        self.distribution_boards = [
            {"id": 2, "building_id": 5, "name": "건물test 보조배전반", "location": "건물test 지하1층"},
            {"id": 3, "building_id": 5, "name": "건물test 옥상배전반", "location": "건물test 옥상"},
            {"id": 4, "building_id": 5, "name": "건물test 비상배전반", "location": "건물test 2층"},
            {"id": 7, "building_id": 5, "name": "배전반 test", "location": "위치 test"},
            {"id": 8, "building_id": 7, "name": "배전반알림test", "location": "시설알림test"}  # 문제 배전반
        ]
        
        # 센서 타입 정의 (새로운 방식)
        self.sensor_types = {
            1: "전류",
            2: "온도", 
            3: "습도"
        }
        
        # 센서 초기값 설정
        self.init_sensor_values()
        
        self.create_widgets()
        
    def init_sensor_values(self):
        """센서 초기값 설정"""
        for sensor in self.sensors:
            sensor_id = sensor["id"]
            sensor_type = sensor["type"]
            
            if sensor_type == 1:  # 전류 센서
                self.sensor_last_values[sensor_id] = {
                    "current": 8.5,  # 중간값으로 시작
                    "voltage": 230.0,
                    "power": 1500.0,
                    "frequency": 60.0
                }
            elif sensor_type == 2:  # 온도 센서
                self.sensor_last_values[sensor_id] = {
                    "temperature": 30.0,
                    "ambient_temp": 22.0
                }
            elif sensor_type == 3:  # 습도 센서
                self.sensor_last_values[sensor_id] = {
                    "humidity": 55.0,
                    "ambient_temp": 25.0,
                    "ambient_humi": 55.0
                }
                
    def get_stable_value(self, sensor_id: int, field: str, min_val: float, max_val: float, max_change: float = 0.5) -> float:
        """안정적인 값 변화 생성"""
        if sensor_id not in self.sensor_last_values:
            return random.uniform(min_val, max_val)
            
        last_value = self.sensor_last_values[sensor_id].get(field, (min_val + max_val) / 2)
        
        # 최대 변화량 내에서 랜덤 변화
        change = random.uniform(-max_change, max_change)
        new_value = last_value + change
        
        # 범위 제한
        new_value = max(min_val, min(max_val, new_value))
        
        # 값 저장
        self.sensor_last_values[sensor_id][field] = new_value
        
        return new_value
        
    def create_widgets(self):
        # 메인 프레임
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky="nsew")
        
        # MQTT 연결 설정
        connection_frame = ttk.LabelFrame(main_frame, text="MQTT 연결 설정", padding="10")
        connection_frame.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 10))
        
        ttk.Label(connection_frame, text="브로커 주소:").grid(row=0, column=0, sticky="w")
        self.broker_entry = ttk.Entry(connection_frame, width=30)
        self.broker_entry.insert(0, "139.150.72.51")
        self.broker_entry.grid(row=0, column=1, padx=(10, 0))
        
        ttk.Label(connection_frame, text="포트:").grid(row=0, column=2, sticky="w", padx=(20, 0))
        self.port_entry = ttk.Entry(connection_frame, width=10)
        self.port_entry.insert(0, "1883")
        self.port_entry.grid(row=0, column=3, padx=(10, 0))
        
        ttk.Label(connection_frame, text="클라이언트 ID:").grid(row=1, column=0, sticky="w", pady=(10, 0))
        self.client_id_entry = ttk.Entry(connection_frame, width=30)
        self.client_id_entry.insert(0, "hdms_data_generator")
        self.client_id_entry.grid(row=1, column=1, padx=(10, 0), pady=(10, 0))
        
        self.connect_btn = ttk.Button(connection_frame, text="연결", command=self.connect_mqtt)
        self.connect_btn.grid(row=1, column=2, padx=(20, 0), pady=(10, 0))
        
        self.disconnect_btn = ttk.Button(connection_frame, text="연결해제", command=self.disconnect_mqtt, state=tk.DISABLED)
        self.disconnect_btn.grid(row=1, column=3, padx=(10, 0), pady=(10, 0))
        
        # 데이터 생성 제어
        control_frame = ttk.LabelFrame(main_frame, text="데이터 생성 제어", padding="10")
        control_frame.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(0, 10))
        
        ttk.Label(control_frame, text="발행 주기 (초):").grid(row=0, column=0, sticky="w")
        self.interval_entry = ttk.Entry(control_frame, width=10)
        self.interval_entry.insert(0, "2")
        self.interval_entry.grid(row=0, column=1, padx=(10, 0))
        
        self.start_btn = ttk.Button(control_frame, text="시작", command=self.start_generation, state=tk.DISABLED)
        self.start_btn.grid(row=0, column=2, padx=(20, 0))
        
        self.stop_btn = ttk.Button(control_frame, text="중지", command=self.stop_generation, state=tk.DISABLED)
        self.stop_btn.grid(row=0, column=3, padx=(10, 0))
        
        # 상태 표시
        status_frame = ttk.LabelFrame(main_frame, text="상태", padding="10")
        status_frame.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(0, 10))
        
        self.status_label = ttk.Label(status_frame, text="연결 끊김", foreground="red")
        self.status_label.grid(row=0, column=0, sticky="w")
        
        ttk.Label(status_frame, text="발행된 메시지:").grid(row=0, column=1, sticky="w", padx=(20, 0))
        self.message_count_label = ttk.Label(status_frame, text="0")
        self.message_count_label.grid(row=0, column=2, sticky="w", padx=(10, 0))
        
        # 로그 출력
        log_frame = ttk.LabelFrame(main_frame, text="로그", padding="10")
        log_frame.grid(row=3, column=0, columnspan=2, sticky="nsew")
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=15, width=80)
        self.log_text.grid(row=0, column=0, sticky="nsew")
        
        # 로그 지우기 버튼
        clear_log_btn = ttk.Button(log_frame, text="로그 지우기", command=self.clear_log)
        clear_log_btn.grid(row=1, column=0, pady=(10, 0))
        
        # 그리드 가중치 설정
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(3, weight=1)
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        
        self.message_count = 0
        
    def log(self, message: str):
        """로그 메시지를 GUI에 출력"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] {message}\n"
        self.log_text.insert(tk.END, log_message)
        self.log_text.see(tk.END)
        print(log_message.strip())  # 콘솔에도 출력
        
    def clear_log(self):
        """로그 지우기"""
        self.log_text.delete(1.0, tk.END)
        
    def connect_mqtt(self):
        """MQTT 브로커에 연결"""
        try:
            broker = self.broker_entry.get().strip()
            port = int(self.port_entry.get().strip())
            client_id = self.client_id_entry.get().strip()
            
            if not broker or not client_id:
                messagebox.showerror("오류", "브로커 주소와 클라이언트 ID를 입력하세요.")
                return
            
            # MQTT 클라이언트 생성
            self.mqtt_client = mqtt.Client(client_id)
            self.mqtt_client.on_connect = self.on_connect
            self.mqtt_client.on_disconnect = self.on_disconnect
            self.mqtt_client.on_publish = self.on_publish
            
            self.log(f"MQTT 브로커 연결 시도: {broker}:{port}")
            self.mqtt_client.connect(broker, port, 60)
            self.mqtt_client.loop_start()
            
        except Exception as e:
            self.log(f"MQTT 연결 오류: {str(e)}")
            messagebox.showerror("연결 오류", f"MQTT 브로커 연결에 실패했습니다: {str(e)}")
            
    def disconnect_mqtt(self):
        """MQTT 브로커 연결 해제"""
        if self.mqtt_client:
            self.stop_generation()
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
            
    def on_connect(self, client, userdata, flags, rc):
        """MQTT 연결 성공 콜백"""
        if rc == 0:
            self.is_connected = True
            self.status_label.config(text="연결됨", foreground="green")
            self.connect_btn.config(state=tk.DISABLED)
            self.disconnect_btn.config(state=tk.NORMAL)
            self.start_btn.config(state=tk.NORMAL)
            self.log("MQTT 브로커에 연결되었습니다.")
        else:
            self.log(f"MQTT 연결 실패: {rc}")
            
    def on_disconnect(self, client, userdata, rc):
        """MQTT 연결 해제 콜백"""
        self.is_connected = False
        self.status_label.config(text="연결 끊김", foreground="red")
        self.connect_btn.config(state=tk.NORMAL)
        self.disconnect_btn.config(state=tk.DISABLED)
        self.start_btn.config(state=tk.DISABLED)
        self.stop_btn.config(state=tk.DISABLED)
        self.log("MQTT 브로커 연결이 해제되었습니다.")
        
    def on_publish(self, client, userdata, mid):
        """메시지 발행 완료 콜백"""
        self.message_count += 1
        self.message_count_label.config(text=str(self.message_count))
        
    def start_generation(self):
        """데이터 생성 시작"""
        if not self.is_connected:
            messagebox.showerror("오류", "먼저 MQTT 브로커에 연결하세요.")
            return
            
        self.is_running = True
        self.start_btn.config(state=tk.DISABLED)
        self.stop_btn.config(state=tk.NORMAL)
        
        # 백그라운드 스레드에서 데이터 생성
        self.generator_thread = threading.Thread(target=self.generate_data_loop, daemon=True)
        self.generator_thread.start()
        
        self.log("데이터 생성을 시작합니다.")
        
    def stop_generation(self):
        """데이터 생성 중지"""
        self.is_running = False
        self.start_btn.config(state=tk.NORMAL)
        self.stop_btn.config(state=tk.DISABLED)
        self.log("데이터 생성을 중지합니다.")
        
    def generate_data_loop(self):
        """데이터 생성 루프"""
        try:
            interval = float(self.interval_entry.get())
        except ValueError:
            interval = 2.0
            
        while self.is_running:
            try:
                # 센서 데이터만 생성
                self.generate_sensor_data()
                
                time.sleep(interval)
                
            except Exception as e:
                self.log(f"데이터 생성 중 오류: {str(e)}")
                time.sleep(1)
                
    def generate_sensor_data(self):
        """센서 데이터 생성 및 발행"""
        if not self.mqtt_client:
            return
            
        for sensor in self.sensors:
            try:
                # 센서 타입에 따른 데이터 생성
                sensor_data = self.create_sensor_data(sensor)
                
                # 토픽: HS/{sensor_id}/data
                topic = f"HS/{sensor['id']}/data"
                
                # 메시지 발행
                payload = json.dumps(sensor_data, ensure_ascii=False)
                self.mqtt_client.publish(topic, payload, qos=1)
                
                self.log(f"센서 데이터 발행: {topic} -> {sensor['name']} ({self.sensor_types.get(sensor['type'], '알 수 없음')})")
                
            except Exception as e:
                self.log(f"센서 데이터 생성 오류: {str(e)}")
                
    def create_sensor_data(self, sensor: Dict[str, Any]) -> Dict[str, Any]:
        """센서 타입에 따른 실제 데이터 생성 - 안정적인 값 변화"""
        is_connected = random.choice([True, True, True, True, True, False])  # 85% 연결 확률
        
        sensor_id = sensor["id"]
        base_data = {
            "sensor_id": sensor_id,
            "sensor_type": sensor["type"],
            "sensor_name": sensor["name"],
            "timestamp": datetime.datetime.now().isoformat(),
            "is_connected": is_connected,
            "status": "normal" if is_connected else "offline",
            "rssi": random.randint(-80, -30),
            "has_event": random.choice([True, False])
        }
        
        # 센서 타입별 안정적인 데이터 생성
        if sensor["type"] == 1:  # 전류 센서
            current_value = round(self.get_stable_value(sensor_id, "current", 1.0, 12.0, 0.3), 2)
            voltage_value = round(self.get_stable_value(sensor_id, "voltage", 220.0, 240.0, 1.0), 1)
            power_value = round(self.get_stable_value(sensor_id, "power", 200.0, 2500.0, 50.0), 1)
            frequency_value = round(self.get_stable_value(sensor_id, "frequency", 59.8, 60.2, 0.1), 1)
            
            base_data.update({
                "current": current_value,
                "current_adc": random.randint(int(current_value * 100), int(current_value * 300)),
                "voltage": voltage_value,
                "power": power_value,
                "frequency": frequency_value,
                "value": current_value,
                "unit": "A"
            })
        elif sensor["type"] == 2:  # 온도 센서
            temperature_value = round(self.get_stable_value(sensor_id, "temperature", 25.0, 40.0, 0.5), 1)
            ambient_temp_value = round(self.get_stable_value(sensor_id, "ambient_temp", 18.0, 25.0, 0.3), 1)
            
            base_data.update({
                "temperature": temperature_value,
                "temperature_adc": random.randint(int(temperature_value * 50), int(temperature_value * 80)),
                "ambient_temp": ambient_temp_value,
                "value": temperature_value,
                "unit": "°C"
            })
        elif sensor["type"] == 3:  # 습도 센서
            humidity_value = round(self.get_stable_value(sensor_id, "humidity", 45.0, 70.0, 1.0), 1)
            ambient_temp_value = round(self.get_stable_value(sensor_id, "ambient_temp", 20.0, 28.0, 0.5), 1)
            ambient_humi_value = round(self.get_stable_value(sensor_id, "ambient_humi", 40.0, 65.0, 1.0), 1)
            
            base_data.update({
                "humidity": humidity_value,
                "ambient_temp": ambient_temp_value,
                "ambient_humi": ambient_humi_value,
                "value": humidity_value,
                "unit": "%"
            })
        else:
            # 기본 센서 데이터
            default_value = round(random.uniform(0, 100), 2)
            base_data.update({
                "value": default_value,
                "unit": "unit"
            })
            
        return base_data

if __name__ == "__main__":
    root = tk.Tk()
    app = MqttDataGenerator(root)
    root.mainloop() 