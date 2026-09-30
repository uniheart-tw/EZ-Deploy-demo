# EZ-Deploy Email 通知服務 實戰指南 (訂閱者手冊) --手刻版

> 前提：已經訂閱擁有 Email 通知服務 的付費方案

## EZ-Deploy 系統架構與跨角色互動全景圖
![alt text](/imgs/architecture.png)

訂閱者 / 設計者 (User)：
* 登入 EZ-Deploy 平台，啟用 Email 通知服務並上傳系統HTML。   
* 透過CLI的方式上傳設計好的 Email Template到EZ-Deploy資料庫
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
## 第二步：系統環境準備

>在開始 EZ-Deploy Email 通知服務實作前，先完成本機環境與專案目錄準備。
---

### 2.1 環境需求

本教材使用 Shell Script 操作 Email API，因此本機需要準備以下工具：

* Bash
* curl
* jq

確認工具是否已安裝：

```bash
bash --version
curl --version
jq --version
```
![alt text](/imgs/env-01.png)
如果 macOS 尚未安裝 `jq`，可以使用：

```bash
brew install jq
```

#### macOS 使用者

macOS 可以直接使用 Terminal 執行本教材的 Bash Script。

例如：
```bash
bash template_manage.sh order_confirmation templates/order_confirmation.html
bash template_manage.sh template_id template_file
```
不需要另外建立 Python 虛擬環境。

#### Windows 使用者

本教材的 `.sh` Script 是使用 **Bash** 撰寫，因此 Windows 使用者建議使用：

**WSL（Windows Subsystem for Linux）+ Ubuntu**

不建議直接使用 PowerShell 執行本教材的 `.sh` Script。

安裝 WSL / Ubuntu 後，在 Ubuntu Terminal 中確認：

```bash
bash --version
curl --version
jq --version
```

如果沒有 `jq`：

```bash
sudo apt update
sudo apt install jq
```

之後即可使用與 macOS 相同的指令，例如：

```bash
bash template_manage.sh order_confirmation templates/order_confirmation.html
bash template_manage.sh template_id template_file
```

> **為什麼 Windows 建議使用 WSL？**
>
> 本教材會使用 Bash 語法與 Shell Script，例如：
>
> ```bash
>bash template_manage.sh order_confirmation templates/order_confirmation.html
>bash template_manage.sh template_id template_file
> ```
>
> 如果直接改用 PowerShell，`.sh` Script 語法都會不同，因此需要另外修改教材中的指令與 Script。
>
> 為了讓 macOS、Linux 與 Windows 使用者都能使用同一套教材，本教材統一以 **Bash** 為操作環境；Windows 使用者使用 **WSL + Ubuntu** 即可。

---

### 2.2 建立專案目錄

建立教材專案：

```bash
mkdir EZ-Deploy-demo
cd EZ-Deploy-demo
```

建立目前使用的系統和email樣板：

```bash
mkdir -p demo/templates
```

專案目錄：

```text
EZ-Deploy-demo/
├── .env.local
├── .env.owner1
├── template_manage.sh
├── README.md
│
└── demo/
    ├── templates/
    │   └── test_email.html
    └── test_order.html
```

其中：

| 檔案 / 目錄                         | 用途                                  |
| ------------------------------- | ----------------------------------- |
| `.env.local`                    | 本機測試環境與key存放                |
| `.env.owner1`                    | 店主 的 Email Template 設定（比如寄件者名稱，負責人副本，客戶回信地址）|
| `README.md`                     | 專案說明                                |
| `demo/`                        | demo 系統                            |
| `template_manage.sh`            | 上傳 / 刪除 / 查看 Email Template 的 CLI Script |
| `templates/`                    | Email Template 檔案                   |
| `test_email.html` | demo 系統的 Email Template            |
| `test_order.html` | demo 系統的前端|
---

### 2.3 設定 `.env.local`

`.env.local` 放置本機測試時使用的環境變數。

先執行
```bash
cp .env.local.example .env.local
```
得到下面的內容：
```bash
# .env.local
export API_BASE="https://ai-works.uniheart-ai.com/"
export SITE_KEY="sk_pub_xxxxxxxxx" #替換成自己的
export API_KEY="api_key_xxxxxxxxx" #替換成自己的
```

