# Final Release Runbook（你只需最後點上架）

## A. 上架前 App 內檢查

1. 開啟 `設定` 分頁  
2. `資料來源模式` 選 `正式 + fallback`  
3. Endpoint 保持：`https://data.moa.gov.tw/Service/OpenData/FromM/FarmTransData.aspx`  
4. 點 `測試行情 API`，確認顯示「連線成功」  
5. `PRO 狀態` 按「重新檢查訂閱」

## B. Xcode 最終建置

1. 已用 Xcode CLI 重新封存並匯出 App Store Connect IPA。  
2. 已修正 App Icon 為無白邊、RGB、無 alpha 的 1024 PNG。  
3. 已上傳 `1.0 (4)`：Delivery UUID `a40f9617-c3d7-4d1f-a788-1aa6c5620922`。

## C. App Store Connect 填寫

1. 截圖已由使用者上傳。  
2. 主分類已設定為「商業」，第二分類為「工具程式」。  
3. Support URL 已設定：`https://github.com/kingboss568/restaurantops-purchasing/blob/main/Docs/support.md`。  
4. 隱私權政策 URL 已設定：`https://github.com/kingboss568/restaurantops-purchasing/blob/main/Docs/privacy-policy.md`。  
5. App 描述需包含 Apple 標準 EULA：`https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`。  
6. App 隱私權問卷已設定為「不收集資料」。  
7. Review Notes 口徑：  
   - 行情資料來自公開資料，可能有延遲  
   - AI 僅生成議價文字，不參與價格計算
   - PRO 訂閱頁已提供可點擊的 Privacy Policy 與 Apple 標準 EULA 連結

## D. 最後提交

1. 右側「提交項目草稿」抽屜已顯示 `iOS App 1.0` 為「已可提交的項目」。  
2. 帳號持有人最後按「提交以供審查」。  
3. 若要同時送審訂閱，請先確認 `com.restaurantops.purchasing.pro.monthly` 已完成本地化與審查資訊。
