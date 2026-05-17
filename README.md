# 餐採智控（Phase 2）

餐廳進貨價格 AI 比價 + 議價助理。整合於 RestaurantOps，協助餐廳掌握食材行情、對照供應商報價、產生可貼到 LINE 的議價話術。

## 功能總覽

- 常用食材清單與分類管理（SwiftData）
- 農產品交易行情匯入（protocol-first API client，附 Mock JSON）
- 食材 ↔ 市場品項對應（synonym table + fuzzy；AI 候選僅供建議，必須由使用者確認）
- 多供應商報價輸入與單位換算（kg / g / 台斤 / 公升 / 毫升）
- Deterministic 價差、7 日 / 30 日均價、排名、狀態計算（volume-weighted；缺 volume 退回 arithmetic）
- AI 議價助理（Apple Foundation Models，不可用時自動 fallback 到內建範本）
- 離線快取 fallback、最後更新時間顯示

## 技術棧

- Swift 5.10、SwiftUI、SwiftData、Swift Charts
- iOS 17+ / macOS 14+
- Apple Foundation Models（iOS 26+，可選；不可用時自動 fallback）
- Swift Package：`RestaurantOpsPurchasingCore`
- 所有金額一律使用 `Decimal`

## 模組

```
RestaurantOpsPurchasing/
├── Models/          # @Model + enums + read structs
├── DTOs/            # MarketPriceDTO / MarketPriceMapper（民國+西元日期容錯）
├── Services/        # API client, comparison, matcher, repository, AI
├── ViewModels/      # 7 ViewModels（MVVM）
├── Views/           # 7 Views + AppShell + DesignSystem
└── Resources/       # agri_price_mock.json、ingredient_synonyms_zh_TW.json
```

## 驗證

```bash
swift test
# Executed 43 tests, with 0 failures

xcodebuild -scheme RestaurantOpsPurchasing \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
# ** BUILD SUCCEEDED **
```

## 資料來源與限制

- 內建 mock JSON 為示範資料；正式版需介接農業部「農產品交易行情」API。
- API DTO 不直接寫入 SwiftData；先過 `MarketPriceMapper`（民國/西元日期容錯）。
- `sourceKey = sourceName|tradeDate|marketCode|itemCode|unit`，重複時 upsert，不重複新增。
- 行情、單位、規格差異請以實際交易與供應商確認為準。

## AI 限界

- AI 僅產生議價文字與市場品項候選建議。
- AI **不** 計算價差、均價、排名；這些一律由 deterministic Swift service 計算。
- AI **不** 自動確認食材對應；必須由使用者點選「確認對應」後才寫入 mapping。
- Foundation Models 不可用時自動 fallback 到範本（顯示「內建範本」徽章）。
- 不得稱公開資料為「訓練 Apple Foundation Models」。

## Disclaimer

本 App 為餐廳採購輔助工具，不構成法律、會計、稅務、採購保證或其他專業意見。實際交易條件與風險請由使用者自行判斷並與供應商確認。

## 文件

- `Docs/app-store-listing.md`
- `Docs/review-checklist.md`
- `Docs/debug-report.md`
- `TODO_PHASE_2.md`
- `「工程實作指令」.md`（authoritative spec）