#### 注意事項
建立.env.local的目的是將這些「環境設定 / 敏感資訊」與 template_manage.sh 的程式碼分開。

這樣 template_manage.sh 不需要把 API Key 直接寫死在 Script 裡，也方便之後更換測試環境

---

### 2.4 載入環境變數

每次開啟新的 Terminal Session 時，可以執行：

```bash
source .env.local
```

確認環境變數是否已載入：

```bash
echo $API_BASE
echo $SITE_KEY
```

---
## 第三步：金鑰有效性測試與錯誤排查

### 3.1 驗證 Site Key 與 API Key

載入環境變數
```bash
source .env.local
```

第一次執行：
因為還沒有上傳過所以data會為空，但是"code": "SUCCESS"，代表取得的SITE_KEY和API_KEY沒有問題
```
bash template_manage.sh list
```

![alt text](/imgs/verify-03.png)
確認成功後，即可進入下一步建立 Email Template。

### 3.2 判斷結果

| HTTP Status | Response Code / Message | 可能原因                    | 代表什麼           |
| ----------- | ----------------------- | ----------------------- | -------------- |
| `200`       | `SUCCESS`               | Site Key 與 API Key 驗證成功 | 金鑰有效，可以繼續下一步   |
| `403`       | `INVALID_API_KEY`       | API Key 無效或不存在          | API Key 無法通過驗證 |
| `403`       | `INVALID_API_KEY`       | Site Key 或 API Key 無效   | SITE_KEY無法通過驗證     |

如果缺少API_BASE，會得到錯誤：缺少 API_BASE（或 API_BASE_URL）、SITE_KEY 或 API_KEY。
![alt text](/imgs/verify-04.png)
![alt text](/imgs/verify-05.png)

---
## 第四步：設計與上傳 Email Template（以點餐系統為例）

### 4.1 設計 Template HTML 規範
為了讓 template_manage.sh 能自動將「主旨」與「內文」拆解並送給 API，Email Template HTML檔必須包含以下兩組自訂標籤：

| **標籤區塊** | **說明** | **處理方式** |
|---|---|---|
| `<!-- SUBJECT -->` ... `<!-- /SUBJECT -->` | **信件主旨** 區塊 | 腳本會擷取中間文字，去除前後換行與空白後，作為信件主旨。 |
| `<!-- BODY -->` ... `<!-- /BODY -->` | **信件內文** 區塊 | 腳本會完整擷取中間的 HTML 碼，作為信件內文。 |

**語法注意事項**：
1. 標籤必須獨立成行（前後不能有其他 HTML 標籤或文字），否則解析腳本會無法識別。
2. 使用 HTML 註解 <!-- --> 的好處是：直接用瀏覽器開啟 HTML 時，標籤不會干擾畫面呈現。

