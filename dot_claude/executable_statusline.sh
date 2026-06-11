#!/usr/bin/env bash
# Claude Code status line: context fill + 5h / weekly usage limits.
input=$(cat)

# Dim model name for a little context on the left.
model=$(jq -r '.model.display_name // ""' <<<"$input")

# Pick a color by percentage: green < 50, yellow < 80, red otherwise.
color_for() {
  local p=${1%.*}   # integer part
  if   [ -z "$p" ];      then printf '90'    # grey when unknown
  elif [ "$p" -lt 50 ];  then printf '32'    # green
  elif [ "$p" -lt 80 ];  then printf '33'    # yellow
  else                        printf '31'    # red
  fi
}

# Format seconds-until-reset as a compact "2d" / "3h" / "45m" / "<1m".
reset_in() {
  local at=$1 now delta
  [ -z "$at" ] || [ "$at" = "null" ] && return
  now=$(date +%s)
  delta=$((at - now))
  [ "$delta" -le 0 ] && { printf 'now'; return; }
  if   [ "$delta" -ge 86400 ]; then printf '%dd' $((delta / 86400))
  elif [ "$delta" -ge 3600 ];  then printf '%dh' $((delta / 3600))
  elif [ "$delta" -ge 60 ];    then printf '%dm' $((delta / 60))
  else                              printf '<1m'
  fi
}

# Render "<label> <pct>% (resets <when>)" colored, or grey "n/a" if missing.
segment() {
  local label=$1 pct=$2 reset=$3
  if [ -z "$pct" ] || [ "$pct" = "null" ]; then
    printf '\033[90m%s n/a\033[0m' "$label"
  else
    local c; c=$(color_for "$pct")
    printf '\033[%sm%s %.0f%%\033[0m' "$c" "$label" "$pct"
    [ -n "$reset" ] && printf '\033[90m \xe2\x86\xbb %s\033[0m' "$reset"
  fi
}

ctx=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
h5=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
wk=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
h5_at=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
wk_at=$(jq -r '.rate_limits.seven_day.resets_at // empty' <<<"$input")

out=""
[ -n "$model" ] && out="\033[90m$model\033[0m  "
out+="$(segment 'ctx' "$ctx")  "
out+="$(segment '5h' "$h5" "$(reset_in "$h5_at")")  "
out+="$(segment 'wk' "$wk" "$(reset_in "$wk_at")")"

printf '%b' "$out"
