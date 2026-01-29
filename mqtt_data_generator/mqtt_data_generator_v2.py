#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import paho.mqtt.client as mqtt
import json
import threading
import time
import datetime
import random
from typing import Dict, Any, Optional

class MqttDataGeneratorV2:
    def __init__(self, root):
        self.root = root
        self.root.title("HDMS MQTT 센서 데이터 생성기 V2")
        self.root.geometry("1200x800")
        
        # MQTT 설정
        self.mqtt_client: Optional[mqtt.Client] = None
        self.is_connected = False
        self.is_running = False
        self.generator_thread: Optional[threading.Thread] = None
        
        # 토픽 프리픽스 설정 (환경별 분리용)
        self.topic_prefix = "HS"  # 기본값: HS, 개발환경: AHS, 테스트환경: THS 등
        
        # 센서 설정 (동적 설정 가능)
        self.sensors = {
            "current": [],
            "temperature": [],
            "humidity": []
        }
        
        # 기본 센서 추가
        self.add_default_sensors()
        
        # 센서별 입력값 저장
        self.sensor_values = {
            "current": {"current": 8.5},
            "temperature": {"temperature": 25.0},
            "humidity": {"humidity": 55.0}
        }
        
        # 센서별 변동 범위 설정 (실제와 유사한 범위)
        self.sensor_variations = {
            "current": {"range": 0.5, "trend_probability": 0.1},      # ±0.5A, 10% 확률로 트렌드 변화
            "temperature": {"range": 2.0, "trend_probability": 0.05}, # ±2°C, 5% 확률로 트렌드 변화  
            "humidity": {"range": 3.0, "trend_probability": 0.08}     # ±3%, 8% 확률로 트렌드 변화
        }
        
        # 센서별 현재 트렌드 (상승/하강/유지)
        self.sensor_trends = {
            "current": 0.0,      # -1: 하강, 0: 유지, 1: 상승
            "temperature": 0.0,
            "humidity": 0.0
        }
        
        self.message_count = 0
        self.create_widgets()
        
    def create_widgets(self):
        # 메인 프레임
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky="nsew")
        
        # MQTT 연결 설정
        self.create_connection_frame(main_frame)
        
        # 센서 관리 프레임
        self.create_sensor_management_frame(main_frame)
        
        # 센서 타입별 프레임 (가로 배치)
        sensors_frame = ttk.Frame(main_frame)
        sensors_frame.grid(row=2, column=0, columnspan=3, sticky="ew", pady=(10, 0))
        
        # 전류센서 프레임
        self.create_current_sensor_frame(sensors_frame)
        
        # 온도센서 프레임
        self.create_temperature_sensor_frame(sensors_frame)
        
        # 습도센서 프레임
        self.create_humidity_sensor_frame(sensors_frame)
        
        # 제어 버튼
        self.create_control_frame(main_frame)
        
        # 상태 표시
        self.create_status_frame(main_frame)
        
        # 로그 출력
        self.create_log_frame(main_frame)
        
        # 그리드 가중치 설정
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(5, weight=1)
        
    def create_connection_frame(self, parent):
        """MQTT 연결 설정 프레임"""
        connection_frame = ttk.LabelFrame(parent, text="🔗 MQTT 연결 설정", padding="10")
        connection_frame.grid(row=0, column=0, columnspan=3, sticky="ew", pady=(0, 10))
        
        # 첫 번째 줄: 브로커 주소, 포트, 클라이언트 ID
        ttk.Label(connection_frame, text="브로커 주소:").grid(row=0, column=0, sticky="w")
        self.broker_entry = ttk.Entry(connection_frame, width=20)
        self.broker_entry.insert(0, "139.150.72.51")
        self.broker_entry.grid(row=0, column=1, padx=(5, 0))
        
        ttk.Label(connection_frame, text="포트:").grid(row=0, column=2, sticky="w", padx=(20, 0))
        self.port_entry = ttk.Entry(connection_frame, width=8)
        self.port_entry.insert(0, "1883")
        self.port_entry.grid(row=0, column=3, padx=(5, 0))
        
        ttk.Label(connection_frame, text="클라이언트 ID:").grid(row=0, column=4, sticky="w", padx=(20, 0))
        self.client_id_entry = ttk.Entry(connection_frame, width=20)
        self.client_id_entry.insert(0, "hdms_data_generator_v2")
        self.client_id_entry.grid(row=0, column=5, padx=(5, 0))
        
        # 두 번째 줄: 토픽 프리픽스 설정
        ttk.Label(connection_frame, text="토픽 프리픽스:").grid(row=1, column=0, sticky="w", pady=(10, 0))
        self.topic_prefix_entry = ttk.Entry(connection_frame, width=15)
        self.topic_prefix_entry.insert(0, self.topic_prefix)
        self.topic_prefix_entry.grid(row=1, column=1, padx=(5, 0), pady=(10, 0))
        
        # 토픽 프리픽스 설명 라벨
        topic_info_label = ttk.Label(connection_frame, text="(운영: HS, 개발: AHS, 테스트: THS)", 
                                    font=('Arial', 8), foreground='gray')
        topic_info_label.grid(row=1, column=2, columnspan=2, sticky="w", padx=(10, 0), pady=(10, 0))
        
        # 토픽 프리픽스 적용 버튼
        self.apply_topic_btn = ttk.Button(connection_frame, text="토픽 적용", command=self.apply_topic_prefix)
        self.apply_topic_btn.grid(row=1, column=4, padx=(20, 0), pady=(10, 0))
        
        # 환경별 프리셋 버튼들
        preset_frame = ttk.Frame(connection_frame)
        preset_frame.grid(row=1, column=5, columnspan=2, padx=(10, 0), pady=(10, 0))
        
        ttk.Button(preset_frame, text="운영(HS)", command=lambda: self.set_topic_preset("HS"), width=8).grid(row=0, column=0, padx=(0, 2))
        ttk.Button(preset_frame, text="개발(AHS)", command=lambda: self.set_topic_preset("AHS"), width=8).grid(row=0, column=1, padx=(2, 2))
        ttk.Button(preset_frame, text="테스트(THS)", command=lambda: self.set_topic_preset("THS"), width=8).grid(row=0, column=2, padx=(2, 0))
        
        # 연결/연결해제 버튼
        self.connect_btn = ttk.Button(connection_frame, text="연결", command=self.connect_mqtt)
        self.connect_btn.grid(row=0, column=6, padx=(20, 0))
        
        self.disconnect_btn = ttk.Button(connection_frame, text="연결해제", command=self.disconnect_mqtt, state=tk.DISABLED)
        self.disconnect_btn.grid(row=0, column=7, padx=(5, 0))
        
    def add_default_sensors(self):
        """기본 센서 추가"""
        self.sensors["current"] = [
            {"id": 21, "name": "전류센서TEST"}
        ]
        self.sensors["temperature"] = [
            {"id": 25, "name": "온도센서TEST"}
        ]
        self.sensors["humidity"] = [
            {"id": 26, "name": "습도센서TEST"}
        ]
        
    def create_sensor_management_frame(self, parent):
        """센서 관리 프레임"""
        mgmt_frame = ttk.LabelFrame(parent, text="🔧 센서 관리", padding="10")
        mgmt_frame.grid(row=1, column=0, columnspan=3, sticky="ew", pady=(10, 0))
        
        # 센서 타입 선택
        ttk.Label(mgmt_frame, text="센서 타입:").grid(row=0, column=0, sticky="w")
        self.sensor_type_var = tk.StringVar(value="current")
        sensor_type_combo = ttk.Combobox(mgmt_frame, textvariable=self.sensor_type_var, values=["current", "temperature", "humidity"], state="readonly", width=12)
        sensor_type_combo.grid(row=0, column=1, padx=(5, 0))
        
        # 센서 ID 입력
        ttk.Label(mgmt_frame, text="센서 ID:").grid(row=0, column=2, sticky="w", padx=(20, 0))
        self.sensor_id_entry = ttk.Entry(mgmt_frame, width=10)
        self.sensor_id_entry.grid(row=0, column=3, padx=(5, 0))
        
        # 센서 이름 입력
        ttk.Label(mgmt_frame, text="센서 이름:").grid(row=0, column=4, sticky="w", padx=(20, 0))
        self.sensor_name_entry = ttk.Entry(mgmt_frame, width=20)
        self.sensor_name_entry.grid(row=0, column=5, padx=(5, 0))
        
        # 센서 추가 버튼
        ttk.Button(mgmt_frame, text="➕ 센서 추가", command=self.add_sensor).grid(row=0, column=6, padx=(20, 0))
        
        # 센서 목록 표시 및 삭제
        ttk.Label(mgmt_frame, text="현재 센서 목록:").grid(row=1, column=0, sticky="w", pady=(10, 0))
        
        # 센서 목록 프레임
        list_frame = ttk.Frame(mgmt_frame)
        list_frame.grid(row=2, column=0, columnspan=7, sticky="ew", pady=(5, 0))
        
        # 센서 목록 리스트박스
        self.sensor_listbox = tk.Listbox(list_frame, height=4, width=80)
        self.sensor_listbox.grid(row=0, column=0, sticky="ew")
        
        # 스크롤바
        scrollbar = ttk.Scrollbar(list_frame, orient="vertical", command=self.sensor_listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.sensor_listbox.config(yscrollcommand=scrollbar.set)
        
        # 센서 삭제 버튼
        ttk.Button(mgmt_frame, text="🗑️ 선택된 센서 삭제", command=self.remove_sensor).grid(row=3, column=0, pady=(5, 0))
        
        # 센서 목록 새로고침 버튼
        ttk.Button(mgmt_frame, text="🔄 목록 새로고침", command=self.refresh_sensor_list).grid(row=3, column=1, padx=(10, 0), pady=(5, 0))
        
        list_frame.columnconfigure(0, weight=1)
        
        # 초기 센서 목록 표시
        self.refresh_sensor_list()
        
    def create_current_sensor_frame(self, parent):
        """⚡ 전류센서 설정 프레임"""
        self.current_frame = ttk.LabelFrame(parent, text="⚡ 전류센서 (Type 1)", padding="10")
        self.current_frame.grid(row=0, column=0, sticky="nsew", padx=(0, 5))
        
        # 센서 목록 프레임
        self.current_sensor_list_frame = ttk.Frame(self.current_frame)
        self.current_sensor_list_frame.grid(row=0, column=0, columnspan=2, sticky="ew")
        
        # 센서 목록 업데이트
        self.update_current_sensor_list()
        
        # 구분선
        ttk.Separator(self.current_frame, orient='horizontal').grid(row=10, column=0, columnspan=2, sticky="ew", pady=10)
        
        # 값 입력
        ttk.Label(self.current_frame, text="⚙️ 값 설정:", font=("", 9, "bold")).grid(row=11, column=0, columnspan=2, sticky="w")
        
        ttk.Label(self.current_frame, text="전류 (A):").grid(row=12, column=0, sticky="w", pady=2)
        self.current_entry = ttk.Entry(self.current_frame, width=15)
        self.current_entry.insert(0, str(self.sensor_values["current"]["current"]))
        self.current_entry.grid(row=12, column=1, padx=(5, 0), pady=2)
        
        # 업데이트 버튼
        update_btn = ttk.Button(self.current_frame, text="🔄 값 업데이트", command=self.update_current_values)
        update_btn.grid(row=13, column=0, columnspan=2, pady=(10, 0))
        
        parent.columnconfigure(0, weight=1)
        
    def create_temperature_sensor_frame(self, parent):
        """🌡️ 온도센서 설정 프레임"""
        self.temperature_frame = ttk.LabelFrame(parent, text="🌡️ 온도센서 (Type 2)", padding="10")
        self.temperature_frame.grid(row=0, column=1, sticky="nsew", padx=5)
        
        # 센서 목록 프레임
        self.temperature_sensor_list_frame = ttk.Frame(self.temperature_frame)
        self.temperature_sensor_list_frame.grid(row=0, column=0, columnspan=2, sticky="ew")
        
        # 센서 목록 업데이트
        self.update_temperature_sensor_list()
        
        # 구분선
        ttk.Separator(self.temperature_frame, orient='horizontal').grid(row=10, column=0, columnspan=2, sticky="ew", pady=10)
        
        # 값 입력
        ttk.Label(self.temperature_frame, text="⚙️ 값 설정:", font=("", 9, "bold")).grid(row=11, column=0, columnspan=2, sticky="w")
        
        ttk.Label(self.temperature_frame, text="온도 (°C):").grid(row=12, column=0, sticky="w", pady=2)
        self.temperature_entry = ttk.Entry(self.temperature_frame, width=15)
        self.temperature_entry.insert(0, str(self.sensor_values["temperature"]["temperature"]))
        self.temperature_entry.grid(row=12, column=1, padx=(5, 0), pady=2)
        
        # 업데이트 버튼
        update_btn = ttk.Button(self.temperature_frame, text="🔄 값 업데이트", command=self.update_temperature_values)
        update_btn.grid(row=13, column=0, columnspan=2, pady=(10, 0))
        
        parent.columnconfigure(1, weight=1)
        
    def create_humidity_sensor_frame(self, parent):
        """💧 습도센서 설정 프레임"""
        self.humidity_frame = ttk.LabelFrame(parent, text="💧 습도센서 (Type 3)", padding="10")
        self.humidity_frame.grid(row=0, column=2, sticky="nsew", padx=(5, 0))
        
        # 센서 목록 프레임
        self.humidity_sensor_list_frame = ttk.Frame(self.humidity_frame)
        self.humidity_sensor_list_frame.grid(row=0, column=0, columnspan=2, sticky="ew")
        
        # 센서 목록 업데이트
        self.update_humidity_sensor_list()
        
        # 구분선
        ttk.Separator(self.humidity_frame, orient='horizontal').grid(row=10, column=0, columnspan=2, sticky="ew", pady=10)
        
        # 값 입력
        ttk.Label(self.humidity_frame, text="⚙️ 값 설정:", font=("", 9, "bold")).grid(row=11, column=0, columnspan=2, sticky="w")
        
        ttk.Label(self.humidity_frame, text="습도 (%):").grid(row=12, column=0, sticky="w", pady=2)
        self.humidity_entry = ttk.Entry(self.humidity_frame, width=15)
        self.humidity_entry.insert(0, str(self.sensor_values["humidity"]["humidity"]))
        self.humidity_entry.grid(row=12, column=1, padx=(5, 0), pady=2)
        
        # 업데이트 버튼
        update_btn = ttk.Button(self.humidity_frame, text="🔄 값 업데이트", command=self.update_humidity_values)
        update_btn.grid(row=13, column=0, columnspan=2, pady=(10, 0))
        
        parent.columnconfigure(2, weight=1)
        
    def create_control_frame(self, parent):
        """제어 버튼 프레임"""
        control_frame = ttk.LabelFrame(parent, text="🎮 데이터 생성 제어", padding="10")
        control_frame.grid(row=3, column=0, columnspan=3, sticky="ew", pady=(10, 0))
        
        ttk.Label(control_frame, text="발행 주기 (초):").grid(row=0, column=0, sticky="w")
        self.interval_entry = ttk.Entry(control_frame, width=10)
        self.interval_entry.insert(0, "2")
        self.interval_entry.grid(row=0, column=1, padx=(5, 0))
        
        self.start_btn = ttk.Button(control_frame, text="▶️ 시작", command=self.start_generation, state=tk.DISABLED)
        self.start_btn.grid(row=0, column=2, padx=(20, 0))
        
        self.stop_btn = ttk.Button(control_frame, text="⏹️ 중지", command=self.stop_generation, state=tk.DISABLED)
        self.stop_btn.grid(row=0, column=3, padx=(10, 0))
        
        ttk.Button(control_frame, text="📤 단발 전송", command=self.send_single_data).grid(row=0, column=4, padx=(20, 0))
        
    def create_status_frame(self, parent):
        """상태 표시 프레임"""
        status_frame = ttk.LabelFrame(parent, text="📊 상태", padding="10")
        status_frame.grid(row=4, column=0, columnspan=3, sticky="ew", pady=(10, 0))
        
        self.status_label = ttk.Label(status_frame, text="❌ 연결 끊김", foreground="red")
        self.status_label.grid(row=0, column=0, sticky="w")
        
        ttk.Label(status_frame, text="발행된 메시지:").grid(row=0, column=1, sticky="w", padx=(30, 0))
        self.message_count_label = ttk.Label(status_frame, text="0", foreground="blue")
        self.message_count_label.grid(row=0, column=2, sticky="w", padx=(5, 0))
        
        # 현재 토픽 형식 표시
        ttk.Label(status_frame, text="토픽 형식:").grid(row=1, column=0, sticky="w", pady=(5, 0))
        self.topic_format_label = ttk.Label(status_frame, text=f"{self.topic_prefix}/{{sensor_id}}/data", 
                                          foreground="green", font=('Arial', 9, 'bold'))
        self.topic_format_label.grid(row=1, column=1, columnspan=2, sticky="w", padx=(5, 0), pady=(5, 0))
        
    def create_log_frame(self, parent):
        """로그 출력 프레임"""
        log_frame = ttk.LabelFrame(parent, text="📝 로그", padding="10")
        log_frame.grid(row=5, column=0, columnspan=3, sticky="nsew", pady=(10, 0))
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=12, width=120)
        self.log_text.grid(row=0, column=0, sticky="nsew")
        
        ttk.Button(log_frame, text="🧹 로그 지우기", command=self.clear_log).grid(row=1, column=0, pady=(5, 0))
        
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        
    def update_current_values(self):
        """전류센서 값 업데이트"""
        try:
            self.sensor_values["current"]["current"] = float(self.current_entry.get())
            self.log("⚡ 전류센서 값이 업데이트되었습니다.")
        except ValueError:
            messagebox.showerror("오류", "올바른 숫자를 입력하세요.")
            
    def update_temperature_values(self):
        """온도센서 값 업데이트"""
        try:
            self.sensor_values["temperature"]["temperature"] = float(self.temperature_entry.get())
            self.log("🌡️ 온도센서 값이 업데이트되었습니다.")
        except ValueError:
            messagebox.showerror("오류", "올바른 숫자를 입력하세요.")
            
    def update_humidity_values(self):
        """습도센서 값 업데이트"""
        try:
            self.sensor_values["humidity"]["humidity"] = float(self.humidity_entry.get())
            self.log("💧 습도센서 값이 업데이트되었습니다.")
        except ValueError:
            messagebox.showerror("오류", "올바른 숫자를 입력하세요.")
            
    def add_sensor(self):
        """센서 추가"""
        try:
            sensor_type = self.sensor_type_var.get()
            sensor_id = int(self.sensor_id_entry.get().strip())
            sensor_name = self.sensor_name_entry.get().strip()
            
            if not sensor_name:
                messagebox.showerror("오류", "센서 이름을 입력하세요.")
                return
                
            # 중복 ID 체크
            for sensor in self.sensors[sensor_type]:
                if sensor["id"] == sensor_id:
                    messagebox.showerror("오류", f"센서 ID {sensor_id}는 이미 존재합니다.")
                    return
            
            # 센서 추가
            self.sensors[sensor_type].append({"id": sensor_id, "name": sensor_name})
            
            # 입력 필드 초기화
            self.sensor_id_entry.delete(0, tk.END)
            self.sensor_name_entry.delete(0, tk.END)
            
            # 센서 목록 새로고침
            self.refresh_sensor_list()
            self.refresh_sensor_frames()
            
            self.log(f"✅ {sensor_type} 센서 추가됨: ID {sensor_id}, 이름 '{sensor_name}'")
            
        except ValueError:
            messagebox.showerror("오류", "센서 ID는 숫자여야 합니다.")
            
    def remove_sensor(self):
        """선택된 센서 삭제"""
        selection = self.sensor_listbox.curselection()
        if not selection:
            messagebox.showwarning("경고", "삭제할 센서를 선택하세요.")
            return
        
        # 선택된 항목의 정보 파싱
        selected_text = self.sensor_listbox.get(selection[0])
        # 형식: "[전류] ID: 19, 이름: 전류센서TEST"
        try:
            sensor_type_map = {"전류": "current", "온도": "temperature", "습도": "humidity"}
            parts = selected_text.split("] ID: ")
            sensor_type_kr = parts[0][1:]  # "[전류" -> "전류"
            sensor_type = sensor_type_map[sensor_type_kr]
            sensor_id = int(parts[1].split(",")[0])
            
            # 센서 삭제
            self.sensors[sensor_type] = [s for s in self.sensors[sensor_type] if s["id"] != sensor_id]
            
            # 센서 목록 새로고침
            self.refresh_sensor_list()
            self.refresh_sensor_frames()
            
            self.log(f"🗑️ {sensor_type} 센서 삭제됨: ID {sensor_id}")
            
        except (IndexError, ValueError, KeyError):
            messagebox.showerror("오류", "센서 삭제 중 오류가 발생했습니다.")
            
    def refresh_sensor_list(self):
        """센서 목록 새로고침"""
        self.sensor_listbox.delete(0, tk.END)
        
        sensor_type_names = {"current": "전류", "temperature": "온도", "humidity": "습도"}
        
        for sensor_type, sensors in self.sensors.items():
            type_name = sensor_type_names[sensor_type]
            for sensor in sensors:
                item_text = f"[{type_name}] ID: {sensor['id']}, 이름: {sensor['name']}"
                self.sensor_listbox.insert(tk.END, item_text)
                
    def refresh_sensor_frames(self):
        """센서 프레임 새로고침"""
        # 각 센서 프레임의 센서 목록 라벨 업데이트
        # 이 부분은 센서 프레임이 이미 생성된 후에 호출되므로 UI 업데이트가 필요
        # 간단히 로그로 알림만 표시
        # 각 센서 프레임의 센서 목록 실시간 업데이트
        self.update_current_sensor_list()
        self.update_temperature_sensor_list()
        self.update_humidity_sensor_list()
        self.log("🔄 센서 목록이 업데이트되었습니다.")
        
    def update_current_sensor_list(self):
        """전류센서 목록 업데이트"""
        # 기존 센서 목록 제거
        for widget in self.current_sensor_list_frame.winfo_children():
            widget.destroy()
        
        # 새로운 센서 목록 추가
        ttk.Label(self.current_sensor_list_frame, text="📍 센서 목록:", font=("", 9, "bold")).grid(row=0, column=0, columnspan=2, sticky="w")
        
        if not self.sensors["current"]:
            ttk.Label(self.current_sensor_list_frame, text="• 등록된 센서가 없습니다", foreground="gray").grid(
                row=1, column=0, columnspan=2, sticky="w", padx=(10, 0))
        else:
            for i, sensor in enumerate(self.sensors["current"]):
                ttk.Label(self.current_sensor_list_frame, text=f"• ID {sensor['id']}: {sensor['name']}", foreground="blue").grid(
                    row=i+1, column=0, columnspan=2, sticky="w", padx=(10, 0))
    
    def update_temperature_sensor_list(self):
        """온도센서 목록 업데이트"""
        # 기존 센서 목록 제거
        for widget in self.temperature_sensor_list_frame.winfo_children():
            widget.destroy()
        
        # 새로운 센서 목록 추가
        ttk.Label(self.temperature_sensor_list_frame, text="📍 센서 목록:", font=("", 9, "bold")).grid(row=0, column=0, columnspan=2, sticky="w")
        
        if not self.sensors["temperature"]:
            ttk.Label(self.temperature_sensor_list_frame, text="• 등록된 센서가 없습니다", foreground="gray").grid(
                row=1, column=0, columnspan=2, sticky="w", padx=(10, 0))
        else:
            for i, sensor in enumerate(self.sensors["temperature"]):
                ttk.Label(self.temperature_sensor_list_frame, text=f"• ID {sensor['id']}: {sensor['name']}", foreground="orange").grid(
                    row=i+1, column=0, columnspan=2, sticky="w", padx=(10, 0))
    
    def update_humidity_sensor_list(self):
        """습도센서 목록 업데이트"""
        # 기존 센서 목록 제거
        for widget in self.humidity_sensor_list_frame.winfo_children():
            widget.destroy()
        
        # 새로운 센서 목록 추가
        ttk.Label(self.humidity_sensor_list_frame, text="📍 센서 목록:", font=("", 9, "bold")).grid(row=0, column=0, columnspan=2, sticky="w")
        
        if not self.sensors["humidity"]:
            ttk.Label(self.humidity_sensor_list_frame, text="• 등록된 센서가 없습니다", foreground="gray").grid(
                row=1, column=0, columnspan=2, sticky="w", padx=(10, 0))
        else:
            for i, sensor in enumerate(self.sensors["humidity"]):
                ttk.Label(self.humidity_sensor_list_frame, text=f"• ID {sensor['id']}: {sensor['name']}", foreground="cyan").grid(
                    row=i+1, column=0, columnspan=2, sticky="w", padx=(10, 0))
        
    def log(self, message: str):
        """로그 메시지 출력"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] {message}\n"
        self.log_text.insert(tk.END, log_message)
        self.log_text.see(tk.END)
        print(log_message.strip())
        
    def clear_log(self):
        """로그 지우기"""
        self.log_text.delete(1.0, tk.END)
        
    def apply_topic_prefix(self):
        """토픽 프리픽스 적용"""
        try:
            new_prefix = self.topic_prefix_entry.get().strip()
            if not new_prefix:
                messagebox.showerror("오류", "토픽 프리픽스를 입력하세요.")
                return
            
            # 영문자와 숫자만 허용 (보안 강화)
            if not new_prefix.replace('_', '').isalnum():
                messagebox.showerror("오류", "토픽 프리픽스는 영문자, 숫자, 언더스코어(_)만 사용 가능합니다.")
                return
            
            old_prefix = self.topic_prefix
            self.topic_prefix = new_prefix
            
            # 상태 표시 업데이트
            self.topic_format_label.config(text=f"{self.topic_prefix}/{{sensor_id}}/data")
            
            self.log(f"🔄 토픽 프리픽스 변경: {old_prefix} → {new_prefix}")
            self.log(f"📝 새로운 토픽 형식: {new_prefix}/{{sensor_id}}/data")
            
            # 현재 상태에 따른 안내 메시지
            if self.is_connected:
                self.log("ℹ️  토픽 프리픽스가 변경되었습니다. 새로운 데이터는 변경된 토픽으로 전송됩니다.")
            else:
                self.log("ℹ️  토픽 프리픽스가 설정되었습니다. MQTT 연결 후 이 설정이 적용됩니다.")
            
            messagebox.showinfo("성공", f"토픽 프리픽스가 '{new_prefix}'로 변경되었습니다.")
            
        except Exception as e:
            self.log(f"❌ 토픽 프리픽스 적용 오류: {str(e)}")
            messagebox.showerror("오류", f"토픽 프리픽스 적용에 실패했습니다: {str(e)}")
    
    def set_topic_preset(self, preset_prefix: str):
        """환경별 토픽 프리셋 설정"""
        try:
            self.topic_prefix_entry.delete(0, tk.END)
            self.topic_prefix_entry.insert(0, preset_prefix)
            
            # 자동으로 적용
            self.apply_topic_prefix()
            
        except Exception as e:
            self.log(f"❌ 토픽 프리셋 설정 오류: {str(e)}")
            messagebox.showerror("오류", f"토픽 프리셋 설정에 실패했습니다: {str(e)}")
        
    def connect_mqtt(self):
        """MQTT 브로커에 연결"""
        try:
            broker = self.broker_entry.get().strip()
            port = int(self.port_entry.get().strip())
            client_id = self.client_id_entry.get().strip()
            
            if not broker or not client_id:
                messagebox.showerror("오류", "브로커 주소와 클라이언트 ID를 입력하세요.")
                return
            
            # paho-mqtt 버전에 따라 Client 생성 방식 분기 (v2.x: CallbackAPIVersion, v1.x: 없음)
            try:
                _ = mqtt.CallbackAPIVersion  # 존재 확인
                self.mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=client_id)
            except AttributeError:
                # paho-mqtt 1.x 호환
                self.mqtt_client = mqtt.Client(client_id)
            self.mqtt_client.on_connect = self.on_connect
            self.mqtt_client.on_disconnect = self.on_disconnect
            self.mqtt_client.on_publish = self.on_publish
            
            self.log(f"🔗 MQTT 브로커 연결 시도: {broker}:{port}")
            self.mqtt_client.connect(broker, port, 60)
            self.mqtt_client.loop_start()
            
        except Exception as e:
            self.log(f"❌ MQTT 연결 오류: {str(e)}")
            messagebox.showerror("연결 오류", f"MQTT 브로커 연결에 실패했습니다: {str(e)}")
            
    def disconnect_mqtt(self):
        """MQTT 브로커 연결 해제"""
        if self.mqtt_client:
            self.stop_generation()
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
            
    def on_connect(self, client, userdata, flags, reason_code=None, properties=None):
        """MQTT 연결 성공 콜백 (paho-mqtt v2 API)"""
        # reason_code는 MQTT v5에서는 ReasonCode 객체(속성 is_failure/ value), v3에서는 int일 수 있음
        if hasattr(reason_code, "is_failure"):
            failed = bool(getattr(reason_code, "is_failure"))
        else:
            failed = int(getattr(reason_code, "value", 0 if reason_code is None else reason_code)) != 0

        if not failed:
            self.is_connected = True
            self.status_label.config(text="✅ 연결됨", foreground="green")
            self.connect_btn.config(state=tk.DISABLED)
            self.disconnect_btn.config(state=tk.NORMAL)
            self.start_btn.config(state=tk.NORMAL)
            self.log("✅ MQTT 브로커에 연결되었습니다.")
        else:
            self.log(f"❌ MQTT 연결 실패: {reason_code}")
            
    def on_disconnect(self, client, userdata, flags=None, reason_code=None, properties=None):
        """MQTT 연결 해제 콜백 (paho-mqtt v2 API)"""
        self.is_connected = False
        self.status_label.config(text="❌ 연결 끊김", foreground="red")
        self.connect_btn.config(state=tk.NORMAL)
        self.disconnect_btn.config(state=tk.DISABLED)
        self.start_btn.config(state=tk.DISABLED)
        self.stop_btn.config(state=tk.DISABLED)
        self.log("❌ MQTT 브로커 연결이 해제되었습니다.")
        
    def on_publish(self, client, userdata, mid, reason_codes=None, properties=None):
        """메시지 발행 완료 콜백 (paho-mqtt v2 API)"""
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
        
        self.generator_thread = threading.Thread(target=self.generate_data_loop, daemon=True)
        self.generator_thread.start()
        
        self.log("▶️ 데이터 생성을 시작합니다.")
        
    def stop_generation(self):
        """데이터 생성 중지"""
        self.is_running = False
        self.start_btn.config(state=tk.NORMAL)
        self.stop_btn.config(state=tk.DISABLED)
        self.log("⏹️ 데이터 생성을 중지합니다.")
        
    def generate_data_loop(self):
        """데이터 생성 루프"""
        try:
            interval = float(self.interval_entry.get())
        except ValueError:
            interval = 2.0
            
        while self.is_running:
            try:
                self.send_all_sensor_data()
                time.sleep(interval)
            except Exception as e:
                self.log(f"❌ 데이터 생성 중 오류: {str(e)}")
                time.sleep(1)
                
    def send_single_data(self):
        """단발 데이터 전송"""
        if not self.is_connected:
            messagebox.showerror("오류", "먼저 MQTT 브로커에 연결하세요.")
            return
        self.send_all_sensor_data()
        
    def send_all_sensor_data(self):
        """모든 센서 데이터 전송"""
        if not self.mqtt_client:
            return
            
        # 전류센서 데이터 전송
        for sensor in self.sensors["current"]:
            data = self.create_current_sensor_data(sensor)
            topic = f"{self.topic_prefix}/{sensor['id']}/data"
            payload = json.dumps(data, ensure_ascii=False)
            self.mqtt_client.publish(topic, payload, qos=1)
            self.log(f"⚡ 전송: {topic} -> {sensor['name']} (전류: {data['current']}A)")
            
        # 온도센서 데이터 전송
        for sensor in self.sensors["temperature"]:
            data = self.create_temperature_sensor_data(sensor)
            topic = f"{self.topic_prefix}/{sensor['id']}/data"
            payload = json.dumps(data, ensure_ascii=False)
            self.mqtt_client.publish(topic, payload, qos=1)
            self.log(f"🌡️ 전송: {topic} -> {sensor['name']} (온도: {data['temperature']}°C)")
            
        # 습도센서 데이터 전송
        for sensor in self.sensors["humidity"]:
            data = self.create_humidity_sensor_data(sensor)
            topic = f"{self.topic_prefix}/{sensor['id']}/data"
            payload = json.dumps(data, ensure_ascii=False)
            self.mqtt_client.publish(topic, payload, qos=1)
            self.log(f"💧 전송: {topic} -> {sensor['name']} (습도: {data['humidity']}%)")
            
    def create_current_sensor_data(self, sensor: Dict[str, Any]) -> Dict[str, Any]:
        """전류센서 데이터 생성"""
        # 실제와 유사한 변동값 생성
        current_value = self.generate_realistic_value("current", "current")
        
        return {
            "sensor_id": sensor["id"],
            "sensor_type": 1,
            "sensor_name": sensor["name"],
            "timestamp": datetime.datetime.now().isoformat(),
            "is_connected": True,
            "status": "normal",
            "current": round(current_value, 2),
            "value": round(current_value, 2),
            "unit": "A"
        }
        
    def create_temperature_sensor_data(self, sensor: Dict[str, Any]) -> Dict[str, Any]:
        """온도센서 데이터 생성"""
        # 실제와 유사한 변동값 생성
        temperature_value = self.generate_realistic_value("temperature", "temperature")
        
        return {
            "sensor_id": sensor["id"],
            "sensor_type": 2,
            "sensor_name": sensor["name"],
            "timestamp": datetime.datetime.now().isoformat(),
            "is_connected": True,
            "status": "normal",
            "temperature": round(temperature_value, 1),
            "value": round(temperature_value, 1),
            "unit": "°C"
        }
        
    def create_humidity_sensor_data(self, sensor: Dict[str, Any]) -> Dict[str, Any]:
        """습도센서 데이터 생성"""
        # 실제와 유사한 변동값 생성
        humidity_value = self.generate_realistic_value("humidity", "humidity")
        
        return {
            "sensor_id": sensor["id"],
            "sensor_type": 3,
            "sensor_name": sensor["name"],
            "timestamp": datetime.datetime.now().isoformat(),
            "is_connected": True,
            "status": "normal",
            "humidity": round(humidity_value, 1),
            "value": round(humidity_value, 1),
            "unit": "%"
        }
        
    def generate_realistic_value(self, sensor_type: str, value_key: str) -> float:
        """실제와 유사한 센서 값 생성"""
        base_value = self.sensor_values[sensor_type][value_key]
        variation_config = self.sensor_variations[sensor_type]
        
        # 트렌드 변화 확률 체크
        if random.random() < variation_config["trend_probability"]:
            # 새로운 트렌드 설정 (-1: 하강, 0: 유지, 1: 상승)
            self.sensor_trends[sensor_type] = random.choice([-0.3, -0.1, 0.0, 0.1, 0.3])
        
        # 기본 랜덤 변동 (-range ~ +range)
        random_variation = random.uniform(-variation_config["range"], variation_config["range"])
        
        # 트렌드 적용 (작은 값으로 지속적인 변화)
        trend_variation = self.sensor_trends[sensor_type] * variation_config["range"] * 0.1
        
        # 최종 값 계산
        new_value = base_value + random_variation + trend_variation
        
        # 센서별 합리적인 범위 제한
        if sensor_type == "current":
            new_value = max(0.0, min(999.0, new_value))  # 0~999A
        elif sensor_type == "temperature":
            new_value = max(-50.0, min(300.0, new_value))  # -50~300°C
        elif sensor_type == "humidity":
            new_value = max(0.0, min(100.0, new_value))  # 0~100% (습도는 물리적 한계)
        
        return new_value

if __name__ == "__main__":
    root = tk.Tk()
    app = MqttDataGeneratorV2(root)
    root.mainloop()