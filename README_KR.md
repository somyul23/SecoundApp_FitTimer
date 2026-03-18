# 📱 FitTimer

## 📌 소개

FitTimer는 운동 효율을 높이기 위해 설계된 iOS 타이머 애플리케이션입니다.
타바타 타이머와 세트 타이머 기능을 제공하며, 운동 기록을 시각적으로 분석할 수 있도록 구현했습니다.

---

## 🚀 주요 기능

### ⏱️ 타바타 타이머

* 라운드 수, 운동 시간, 휴식 시간 설정 가능
* 자동 반복 실행
* 현재 상태(운동/휴식)를 음성과 화면으로 안내

---

### 🏋️ 세트 타이머 (핵심 기능)

* 루틴 생성 / 수정 / 삭제 가능
* 루틴 실행 시 등록된 운동을 순차적으로 진행
* 운동별 설정:

  * 세트 수
  * 휴식 시간
* 개별 운동만 따로 실행 가능
* 세트 완료 버튼:

  * 자동으로 휴식 타이머 실행
  * 종료 시 음성 안내 제공

---

### 📊 운동 기록 및 통계

* 연속 운동 일수 표시
* 주간 총 세트 수
* 지난주 대비 변화량 표시
* 주간 운동량 꺾은선 그래프
* 최근 30일 기준:

  * 가장 많이 수행한 운동 TOP 5
* 월간 캘린더 히트맵 (운동량 시각화)
* 운동 기록 리스트:

  * 운동 이름 / 세트 수 / 수행 시간 표시
  * 개별 기록 삭제 가능

---

### 🔔 알림 및 실행

* 타이머 실행 시 알림창에 진행 상태 표시
* 알림창에서 앱 진입 및 제어 가능 (일시정지 등)

---

### 📱 위젯 기능

* 운동 기록 그래프 위젯

  * 클릭 시 앱 홈 화면 이동
* 루틴 실행 위젯

  * 원하는 루틴을 바로 실행 가능

---

## 🛠 기술 스택

* Swift
* SwiftUI
* MVVM 아키텍처
* Local Data Storage
* WidgetKit
* Notification

---

## 💡 구현 포인트

* 타이머 상태와 운동 흐름을 분리하여 구조 설계
* 세트 타이머 중심의 사용자 인터랙션 최적화
* 다양한 통계 데이터를 시각적으로 표현 (그래프, 히트맵)
* 위젯과 앱 간 연동 기능 구현

---

## 📸 Screenshots

## ⏱️타바타 타이머

<p align="center">
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/4edc281a-bb98-4e6d-af3a-f186593a4c93" />

  <img width="250" alt="image" src="https://github.com/user-attachments/assets/b384de25-c7d6-4ec5-92a4-5cab3d0bb9d8" />

</p>

---

## 🏋️ 세트 타이머

<p align="center">
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/ef8de47b-bcb4-43cc-a8ba-0d6dafe1bf3c" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/ff311643-7672-4a40-bda3-8979160bde9a" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/ab494a7c-583d-449b-91fb-2aab5e9f00f1" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/4bec8a50-94ff-46eb-8e4c-dd338c8fee0d" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/889e293d-1f5a-4948-9579-bb1554c9ef94" />




</p>

---

## 📊 운동 기록

<p align="center">
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/39d9a6a0-5405-4a01-9e71-4cc619ca0620" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/82ed92a4-d5c3-435f-b64d-a4f43911308e" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/beb2e573-00a8-47a4-9807-d5381229d75e" />


</p>