因此，下面提供比較基本的Email Template：
```html
# test_email.html
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

程式說明Email Template的內容：
- 範例的主旨是訂單確認-訂單編號{order_id}
- 範例的主要內容包括顧客的姓名{customer_name}，訂單編號{order_id}，訂單明細（訂購的商品數量，金額等）{items_html}，訂單總金額{total}


### 4.2 定義變數白名單（Allowed Variables）
在 主旨 與 主要內容 中，我們使用大括號 {variable_name} 作為動態資料的預留位置（Placeholder）。

在範例中，我們定義了四個變數(Variables)：

| Variable          | 含義        | 範例值                | Template 中的用途         |
| ----------------- | --------- | ------------------ | --------------------- |
| `{order_id}`      | 訂單編號      | `TEST-001`         | 顯示訂單編號，也可以放在 Email 主旨 |
| `{customer_name}` | 客戶姓名      | `王小明`              | 顯示收件人的姓名              |
| `{items_html}`    | 訂單明細 HTML | `<tr><td>鮮脆雞腿堡</td><td>1</td><td>NT$95</td><td>NT$95</td></tr>` | 將多筆訂單明細放進 Email       |
| `{total}`         | 訂單總額      | `NT$250`           | 顯示訂單總金額               |

**為什麼要設定變數白名單？**
後端寄信服務只會替換白名單內的變數，這樣可以防止未授權或非預期的變數注入，確保渲染安全性。

**特別說明：動態列表變數（例如 {items_html}）是如何產生的？**
您可能會好奇，為什麼 Email 模板裡沒有 for 迴圈語法（例如 {% for item in items %}）？
  1. 設計理念： 為了讓 Email 模板保持單純，本系統採用 「純字串替換」 機制。
  2. 前端處理方式： 顧客在點餐網頁（前端）完成選購後，前端 JavaScript 會將購物車（cart）資料透過 map() 迴圈拼成包含樣式的 <table> 或 <tr> HTML 字串，再將這串 HTML 填入 items_html 變數發送給寄信 API。


### 4.3 本地預覽 HTML

直接用瀏覽器打開`templates/test_email.html`檢查字體，排版等是否有問題

但是這時候 {customer_name}、{order_id} 等變數還只是文字 placeholder。

![alt text](/imgs/upload_template-01.png)

### 4.4 上傳Email Template前的環境設定

每个订阅者可以针对所服务的不同店主或系统，使用独立的 Owner env 配置档，不需要修改共用的template_manage.sh。

先執行：
```bash
cp .env.owner.example .env.owner1
```

編輯 `.env.owner1`：

```bash
# .env.owner1
export TEMPLATE_ID="test_email"
export TEMPLATE_FILE="templates/test_email.html"
export TEMPLATE_FROM_NAME="寄件者名稱"
export TEMPLATE_OWNER_NOTIFY_EMAILS="負責人副本 Email"
export TEMPLATE_REPLY_TO_EMAIL="客戶回信 Email"
```

`TEMPLATE_ID` 是 Template 名稱，`TEMPLATE_FILE` 是 HTML Template 檔案，其他欄位是寄件與回信設定。`ALLOWED_VARIABLES` 不需要手動設定；腳本會掃描 SUBJECT 與 BODY 中的 `{variable_name}`，自動建立完整且去重的變數白名單。

載入 API 憑證與指定樣板和店主的設定：
```bash
source .env.local
source .env.owner1
bash template_manage.sh list
```

開發另一個系統時，改用另一份設定檔即可：
```bash
source .env.local
source .env.owner2
bash template_manage.sh list
```

**特別說明**
.env.owner1、.env.owner2、.env.owner3 是用来区分不同店主 / 系统实例的业务配置，让同一个 template_manage.sh 可以针对不同的店主或系统上传、管理对应的 Email Template，而不需要修改脚本本身。

### 4.5 使用 template_manage.sh 上傳Email Template
```bash
bash template_manage.sh test_email demo/templates/test_email.html
```
成功後應看到類似：
![imgs/upload_template-02.png](/imgs/upload_template-02.png)
代表 Template 已經被成功上傳。

### 4.6 列出Email模板，驗證上傳是否成功
執行：
```bash
bash template_manage.sh list
```
![alt text](/imgs/verify-02.png)

### 4.7 template_manage.sh其他使用方法
- 完成上傳後，可以使用：
```bash
bash template_manage.sh list
```
確認 burger_order_confirmation(template_id) 已經出現在 Template 清單中。
![alt text](/imgs/verify-06.png)
- 刪除 Template：
```bash
bash template_manage.sh --delete test_email
```
![alt text](/imgs/verify-07.png)

---

## 第五步：前端系統 HTML 整合與 Local / Deploy 測試

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

---

### 5.2 Request Payload 與規格對應
實際送出的 Request Body 結構必須嚴格符合 API 規格，欄位名稱（如 template_id、to、variables）不可任意修改：
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
以上作為參考

---

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
  API_BASE: 'https://ai-works.uniheart-ai.com',
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
> 1. **切勿將私密 API Key 寫在前端**：`SITE_KEY` 僅供前端公開驗證使用；具高度權限的管理 Token 絕對不可放入前端程式碼中。

### 5.5 本地測試 Email Notify API

在前端正式部署到 EZ-Deploy 前，可以先使用 `curl` 模擬前端 Request，確認 Email Notify API 可以正常收到請求。

```bash
curl -i "$API_BASE/api/email/notify" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-Site-Key: $SITE_KEY" \
  -H "Origin: https://ai-works.uniheart-ai.com/" \
  -H "Referer: https://your-test-site.example/..." \
  -d '{
    "template_id": "test_order",
    "to": "your-test-email@example.com",
    "variables": {
      "order_id": "TEST-001",
      "customer_name": "王小明",
      "items_html": "<tr><td>雞腿堡</td><td>1</td><td>NT$95</td><td>NT$95</td></tr>",
      "total": "NT$95"
    }
  }'
