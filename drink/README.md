# EZ-Deploy 通用 Demo：非技術使用者指南

這套方式可以製作飲料點餐、花店預訂、咖啡點餐、寵物美容預約、課程報名、書店活動、展覽預約，以及其他你能清楚描述的簡易系統。

你不需要修改程式邏輯。每次只要：

1. 用一般中文寫清楚需求。
2. 把 `母prompt.md` 交給 AI。
3. 取得 Web App 與 Email Template。
4. 按 AI 提供的部署資訊調整既有 `upload_template.sh`。
5. 上傳 Template，再部署 Web App。

---

## 一、母 prompt 沒有限定系統類型

`母prompt.md` 不使用固定 preset。請打開文件，只修改最上方的「需求輸入區」。

你可以描述任何系統，只要說明以下內容：

- 這是什麼系統？
- 品牌或活動叫什麼？
- 使用者可以看見或選擇什麼？
- 使用者要填哪些資料？哪些必填？
- 是否有數量、價格、日期、時段或人數？
- 送出前要確認什麼？
- Email 要顯示什麼？
- 希望使用什麼檔名、Template ID 與風格？

不知道檔名、變數或畫面怎麼設計時可以不寫，AI 會自行決定。

---

## 二、怎樣算「需求說明白」？

建議使用這個簡單句型：

```text
我要建立一個「什麼用途」的系統，品牌叫「名稱」。

使用者可以看見……，選擇……，填寫……。
其中……是必填，送出前要顯示……。

確認後寄送 Email，信中要包含……。
希望畫面風格是……。
```

不需要寫 JavaScript、API payload 或變數名稱。

---

## 三、8 種可以直接複製的需求範例

這些只是範例，不是系統限制。你可以自由增刪需求，也可以描述表格中沒有的系統。

### 1. 🧋 飲料店：麻X茶坊

```text
我要建立一個虛構品牌「麻X茶坊」的飲料店線上點餐系統。

顧客可以瀏覽至少 6 款虛構飲料，選擇甜度、冰量、珍珠／椰果／仙草等加料與數量，加入購物車，修改數量、刪除商品並查看小計與總金額。

送出前填寫姓名、Email、手機、取餐方式（店內取餐或外帶）與備註，並看到完整訂單摘要。確認後寄送訂單 Email，信中顯示品牌、訂單編號、顧客資料、商品客製內容、數量、小計、總額、取餐方式與備註。

Web App 檔名使用 drink_order.html，Email Template ID 使用 drink_order_confirmation，Email 主旨使用「麻X茶坊｜您的訂單已收到」。視覺要清爽、明亮、現代、手機優先。
```

預期 Email 變數通常為：

```text
order_id, customer_name, customer_email, customer_phone, items_html,
total, pickup_method, notes, store_name
```

### 2. 💐 花店：花X日常

```text
我要建立虛構品牌「花X日常」的花束預訂系統。顧客可以瀏覽至少 6 款花束，查看用途、色系、尺寸與價格，選擇數量、取貨或配送方式、希望日期，並填寫卡片內容與備註。顧客需填姓名、Email、手機；送出前顯示花束、日期、卡片、聯絡資料與總額摘要，確認後寄送預訂 Email。畫面自然、柔和、有留白。
```

### 3. ☕ 咖啡店：路X咖啡

```text
我要建立虛構品牌「路X咖啡」的線上點餐系統。顧客可以瀏覽咖啡與其他飲品，選擇 Size、熱或冰、糖量、加料與數量，使用購物車並查看總額。送出前填姓名、Email、手機、取餐方式與備註，確認摘要後寄送訂單 Email。畫面溫暖、簡約、適合手機操作。
```

### 4. 🐶 寵物美容：毛X日常

```text
我要建立虛構品牌「毛X日常」的寵物美容預約系統。飼主可以查看洗澡、剪毛、指甲與基礎護理服務，填寫寵物名字、種類、體型，選擇服務、日期與可用時段。飼主需填姓名、Email、手機與備註；送出前顯示完整預約摘要，確認後寄送待確認 Email。不需要購物車。
```

### 5. 🧁 甜點工作室：法X甜點室

```text
我要建立虛構品牌「法X甜點室」的甜點預訂系統。顧客可以瀏覽至少 6 款甜點，選擇口味、尺寸與數量，加入購物車，選擇取貨日期。顧客需填姓名、Email、手機及備註；送出前顯示品項、數量、取貨日期與總額，確認後寄送預訂 Email。畫面精緻、明亮。
```

### 6. 📚 小型課程：學X所

```text
我要建立虛構品牌「學X所」的課程報名系統。使用者可以查看至少 4 門課程的介紹、日期、時間、剩餘名額與費用，選擇課程、場次及報名人數。報名者需填姓名、Email、手機與備註；送出前顯示課程、日期、人數、費用與聯絡資料，確認後寄送報名 Email。不需要購物車。
```

