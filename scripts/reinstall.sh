#!/usr/bin/env bash
# Reinstall the "review" Claude Code plugin from this local directory, forcing a
# clean pull of the current plugin.json/commands/ (no stale marketplace/plugin
# registration left over from a previous install).
set -euo pipefail

SCOPE="${SCOPE:-user}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_MANIFEST="$SCRIPT_DIR/.claude-plugin/plugin.json"
MARKETPLACE_MANIFEST="$SCRIPT_DIR/.claude-plugin/marketplace.json"

if ! command -v claude >/dev/null 2>&1; then
  echo "❌ 'claude' CLI not found in PATH." >&2
  exit 1
fi

for f in "$PLUGIN_MANIFEST" "$MARKETPLACE_MANIFEST"; do
  if [ ! -f "$f" ]; then
    echo "❌ Missing manifest: $f" >&2
    exit 1
  fi
done

read_json_name() {
  grep -m1 '"name"' "$1" | sed -E 's/.*"name":[[:space:]]*"([^"]+)".*/\1/'
}

PLUGIN_NAME="$(read_json_name "$PLUGIN_MANIFEST")"
MARKETPLACE_NAME="${MARKETPLACE_NAME:-$(read_json_name "$MARKETPLACE_MANIFEST")}"

if [ -z "$PLUGIN_NAME" ] || [ -z "$MARKETPLACE_NAME" ]; then
  echo "❌ Could not read plugin/marketplace name from manifests." >&2
  exit 1
fi

PLUGIN_ID="$PLUGIN_NAME@$MARKETPLACE_NAME"

echo "Plugin dir:   $SCRIPT_DIR"
echo "Plugin id:    $PLUGIN_ID"
echo "Scope:        $SCOPE"
echo

echo "→ Uninstalling existing $PLUGIN_ID (if any)..."
claude plugin uninstall "$PLUGIN_ID" --scope "$SCOPE" >/dev/null 2>&1 || true

echo "→ Removing existing marketplace '$MARKETPLACE_NAME' (if any)..."
claude plugin marketplace remove "$MARKETPLACE_NAME" >/dev/null 2>&1 || true

echo "→ Re-adding marketplace from $SCRIPT_DIR (forces a fresh read of plugin.json)..."
claude plugin marketplace add "$SCRIPT_DIR"

echo "→ Installing $PLUGIN_ID..."
claude plugin install "$PLUGIN_ID" --scope "$SCOPE"

echo
echo "✅ Installed. Restart Claude Code (or start a new session) to load /review:pr."
claude plugin list