```
#### API 測試結果

常見結果：

| 回應                           | 說明                  |
| ---------------------------- | ------------------- |
| `200 + SUCCESS`              | Request 通過驗證並進入寄信流程 |
| `403 ORIGIN_NOT_ALLOWED`     | Origin 不符合允許的網域     |
| `403 TENANT_MISMATCH`        | Referer 的租戶資訊不符合    |
| `403 INVALID_SITE_KEY`       | Site Key 不正確        |
| `400 MISSING_REQUIRED_FIELD` | Request 缺少必要欄位      |

本地測試的目的，是先確認 Request 可以正常送到 Email API。

由於本地並不是從實際 EZ-Deploy 網頁發送請求，所以執行上述指令是，`Referer` 中的租戶資訊可能與 Site 不符，因此收到：

```text
403 TENANT_MISMATCH
```
![alt text](/imgs/local_test.png)

這代表 API 已經收到 Request，並進入來源與租戶驗證流程（是正常的，部署HTML到EZ-Deploy不會出錯）。

> **注意：** 本地測試出現 `ORIGIN_NOT_ALLOWED` 或 `TENANT_MISMATCH`，不代表正式部署後一定會失敗。正式部署到 EZ-Deploy 後，前端網頁會由瀏覽器自動帶入實際的 `Origin` / `Referer`，因此需要再從實際部署的網頁進行一次完整的 Email 發送測試。

---

### 5.6 Deploy 後 E2E 測試

完成本地 API 測試後，將前端系統正式部署到 EZ-Deploy，使用實際網頁進行完整的下單與 Email 發送測試。

#### 5.6.1 上傳系統 HTML

登入 EZ-Deploy，將完成的系統 HTML 上傳。

本範例使用：

```text
test_order.html
```
![alt text](/imgs/deploy-01.png)
上傳完成後，在系統列表中找到剛上傳的系統。

#### 5.6.2 設定分享

點擊系統的「分享」，設定系統的分享方式。

可依需求設定：

* 公開
* 付費解鎖

並設定分享天數，例如：

* 1 天
* 3 天
* 永久

實際可使用的分享期限依 EZ-Deploy 的訂閱方案功能為準。
![alt text](/imgs/deploy-02.png)
![alt text](/imgs/deploy-03.png)
完成設定後，可以取得：

* 短網址
* QR Code

使用短網址或 QR Code 開啟實際的訂單頁面。
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

<table >
  <tr>
    <td>顧客端</td>
    <td><img src="/imgs/deploy-08.jpg"></td>
    
  </tr>
  <tr>
    <td>商家端</td>
        <td><img src="/imgs/deploy-07.jpg" ></td>
  </tr>
</table>

---

## 第六步：Email Service 訂閱者 FAQ

完成 Email Service 設定後，日常使用不需要自行撰寫 Email 安全防護程式。
EZ-Deploy Email Service 會自動處理網站來源檢查、寄送頻率限制，以及異常寄信保護。

以下整理訂閱者最常遇到的問題。

---

### Q1. `Site Key` 和 `API Key` 有什麼不同？

**Site Key** 是前端網站呼叫 Email Notify 時使用的公開識別資訊，可以放在前端程式中。

**API Key** 是管理 Email Template 使用的私密憑證，例如：

* 上傳 Template
* 刪除 Template
* 查看 Template

`API Key` 不應放在前端 HTML 或 JavaScript 中。

本教材的 `template_manage.sh` 會從 CLI 的環境變數取得 `API_KEY`，避免直接把 Key 寫在 Script 裡。

---

### Q2. 其他網站拿到我的 Site Key，可以直接拿來寄信嗎？

不行。

Email Service 會檢查 Email Notify 請求的網站來源。
如果請求不是來自允許的網站，系統會拒絕寄送。

正常使用 EZ-Deploy 時，這些來源檢查會由平台自動處理，訂閱者不需要自行開發。

---

### Q3. Email Service 有寄送數量限制嗎？

有。

目前 Email Service 會限制寄送頻率：

```text
同一 Browser / IP
每分鐘最多 20 封

