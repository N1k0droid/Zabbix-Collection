#!/usr/bin/env bash
# zbx_unsupported_monitor.sh    V 3.0.1                        @N1k0droid 02-26
# =============================================================================
# CONFIG
# =============================================================================

set -o pipefail

DEBUG=1

readonly SCRIPT_NAME="zbx_unsupported_monitor"
readonly LOG_DIR="/var/lib/zabbix/unsupported-items/logs"
readonly SYSLOG_TAG="zbx-unsupported"
readonly ZABBIX_SENDER="/usr/bin/zabbix_sender"
readonly ZABBIX_SERVER="127.0.0.1"
readonly ZABBIX_PORT="10051"
readonly ZABBIX_HOSTNAME="ZABBIX-SERVER"
readonly DELAY_BEFORE_SEND="3"

HOST_NAME="${1:-UNKNOWN}"
ITEM_NAME="${2:-UNKNOWN}"
ITEM_KEY="${3:-UNKNOWN}"
ITEM_STATE_RAW="${4:-unknown}"
EVENT_TIME_RAW="${5:-}"
EVENT_DATE_RAW="${6:-}"

# =============================================================================

log_debug() {
  if [ "$DEBUG" -eq 1 ]; then
    echo "[DEBUG] $*" >&2
  fi
}

log_info() {
  echo "[INFO] $*" >&2
  logger -t "$SYSLOG_TAG" -p user.info "INFO: $*"
}

log_warn() {
  echo "[WARN] $*" >&2
  logger -t "$SYSLOG_TAG" -p user.warning "WARN: $*"
}

log_error() {
  echo "[ERROR] $*" >&2
  logger -t "$SYSLOG_TAG" -p user.err "ERROR: $*"
}

validate_directories() {
  if [ ! -d "$LOG_DIR" ]; then
    log_error "Directory $LOG_DIR does not exist"
    return 1
  fi
  if [ ! -w "$LOG_DIR" ]; then
    log_error "No write permission for directory $LOG_DIR"
    return 1
  fi
  return 0
}

validate_input() {
  if [ -z "$HOST_NAME" ] || [ "$HOST_NAME" = "UNKNOWN" ]; then
    log_error "HOST_NAME is empty or UNKNOWN"
    return 1
  fi
  if [ -z "$ITEM_KEY" ] || [ "$ITEM_KEY" = "UNKNOWN" ]; then
    log_error "ITEM_KEY is empty or UNKNOWN"
    return 1
  fi
  if [ -z "$ITEM_STATE_RAW" ] || [ "$ITEM_STATE_RAW" = "unknown" ]; then
    log_error "ITEM_STATE is empty or unknown"
    return 1
  fi
  return 0
}

normalize_state() {
  local s="$1"
  case "$s" in
    "Not supported"|"Not Supported"|"NOT SUPPORTED"|"not supported")
      echo "Not supported"
      return 0
      ;;
    "Normal"|"NORMAL"|"normal")
      echo "Normal"
      return 0
      ;;
    *)
      echo "$s"
      return 1
      ;;
  esac
}

event_datetime_or_now() {
  local t="$1"
  local d="$2"
  if [ -n "$t" ] && [ -n "$d" ] && [[ "$t" != \\{* ]] && [[ "$d" != \\{* ]]; then
    echo "$d $t"
    return 0
  fi
  date '+%Y.%m.%d %H:%M:%S'
  return 0
}

ensure_file() {
  local f="$1"
  if [ ! -f "$f" ]; then
    : > "$f" || return 1
    return 0
  fi

  # If the file only contains the placeholder line, treat it as empty.
  # Also tolerate trailing whitespace/newlines.
  if awk 'NF==0{next} {lines++; if($0!="No unsupported items") bad=1} END{exit (lines>0 && bad==0)?0:1}' "$f"; then
    : > "$f" || return 1
  fi

  return 0
}

remove_entry_from_file() {
  local file="$1"
  local host="$2"
  local key="$3"

  [ ! -f "$file" ] && return 0

  local tmp="${file}.tmp.$$"
  awk -F'|' -v h="$host" -v k="$key" '
    # Keep lines that are not valid entries
    NF < 5 { print; next }
    # Drop matching entry
    !($2==h && $4==k) { print }
  ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }

  mv "$tmp" "$file"
  return 0
}

find_entry_category() {
  local host="$1"
  local key="$2"
  local cat

  for cat in step3 step2 step1; do
    local f="${LOG_DIR}/unsupported_${cat}.txt"
    [ -f "$f" ] || continue
    if awk -F'|' -v h="$host" -v k="$key" '
         NF>=5 && $2==h && $4==k { found=1 }
         END { exit(found?0:1) }
       ' "$f"; then
      echo "$cat"
      return 0
    fi
  done

  echo ""
  return 0
}

add_or_update_entry() {
  local file="$1"
  local host="$2"
  local key="$3"
  local entry="$4"

  ensure_file "$file" || return 1
  remove_entry_from_file "$file" "$host" "$key" || return 1
  echo "$entry" >> "$file" || return 1
  return 0
}

process_event_locked() {
  local dt="$1"
  local state="$2"

  local unique_key="${HOST_NAME}|${ITEM_KEY}"
  local entry="${dt}|${HOST_NAME}|${ITEM_NAME}|${ITEM_KEY}|${state}"

  local f1="${LOG_DIR}/unsupported_step1.txt"
  local f2="${LOG_DIR}/unsupported_step2.txt"
  local f3="${LOG_DIR}/unsupported_step3.txt"

  ensure_file "$f1" || return 1
  ensure_file "$f2" || return 1
  ensure_file "$f3" || return 1

  if [ "$state" = "Normal" ]; then
    remove_entry_from_file "$f1" "$HOST_NAME" "$ITEM_KEY" || return 1
    remove_entry_from_file "$f2" "$HOST_NAME" "$ITEM_KEY" || return 1
    remove_entry_from_file "$f3" "$HOST_NAME" "$ITEM_KEY" || return 1
    log_info "RESOLVED: $unique_key removed from all files"
    return 0
  fi

  if [ "$state" = "Not supported" ]; then
    local found
    found="$(find_entry_category "$HOST_NAME" "$ITEM_KEY")"

    case "$found" in
      "step3")
        add_or_update_entry "$f3" "$HOST_NAME" "$ITEM_KEY" "$entry" || return 1
        log_info "UPDATED: $unique_key in step3 (timestamp refreshed)"
        ;;
      "step2")
        remove_entry_from_file "$f2" "$HOST_NAME" "$ITEM_KEY" || return 1
        add_or_update_entry "$f3" "$HOST_NAME" "$ITEM_KEY" "$entry" || return 1
        log_info "MOVED: $unique_key step2 -> step3"
        ;;
      "step1")
        remove_entry_from_file "$f1" "$HOST_NAME" "$ITEM_KEY" || return 1
        add_or_update_entry "$f2" "$HOST_NAME" "$ITEM_KEY" "$entry" || return 1
        log_info "MOVED: $unique_key step1 -> step2"
        ;;
      *)
        add_or_update_entry "$f1" "$HOST_NAME" "$ITEM_KEY" "$entry" || return 1
        log_info "NEW: $unique_key added to step1"
        ;;
    esac

    return 0
  fi

  log_error "Unhandled state '$state' for $unique_key"
  return 1
}

