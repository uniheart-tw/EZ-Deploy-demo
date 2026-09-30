#!/usr/bin/env bash
#
# template_manage.sh — Email Template CRUD CLI
#
# API:
#   POST   /api/email/template       create/update (upsert)
#   GET    /api/email/template       list
#   GET    /api/email/template/{id}  get one
#   DELETE /api/email/template/{id}  delete
#
# The HTML file format is a local CLI convention:
#   <!-- SUBJECT --> ... <!-- /SUBJECT -->
#   <!-- BODY -->    ... <!-- /BODY -->
#
# Required environment variables:
#   API_BASE (or API_BASE_URL), SITE_KEY, API_KEY
#
# Template settings can be kept in an owner profile instead of this script:
#   set -a
#   source .env.local
#   source .env.owner1
#   set +a
#   bash demo/template_manage.sh
#
# The positional upload form is an upsert: running it again with the same
# template_id updates the existing template.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_BASE="${API_BASE:-${API_BASE_URL:-}}"
SITE_KEY="${SITE_KEY:-}"
API_KEY="${API_KEY:-}"
RESPONSE_FILE=""

# ═══════════════════════════════════════════════════════════════════════
# 預設模板設定：可由 .env.owner1 / .env.owner2 等環境檔覆寫。
# ALLOWED_VARIABLES 不再預設固定清單；上傳時會從 SUBJECT + BODY 自動分析。
# 若環境檔或 CLI 仍提供 ALLOWED_VARIABLES，則只用來檢查是否與模板一致。
# ═══════════════════════════════════════════════════════════════════════
: "${TEMPLATE_ID:?缺少 TEMPLATE_ID，請在 .env.owner1 設定}"
: "${TEMPLATE_FILE:?缺少 TEMPLATE_FILE，請在 .env.owner1 設定}"
: "${TEMPLATE_FROM_NAME:?缺少 TEMPLATE_FROM_NAME，請在 .env.owner1 設定}"
: "${TEMPLATE_OWNER_NOTIFY_EMAILS:?缺少 TEMPLATE_OWNER_NOTIFY_EMAILS，請在 .env.owner1 設定}"
: "${TEMPLATE_REPLY_TO_EMAIL:?缺少 TEMPLATE_REPLY_TO_EMAIL，請在 .env.owner1 設定}"

# ALLOWED_VARIABLES 留空即可，由模板自動分析
ALLOWED_VARIABLES="${ALLOWED_VARIABLES-}"


usage() {
    cat <<'EOF'
用法：
  bash template_manage.sh [template_id] [template.html] [options]
  bash template_manage.sh list
  bash template_manage.sh get <template_id>
  bash template_manage.sh delete <template_id>

上傳／更新選項：
  --file <path>                       指定模板檔（也可用第二個位置參數）
  --allowed-variables '<json-array>'  可選：檢查是否與模板自動分析結果一致
  --from-name <name>
  --owner-notify-emails <emails>      逗號分隔，最多 5 筆
  --reply-to-email <email>

設定方式：
  建議把每個訂閱者的設定放到不同 env 檔，例如 .env.owner1、.env.owner2：

    source .env.local       # API_BASE、SITE_KEY、API_KEY
    source .env.owner1      # TEMPLATE_ID、TEMPLATE_FILE、寄件設定

    bash demo/template_manage.sh

  TEMPLATE_FILE 可使用相對路徑；腳本會先從目前目錄，再從 demo 目錄尋找。
  模板中的 {variable_name} 會自動轉成 allowed_variables，不需要修改腳本。
  ALLOWED_VARIABLES 只保留作為相容性檢查，未設定時完全由模板推導。

必要環境變數：
  API_BASE（或 API_BASE_URL）、SITE_KEY、API_KEY

EOF
}

die() {
    echo "錯誤：$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "$RESPONSE_FILE" && -f "$RESPONSE_FILE" ]]; then
        rm -f "$RESPONSE_FILE"
    fi
}
trap cleanup EXIT

