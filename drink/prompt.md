# EZ-Deploy Web App 生成 Prompt｜麻X茶坊

> 此為依據 `通用prompt.md` 建立的麻X茶坊專用生成 Prompt。
>
> 請依下方已確認需求，直接建立完整 Web App 與 Email Template。
>
> 本 Prompt 只產生 Web App 與 Email Template，**不產生、不覆寫 `upload_template.sh`**。

---

# 麻X茶坊專案需求（已確認）

以下需求已確認，請完整實作，不要改成其他系統。

```text
我要建立一個虛構品牌「麻X茶坊」的飲料店線上點餐系統。

顧客可以瀏覽至少 6 款虛構飲料，選擇甜度、冰量、珍珠／椰果／仙草等加料與數量，加入購物車，修改數量、刪除商品並查看小計與總金額。

送出前要填寫姓名、Email、手機、取餐方式（店內取餐或外帶）與備註，並看到完整訂單摘要。確認後寄送訂單確認 Email，信中顯示品牌、訂單編號、顧客資料、商品客製內容、數量、小計、總額、取餐方式與備註。

Web App 檔名使用 drink_order.html，Email Template ID 使用 drink_order_confirmation，Email 主旨使用「麻X茶坊｜您的訂單已收到」。視覺風格要清爽、明亮、現代、手機優先。

本專案 Email 動態變數固定為 order_id、customer_name、customer_email、customer_phone、items_html、total、pickup_method、notes、store_name 共 9 個；Web App payload、Email Template placeholders 與完成回覆中的 ALLOWED_VARIABLES 必須完全一致。
```

> 麻X茶坊為教學用虛構品牌。商品名稱、描述、價格與視覺素材必須使用原創 Demo 內容，不得複製真實品牌。

---

# 以下是固定規格（不要修改）

## 1. Role

你是一位熟悉 HTML5、CSS3、JavaScript、Mobile-first RWD、無障礙表單、HTML Email 與 EZ-Deploy Email API 的資深前端工程師。

請從「麻X茶坊專案需求」分析並整理：

- 系統類型與主要目標
- 虛構品牌名稱
- 商品、服務、活動或展覽內容
- 選項、日期、時段、數量、購物車或預約流程
- 顧客欄位與必填規則
- 是否需要價格、小計與總額
- 送出前摘要內容
- Email 應顯示的資料
- Web App 檔名、Template ID、Email 主旨與視覺方向

不要強迫所有系統使用購物車。訂購、預訂、預約、報名、詢價、活動、展示或其他表單型服務，都應依需求設計合適流程。

需求未指定的展示資料請自行建立原創虛構內容；不要反問使用者技術問題，也不要複製真實品牌資料。

## 2. 只輸出兩個完整檔案

### File 1 — Web App

檔名依需求決定；未指定時，自動使用語意清楚的英文 snake_case 檔名，例如：

```text
service_booking.html
course_registration.html
```

要求：

- 完整 HTML、CSS、JavaScript 放在同一檔案。
- 不使用 npm、前端框架、CDN 或 Build Process。
- 可以直接在現代瀏覽器開啟。
- 支援手機與 Desktop。
- 完整實作需求，不可只做靜態畫面。

### File 2 — Email Template

Template ID 依需求決定；未指定時，從系統用途推導英文 snake_case 名稱，例如：

```text
service_booking_confirmation
```

檔案必須建立在：

```text
templates/[template_id].html
```

要求：

- 使用 Inline CSS 與 Email-safe table layout。
- 支援手機 Email App。
- 不使用 JavaScript、外部 CSS 或外部字型。
- 包含完整動態資料。

### 禁止產生的檔案

```text
upload_template.sh
key.txt
.env
任何私密金鑰檔案
```

專案會使用既有的共用 `upload_template.sh`。AI 只需在完成回覆中提供該次應使用的 `TEMPLATE_ID` 與 `ALLOWED_VARIABLES`，不得建立或修改腳本。

## 3. Web App 通用功能

依需求選擇適合的能力：

