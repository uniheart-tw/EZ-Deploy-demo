#!/usr/bin/env bash
#
# upload_template.sh — 範例：透過 POST /api/email/template 上傳 Email 模板
#
# 用途：
#   讀取一份「獨立信件模板檔」（含 <!-- SUBJECT --> / <!-- BODY --> 兩區，可直接在
#   瀏覽器預覽），解析後拆成 POST /api/email/template 需要的
#   subject_template / body_html_template，上傳到自己的 Site 帳號下。
#   同時示範 Issue #181 的用戶層設定：from_name（此模板專屬的寄件人顯示名稱）、
#   owner_notify_emails（負責人副本，notify 時後端自動 Cc，前端無法覆蓋）、
#   reply_to_email（消費者回信導向的信箱）。
#   驗證方式為 X-Api-Key（API Key）+ X-Site-Key（公開 Site Key），無需 Cognito。
#   契約來源：docs/api/email.md（## POST /api/email/template）
#
# 模板檔格式（見 templates/drink_order_confirmation.html）：
#   主旨區：<!-- SUBJECT --> ... <!-- /SUBJECT -->   純文字，可含 {變數}
#   內文區：<!-- BODY -->    ... <!-- /BODY -->      HTML，可含 {變數}
#
# 需要的憑證（於後台「啟用 Email 服務」或「重新產生金鑰」時取得，僅顯示一次）：
#   - SITE_KEY   公開 Site Key，格式 sk_pub_xxxxx
#   - API_KEY    私密 API Key，格式 api_key_xxxxx（切勿外流 / 切勿嵌前端 / 切勿寫死進檔案）
#
# 用法：
#   export API_BASE="https://dev-ai-works.uniheart-ai.com"
#   export SITE_KEY="sk_pub_xxxxxxxxxxxx"
#   export API_KEY="api_key_xxxxxxxxxxxx"
#   bash upload_template.sh
#
#   自訂 template_id 與模板檔：
#   bash upload_template.sh <template_id> <template_html_file>
#
#   自訂用戶層設定（皆選填，未設定則沿用 SITE# 層級預設）：
#   export TEMPLATE_FROM_NAME="麻古華榮店"
#   export TEMPLATE_OWNER_NOTIFY_EMAILS="owner@example.com,manager@example.com"
#   export TEMPLATE_REPLY_TO_EMAIL="service@example.com"
#
set -euo pipefail

# ─── 設定 ────────────────────────────────────────────────────────────────
API_BASE="https://dev-ai-works.uniheart-ai.com"
SITE_KEY="sk_pub_9tvpxpg22imoxo9l"
API_KEY="api_key_mawtec28k31frb0v9ax2520l"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 模板識別碼（前端 notify 時用同一個 template_id 指定要寄的模板）
TEMPLATE_ID="${1:-drink_order_confirmation}"

# 模板檔（預設對應 template_id 的檔案）
TEMPLATE_FILE="${2:-$SCRIPT_DIR/templates/${TEMPLATE_ID}.html}"

# 允許的變數清單（供後端／文件參考；需與模板 {placeholder} 對應）
# ALLOWED_VARIABLES='["order_id","customer_name","store_name","items_html","item_count","total","pickup_time"]'
ALLOWED_VARIABLES='["order_id","customer_name","store_name","customer_email","customer_phone","items_html","total","pickup_method","notes"]'
# 用戶層設定（Issue #181，皆選填）：
#   FROM_NAME             此模板專屬的寄件人顯示名稱（未設則 notify 時 fallback 到 SITE#.default_from_name）
#   OWNER_NOTIFY_EMAILS   負責人副本，逗號分隔多筆（notify 時後端自動加入 Cc，前端無法覆蓋）
#   REPLY_TO_EMAIL        消費者回信導向的信箱
TEMPLATE_FROM_NAME="${TEMPLATE_FROM_NAME:-麻X茶坊}"
TEMPLATE_OWNER_NOTIFY_EMAILS="${TEMPLATE_OWNER_NOTIFY_EMAILS:-diya2026@163.com}"
TEMPLATE_REPLY_TO_EMAIL="${TEMPLATE_REPLY_TO_EMAIL:-diya2026@163.com}"

# ─── 前置檢查 ────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
    echo "錯誤：需要 jq 來安全組裝 JSON。請先安裝 jq（brew install jq）。" >&2
    exit 1
fi
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "錯誤：找不到模板檔：$TEMPLATE_FILE" >&2
    exit 1
fi

