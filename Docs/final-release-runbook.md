# Final Release Runbook（你只需最後點上架）

## A. 上架前 App 內檢查

1. 開啟 `設定` 分頁  
2. `資料來源模式` 選 `正式 + fallback`  
3. Endpoint 保持：`https://data.moa.gov.tw/Service/OpenData/FromM/FarmTransData.aspx`  
4. 點 `測試行情 API`，確認顯示「連線成功」  
5. `PRO 狀態` 按「重新檢查訂閱」

## B. Xcode 最終建置

1. 選擇實際 iOS App Target（Archive 用）  
2. `Product > Archive`  
3. `Distribute App > App Store Connect > Upload`

## C. App Store Connect 填寫

1. 匯入截圖（首頁、比價、PRO 戰情、議價助手）  
2. 貼上 `Docs/app-store-listing.md` 文案  
3. 建立 IAP：`com.restaurantops.purchasing.pro.monthly`  
4. 填寫 Review Notes：  
   - 行情資料來自公開資料，可能有延遲  
   - AI 僅生成議價文字，不參與價格計算

## D. 最後提交

1. 確認 Build Processing 完成  
2. `Add for Review`  
3. `Submit for Review`
