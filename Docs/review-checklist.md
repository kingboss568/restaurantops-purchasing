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
- [x] 隱私權政策正式 URL 已填入 App Store Connect。
- [x] App Store Connect 主分類已設定為「商業」，第二分類為「工具程式」。
- [x] App 隱私權問卷已設定為「不收集資料」。

## Compliance

- [x] 價格計算以 deterministic service 實作，非 AI 決策。
- [x] 具備專業意見免責聲明（README / listing）。
- [x] local-first 設計，核心流程不依賴雲端。
- [x] App Store Connect build 重新上傳成功：`1.0 (4)`，Delivery UUID `a40f9617-c3d7-4d1f-a788-1aa6c5620922`。
- [ ] StoreKit 商品 `com.restaurantops.purchasing.pro.monthly` 已在 App Store Connect 建立並 Ready to Submit。
- [x] 上線環境使用內建正式農業部 endpoint 與 mock fallback。

## Final Submission Steps

1. App Store Connect 目前已顯示 `iOS App 1.0` 為「已可提交的項目」。
2. 最後由帳號持有人按右側抽屜底部的「提交以供審查」。
3. 若要一起送審訂閱商品，需確認 StoreKit 商品 `com.restaurantops.purchasing.pro.monthly` 的本地化與審查資訊已完整。