# ─── 解析模板檔：抽出 SUBJECT / BODY 兩區 ────────────────────────────────
# 用 awk 依標記擷取區塊內容（標記本身不納入）。
# 只認「整行 trim 後正好等於標記」的行當分隔，避免說明文字中提到標記時誤判。
extract_block() {
    # $1 = 起始標記, $2 = 結束標記, $3 = 檔案
    awk -v start="$1" -v end="$2" '
        function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s; }
        { line = trim($0); }
        line == end   { grab=0 }
        grab          { print }
        line == start { grab=1 }
    ' "$3"
}

SUBJECT_RAW="$(extract_block '<!-- SUBJECT -->' '<!-- /SUBJECT -->' "$TEMPLATE_FILE")"
BODY_RAW="$(extract_block '<!-- BODY -->' '<!-- /BODY -->' "$TEMPLATE_FILE")"

# 主旨去除前後空白／換行（主旨應為單行純文字）
SUBJECT_TEMPLATE="$(printf '%s' "$SUBJECT_RAW" | tr -d '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
BODY_HTML_TEMPLATE="$BODY_RAW"

if [ -z "$SUBJECT_TEMPLATE" ]; then
    echo "錯誤：模板檔缺少 <!-- SUBJECT --> ... <!-- /SUBJECT --> 區塊或內容為空。" >&2
    exit 1
fi
if [ -z "$(printf '%s' "$BODY_HTML_TEMPLATE" | tr -d '[:space:]')" ]; then
    echo "錯誤：模板檔缺少 <!-- BODY --> ... <!-- /BODY --> 區塊或內容為空。" >&2
    exit 1
fi

# 把逗號分隔的 OWNER_NOTIFY_EMAILS 轉成 JSON 陣列（空字串則為空陣列）
if [ -n "$TEMPLATE_OWNER_NOTIFY_EMAILS" ]; then
    OWNER_EMAILS_JSON="$(printf '%s' "$TEMPLATE_OWNER_NOTIFY_EMAILS" | jq -R -c 'split(",") | map(gsub("^\\s+|\\s+$";""))')"
else
    OWNER_EMAILS_JSON='[]'
fi

# ─── 組裝 request body（用 jq 確保 JSON 正確跳脫；用戶層欄位選填、空值不帶入）──
PAYLOAD="$(jq -n \
    --arg tid "$TEMPLATE_ID" \
    --arg subj "$SUBJECT_TEMPLATE" \
    --arg body "$BODY_HTML_TEMPLATE" \
    --argjson vars "$ALLOWED_VARIABLES" \
    --arg from_name "$TEMPLATE_FROM_NAME" \
    --argjson owner_emails "$OWNER_EMAILS_JSON" \
    --arg reply_to "$TEMPLATE_REPLY_TO_EMAIL" \
    '{template_id:$tid, subject_template:$subj, body_html_template:$body, allowed_variables:$vars}
     + (if $from_name != "" then {from_name:$from_name} else {} end)
     + (if ($owner_emails | length) > 0 then {owner_notify_emails:$owner_emails} else {} end)
     + (if $reply_to != "" then {reply_to_email:$reply_to} else {} end)')"

echo "── 上傳模板到 ${API_BASE}/api/email/template ──"
echo "template_id: ${TEMPLATE_ID}"
echo "template_file: ${TEMPLATE_FILE}"
echo "site_key:    ${SITE_KEY}"
echo "subject:     ${SUBJECT_TEMPLATE}"
echo "from_name:   ${TEMPLATE_FROM_NAME:-（未設，寄信時 fallback SITE#.default_from_name）}"
echo "owner_notify_emails: ${TEMPLATE_OWNER_NOTIFY_EMAILS:-（未設，寄信時不加 Cc）}"
echo "reply_to_email: ${TEMPLATE_REPLY_TO_EMAIL:-（未設，寄信時不帶 Reply-To）}"
echo

# ─── 呼叫 API ────────────────────────────────────────────────────────────
HTTP_CODE="$(curl -sS -o /tmp/email_template_resp.json -w '%{http_code}' \
    -X POST "${API_BASE}/api/email/template" \
    -H "X-Api-Key: ${API_KEY}" \
    -H "X-Site-Key: ${SITE_KEY}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")"

echo "HTTP ${HTTP_CODE}"
cat /tmp/email_template_resp.json | (jq . 2>/dev/null || cat)
echo

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 模板上傳成功。前端 notify 時使用 template_id=\"${TEMPLATE_ID}\" 即可套用。"
else
    echo "❌ 上傳失敗（HTTP ${HTTP_CODE}）。常見原因：" >&2
    echo "   - 403 INVALID_API_KEY：API_KEY 或 SITE_KEY 不正確" >&2
    echo "   - 400 MISSING_REQUIRED_FIELD：缺少必填欄位" >&2
    exit 1
fi
