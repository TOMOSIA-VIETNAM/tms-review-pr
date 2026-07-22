#!/usr/bin/env bash
# Copy this repo's src/ into ~/.cursor/plugins/local/tms so Cursor can load the
# tms plugin locally without publishing. Does not touch Claude Code installs.
#
# Why copy, not symlink: Cursor rejects symlinks whose target resolves outside
# ~/.cursor/plugins/local (silent warn in "Cursor Plugins.log"). Docs still
# suggest ln -s to an external repo path — that does not work today.
# Re-run this script after editing src/ so the installed copy stays in sync.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_SRC="$SCRIPT_DIR/src"
CURSOR_LOCAL="${CURSOR_PLUGINS_LOCAL:-$HOME/.cursor/plugins/local}"
TARGET="$CURSOR_LOCAL/tms"

PLUGIN_MANIFEST="$PLUGIN_SRC/.cursor-plugin/plugin.json"
if [ ! -f "$PLUGIN_MANIFEST" ]; then
  echo "❌ Missing Cursor manifest: $PLUGIN_MANIFEST" >&2
  exit 1
fi

if [ ! -f "$PLUGIN_SRC/cursor/commands/review-pr.md" ]; then
  echo "❌ Missing Cursor command: $PLUGIN_SRC/cursor/commands/review-pr.md" >&2
  exit 1
fi

mkdir -p "$CURSOR_LOCAL"

# Remove previous install (symlink from older script versions, or stale copy).
rm -rf "$TARGET"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "$PLUGIN_SRC/" "$TARGET/"
else
  mkdir -p "$TARGET"
  cp -R "$PLUGIN_SRC"/. "$TARGET/"
fi

if [ -L "$TARGET" ]; then
  echo "❌ $TARGET is still a symlink; Cursor will reject it." >&2
  exit 1
fi

if [ ! -f "$TARGET/.cursor-plugin/plugin.json" ] || [ ! -f "$TARGET/cursor/commands/review-pr.md" ]; then
  echo "❌ Install incomplete under $TARGET" >&2
  exit 1
fi

echo "Plugin src:  $PLUGIN_SRC"
echo "Installed:   $TARGET  (real directory copy)"
echo
echo "✅ Done. Restart Cursor (or Developer: Reload Window) so /review-pr is available."
echo "   Requires: gh auth login"
echo "   After editing src/: re-run this script, then reload Cursor."
