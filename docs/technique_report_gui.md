# EZ-Deploy Email 通知服務 實戰指南 (訂閱者手冊) --網頁版

> 前提：已經訂閱擁有 Email 通知服務 的付費方案

> 本文件是 [`technique_report_manual.md`](./technique_report_manual.md)（手刻 / CLI 版）的網頁版。
> 差別在於：**金鑰有效性測試、錯誤排查，以及 Template 的列出 / 查看 / 上傳 / 刪除，全部改用一個網頁操作**，不需要安裝 `bash`、`curl`、`jq`，也不需要 WSL。
>
> 最重要的一點：`SITE_KEY` 與 `API_KEY` **在網頁開啟時由使用者當場輸入**，不會寫死在網頁檔案裡、也不會自動存進瀏覽器。關閉或重新整理頁面後就需要重新輸入，因此不會有把金鑰外洩在檔案中的安全問題。

## EZ-Deploy 系統架構與跨角色互動全景圖
![alt text](/imgs/architecture.png)

訂閱者 / 設計者 (User)：
* 登入 EZ-Deploy 平台，啟用 Email 通知服務並上傳系統HTML。
* 透過**網頁管理介面**上傳設計好的 Email Template 到 EZ-Deploy 資料庫
* 取得與交付資源：系統部署完成後，取得平台產出的 QR Code 與短網址，並將其交付給合作的店家(Owner)。

Easy Deploy(SaaS平台)：
* 接收訂閱者的設定與 Template 和 部署上傳的系統HTML 並生成專屬 QR Code 與短網址。
* 數據處理與觸發通知：當顧客送出訂單時，接收訂單 Payload 並自動觸發 Email 機制——同時寄送「訂單確認信」給顧客，以及「訂單通知副本」給店主。

店家 (Owner)：
* 接收訂閱者交付的資源，在線下（如桌貼、海報）張貼 QR Code 或於線上社交平台發布連結。
* 接收訂單通知：當顧客完成訂單後，收到來自 EZ Deploy 平台的訂單通知 Email。

顧客 (Customer)：
* 掃描 QR Code 或點擊分享連結進入系統頁面並提交訂單。
* 接收確認信：下單成功後，即時收到訂單確認信。

## 第一步：啟用 Email 通知服務與憑證備份

> 這一步與 CLI 版完全相同。

### 1.1 在 EZ-Deploy 啟用 Email 通知服務
1. 首次啟用 Email Notification
2. 取得SITE_KEY和API_KEY：
  - `SITE_KEY`：網站金鑰
  - `API_KEY`：API金鑰
![alt text](/imgs/email_enable.png)
![alt text](/imgs/email_enable-01.jpg)

### 1.2 Key安全備份與儲存
1. Email 通知服務已啟用信件通知
    - 根據信件信息：API_KEY 僅於啟用/輪替時**顯示一次**，請妥善保存，系統**不會再次顯示明碼**。
    - **將SITE_KEY與API_KEY，妥善保存**。
![alt text](/imgs/email_enable-03.jpg)
![alt text](/imgs/email_enable-02.jpg)

---
## 第二步：系統環境準備（網頁版超簡單）

> 網頁版不需要 `bash`、`curl`、`jq`，也不需要 WSL。只要一個現代瀏覽器（Chrome、Edge、Safari、Firefox）即可。

### 2.1 環境需求

| 項目 | CLI 版（手刻版） | 網頁版（本文件） |
| --- | --- | --- |
| Bash | 需要 | 不需要 |
| curl | 需要 | 不需要 |
| jq | 需要 | 不需要 |
| WSL（Windows） | 建議 | 不需要 |
| 瀏覽器 | — | **需要**（Chrome / Edge / Safari / Firefox 皆可） |

### 2.2 取得管理網頁

本教材提供的管理網頁位於：

```text
demo/template_manage.html
```

取得方式二選一：