validate_sender_prerequisites() {
  if [ ! -x "$ZABBIX_SENDER" ]; then
    log_error "zabbix_sender not found or not executable at $ZABBIX_SENDER"
    return 1
  fi
  return 0
}

send_metric() {
  local metric_key="$1"
  local metric_value="$2"

  local output rc
  output=$("$ZABBIX_SENDER" -z "$ZABBIX_SERVER" -p "$ZABBIX_PORT" \
    -s "$ZABBIX_HOSTNAME" -k "$metric_key" -o "$metric_value" 2>&1)
  rc=$?

  if [ $rc -ne 0 ]; then
    log_error "Failed to send metric $metric_key (exit code: $rc)"
    log_error "Output: $output"
    return 1
  fi
  return 0
}

process_category_for_send() {
  local category="$1"
  local file="${LOG_DIR}/unsupported_${category}.txt"

  ensure_file "$file" || return 1

  # Build output and count only valid entries (NF>=5). Ignore placeholders and junk.
  local log_value line_count
  log_value="$(awk -F'|' '
      NF>=5 && $2!="" && $4!="" {
        count++
        printf "%s - HOST: %s ITEM: %s KEY: %s STATE: %s\\n", $1, $2, $3, $4, $5
      }
      END {
        if (count==0) {
          # Print nothing; caller will replace with placeholder
        }
      }
    ' "$file")"

  line_count="$(awk -F'|' 'NF>=5 && $2!="" && $4!="" {count++} END{print count+0}' "$file")"

  if [ "$line_count" -eq 0 ]; then
    log_value="No unsupported items"
  else
    # Remove trailing newline (cosmetic) if present
    log_value="${log_value%$'\\n'}"
  fi

  send_metric "zabbix.unsupported.${category}[log]" "$log_value" || return 1
  send_metric "zabbix.unsupported.${category}[count]" "$line_count" || return 1

  log_info "Category $category: $line_count items sent"
  return 0
}

send_all_metrics() {
  validate_sender_prerequisites || return 1

  local rc=0
  for category in step1 step2 step3; do
    process_category_for_send "$category" || rc=1
  done

  return $rc
}

main() {
  validate_directories || return 1
  validate_input || return 1

  local ITEM_STATE
  if ITEM_STATE="$(normalize_state "$ITEM_STATE_RAW")"; then
    :
  else
    log_debug "Invalid ITEM_STATE received: '$ITEM_STATE_RAW' (expected 'Not supported' or 'Normal')"
    return 1
  fi

  local EVENT_DT
  EVENT_DT="$(event_datetime_or_now "$EVENT_TIME_RAW" "$EVENT_DATE_RAW")"

  log_info "Script started"
  log_debug "Parameters: HOST='$HOST_NAME' ITEM_NAME='$ITEM_NAME' ITEM_KEY='$ITEM_KEY' STATE='$ITEM_STATE' EVENT_TIME='$EVENT_TIME_RAW' EVENT_DATE='$EVENT_DATE_RAW' EVENT_DT='$EVENT_DT'"

  local lock_file="${LOG_DIR}/.lock"
  exec 9>"$lock_file" || { log_error "Failed to open lock file $lock_file"; return 1; }
  if command -v flock >/dev/null 2>&1; then
    flock -x 9
  fi

  log_info "PHASE 1: Processing event"
  process_event_locked "$EVENT_DT" "$ITEM_STATE" || return 1

  log_info "PHASE 2: Waiting ${DELAY_BEFORE_SEND}s before sending metrics"
  sleep "$DELAY_BEFORE_SEND"

  log_info "PHASE 3: Sending metrics to Zabbix"
  send_all_metrics || return 1

  log_info "Script completed successfully"
  return 0
}

main
exit_code=$?

if [ $exit_code -ne 0 ]; then
  log_error "Script failed with exit code $exit_code"
fi

exit $exit_code
