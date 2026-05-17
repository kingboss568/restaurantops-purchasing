# TODO Phase 3 (下一階段)

Phase 2 MVP 已完成（41 個服務測試 + 2 個 repository 測試 + iOS Simulator build 通過）。下一階段：

1. `LiveAgriPriceAPIClient` 串接農業部正式 API，補上 `sourceURL` / `licenseNote` 並驗證 quota / 限速。
2. CloudKit 同步（餐廳、食材、供應商、報價、mapping）。
3. StoreKit 2 訂閱與付費牆（餐廳數量、進階比價、AI 配額）。
4. PDF / CSV 匯出（PriceComparisonResult、Supplier 報價歷史），含單元測試。
5. 本地 RAG 索引與 evidence 引用（行情、單位、規格、農產品分類規則）。
6. App Store 截圖自動化（xcodebuildmcp + 4 機型 × 6 場景 × 4 語）。
7. UI onboarding、a11y（VoiceOver、Dynamic Type、減少動態、色盲友善）。
8. piece / box 的 pack size 設定 UI（讓無法換算的單位變可換算）。
9. 供應商議價歷史與接受率追蹤（不在 MVP）。
10. AI candidate 整合（Foundation Models 工具呼叫候選 ranking，但仍保留 user-confirm gate）。