* 從 [EZ-Deploy-demo GitHub Repository](https://github.com/uniheart-tw/EZ-Deploy-demo.git) 下載整個專案。
* 或單獨下載 `demo/template_manage.html` 這個檔案。

專案目錄（網頁版相關檔案）：

```text
EZ-Deploy-demo/
├── README.md
│
├── docs/
│   ├── technique_report_manual.md   # CLI 版手冊
│   └── technique_report_gui.md      # 本文件（網頁版手冊）
│
└── demo/
    ├── template_manage.html         # ★ 網頁版管理介面（本教材主角）
    ├── templates/
    │   └── test_email.html          # Email Template 範例
    └── test_order.html              # demo 系統前端
```

| 檔案 / 目錄 | 用途 |
| --- | --- |
| `demo/template_manage.html` | 網頁版 Email Template 管理介面（列出 / 查看 / 上傳 / 刪除 / 金鑰驗證） |
| `demo/templates/test_email.html` | Email Template 範例 |
| `demo/test_order.html` | demo 系統前端 |

### 2.3 將管理網頁部署到 EZ-Deploy 並分享

> ⚠️ **不要直接用瀏覽器打開本機檔案（`file://`）。**
> 管理網頁是從瀏覽器直接呼叫 Email API，API 會檢查請求的來源（Origin / Referer）。若用 `file://` 或任意本機伺服器開啟，來源不被允許，會被擋下而出現錯誤（CORS / `TENANT_MISMATCH` 之類），**不是金鑰的問題**。
>
> 正確做法：把 `demo/template_manage.html` **上傳到 EZ-Deploy 並分享**，從 EZ-Deploy 產生的網址開啟，瀏覽器才會帶上被允許的來源。

部署步驟：

1. 登入 EZ-Deploy，上傳 `demo/template_manage.html`（和上傳 `test_order.html` 這類系統 HTML 的方式相同）。
2. 在系統列表找到剛上傳的管理網頁，點「分享」。
3. 設定分享方式與天數後，取得短網址 / QR Code。
4. 用該短網址開啟管理網頁。
![alt text](/imgs/gui-verify-01.png)

從 EZ-Deploy 分享網址開啟後，網頁上會看到：

1. **① 憑證設定**：填入 `API_BASE`、`SITE_KEY`、`API_KEY`。
2. 四個分頁：**列出 / 驗證**、**查看單一**、**上傳 / 更新**、**刪除**。

> **憑證不會被存起來**
> `SITE_KEY` 與 `API_KEY` 只會存在這個頁面的記憶體中。你沒有把它們寫進任何檔案，重新整理頁面後需要重新輸入。這就是網頁版相較於把 Key 寫在 `.env` 檔的安全優勢。

### 2.4 填入憑證（取代 `.env.local`）

CLI 版是把下列內容放進 `.env.local`：

```bash
# .env.local（CLI 版才需要）
export API_BASE="https://ai-works.uniheart-ai.com/"
export SITE_KEY="sk_pub_xxxxxxxxx"
export API_KEY="api_key_xxxxxxxxx"
```

網頁版則是**直接在「① 憑證設定」區塊填入**同樣的三個值：

| 網頁欄位 | 對應 `.env.local` | 說明 |
| --- | --- | --- |
| `API_BASE` | `API_BASE` | **填入目前開啟這個管理網頁的主機名稱**（見下方特別注意），結尾斜線會自動去除 |
| `SITE_KEY` | `SITE_KEY` | 網站金鑰 |
| `API_KEY` | `API_KEY` | API 金鑰（管理 Template 用的私密憑證） |

> ⚠️ **特別注意：`API_BASE` 要填「當前主機名稱」**
>
> 因為網頁已經是從 EZ-Deploy 分享網址開啟（見 2.3），`API_BASE` 要填**目前瀏覽器網址列上的主機**，也就是這個管理網頁正在運行的主機，API 的來源檢查才會通過。
>
> 例如網址列是 `https://your-host.example/s/xxxx` 時，`API_BASE` 就填 `https://your-host.example`（只要協定 + 主機，不含後面的路徑）。
>
> 若填成與當前主機不同的網域（例如硬寫某個固定網域），瀏覽器的來源 / CORS 檢查會失敗，出現連線錯誤。
>
> **若使用自定域名（Custom Domain）：** `API_BASE` 一樣填目前網址列上的那個自定域名即可，規則不變——當前主機是什麼就填什麼。下圖即為使用自定域名開啟管理網頁的範例：
> ![alt text](/imgs/gui-verify-02.png)

勾選欄位旁的「顯示」可以暫時看到金鑰明碼以便核對；按「清除憑證」會立即把 `SITE_KEY` / `API_KEY` 清空。

---
## 第三步：金鑰有效性測試與錯誤排查（網頁版）

> 這是本文件相較於 CLI 版最主要的差異：原本用 `bash template_manage.sh list` 做的金鑰驗證，改成在網頁上**按一個按鈕**。

### 3.1 驗證 Site Key 與 API Key

1. 在「① 憑證設定」填好 `API_BASE`、`SITE_KEY`、`API_KEY`。
2. 按下 **「驗證金鑰有效性（list）」** 按鈕。

這個動作等同 CLI 版的：

```bash
source .env.local
bash template_manage.sh list
```

網頁會對 `GET /api/email/template` 發出請求，並把結果顯示在下方的狀態區塊：

* **第一次執行時 data 會是空的**，但只要回應的 `code` 是 `SUCCESS`（HTTP `200`），就代表取得的 `SITE_KEY` 與 `API_KEY` 沒有問題。
* 確認成功後，即可進入下一步建立 Email Template。

### 3.2 判斷結果

網頁會自動解讀 HTTP 狀態碼，並以顏色與中文說明呈現（綠色成功、紅色失敗），對應關係與 CLI 版一致：

| HTTP Status | Response Code / Message | 可能原因 | 代表什麼 | 網頁呈現 |
| --- | --- | --- | --- | --- |
| `200` | `SUCCESS` | Site Key 與 API Key 驗證成功 | 金鑰有效，可以繼續下一步 | 綠色「✅ 成功」 |
| `403` | `INVALID_API_KEY` | API Key 無效或不存在 | API Key 無法通過驗證 | 紅色「❌ 403」 |
| `403` | `INVALID_API_KEY` | Site Key 或 API Key 無效 | SITE_KEY 無法通過驗證 | 紅色「❌ 403」 |
| `400` | `MISSING_REQUIRED_FIELD` 等 | 必填欄位或 JSON 格式問題 | Request 格式不正確 | 紅色「❌ 400」 |
| `404` | — | 找不到指定的 Template | 該 template_id 不存在 | 紅色「❌ 404」 |

**缺少欄位時：**
如果沒有填 `API_BASE`、`SITE_KEY` 或 `API_KEY` 就按驗證，網頁不會送出請求，而是直接提示「缺少 API_BASE／SITE_KEY／API_KEY」，對應 CLI 版的錯誤訊息「缺少 API_BASE（或 API_BASE_URL）、SITE_KEY 或 API_KEY」。
![alt text](/imgs/verify-04.png)
![alt text](/imgs/verify-05.png)

### 3.3 網頁版特有的錯誤排查：CORS / 連線失敗

網頁是從瀏覽器直接呼叫 API，和 CLI 版的 `curl` 不同，會多一層**瀏覽器跨來源（CORS）限制**。

| 網頁顯示 | 意義 | 處理方式 |
| --- | --- | --- |
| 紅色「連線失敗」/ `Failed to fetch` | 瀏覽器無法連線或被 CORS 阻擋 | **這通常不是金鑰錯誤。** 確認 `API_BASE` 正確、網路可連線；若是瀏覽器 CORS 阻擋，表示 API 伺服器未允許此頁面的跨來源請求，可改用 `template_manage.sh` 從 CLI 測試金鑰。 |
| 紅色「❌ 403」 | 金鑰或來源驗證失敗 | 檢查 `SITE_KEY` / `API_KEY` 是否正確。 |

> **重點：** 「連線失敗 / Failed to fetch」與「403 金鑰錯誤」是兩回事。前者是瀏覽器 / 網路層面的問題，後者才是憑證問題。網頁會分開提示，避免誤判金鑰無效。

---
## 第四步：設計與上傳 Email Template（以點餐系統為例）

> Template HTML 的設計規範與 CLI 版完全相同；差別只在**上傳方式從指令改成網頁操作**。

### 4.1 設計 Template HTML 規範

為了讓系統能自動把「主旨」與「內文」拆解並送給 API，Email Template HTML 檔必須包含以下兩組自訂標籤：

| **標籤區塊** | **說明** | **處理方式** |
|---|---|---|
| `<!-- SUBJECT -->` ... `<!-- /SUBJECT -->` | **信件主旨** 區塊 | 擷取中間文字，去除前後換行與空白後，作為信件主旨。 |
| `<!-- BODY -->` ... `<!-- /BODY -->` | **信件內文** 區塊 | 完整擷取中間的 HTML 碼，作為信件內文。 |

**語法注意事項**：
1. 標籤必須獨立成行（前後不能有其他 HTML 標籤或文字），否則網頁的解析會無法識別。
2. 使用 HTML 註解 `<!-- -->` 的好處是：直接用瀏覽器開啟 HTML 時，標籤不會干擾畫面呈現。

基本範例（`demo/templates/test_email.html`）：
```html
<!-- SUBJECT -->
訂單確認 - {order_id}
<!-- /SUBJECT -->

<!-- BODY -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>訂單確認</title>
</head>

<body>
  <h1>您好，{customer_name}</h1>
  <p>訂單編號：{order_id}</p>
  <h2>訂單明細</h2>
  <table
      width="100%"
      cellpadding="8"
      cellspacing="0"
      style="border-collapse: collapse;"
    >
      <thead>
        <tr>
          <th>品項</th>
          <th>數量</th>
          <th>單價</th>
          <th>小計</th>
        </tr>
      </thead>

      <tbody>
        {items_html}
      </tbody>
    </table>
  <p>訂單總額：{total}</p>
</body>
</html>
<!-- /BODY -->
```

### 4.2 定義變數（Allowed Variables）

在主旨與內文中，使用大括號 `{variable_name}` 作為動態資料的預留位置（Placeholder）。範例中定義了四個變數：

| Variable | 含義 | 範例值 | Template 中的用途 |
| --- | --- | --- | --- |
| `{order_id}` | 訂單編號 | `TEST-001` | 顯示訂單編號，也可以放在 Email 主旨 |
| `{customer_name}` | 客戶姓名 | `王小明` | 顯示收件人的姓名 |
| `{items_html}` | 訂單明細 HTML | `<tr><td>鮮脆雞腿堡</td><td>1</td><td>NT$95</td><td>NT$95</td></tr>` | 將多筆訂單明細放進 Email |
| `{total}` | 訂單總額 | `NT$250` | 顯示訂單總金額 |

**白名單是自動產生的，不需要手動設定。**
網頁會掃描 SUBJECT 與 BODY 中的 `{variable_name}`，自動建立去重後的 `allowed_variables`，並在上傳前顯示給你確認。這與 CLI 版 `template_manage.sh` 的行為一致（只掃描 SUBJECT + BODY，忽略 CSS / HTML 中其他的大括號）。

### 4.3 本地預覽 HTML

和 CLI 版一樣，可以直接用瀏覽器打開 `demo/templates/test_email.html` 檢查字體、排版，但此時 `{customer_name}`、`{order_id}` 等變數仍只是文字 placeholder。
![alt text](/imgs/upload_template-01.png)

### 4.4 上傳 Template（網頁版）

網頁版不需要 `.env.owner1` 這類環境檔，寄件設定直接在上傳表單中填寫。

操作步驟：

1. 切換到 **「上傳 / 更新」** 分頁。
2. 填入 **`template_id`**（必填），例如 `test_email`。
3. 載入 Template HTML：
   * 把 `.html` 檔**拖進**虛線框，或點虛線框**選擇檔案**；
   * 也可以直接把 HTML 內容**貼進**下方文字框。
   * （若 `template_id` 空白，網頁會以檔名自動帶入。）
4. 按 **「解析 / 預覽變數」**，確認解析出的**主旨**與**自動分析變數**正確無誤。
5. 填入選填的寄件設定（對應 CLI 版 `.env.owner1`）：

   | 網頁欄位 | 對應 `.env.owner1` | 說明 |
   | --- | --- | --- |
   | `from_name` | `TEMPLATE_FROM_NAME` | 寄件者名稱 |
   | `reply_to_email` | `TEMPLATE_REPLY_TO_EMAIL` | 客戶回信 Email |
   | `owner_notify_emails` | `TEMPLATE_OWNER_NOTIFY_EMAILS` | 負責人副本 Email，逗號分隔，最多 5 筆 |

6. 按 **「上傳 / 更新」**。

這個動作等同 CLI 版的：

```bash
source .env.local
source .env.owner1
bash template_manage.sh test_email demo/templates/test_email.html
```

送出的 Request 與 CLI 版相同（`POST /api/email/template`），payload 包含 `template_id`、`subject_template`、`body_html_template`、`allowed_variables`，以及有填才會帶上的 `from_name` / `reply_to_email` / `owner_notify_emails`。

成功後狀態區會顯示綠色「✅ 成功」與 HTTP `200`，代表 Template 已成功上傳。
![imgs/upload_template-02.png](/imgs/upload_template-02.png)

> **upsert（新增即更新）：** 用相同的 `template_id` 再上傳一次，就會更新既有的 Template，與 CLI 版行為一致。

### 4.5 列出 Template，驗證上傳是否成功

切換到 **「列出 / 驗證」** 分頁，按「列出 Templates」。
網頁會把回傳的 Template 以清單呈現，每一筆後面都有「查看」「刪除」按鈕，方便直接操作。

這等同 CLI 版的：

```bash
bash template_manage.sh list
```
![alt text](/imgs/verify-02.png)
![alt text](/imgs/verify-06.png)

### 4.6 查看與刪除 Template

| 動作 | 網頁操作 | 對應 CLI 指令 | API |
| --- | --- | --- | --- |
| 查看單一 | 「查看單一」分頁輸入 `template_id` 按「查看」；或在清單點該筆的「查看」 | `bash template_manage.sh get <template_id>` | `GET /api/email/template/{id}` |
| 刪除 | 「刪除」分頁輸入 `template_id` 按「刪除」（會跳出確認）；或在清單點該筆的「刪除」 | `bash template_manage.sh --delete <template_id>` | `DELETE /api/email/template/{id}` |

刪除成功後會顯示綠色「✅ 成功」。
![alt text](/imgs/verify-07.png)

> 查看與列出只需要 `SITE_KEY`；**上傳與刪除需要 `API_KEY`**。若未填 `API_KEY` 就按上傳 / 刪除，網頁會先提示缺少憑證，不會送出請求。

---
## 第五步：前端系統 HTML 整合與 Local / Deploy 測試

> 這一步與 CLI 版相同。前端系統（如 `test_order.html`）呼叫的是 **Email Notify API**（寄信），和本教材的 Template 管理網頁是兩回事：
>
> * **Template 管理網頁**（`template_manage.html`）：訂閱者自己用，需要 `API_KEY`，負責上傳 / 管理 Template。
> * **前端系統**（`test_order.html`）：給顧客用，只用公開的 `SITE_KEY`，負責送訂單、觸發寄信。

### 5.1 追蹤 API 進入點與 Request 結構

前端呼叫 Email Notify API 的核心程式碼範例如下：

```html
#test_order.html

const response = await fetch(`${cleanApiBase}/api/email/notify`, {
  method: 'POST',
  headers: {
    'X-Site-Key': CONFIG.SITE_KEY,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(payload)
});
```

#### 關鍵元件拆解

| **項目** | **原始程式碼範例** | **說明** |
|---|---|---|
| **API Base URL** | `CONFIG.API_BASE` | API Server 的基礎網域位置 |
| **API Path** | `/api/email/notify` | Email Notify API 的固定端點路徑 |
| **HTTP Method** | `POST` | 將訂單與 Payload 資料傳送到 API |
| **Request Headers** | `X-Site-Key` / `Content-Type` | 提供 Site 身份驗證與 JSON 格式宣告 |
| **Request Body** | `JSON.stringify(payload)` | 真正傳遞給 API 的 Payload 資料 |

### 5.2 Request Payload 與規格對應

實際送出的 Request Body 結構必須嚴格符合 API 規格，欄位名稱（如 `template_id`、`to`、`variables`）不可任意修改：
```html
// 前端產生的 Payload 範例
const payload = {
  template_id: CONFIG.TEMPLATE_ID,
  to: customerEmail,
  variables: {
    order_id: orderId,
    customer_name: customerName,
    items_html: itemsHtml,
    total: `NT$${totalAmount}`
  }
};
```
API 實際接收到的 JSON 範例會是：
```json
{
  "template_id": "test_order",
  "to": "test@example.com",
  "variables": {
    "order_id": "DX-20260930-1234",
    "customer_name": "王小明",
    "items_html": "<tr><td>鮮脆雞腿堡</td><td>1</td><td>NT$95</td><td>NT$95</td></tr>",
    "total": "NT$95"
  }
}
```

### 5.3 Variables 與 Template Placeholder 對應機制

變數(variables) 是前端資料與 Email Template 之間最重要的橋樑。Email Template 中的 Placeholder 必須與 variables 的 Key 完全一致：

| **Email Template Placeholder** | **variables (Key)** | **前端 JavaScript 資料** |
|---|---|---|
| `{order_id}` | `order_id` | `orderId` |
| `{customer_name}` | `customer_name` | `customerName` |
| `{items_html}` | `items_html` | `itemsHtml` |
| `{total}` | `total` | `` `NT$${totalAmount}` `` |

### 5.4 前端 CONFIG 設定檔作用

```html
const CONFIG = {
  API_BASE: 'https://ai-works.uniheart.com.tw',
  SITE_KEY: 'sk_pub_xxxxxx',
  TEMPLATE_ID: 'test_email',
};
```

| **CONFIG 欄位** | **用途** | **程式對應位置** |
|---|---|---|
| `API_BASE` | API Server URL | `fetch(\`${cleanApiBase}/api/email/notify\`)` |
| `SITE_KEY` | Site 驗證資訊 | Request Header：`X-Site-Key` |
| `TEMPLATE_ID` | 指定使用的 Email Template | Payload：`template_id` |

> ⚠️ **重要觀念提醒**
>
> 1. **切勿將私密 API Key 寫在前端**：`SITE_KEY` 僅供前端公開驗證使用；具高度權限的 `API_KEY` 絕對不可放入前端程式碼中。
> 2. 本教材的 Template 管理網頁（`template_manage.html`）雖然會用到 `API_KEY`，但那是**訂閱者本機操作**用的；它要求你每次手動輸入、不寫入檔案，正是為了避免 `API_KEY` 外洩。前端給顧客用的頁面（`test_order.html`）則永遠只用 `SITE_KEY`。

### 5.5 本地測試 Email Notify API

在前端正式部署到 EZ-Deploy 前，可以先模擬前端 Request，確認 Email Notify API 可以正常收到請求。

#### API 測試結果

常見結果：

| 回應 | 說明 |
| --- | --- |
| `200 + SUCCESS` | Request 通過驗證並進入寄信流程 |
| `403 ORIGIN_NOT_ALLOWED` | Origin 不符合允許的網域 |
| `403 TENANT_MISMATCH` | Referer 的租戶資訊不符合 |
| `403 INVALID_SITE_KEY` | Site Key 不正確 |
| `400 MISSING_REQUIRED_FIELD` | Request 缺少必要欄位 |


### 5.6 Deploy 後 E2E 測試

完成本地 API 測試後，將前端系統正式部署到 EZ-Deploy，使用實際網頁進行完整的下單與 Email 發送測試。

#### 5.6.1 上傳系統 HTML

登入 EZ-Deploy，將完成的系統 HTML（本範例使用 `test_order.html`）上傳。
![alt text](/imgs/deploy-01.png)
上傳完成後，在系統列表中找到剛上傳的系統。

#### 5.6.2 設定分享

點擊系統的「分享」，設定分享方式（公開 / 付費解鎖）與分享天數（1 天 / 3 天 / 永久，依訂閱方案為準）。
![alt text](/imgs/deploy-02.png)
![alt text](/imgs/deploy-03.png)
完成後可取得短網址與 QR Code。
![alt text](/imgs/deploy-04.jpg)

#### 5.6.3 完整測試流程

開啟剛建立的分享頁面，完成一次訂單。
```text
EZ-Deploy 分享頁面
        ↓
顧客填寫訂單
        ↓
前端 POST /api/email/notify
        ↓
Email API 驗證
        ↓
取得 Email Template
        ↓
套用 Template Variables
        ↓
SES 寄送 Email
        ↓
顧客收到訂單通知
        ↓
店主 Owner 收到通知
```
確認：

1. 訂單頁面可以正常開啟。
2. 商品可以正常加入訂單。
3. 可以正常送出訂單。
4. 前端使用正確的 `template_id`。
5. Template 中的 placeholder 都能取得對應的訂單資料。
6. Email API 正常處理 Request。
7. 顧客測試信箱收到訂單通知 Email。
8. 店主 Owner 收到負責人通知 Email。
9. Email 中的訂單編號、顧客資料、商品明細、取餐資訊、金額及備註等內容正確顯示。
![alt text](/imgs/deploy-05.jpg)
![alt text](/imgs/deploy-06.jpg)

<table>
  <tr>
    <td>顧客端</td>
    <td><img src="/imgs/deploy-08.jpg"></td>
  </tr>
  <tr>
    <td>商家端</td>
    <td><img src="/imgs/deploy-07.jpg"></td>
  </tr>
</table>

---
## 第六步：Email Service 訂閱者 FAQ

完成 Email Service 設定後，日常使用不需要自行撰寫 Email 安全防護程式。EZ-Deploy Email Service 會自動處理網站來源檢查、寄送頻率限制，以及異常寄信保護。

### Q0.（網頁版）憑證輸入網頁安全嗎？會不會外洩？

安全。`template_manage.html` 是**純前端網頁**，`SITE_KEY` / `API_KEY` 只存在你瀏覽器當下的記憶體中：

* 不會寫進網頁檔案（Key 不是寫死的）。
* 不會自動存進瀏覽器（沒有使用 localStorage / cookie 保存）。
* 重新整理或關閉頁面後就清空，需要重新輸入。

這正是網頁版相較於把 `API_KEY` 放在 `.env` 檔的優勢：不會有金鑰殘留在檔案裡被誤上傳或外洩的風險。前端給顧客的頁面（`test_order.html`）則永遠只用公開的 `SITE_KEY`，不會接觸 `API_KEY`。

### Q0b.（網頁版）出現「連線失敗 / Failed to fetch」是金鑰錯了嗎？

不一定。網頁是從瀏覽器直接呼叫 API，會受瀏覽器**跨來源（CORS）**限制。「連線失敗 / Failed to fetch」通常是 CORS 或網路問題，而不是金鑰錯誤；真正的金鑰問題會回 `403`。若遇到 CORS 阻擋，可改用 CLI 版 `template_manage.sh` 測試金鑰。

### Q1. `Site Key` 和 `API Key` 有什麼不同？

**Site Key** 是前端網站呼叫 Email Notify 時使用的公開識別資訊，可以放在前端程式中。

**API Key** 是管理 Email Template 使用的私密憑證（上傳 / 刪除 / 查看 Template）。`API Key` 不應放在前端 HTML 或 JavaScript 中。

本教材的網頁版把 `API_KEY` 設計成**由使用者當場輸入、不存檔**，避免把 Key 寫死在任何檔案裡。

### Q2. 其他網站拿到我的 Site Key，可以直接拿來寄信嗎？

不行。Email Service 會檢查 Email Notify 請求的網站來源，如果請求不是來自允許的網站，系統會拒絕寄送。正常使用 EZ-Deploy 時，這些來源檢查由平台自動處理。

### Q3. Email Service 有寄送數量限制嗎？

有。

```text
同一 Browser / IP
每分鐘最多 20 封

單一 Site
每小時最多 1,000 封
```

超過限制時系統會暫時拒絕後續寄信請求（網頁上會呈現為 `429`）。前端系統應避免因重複點擊、重複送出訂單或程式錯誤而連續觸發 Email Notify。

### Q4. 什麼是 Bounce 和 Complaint？

**Bounce（退信）**：例如收件人的 Email 地址不存在，導致信件無法送達。
**Complaint（垃圾信檢舉）**：收件者收到 Email 後，將信件標記為垃圾信或進行檢舉。
如果退信或 Complaint 持續增加，可能會影響 Email Service 的正常使用。

### Q5. 如果退信太多，會發生什麼事？

Email Service 會自動啟動保護機制。當：

```text
Bounce Rate > 3%
且
Total Bounce Count > 20
```

系統會將 Email Service 暫停。此機制由平台自動處理。

### Q6. Email Service 被暫停後，Template 還可以管理嗎？

可以。Email Service 暫停後，**Template 管理功能仍然可以使用**（查看 / 上傳 / 修改 / 刪除），也就是說，你仍然可以用這個管理網頁操作 Template，但**所有 Template 的 Email 寄送功能都會暫停**。

### Q7. Email Service 被暫停後，要怎麼恢復？

需要回到 **EZ-Deploy 平台**重新啟用 Email Service。重新啟用後，原本的 Template 可以繼續使用，不需要重新建立。

### Q8. 重新啟用後，需要重新取得金鑰嗎？

不需要。重新啟用 Email Service **不會更換原本的金鑰**，原本的 `Site Key` / `API Key` 仍然可以繼續使用，因此也不需要重新在管理網頁輸入新的金鑰（但因為網頁不存檔，每次開啟仍要重新輸入既有金鑰）。

### Q9. 如果我有好幾個不同系統的 Template 呢？

同一個訂閱者可以有多個不同系統的 Email Template（例如 `burger_order_confirmation`、`drink_order_confirmation`、`booking_confirmation`），這些 Template 都屬於同一個 Email Service。網頁版不需要像 CLI 版準備多份 `.env.owner` 檔，上傳時直接在表單填入各自的寄件設定即可。

### Q10. Template 被暫停後，需要重新上傳嗎？

不需要。服務暫停並不代表 Template 被刪除，Template 資料仍然保留，重新啟用 Email Service 後可以繼續使用原本的 Template。

### Q11. 平常使用 Email Service，我需要自己處理哪些事情？

1. `Site Key` 可以提供前端使用。
2. `API Key` 不要放在前端 HTML 或 JavaScript（本教材的管理網頁會要求你當場輸入、不存檔）。
3. 避免前端重複觸發 Email Notify。
4. 確認 Email Template 中的 Variables 與前端傳入資料一致。
5. 如果 Email Service 被停用，請到 EZ-Deploy 重新啟用服務。

其他像網站來源檢查、寄送頻率限制、Bounce / Complaint 監控、異常寄送保護，都由 EZ-Deploy Email Service 自動處理。

### Q12. Email Service 被停用/暫停時，我還能管理不同系統的 Template 嗎？

可以。服務停用影響的是**Email 寄送功能**，不是 Template 管理功能。即使服務目前是停用 / 暫停狀態，仍然可以用管理網頁完成 Template 的新增、修改、查看或刪除，等重新啟用 Email Service 後再恢復寄送。

---

## 原始碼取得與使用方式

「本手冊以 EZ-Deploy-demo 作為前端整合範例，讀者可從 Github Repository 取得原始碼，並依本手冊成功使用 Email 通知服務」

* 網頁版管理介面：`demo/template_manage.html`
* CLI 版手冊：[`technique_report_manual.md`](./technique_report_manual.md)

[EZ-Deploy-demo GitHub Repository](https://github.com/uniheart-tw/EZ-Deploy-demo.git)