- 訂購／預訂：商品、客製選項、數量、購物車、小計、總額、交付方式。
- 預約：服務、日期、時段、人數、對象資料、備註。
- 報名：活動／課程、場次、人數、參加者資料、費用。
- 詢價：需求類型、規格、預算、聯絡方式、說明。
- 展示＋預約：內容介紹、Gallery placeholder、日期、時段、預約人數。
- 其他系統：根據自然語言需求建立合理流程。

所有系統都必須：

1. 顯示完整內容或服務資訊。
2. 驗證必要欄位。
3. 在送出前顯示完整摘要。
4. 讓使用者返回修改。
5. 確認後才呼叫 Email API。
6. 送出時停用按鈕，避免重複寄送。
7. 成功後顯示訂單／預約／報名／案件編號。
8. 失敗時保留資料並顯示可操作的中文錯誤。

## 4. RWD 與 UI／UX

Web App 必須包含：

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

並符合：

- `<html lang="zh-Hant">`
- Mobile-first
- Flexbox 或 Grid
- 手機與 Desktop responsive layout
- 觸控按鈕高度至少約 44px
- label、錯誤訊息與資訊層級清楚
- 鍵盤 focus 清楚可見
- 支援 `prefers-reduced-motion`
- 使用 data URL favicon 或確實存在的 favicon，避免自動請求受保護路徑的 `favicon.ico`
- 使用圖片 placeholder、Emoji、CSS 圖形或原創素材

不可複製真實品牌 Logo、商標、官方圖片、完整菜單、官方 UI 或官方文案。

## 5. CONFIG

JavaScript 必須有集中設定：

```javascript
const CONFIG = {
  API_BASE: '[EZ-DEPLOY API BASE]',
  SITE_KEY: '[SITE_KEY]',
  TEMPLATE_ID: '[依需求決定的 template_id]',
  STORE_NAME: '[依需求決定的虛構品牌名稱]'
};
```

規則：

- `TEMPLATE_ID` 必須與 Email Template 檔名一致。
- `STORE_NAME` 必須與品牌名稱一致。
- `API_BASE` 部署時必須是完整 HTTPS 絕對網址。
- `SITE_KEY` 只可使用公開的 `sk_pub_...`。
- 未提供部署值時保留 placeholder，但送出前必須偵測並停止 fetch，以中文提示「尚未完成部署設定」。
- 移除 `API_BASE` 尾端 `/` 後再串接 API path。
- 不可猜測、產生、要求或寫入 `sk_secret_...`、`api_key_...`、密碼或其他私密憑證。

## 6. Email API

確認送出後呼叫：

```javascript
fetch(`${apiBase}/api/email/notify`, {
  method: 'POST',
  headers: {
    'X-Site-Key': CONFIG.SITE_KEY,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    template_id: CONFIG.TEMPLATE_ID,
    to: customerEmail,
    variables
  })
});
```

- `customerEmail` 必須通過基本 Email 格式驗證。
- `Origin` 與 `Referer` 由瀏覽器自動附加，不可用 JavaScript 手動設定。
- 安全解析 JSON 或非 JSON 錯誤回應。
- 至少處理以下 code：

```text
INVALID_SITE_KEY
ORIGIN_NOT_ALLOWED
TENANT_MISMATCH
NOT_FOUND
EMAIL_QUOTA_EXCEEDED
RATE_LIMITED
SITE_DISABLED
SITE_SUSPENDED
```

## 7. 動態變數由需求自動產生

不要硬套固定產業欄位。請根據需求設計語意清楚的 snake_case 變數。

所有系統至少應考慮：

```text
store_name
customer_name
customer_email
notes
```

再依需求加入，例如：

```text
order_id
booking_id
registration_id
customer_phone
items_html
services_html
details_html
total
pickup_method
booking_date
booking_time
participant_count
```

原則：

- 不適用的變數不要加入。
- 同一概念只使用一個名稱，不建立同義變數。
- 品牌使用 `store_name`，由 `escapeHtml(CONFIG.STORE_NAME)` 傳入。
- 識別碼依系統使用 `order_id`、`booking_id`、`registration_id`、`reservation_id` 或語意更合適的名稱。
- 多筆明細使用 `items_html`、`services_html` 或 `details_html`，只選一個適合的名稱。
- HTML 明細只能由程式以固定 Email-safe markup 產生；所有資料文字先 HTML escape。
- 使用者輸入不可直接插入 `innerHTML` 或 Email HTML。

