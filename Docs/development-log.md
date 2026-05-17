# RestaurantOps Purchasing Phase 2 開發紀錄

**日期：** 2026-05-17
**執行者：** Claude Code (Opus 4.7 1M)
**依據規格：** `「工程實作指令」.md`（1693 行）+ `Codex 開發說明書.md` + `2. RestaurantOps Phase 2：餐廳進貨價格 AI 比價 + 議價助理.md`
**指令：** @Jiang「依照規格書完成 iOS-app 設計」

---

## 1. 初始狀態盤點

進場時 repo 只有部分骨架：

- `Package.swift`（Swift 5.10、iOS 17 / macOS 14、library target `RestaurantOpsPurchasingCore`）
- `RestaurantOpsPurchasing/Models/PurchasingModels.swift`（253 行）— enum 命名與 spec **不一致**（如 `PriceComparisonStatus.favorable / aboveMarket / needsMarketLink` vs spec 的 `cheaperThanMarket / higherThanMarket / nearMarket / missingMarketData / unitMismatch`）
- 3 個 service 雛形（`PriceComparisonService`、`IngredientMarketMatcher`、`MarketPriceCache`）— 邏輯不完整
- 1 個測試檔（181 行）— 對齊舊 enum
- 缺：DTO/Mapper、AgriPriceAPIClient、UnitConversionService、NegotiationDraftAI、Repository、ViewModels、Views、Mock JSON、Synonym JSON、其他測試
- `RestaurantOpsPurchasing.xcodeproj`：空殼，只有 `project.xcworkspace`，**缺 `project.pbxproj`**

---

## 2. 決策（與 @Jiang 確認）

| 議題 | 選項 | 決議 |
|------|------|------|
| 命名衝突 | 完全對齊規格書 / 保留現有 / 雙 alias | **完全對齊規格書**（重構現有 enum + service + test） |
| Build 驗證 | 只跑 swift test / 嘗試 xcodebuild | **嘗試 xcodebuild 全量 build** |

---

## 3. 任務分解（TaskCreate）

```
#1 Phase A: Models, Enums, DTO, Mapper, Mock client
#2 Phase B: UnitConversionService + PriceComparisonService 重寫
#3 Phase C: Matcher + Synonym JSON
#4 Phase D: Repository + Cache + mock JSON
#5 Phase E: NegotiationDraftAI + Foundation Models adapter + fallback
#6 Phase F: 7 ViewModels + 7 Views + DesignSystem
#7 Phase G: Tests 全面補齊
#8 Validation: swift test + xcodebuild
```

---

## 4. 執行流程

### 4.1 Phase A–E（delegated to Opus subagent，背景執行）

委派子代理執行 Phase A–E（28 次工具呼叫、約 7.5 分鐘），完成：

**Models / Enums**
- `PurchasingEnums.swift`：`UnitType`（補 `catty`）、`IngredientCategory`（補 `fruit`）、`MappingSource`、`FetchStatus`、`PriceComparisonStatus`（完全對齊 spec 命名）、`NegotiationTone` + 全部 zh-TW `displayName`
- `PurchasingModels.swift`：7 個 `@Model`（補 `categoryCode`、`marketCode`、`sourceKey`、`linkedMarketItemName`、`createdAt/updatedAt`，新增 `IngredientMarketMapping`、`MarketPriceFetchLog`）
- `PurchasingReadModels.swift`：10 個 read struct（`NormalizedPrice`、`MarketItem`、`IngredientMarketCandidate`、`MarketPriceRecordInput`、`MarketPriceImportResult`、`SupplierPriceComparison`、`PriceComparisonResult`、`NegotiationContext`、`NegotiationDraft`）

**DTO + Mapper**
- `MarketPriceDTO`：中文 CodingKeys（交易日期/作物代號/作物名稱/市場代號/市場名稱/上中下價/平均價/交易量/種類代碼）
- `MarketPriceMapper`：民國/西元日期容錯、Decimal 解析（空字串/`-`/comma/whitespace）、deterministic `sourceKey`
- `MockAgriPriceAPIClient`（`Bundle.module` 讀 `agri_price_mock.json`）+ `LocalDTOFilter`
- `LiveAgriPriceAPIClient` 骨架