require_jq() {
    command -v jq >/dev/null 2>&1 || die "需要 jq 來組裝及解析 JSON，請先安裝 jq（brew install jq）。"
}

require_credentials() {
    if [[ -z "$API_BASE" || -z "$SITE_KEY" || -z "$API_KEY" ]]; then
        die "缺少 API_BASE（或 API_BASE_URL）、SITE_KEY 或 API_KEY。請先 export 這些變數；若從 env 檔載入，可使用：set -a; source <env-file>; set +a"
    fi

    while [[ "$API_BASE" == */ ]]; do
        API_BASE="${API_BASE%/}"
    done

    if [[ -z "$RESPONSE_FILE" ]]; then
        RESPONSE_FILE="$(mktemp "${TMPDIR:-/tmp}/template_manage.XXXXXX")"
    fi
}

validate_template_id() {
    local template_id="$1"
    [[ -n "$template_id" ]] || die "template_id 不可為空"
    [[ "$template_id" =~ ^[A-Za-z0-9._-]+$ ]] || die "template_id 只能包含英數字、句點、底線及連字號"
}

urlencode() {
    jq -nr --arg value "$1" '$value | @uri'
}

print_response() {
    if [[ ! -s "$RESPONSE_FILE" ]]; then
        echo "（回應沒有 body）"
    elif jq . "$RESPONSE_FILE" >/dev/null 2>&1; then
        jq . "$RESPONSE_FILE"
    else
        cat "$RESPONSE_FILE"
    fi
}

request() {
    local method="$1"
    local path="$2"
    local payload="${3:-}"
    local -a curl_args

    curl_args=(
        -sS
        -o "$RESPONSE_FILE"
        -w '%{http_code}'
        -X "$method"
        "${API_BASE}${path}"
        -H "X-Api-Key: ${API_KEY}"
        -H "X-Site-Key: ${SITE_KEY}"
    )

    if [[ -n "$payload" ]]; then
        curl_args+=(
            -H 'Content-Type: application/json'
            -d "$payload"
        )
    fi

    if ! HTTP_CODE="$(curl "${curl_args[@]}")"; then
        die "無法連線到 API：${API_BASE}${path}"
    fi
}

finish_request() {
    local success_message="$1"
    local failure_message="$2"

    echo "HTTP ${HTTP_CODE}"
    print_response
    echo

    if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
        echo "✅ ${success_message}"
    else
        echo "❌ ${failure_message}（HTTP ${HTTP_CODE}）。" >&2
        case "$HTTP_CODE" in
            400) echo "   - 請檢查必填欄位及 JSON 格式。" >&2 ;;
            403) echo "   - API_KEY 或 SITE_KEY 無效（INVALID_API_KEY）。" >&2 ;;
            404) echo "   - 找不到指定的 Email Template。" >&2 ;;
        esac
        return 1
    fi
}

extract_block() {
    local start_marker="$1"
    local end_marker="$2"
    local template_file="$3"

    awk -v start="$start_marker" -v end="$end_marker" '
        function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
        {
            line = trim($0)
            if (line == start) { found_start = 1; grabbing = 1; next }
            if (line == end) { found_end = 1; grabbing = 0; next }
            if (grabbing) print
        }
        END {
            if (!found_start || !found_end) exit 2
        }
    ' "$template_file"
}