### 7. 📖 獨立書店：青X書室

```text
我要建立虛構品牌「青X書室」的書店與活動網站。使用者可以瀏覽原創選書及書店活動，切換「選書預訂」與「活動報名」。選書可選數量並計算總額；活動可選場次與人數。使用者需填姓名、Email、手機與備註；送出前顯示申請類型及完整摘要，確認後寄送 Email。畫面文藝、安靜、有閱讀感。
```

### 8. 🎨 小型展覽：光X藝文展

```text
我要建立虛構品牌「光X藝文展」的展覽介紹與預約系統。網站要顯示至少 3 個原創展覽、策展介紹、展期與 Gallery placeholder。參觀者可選展覽、日期、時段及人數，填姓名、Email、手機與備註；送出前顯示預約摘要，確認後寄送 Email。不需要購物車或付款。畫面極簡、有大量留白。
```

### 其他系統

你也可以描述：診所一般預約、餐廳訂位、攝影服務預約、租借登記、志工報名、詢價表單、旅遊行程諮詢等。請避免要求收集醫療細節、密碼、信用卡或不必要的敏感資料。

---

## 四、把母 prompt 交給 AI

修改完需求輸入區後，在專案目錄中對 AI 說：

```text
請閱讀 母prompt.md，依照需求完成專案。
請直接建立 Web App 與 Email Template 兩個完整檔案，不要建立 upload_template.sh，不要省略程式碼。
完成後執行 Final Check，並告訴我 TEMPLATE_ID 與 ALLOWED_VARIABLES。
```

AI 應建立：

```text
[web_app].html
templates/[template_id].html
```

AI 不應建立：

```text
upload_template.sh
key.txt
.env
```

完成回覆中應包含：

```text
APP_FILENAME: ...
TEMPLATE_ID: ...
TEMPLATE_FILE: templates/....html
ALLOWED_VARIABLES='["..."]'
```

---

## 五、使用既有 upload_template.sh

`upload_template.sh` 是共用工具，不需要每個 Demo 重新生成。

每次製作新系統時，只需處理：

1. Template ID
2. Template 檔案路徑
3. `ALLOWED_VARIABLES`

### 方法 A：執行時指定 ID 與檔案（建議）

不必修改腳本內的預設 Template ID，直接執行：

```bash
bash upload_template.sh <template_id> templates/<template_id>.html
```

飲料範例：

```bash
bash upload_template.sh drink_order_confirmation templates/drink_order_confirmation.html
```

花店範例：

```bash
bash upload_template.sh flower_preorder_confirmation templates/flower_preorder_confirmation.html
```

### 唯一通常需要修改的地方：ALLOWED_VARIABLES

AI 完成時會提供一整行，例如飲料系統：

```bash
ALLOWED_VARIABLES='["order_id","customer_name","customer_email","customer_phone","items_html","total","pickup_method","notes","store_name"]'
```

打開既有 `upload_template.sh`，找到未被 `#` 註解的這一行：

```bash
ALLOWED_VARIABLES='[...]'
```

用 AI 提供的完整一行取代它。不要自己重新拼字或增加變數。

必須符合：

```text
Web App variables
= Email Template 的 {placeholder}
= upload_template.sh 的 ALLOWED_VARIABLES
```

如果三者不同，上傳或寄信可能失敗。

### 什麼時候要修改腳本預設值？

如果你不想每次在命令後輸入 Template ID，可以修改：

```bash
TEMPLATE_ID="${1:-你的_template_id}"
```

模板路徑保持通用即可：

```bash
TEMPLATE_FILE="${2:-$SCRIPT_DIR/templates/${TEMPLATE_ID}.html}"
```

這不是必要步驟；使用方法 A 最不容易出錯。

---

## 六、金鑰怎麼處理？

### 三種名稱不要混淆

| 名稱 | 格式 | 可否放 Web App | 用途 |
|---|---|---:|---|
| Public Site Key | `sk_pub_...` | 可以 | Web App 呼叫 notify |
| Site Secret | `sk_secret_...` | 不可以 | 私密憑證 |
| Private API Key | `api_key_...` | 不可以 | 上傳 Email Template |

建議共用 `upload_template.sh` 只從 Terminal 環境變數讀取：

```bash
API_BASE="${API_BASE:?請先設定 API_BASE}"
SITE_KEY="${SITE_KEY:?請先設定 SITE_KEY}"
API_KEY="${API_KEY:?請先設定 API_KEY}"
```

不要把真實私密值寫死在腳本、`key.txt`、README、母 prompt 或 Web App。

在 macOS Terminal 設定：

```bash
export API_BASE="https://你的-EZ-Deploy-網域"
export SITE_KEY="sk_pub_你的公開SiteKey"
read -s API_KEY
export API_KEY
echo
```