**Services**
- `DefaultUnitConversionService`（kg/g/catty/liter/ml + piece/box throw `missingPackSize`）
- `DefaultPriceComparisonService`（protocol-first；volume-weighted average + arithmetic fallback；status 5 種；rank 只給可比較者）
- `SynonymIngredientMarketMatcher`（exact → synonym → contains → Levenshtein fuzzy）
- `DefaultPurchasingRepository`（sourceKey upsert、`MarketPriceFetchLog`、`availableMarketItems`）
- `TemplateNegotiationDraftAI`（4 種 tone 範本 + 資料不足分支，不捏造市場資料）
- `FoundationModelsNegotiationDraftAI`（`#if canImport(FoundationModels)` + `#available(iOS 26, macOS 26, *)` gate，runtime fail → fallback to template）
- `PurchasingFormatters`（Decimal-safe 金額/百分比/日期）

**ViewModels**
- 7 個 `@MainActor` `ObservableObject` ViewModel，全部走 service / repository，不在 ViewModel 做運算

**Resources**
- `agri_price_mock.json`：4200 行（30+ 天、多市場、多品項、含缺 volume / 空字串價 / duplicate sourceKey）
- `ingredient_synonyms_zh_TW.json`：spec §9.3 全部 synonyms

子代理結束後達到 token 限制（usage limit），未及補 Views + Tests。

### 4.2 修補 Bundle.module compile error

`Bundle.module` 為 internal，不能當 public init 的 default value。改成：

```swift
public init(bundle: Bundle? = nil, resourceName: String = "...") {
    let resolvedBundle = bundle ?? .module
    ...
}
```

修補 `IngredientMarketMatcher.swift` 與 `AgriPriceAPIClient.swift`。`swift build` 通過。

### 4.3 Phase F：Views + AppShell（主執行）

寫 11 個 SwiftUI 檔：

| 檔案 | 行數 | 重點 |
|------|------|------|
| `DesignSystem.swift` | 65 | `PurchasingTheme`、`StatusBadge`、`EmptyStateView`、`DisclaimerFooter`、status tint extension |
| `Pasteboard.swift` | 17 | UIKit / AppKit 雙平台 copy |
| `IngredientListView.swift` | 96 | List + searchable + AddIngredientSheet + badge「尚未對應行情」 |
| `IngredientDetailView.swift` | 75 | mapping section + 候選列表 + AI 標籤「AI 建議，請確認」 |
| `MarketPriceTrendView.swift` | 100 | Swift Charts LineMark + 卡片列表 + 快取/最後更新 badge |
| `SupplierListView.swift` | 90 | searchable + AddSupplierSheet + onDelete |
| `SupplierQuoteEntryView.swift` | 100 | Decimal 驗證 + unit mismatch warning + 不可未來日期 |
| `PriceComparisonDashboardView.swift` | 115 | 市場行情卡片 + 排名 + status badge + 進入議價 |
| `NegotiationAssistantView.swift` | 110 | 資料依據卡 + tone Picker + TextEditor + Copy/Share/重生成 |
| `AppShellView.swift` | 120 | TabView 4 分頁 + IngredientPicker + 注入 service |
| `PurchasingDemoStore.swift` | 75 | 10 食材 + 3 供應商 + 9 quotes seed |

更新 `RestaurantOpsPurchasingApp.swift` 的 `modelContainer` 加入 `IngredientMarketMapping`、`MarketPriceFetchLog`。

中間遇到 `MarketPriceRecord` 不是 `Identifiable`（@Model 不自動 conform），改用 `ForEach(..., id: \.id)`。

### 4.4 Phase G：Tests 全面補齊

寫 6 個測試檔（43 個測試）：

| 檔案 | 測試數 | 對應 spec |
|------|--------|-----------|
| `TestSupport.swift` | — | factory helpers |
| `PriceComparisonServiceTests` | 12 | §17.1 全 12 案例 |
| `UnitConversionServiceTests` | 8 | §17.2 全部 |
| `IngredientMarketMatcherTests` | 6 | §17.3 |
| `MarketPriceMapperTests` | 8 | §17.4 |
| `NegotiationDraftAITests` | 6 | §17.5 |
| `PurchasingRepositoryTests` | 3 | sourceKey upsert / fetch log / available items |

**首次 `swift test`：43 tests, 6 failures**

失敗根因：
1. `test_minguoDate`：mapper 先試 `yyyy.MM.dd` gregorian，把 `115.05.16` 當成西元 115 年解析。
2. `test_mockJSON_decodesAndMaps` + 3 個 repo tests：mock JSON 全是民國日期，跟 #1 同一根因，造成所有 mapper 拋 `unparseableDate`，repo 沒寫進任何資料。

