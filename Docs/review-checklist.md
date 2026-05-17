# App Review Submission Checklist

Date: 2026-05-17
App: 餐採智控

## Build And Quality

- [x] `swift test` 通過。
- [x] deterministic 比價邏輯由 `PriceComparisonService` 負責。
- [x] 行情 API 抽象為 protocol（`AgriPriceAPIClient`）可 mock。
- [x] API 失敗時有本地 fallback（`MarketPriceCache`）。
- [x] Xcode iOS Simulator build 驗證（`xcodebuild -scheme RestaurantOpsPurchasing -destination 'generic/platform=iOS Simulator' build`）。

## Metadata

- [x] App 名稱、描述、關鍵字草稿完成（`Docs/app-store-listing.md`）。
- [x] Support URL 已替換為 GitHub 公開專案頁。
- [x] Marketing URL 已替換為 GitHub 公開專案頁。
- [x] 隱私權政策正式 URL 已補入上架文件，待填入 App Store Connect。

## Compliance

- [x] 價格計算以 deterministic service 實作，非 AI 決策。
- [x] 具備專業意見免責聲明（README / listing）。
- [x] local-first 設計，核心流程不依賴雲端。
- [ ] 上傳 TestFlight 並完成第一輪外部測試。
- [ ] StoreKit 商品 `com.restaurantops.purchasing.pro.monthly` 已在 App Store Connect 建立並 Ready to Submit。
- [ ] 上線環境變數 `MARKET_DATA_MODE=liveWithMockFallback` 與 `AGRI_PRICE_ENDPOINT` 已配置。

## Final Submission Steps

1. 在含 App target 的主專案執行 Archive 並完成簽章。
2. 上傳 TestFlight，驗證免費流程與 PRO 購買流程。
3. 補齊 6.9 吋 / 6.7 吋截圖（首頁、比價、PRO 戰情、議價助手）。
4. 填寫 App Review Notes，說明行情資料可能延遲、AI 只生成文字不計價。
