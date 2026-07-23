#!/usr/bin/env bash
# corpus-refresh.sh — Check analyzed corpus sources for new policies.
#
# Clones each analyzed source (shallow), counts .rego files (excluding tests),
# and compares against the last-known count stored in corpus/counts.json.
#
# Usage:
#   ./scripts/corpus-refresh.sh          # check all sources
#   ./scripts/corpus-refresh.sh --update  # update counts.json with current values

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
COUNTS_FILE="$REPO_ROOT/corpus/counts.json"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

UPDATE_MODE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE_MODE=true
fi

# Sources we've analyzed — repo URL, subdirectory to search, last-known count
declare -A SOURCES=(
  ["gatekeeper-library"]="https://github.com/open-policy-agent/gatekeeper-library|src|49"
  ["aws-infra-policy-as-code"]="https://github.com/aws-samples/aws-infra-policy-as-code-with-terraform|policy-as-code/OPA/policy|90"
  ["raspbernetes"]="https://github.com/raspbernetes/k8s-security-policies|policies|62"
  ["conftest"]="https://github.com/open-policy-agent/conftest|examples|44"
  ["instrumenta-policies"]="https://github.com/instrumenta/policies|.|30"
  ["redhat-cop-rego"]="https://github.com/redhat-cop/rego-policies|.|30"
)

# Load existing counts if available
declare -A KNOWN_COUNTS
if [[ -f "$COUNTS_FILE" ]]; then
  while IFS='=' read -r key value; do
    KNOWN_COUNTS["$key"]="$value"
  done < <(python3 -c "
import json, sys
with open('$COUNTS_FILE') as f:
    d = json.load(f)
for k, v in d.items():
    print(f'{k}={v}')
" 2>/dev/null || true)
fi

echo "=== Corpus Refresh Check ==="
echo ""

CHANGED=0
declare -A NEW_COUNTS

for name in "${!SOURCES[@]}"; do
  IFS='|' read -r url subdir last_known <<< "${SOURCES[$name]}"
  
  echo -n "Checking $name... "
  
  if git clone --depth 1 --quiet "$url" "$TMPDIR/$name" 2>/dev/null; then
    current=$(command find "$TMPDIR/$name/$subdir" -name '*.rego' ! -name '*_test*' ! -name '*test*' 2>/dev/null | wc -l | tr -d ' ')
    known="${KNOWN_COUNTS[$name]:-$last_known}"
    NEW_COUNTS["$name"]="$current"
    
    if [[ "$current" -gt "$known" ]]; then
      diff=$((current - known))
      echo "⚠️  $current policies (was $known, +$diff new)"
      CHANGED=1
    elif [[ "$current" -lt "$known" ]]; then
      diff=$((known - current))
      echo "📉 $current policies (was $known, -$diff removed)"
      CHANGED=1
    else
      echo "✅ $current policies (unchanged)"
    fi
  else
    echo "❌ clone failed"
  fi
done

echo ""

if [[ "$CHANGED" -eq 1 ]]; then
  echo "⚠️  Some sources have changed. Re-analysis may be needed."
  echo "   Run with --update to save new counts after re-analysis."
else
  echo "✅ All sources unchanged since last analysis."
fi

if $UPDATE_MODE; then
  python3 -c "
import json
counts = {$(for name in "${!NEW_COUNTS[@]}"; do echo "\"$name\": ${NEW_COUNTS[$name]},"; done)}
with open('$COUNTS_FILE', 'w') as f:
    json.dump(counts, f, indent=2, sort_keys=True)
    f.write('\n')
print('Updated $COUNTS_FILE')
"
fi
