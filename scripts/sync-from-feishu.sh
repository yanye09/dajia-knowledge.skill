#!/bin/bash
# sync-from-feishu.sh — 搭+ 知识库飞书源同步检查
# Usage: bash sync-from-feishu.sh <skill_dir> [light|full]
#   light (默认): 仅检查 PRD revision_id（1 次 API 调用）
#   full:        检查 PRD + 台账 edit_time + 台账 row_count（3 次 API 调用）
# Exit codes: 0=无变化, 2=有变化, 3=获取失败(需检查认证/网络)

set -euo pipefail

SKILL_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
STATE_FILE="$SKILL_DIR/state/sync-state.json"
CHECK_MODE="${2:-light}"

if [ ! -f "$STATE_FILE" ]; then
  echo '{"error":"sync-state.json not found","hint":"run from skill root or pass skill_dir as arg"}'
  exit 3
fi

# ============================================================
# 辅助函数：安全地从 JSON 响应中提取字段
# 返回 0 表示成功提取，非 0 表示提取失败（响应非 JSON 或字段缺失）
# ============================================================
extract_field() {
  local raw_input="$1"
  local json_path="$2"
  local result
  result=$(echo "$raw_input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # Navigate dotted path like 'data.document.revision_id'
    parts = '$json_path'.split('.')
    for p in parts:
        if p.isdigit():
            data = data[int(p)]
        else:
            data = data[p]
    print(data)
except (json.JSONDecodeError, KeyError, TypeError, IndexError) as e:
    print('__PARSE_ERROR__:' + str(e), file=sys.stderr)
    sys.exit(1)
" 2>/dev/null) || return 1
  if [[ "$result" == __PARSE_ERROR__:* ]]; then
    return 1
  fi
  echo "$result"
  return 0
}

# ============================================================
# 读取缓存指纹
# ============================================================
CACHED_PRD_REV=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['sources']['prd_doc']['revision_id'])" 2>/dev/null) || CACHED_PRD_REV=""
CACHED_LEDGER_EDIT=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['sources']['ledger_sheet']['obj_edit_time'])" 2>/dev/null) || CACHED_LEDGER_EDIT=""
CACHED_LEDGER_ROWS=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['sources']['ledger_sheet']['row_count'])" 2>/dev/null) || CACHED_LEDGER_ROWS=""

# ============================================================
# PRD 检查（light 和 full 模式都执行）
# ============================================================
PRD_RAW=$(lark-cli docs +fetch --api-version v2 --doc FkFZdljhJoJN1xx0QgfcqxgBnsf --scope outline --max-depth 1 2>&1) || PRD_RAW=""
CURRENT_PRD_REV=$(extract_field "$PRD_RAW" "data.document.revision_id" 2>/dev/null) || CURRENT_PRD_REV=""

if [ -z "$CURRENT_PRD_REV" ]; then
  PRD_ERROR="true"
  PRD_ERROR_MSG="failed to parse revision_id from lark-cli response (auth expired or network error?)"
else
  PRD_ERROR="false"
  PRD_ERROR_MSG=""
fi

# ============================================================
# 台账检查（仅 full 模式）
# ============================================================
LEDGER_ERROR="false"
LEDGER_ERROR_MSG=""
CURRENT_LEDGER_EDIT=""
CURRENT_LEDGER_ROWS=""

if [ "$CHECK_MODE" = "full" ]; then
  LEDGER_NODE_RAW=$(lark-cli wiki spaces get_node --params '{"token":"FGjtwH4qQi4trUkvPQvcM24unHh"}' --format json 2>&1) || LEDGER_NODE_RAW=""
  CURRENT_LEDGER_EDIT=$(extract_field "$LEDGER_NODE_RAW" "data.node.obj_edit_time" 2>/dev/null) || CURRENT_LEDGER_EDIT=""

  LEDGER_INFO_RAW=$(lark-cli sheets +info --url "https://scntlaw1t3yy.feishu.cn/sheets/W5fJsGIEPhyee1ttMU6c1keUnmc" 2>&1) || LEDGER_INFO_RAW=""
  CURRENT_LEDGER_ROWS=$(extract_field "$LEDGER_INFO_RAW" "data.sheets.sheets.0.grid_properties.row_count" 2>/dev/null) || CURRENT_LEDGER_ROWS=""

  if [ -z "$CURRENT_LEDGER_EDIT" ] || [ -z "$CURRENT_LEDGER_ROWS" ]; then
    LEDGER_ERROR="true"
    LEDGER_ERROR_MSG="failed to parse ledger data from lark-cli response (auth expired or network error?)"
  fi
fi

# ============================================================
# 比较
# ============================================================
PRD_CHANGED="false"
LEDGER_CHANGED="false"

if [ "$PRD_ERROR" = "false" ] && [ -n "$CACHED_PRD_REV" ] && [ "$CACHED_PRD_REV" != "$CURRENT_PRD_REV" ]; then
  PRD_CHANGED="true"
fi

if [ "$CHECK_MODE" = "full" ] && [ "$LEDGER_ERROR" = "false" ]; then
  if [ -n "$CACHED_LEDGER_EDIT" ] && [ "$CACHED_LEDGER_EDIT" != "$CURRENT_LEDGER_EDIT" ]; then
    LEDGER_CHANGED="true"
  elif [ -n "$CACHED_LEDGER_ROWS" ] && [ "$CACHED_LEDGER_ROWS" != "$CURRENT_LEDGER_ROWS" ]; then
    LEDGER_CHANGED="true"
  fi
fi

# ============================================================
# 输出 JSON
# ============================================================
python3 -c "
import json
output = {
  'check_mode': '$CHECK_MODE',
  'prd_changed': True if '$PRD_CHANGED' == 'true' else False,
  'ledger_changed': True if '$LEDGER_CHANGED' == 'true' else False,
  'any_error': True if '$PRD_ERROR' == 'true' or '$LEDGER_ERROR' == 'true' else False,
  'prd': {
    'cached_revision': '$CACHED_PRD_REV',
    'current_revision': '$CURRENT_PRD_REV',
    'error': True if '$PRD_ERROR' == 'true' else False,
    'error_msg': '$PRD_ERROR_MSG'
  },
  'ledger': {
    'cached_edit_time': '$CACHED_LEDGER_EDIT',
    'current_edit_time': '$CURRENT_LEDGER_EDIT',
    'cached_rows': '$CACHED_LEDGER_ROWS',
    'current_rows': '$CURRENT_LEDGER_ROWS',
    'error': True if '$LEDGER_ERROR' == 'true' else False,
    'error_msg': '$LEDGER_ERROR_MSG',
    'skipped': True if '$CHECK_MODE' == 'light' else False
  }
}
print(json.dumps(output, indent=2, ensure_ascii=False))
"

# ============================================================
# 退出码
# ============================================================
if [ "$PRD_ERROR" = "true" ] || [ "$LEDGER_ERROR" = "true" ]; then
  exit 3   # 获取失败
elif [ "$PRD_CHANGED" = "true" ] || [ "$LEDGER_CHANGED" = "true" ]; then
  exit 2   # 有变化
else
  exit 0   # 无变化
fi