`read -s` 輸入時畫面不顯示文字是正常的。

> 如果目前共用腳本仍寫死私密 API Key，先請維護者把它改為環境變數，並在 EZ-Deploy 後台輪替已寫入檔案的舊憑證。

---

## 七、上傳 Email Template

1. macOS 第一次使用先安裝 `jq`：

```bash
brew install jq
```

2. 設定環境變數。
3. 把 AI 提供的 `ALLOWED_VARIABLES` 複製到共用腳本。
4. 執行：

```bash
bash upload_template.sh <template_id> templates/<template_id>.html
```

5. 看到 `HTTP 200` 或「模板上傳成功」才算完成。

每次 Email Template 或變數有改動，都要重新上傳。

---

## 八、設定與部署 Web App

Web App 中會有：

```javascript
const CONFIG = {
  API_BASE: '[EZ-DEPLOY API BASE]',
  SITE_KEY: '[SITE_KEY]',
  TEMPLATE_ID: '實際的_template_id',
  STORE_NAME: '虛構品牌名稱'
};
```

部署前只替換：

```javascript
API_BASE: 'https://你的-EZ-Deploy-網域',
SITE_KEY: 'sk_pub_你的公開SiteKey',
```

不可放入：

```text
sk_secret_...
api_key_...
```

部署後網址必須類似：

```text
https://你的網域/uploads/org_你的組織ID/你的網頁.html
```

`org_...` 必須與 Public Site Key 所屬組織一致。不要用 `file://` 當成正式寄信測試，也不要設定 `no-referrer`。

---

## 九、以飲料系統測試

1. 開啟部署後的 `drink_order.html`。
2. 選一杯飲料及不同甜度、冰量、加料。
3. 加入購物車並修改數量。
4. 確認小計與總額。
5. 填姓名、測試 Email、手機、取餐方式與備註。
6. 查看訂單摘要並返回修改一次。
7. 再確認送出。
8. 確認頁面顯示訂單編號。
9. 確認收到 Email，且品牌、商品客製、數量、金額與資料正確。

飲料範例若使用動態品牌，通常共有 **9 個變數**：

```text
order_id
customer_name
customer_email
customer_phone
items_html
total
pickup_method
notes
store_name
```

其他系統的變數數量不一定是 9；以 AI 每次提供的 `ALLOWED_VARIABLES` 為準。

---

## 十、常見錯誤

| 錯誤 | 原因 | 處理方式 |
|---|---|---|
| URL 含 `[EZ-DEPLOY API BASE]` | Web App 還沒填 API Base | 換成完整 HTTPS API Base 後重新部署 |
| `favicon.ico 403` | HTML 沒有指定 favicon | 請 AI 加入 data URL favicon |
| `INVALID_SITE_KEY` | Public Site Key 錯誤 | 從後台重新複製 `sk_pub_...` |
| `ORIGIN_NOT_ALLOWED` | 部署網域不被允許 | 使用正確 EZ-Deploy 網域或檢查後台設定 |
| `TENANT_MISMATCH` | org 路徑與 Site Key 不同，或 Referer 不完整 | 部署到正確 `/uploads/org_.../`，不要設定 `no-referrer` |
| `NOT_FOUND` | Template 未上傳或 ID 不一致 | 上傳模板並核對 Template ID |
| 變數錯誤 | 三處變數集合不同 | 複製 AI 最新的 `ALLOWED_VARIABLES` 後重新上傳模板 |
| `EMAIL_QUOTA_EXCEEDED` | 本月額度用完 | 查看方案或等待重置 |
| `RATE_LIMITED` | 短時間送出太多次 | 稍後再試 |
| `SITE_DISABLED`／`SITE_SUSPENDED` | Email 服務停用 | 到後台確認狀態 |

正確 notify URL 應類似：

```text
https://你的-EZ-Deploy-網域/api/email/notify
```

不應包含：

```text
/uploads/org_.../[EZ-DEPLOY API BASE]/api/email/notify
```

---

## 十一、每次完成後檢查

- [ ] 我只修改了母 prompt 的需求輸入區
- [ ] AI 只建立 Web App 與 Email Template
- [ ] AI 沒有建立或覆寫 `upload_template.sh`
- [ ] AI 提供了 Template ID、Template 路徑與 `ALLOWED_VARIABLES`
- [ ] 我已把最新 `ALLOWED_VARIABLES` 複製到共用腳本
- [ ] Email Template 上傳成功
- [ ] Web App 只包含公開 `sk_pub_...`
- [ ] Web App 位於正確 `/uploads/org_.../` 路徑
- [ ] 送出前可以確認並返回修改
- [ ] 測試 Email 已收到且內容正確
- [ ] 專案沒有真實 `sk_secret_...`、`api_key_...`、密碼或 TODO

完成後，只需重新改寫需求輸入區，就能製作下一個完全不同的 Demo。