resolve_template_file() {
    if [[ "$TEMPLATE_FILE" = /* && -f "$TEMPLATE_FILE" ]]; then
        return 0
    fi

    if [[ -f "$TEMPLATE_FILE" ]]; then
        TEMPLATE_FILE="$(cd "$(dirname "$TEMPLATE_FILE")" && pwd)/$(basename "$TEMPLATE_FILE")"
    elif [[ -f "$SCRIPT_DIR/$TEMPLATE_FILE" ]]; then
        TEMPLATE_FILE="$SCRIPT_DIR/$TEMPLATE_FILE"
    elif [[ -f "$SCRIPT_DIR/../$TEMPLATE_FILE" ]]; then
        TEMPLATE_FILE="$SCRIPT_DIR/../$TEMPLATE_FILE"
    else
        die "找不到模板檔：$TEMPLATE_FILE"
    fi
}

extract_template_variables() {
    local template_content="$1"

    # 只掃描 SUBJECT + BODY，避免 HTML/CSS 中的其他大括號被誤判。
    # jq scan 的規則與 preview_template.sh 相同：{name}，name 必須是合法識別字。
    jq -R -s -c '[scan("\\{([A-Za-z_][A-Za-z0-9_]*)\\}") | .[0]] | unique' <<<"$template_content"
}

validate_allowed_variables() {
    local detected_variables="$1"

    if [[ -z "$ALLOWED_VARIABLES" ]]; then
        ALLOWED_VARIABLES="$detected_variables"
        return
    fi

    jq -e 'type == "array" and all(.[]; type == "string")' >/dev/null <<<"$ALLOWED_VARIABLES" \
        || die "ALLOWED_VARIABLES 必須是字串陣列 JSON"

    local expected_normalized detected_normalized missing extra
    expected_normalized="$(jq -c 'unique | sort' <<<"$ALLOWED_VARIABLES")"
    detected_normalized="$(jq -c 'unique | sort' <<<"$detected_variables")"

    if [[ "$expected_normalized" != "$detected_normalized" ]]; then
        missing="$(jq -c --argjson expected "$detected_normalized" --argjson actual "$expected_normalized" '$expected - $actual' <<<"null")"
        extra="$(jq -c --argjson expected "$detected_normalized" --argjson actual "$expected_normalized" '$actual - $expected' <<<"null")"
        die "ALLOWED_VARIABLES 與模板中的變數不一致。模板自動分析結果：${detected_normalized}；缺少：${missing}；多出：${extra}。請移除 ALLOWED_VARIABLES 或更新它。"
    fi

    # 即使呼叫者有提供舊設定，payload 仍以模板分析結果為準。
    ALLOWED_VARIABLES="$detected_variables"
}

parse_upload_args() {
    # template_id 可省略，直接使用 env profile 內的 TEMPLATE_ID。
    # 因此 --file/其他 options 可以放在第一個參數。
    if [[ -n "${1:-}" && "${1#--}" == "$1" ]]; then
        TEMPLATE_ID="$1"
        shift
    fi
    validate_template_id "$TEMPLATE_ID"

    if [[ $# -gt 0 && "${1#--}" == "$1" ]]; then
        TEMPLATE_FILE="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                [[ $# -ge 2 ]] || die "--file 需要指定檔案路徑"
                TEMPLATE_FILE="$2"
                shift 2
                ;;
            --allowed-variables)
                [[ $# -ge 2 ]] || die "--allowed-variables 需要 JSON array"
                ALLOWED_VARIABLES="$2"
                shift 2
                ;;
            --from-name)
                [[ $# -ge 2 ]] || die "--from-name 需要指定名稱"
                TEMPLATE_FROM_NAME="$2"
                shift 2
                ;;
            --owner-notify-emails)
                [[ $# -ge 2 ]] || die "--owner-notify-emails 需要逗號分隔的 email"
                TEMPLATE_OWNER_NOTIFY_EMAILS="$2"
                shift 2
                ;;
            --reply-to-email)
                [[ $# -ge 2 ]] || die "--reply-to-email 需要指定 email"
                TEMPLATE_REPLY_TO_EMAIL="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "不支援的上傳／更新參數：$1"
                ;;
        esac
    done
}

build_upload_payload() {
    resolve_template_file

    local subject_raw body_raw
    if ! subject_raw="$(extract_block '<!-- SUBJECT -->' '<!-- /SUBJECT -->' "$TEMPLATE_FILE")"; then
        die "模板檔缺少完整的 SUBJECT 區塊"
    fi
    if ! body_raw="$(extract_block '<!-- BODY -->' '<!-- /BODY -->' "$TEMPLATE_FILE")"; then
        die "模板檔缺少完整的 BODY 區塊"
    fi

    SUBJECT_TEMPLATE="$(printf '%s' "$subject_raw" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    BODY_HTML_TEMPLATE="$body_raw"

    [[ -n "$SUBJECT_TEMPLATE" ]] || die "SUBJECT 區塊不可為空"
    [[ -n "$(printf '%s' "$BODY_HTML_TEMPLATE" | tr -d '[:space:]')" ]] || die "BODY 區塊不可為空"

    local detected_variables
    detected_variables="$(extract_template_variables "${SUBJECT_TEMPLATE}
${BODY_HTML_TEMPLATE}")"
    validate_allowed_variables "$detected_variables"

    local owner_emails_json='[]'
    if [[ -n "$TEMPLATE_OWNER_NOTIFY_EMAILS" ]]; then
        owner_emails_json="$(printf '%s' "$TEMPLATE_OWNER_NOTIFY_EMAILS" | jq -R -c 'split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))')"
        [[ "$(jq 'length' <<<"$owner_emails_json")" -le 5 ]] || die "owner_notify_emails 最多只能有 5 筆"
    fi

    jq -n \
        --arg tid "$TEMPLATE_ID" \
        --arg subj "$SUBJECT_TEMPLATE" \
        --arg body "$BODY_HTML_TEMPLATE" \
        --arg vars_json "$ALLOWED_VARIABLES" \
        --arg from_name "$TEMPLATE_FROM_NAME" \
        --argjson owner_emails "$owner_emails_json" \
        --arg reply_to "$TEMPLATE_REPLY_TO_EMAIL" \
        '{template_id: $tid, subject_template: $subj, body_html_template: $body,
          allowed_variables: ($vars_json | fromjson)}
         + (if $from_name != "" then {from_name: $from_name} else {} end)
         + (if ($owner_emails | length) > 0 then {owner_notify_emails: $owner_emails} else {} end)
         + (if $reply_to != "" then {reply_to_email: $reply_to} else {} end)'
}

upload_template() {
    local operation="$1"
    local payload
    payload="$(build_upload_payload)"

    echo "── ${operation} Email Template ──"
    echo "endpoint:    ${API_BASE}/api/email/template"
    echo "template_id: ${TEMPLATE_ID}"
    echo "template_file: ${TEMPLATE_FILE}"
    echo "subject:     $(jq -r '.subject_template' <<<"$payload")"
    echo

    request POST '/api/email/template' "$payload"
    finish_request "模板 ${operation} 成功" "模板 ${operation} 失敗"
}

list_templates() {
    request GET '/api/email/template'
    finish_request "模板列表取得成功" "取得模板列表失敗"
}

get_template() {
    local template_id="$1"
    validate_template_id "$template_id"
    request GET "/api/email/template/$(urlencode "$template_id")"
    finish_request "模板取得成功" "取得模板失敗"
}

delete_template() {
    local template_id="$1"
    validate_template_id "$template_id"
    echo "── 刪除 Email Template ──"
    echo "template_id: ${template_id}"
    echo

    request DELETE "/api/email/template/$(urlencode "$template_id")"
    finish_request "模板刪除成功" "模板刪除失敗"
}

require_jq

case "${1:-}" in
    -h|--help|help)
        usage
        ;;
    list|ls)
        [[ $# -eq 1 ]] || die "list 不接受其他參數"
        require_credentials
        list_templates
        ;;
    get|show)
        [[ $# -eq 2 ]] || die "用法：template_manage.sh get <template_id>"
        require_credentials
        get_template "$2"
        ;;
    delete|remove|--delete)
        [[ $# -eq 2 ]] || die "用法：template_manage.sh delete <template_id>"
        require_credentials
        delete_template "$2"
        ;;
    *)
        require_credentials
        parse_upload_args "$@"
        upload_template "上傳／更新"
        ;;
esac