必須保證：

```text
Web App payload.variables 的 key 集合
= Email Template 實際使用的 {placeholder} 集合
= 完成回覆提供的 ALLOWED_VARIABLES 集合
```

Email Template 必須至少使用每一個允許變數一次，不可有多餘 placeholder。

## 8. Email Template 格式

必須各有且只有一組標記：

```html
<!-- SUBJECT -->
[依需求產生的單行純文字主旨]
<!-- /SUBJECT -->

<!-- BODY -->
完整 HTML Email
<!-- /BODY -->
```

Email 至少顯示：

- `{store_name}`
- 案件／訂單／預約／報名狀態與識別碼
- 需求指定的商品、服務、日期、時段或活動內容
- 顧客資料
- 金額（適用時）
- 備註

Subject 不可使用 HTML 明細變數。

## 9. Security

- 驗證必填、Email、正整數、日期、時段與必要選項。
- 所有進入 HTML context 的使用者與設定文字必須 escape `& < > " '`。
- 只允許程式控制的固定 HTML 標籤進入明細變數。
- 不收集信用卡號、CVV、密碼、身分證號或不必要的敏感資料。
- 前端金額只供 Demo，不代表正式付款或後端交易驗證。
- 不把真實憑證、個資或測試資料寫死在檔案。

## 10. 部署相容性

程式與錯誤訊息必須考慮：

- 正式頁面部署於 `https://{網域}/uploads/org_{org_id}/[app_filename]`。
- `org_id` 必須與 Site Key 綁定組織一致。
- 不設定 `no-referrer` 或會移除必要 Referer path 的政策。
- 不把本機 `file://` 視為正式 Email API 測試。
- `TENANT_MISMATCH` 時引導檢查 org 路徑與 Referer。
- `ORIGIN_NOT_ALLOWED` 時引導檢查部署網域。
- `NOT_FOUND` 時引導檢查 Template 是否已上傳及 ID 是否一致。

## 11. Output Format

如果能操作檔案，直接建立兩個檔案。如果只能輸出文字，依序輸出：

1. `File 1 — [Web App 檔名]` 的完整 code block。
2. `File 2 — templates/[template_id].html` 的完整 code block。

不得輸出 `upload_template.sh`。

兩個檔案後，必須提供一段「部署資訊」：

```text
APP_FILENAME: 實際檔名
TEMPLATE_ID: 實際 template_id
TEMPLATE_FILE: templates/實際template_id.html
ALLOWED_VARIABLES='["依實際需求產生的變數"]'
```

`ALLOWED_VARIABLES` 必須是單行合法 JSON array，可直接複製到既有 `upload_template.sh`。

## 12. Final Check

完成前必須實際逐項檢查：

- [ ] 只建立 Web App 與 Email Template，沒有建立或修改 `upload_template.sh`
- [ ] 兩個檔案完整，沒有 TODO、FIXME、省略號或「其餘略」
- [ ] HTML 可以直接開啟，JavaScript 語法正確
- [ ] viewport、Mobile-first RWD、favicon 完整
- [ ] 系統流程符合需求，不強迫不適用的購物車或金額
- [ ] 商品、服務、日期、時段與顧客欄位完整
- [ ] 必填、Email、數量及必要選項驗證完整
- [ ] 有送出前摘要、返回修改及防止重複送出
- [ ] API placeholder 不會被當成相對 URL 送出
- [ ] 前端沒有 `sk_secret_...`、`api_key_...`、密碼或敏感資料
- [ ] `CONFIG.TEMPLATE_ID` 與 Email Template 檔名一致
- [ ] payload keys 與 Template placeholders 完全一致
- [ ] `{store_name}` 由 `CONFIG.STORE_NAME` 傳入並顯示
- [ ] SUBJECT／BODY 各恰好一組，Email 使用 Inline CSS
- [ ] 使用者及設定文字已依 HTML context 安全 escape
- [ ] 常見 API 錯誤有中文操作提示
- [ ] 完成回覆提供正確 `ALLOWED_VARIABLES` 單行

若任何項目失敗，先修正並重新檢查後再回報完成。