**修補：** 在 `MarketPriceMapper.parseDate` 中把民國日期偵測（3 段、年份 < 200）放到最前面，先於 gregorian formatter。

**再跑：43 tests, 0 failures**

### 4.5 Validation：xcodebuild

`.xcodeproj` 是壞的（缺 `project.pbxproj`），直接 `xcodebuild -list` 失敗。

決策：移除空殼 `.xcodeproj`，改用 SwiftPM 自動產生的 workspace scheme。

```bash
rm -rf RestaurantOpsPurchasing.xcodeproj
xcodebuild -scheme RestaurantOpsPurchasing \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
# ** BUILD SUCCEEDED **
```

iOS 17.0-simulator arm64 target、iOS SDK 26.5、Xcode 17F42。

### 4.6 文件更新

- `README.md`：重寫，產品名 `RestaurantOps Purchasing`（移除前手的 `FreshCost Radar` 占位）、加 Phase 2 完成驗證指令
- `TODO_PHASE_2.md`：改為「下一階段 TODO」（10 項：LiveAPI、CloudKit、StoreKit 2、PDF/CSV、RAG、App Store 自動化、a11y、pack size、議價歷史、AI candidate ranking）
- `Docs/development-log.md`：本檔

---

## 5. 最終結果

### 程式碼規模

```
Models       :   3 files,   ~470 lines
DTOs         :   1 file ,   ~205 lines
Services     :   7 files,   ~860 lines
ViewModels   :   1 file ,   ~380 lines
Views        :  11 files,  ~960 lines
Resources    :   2 JSON ,  ~4250 lines
Tests        :   7 files,   ~440 lines
─────────────────────────────────────
Swift total  :  約 3300 行
```

### 驗證

| 指令 | 結果 |
|------|------|
| `swift build` | Build complete (17.32s) |
| `swift test` | **Executed 43 tests, with 0 failures** (10s) |
| `xcodebuild -scheme RestaurantOpsPurchasing -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` | ****✅ BUILD SUCCEEDED** |

### Spec §18 驗收清單

全部通過（25 項，詳見對話末 final report）。

---

## 6. 遇到的坑與啟示

1. **`Bundle.module` 是 internal**：不能當 public init 的 default value。改成 `Bundle? = nil` + nil-coalesce。
2. **`@Model` 不自動 conform `Identifiable`**：SwiftData macro 提供 `persistentModelID` 但不是 `Identifiable.id`。`ForEach` 要 `id: \.id` 指定。
3. **民國日期 vs 西元 `yyyy.MM.dd`**：DateFormatter 會把 `115.05.16` 當西元 115 年（合法解析），順序很重要 — **民國檢測必須先**。
4. **空殼 `.xcodeproj`**：刪掉反而比修好，SwiftPM 自動產生的 workspace scheme 就能 iOS Simulator build。
5. **Token usage limit**：子代理跑大型實作會撞限額，分 phase 委派 + 主要任務自己接手較穩。
6. **mock JSON 4200 行**：覆蓋 30 天 × 5 品項 × 多市場 + 邊界 case，跑完一次 import 涵蓋 Repository 與 Mapper 大部分路徑，效益高。

---

## 7. AI 限界（再確認）

依 `Codex 開發說明書` 與 spec §11~12 嚴格遵守：

- AI **不** 計算金額、價差、均價、排名
- AI **不** 自動寫入 `Ingredient.linkedMarketItemCode`（必須使用者 confirm）
- AI **不** 自稱 AI、不輸出 Markdown / 表格、不威脅、不捏造市場資料
- 公開資料不稱為「訓練 Apple Foundation Models」
- 議價、行情、採購輔助一律附 disclaimer「輔助資訊，不構成專業意見」

---

## 8. 下一步建議

1. 串接農業部正式 API（補 `sourceURL` / `licenseNote` / 429 退避）
2. piece / box 的 pack size UI（讓無法換算單位變可換算）
3. CloudKit 同步（餐廳、食材、供應商、報價 → 跨裝置）
4. App Store 截圖自動化（xcodebuildmcp + 4 機型 × 6 場景 × 4 語）
5. a11y 驗證（VoiceOver、Dynamic Type、減少動態、色盲友善）

— 完 —
