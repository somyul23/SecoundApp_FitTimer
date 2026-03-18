# 📱 FitTimer

## 📌 概要

FitTimerは、運動効率を向上させるために開発されたiOSタイマーアプリです。
タバタタイマーとセットタイマー機能を提供し、運動記録を視覚的に分析できるように設計しました。

---

## 🚀 主な機能

### ⏱️ タバタタイマー

* ラウンド数・運動時間・休憩時間を設定可能
* 自動で繰り返し実行
* 現在の状態（運動 / 休憩）を音声と画面で通知

---

### 🏋️ セットタイマー（主要機能）

* ルーティンの追加 / 編集 / 削除
* ルーティン実行時、登録された運動を順番に進行
* 各運動ごとの設定:

  * セット数
  * 休憩時間
* 個別の運動のみ実行可能
* セット完了ボタン:

  * 自動で休憩タイマー開始
  * 終了時に音声通知

---

### 📊 運動記録・統計

* 連続運動日数の表示
* 週間合計セット数
* 前週との比較
* 週間運動量の折れ線グラフ
* 過去30日間:

  * 最も多く行った運動 TOP5
* 月間カレンダーヒートマップ
* 記録リスト:

  * 運動名 / セット数 / 実行時間
  * 個別削除可能

---

### 🔔 通知機能

* タイマー実行中、通知に状態表示
* 通知からアプリへ遷移し操作可能（停止など）

---

### 📱 ウィジェット

* 運動記録グラフウィジェット

  * タップでホーム画面へ遷移
* ルーティン実行ウィジェット

  * 任意のルーティンを即時実行

---

## 🛠 技術スタック

* Swift
* SwiftUI
* MVVMアーキテクチャ
* ローカルデータ保存
* WidgetKit
* Notification

---

## 💡 実装ポイント

* タイマーと状態管理を分離した設計
* セットタイマー中心のUX最適化
* グラフ・ヒートマップによるデータ可視化
* ウィジェットとアプリの連携実装

---

## 📸 Screenshots

## ⏱️ タバタタイマー

<p align="center">
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/4edc281a-bb98-4e6d-af3a-f186593a4c93" />

  <img width="250" alt="image" src="https://github.com/user-attachments/assets/b384de25-c7d6-4ec5-92a4-5cab3d0bb9d8" />

</p>

---

## 🏋️ セットタイマー（主要機能）

<p align="center">
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/ef8de47b-bcb4-43cc-a8ba-0d6dafe1bf3c" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/ff311643-7672-4a40-bda3-8979160bde9a" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/ab494a7c-583d-449b-91fb-2aab5e9f00f1" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/4bec8a50-94ff-46eb-8e4c-dd338c8fee0d" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/889e293d-1f5a-4948-9579-bb1554c9ef94" />




</p>

---

## 📊 運動記録・統計

<p align="center">
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/39d9a6a0-5405-4a01-9e71-4cc619ca0620" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/82ed92a4-d5c3-435f-b64d-a4f43911308e" />
  <img width="250" alt="image" src="https://github.com/user-attachments/assets/beb2e573-00a8-47a4-9807-d5381229d75e" />


</p>