單一 Site
每小時最多 1,000 封
```

如果超過限制，系統會暫時拒絕後續寄信請求。

因此，前端系統應避免因為重複點擊、重複送出訂單或程式錯誤而連續觸發 Email Notify。

---

### Q4. 什麼是 Bounce 和 Complaint？

Email 寄出後，系統會持續監控寄送結果。

**Bounce（退信）**

例如收件人的 Email 地址不存在，導致信件無法送達。

**Complaint（垃圾信檢舉）**

收件者收到 Email 後，將信件標記為垃圾信或進行檢舉。

如果退信或 Complaint 持續增加，可能會影響 Email Service 的正常使用。

---

### Q5. 如果退信太多，會發生什麼事？

Email Service 會自動啟動保護機制。

目前當：

```text
Bounce Rate > 3%

且

Total Bounce Count > 20
```

系統會將 Email Service 暫停。

這項機制是平台自動處理，訂閱者不需要自行設定。

---

### Q6. Email Service 被暫停後，Template 還可以管理嗎？

可以。

Email Service 暫停後，**Template 管理功能仍然可以使用**。

也就是說，訂閱者仍然可以：

* 查看 Template
* 上傳 Template
* 修改 / 更新 Template
* 刪除 Template

但是，**所有 Template 的 Email 寄送功能都會暫停**。

例如同一個訂閱者有：

```text
burger_order_confirmation
drink_order_confirmation
booking_confirmation
```

即使只有其中一個 Template 發生大量退信，當 Email Service 進入停用狀態後，這個訂閱者底下的 Email Template 都會暫停寄送。

---

### Q7. Email Service 被暫停後，要怎麼恢復？

需要回到 **EZ-Deploy 平台**重新啟用 Email Service。

重新啟用後，原本的 Template 可以繼續使用，不需要重新建立。

---

### Q8. 重新啟用後，需要重新取得金鑰嗎？

不需要。

重新啟用 Email Service **不會更換原本的金鑰**。

原本的：

```text
Site Key
API Key
```

仍然可以繼續使用。

因此，前端系統與 `template_manage.sh` 不需要因為重新啟用服務而重新設定金鑰。

---

### Q9. 如果我有好幾個不同系統的 Template 呢？

同一個訂閱者可以有多個不同系統的 Email Template。

例如：

```text
漢堡店
└── burger_order_confirmation

飲料店
└── drink_order_confirmation

預約系統
└── booking_confirmation
```

這些 Template 都屬於同一個 Email Service。

如果 Email Service 因為退信或 Complaint 進入停用狀態，**這些 Template 的寄信功能都會一起暫停**。

重新在 EZ-Deploy 啟用 Email Service 後，這些 Template 才會恢復寄送。

---

### Q10. Template 被暫停後，需要重新上傳嗎？

不需要。

服務暫停並不代表 Template 被刪除。

Template 資料仍然保留，訂閱者仍然可以查看及管理 Template。

重新啟用 Email Service 後，可以繼續使用原本的 Template。

---

### Q11. 平常使用 Email Service，我需要自己處理哪些事情？

訂閱者主要注意以下幾件事情：

1. `Site Key` 可以提供前端使用。
2. `API Key` 不要放在前端 HTML 或 JavaScript。
3. 避免前端重複觸發 Email Notify。
4. 確認 Email Template 中的 Variables 與前端傳入資料一致。
5. 如果 Email Service 被停用，請到 EZ-Deploy 重新啟用服務。

其他像是：

* 網站來源檢查
* 寄送頻率限制
* Bounce 監控
* Complaint 監控
* 異常寄送保護

都由 EZ-Deploy Email Service 自動處理。

---

### Q12. Email Service 被停用/暫停時，我還能管理不同系統的 Template 嗎？

可以。

服務停用影響的是**Email 寄送功能**，不是 Template 管理功能。

因此，即使服務目前是停用/暫停狀態，訂閱者仍然可以先完成 Template 的新增、修改、查看或刪除，等重新啟用 Email Service 後再恢復寄送。

---

## 原始碼取得與使用方式

「本手冊以 EZ-Deploy-demo 作為前端整合範例，讀者可從 Github Repository 取得原始碼，並依本手冊成功使用Email通知服務」

[EZ-Deploy-demo GitHub Repository](https://github.com/uniheart-tw/EZ-Deploy-demo.git)