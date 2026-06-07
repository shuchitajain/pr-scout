#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<'EOF'
Usage:
  ./scripts/pr-scout-init.sh [target-directory]

Copies PR-Scout assets into target-directory (default: current directory).
Additive and idempotent: existing files are never overwritten.
EOF
      exit 0
      ;;
    --*)
      echo "ERROR: unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "${TARGET_DIR}" ]]; then
        echo "ERROR: multiple target directories provided" >&2
        exit 1
      fi
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ASSET_ROOT="${SOURCE_ROOT}/.ai/pr-scout"
mkdir -p "${TARGET_DIR}"
TARGET_ROOT="$(cd "${TARGET_DIR}" && pwd)"

if [[ ! -d "${ASSET_ROOT}" ]]; then
  echo "ERROR: pr-scout assets not found at ${ASSET_ROOT}" >&2
  exit 1
fi

created_files=0
skipped_files=0

copy_tree_additive() {
  local source_dir="$1"
  local destination_dir="$2"

  mkdir -p "${destination_dir}"

  while IFS= read -r -d '' dir_path; do
    local relative="${dir_path#${source_dir}/}"
    [[ "${relative}" == "${dir_path}" ]] && relative=""
    mkdir -p "${destination_dir}/${relative}"
  done < <(find "${source_dir}" -type d -print0)

  while IFS= read -r -d '' file_path; do
    local relative="${file_path#${source_dir}/}"
    local target_file="${destination_dir}/${relative}"
    if [[ -e "${target_file}" ]]; then
      skipped_files=$((skipped_files + 1))
      continue
    fi

    cp "${file_path}" "${target_file}"
    created_files=$((created_files + 1))
  done < <(find "${source_dir}" -type f -print0)
}

ensure_pr_scout_paragraph() {
  local target_file="$1"
  local paragraph

  paragraph=$(cat <<'EOF'

## PR-Scout

This repo uses PR-Scout for story-to-diff validation. Run `/pr-scout self-check story <ID>` for local changes or `/pr-scout review pr <PR> story <ID>` for pull requests. Agent files live in `.ai/pr-scout/agents/`.
EOF
)

  mkdir -p "$(dirname "${target_file}")"

  if [[ ! -f "${target_file}" ]]; then
    printf "%s\n" "${paragraph}" > "${target_file}"
    created_files=$((created_files + 1))
    return
  fi

  if grep -Fq ".ai/pr-scout/agents/" "${target_file}"; then
    return
  fi

  printf "%s\n" "${paragraph}" >> "${target_file}"
}

ensure_gitignore_block() {
  local gitignore_file="${TARGET_ROOT}/.gitignore"
  local start_marker="# pr-scout"

  if [[ ! -f "${gitignore_file}" ]]; then
    cat >"${gitignore_file}" <<'EOF'
# pr-scout
.ai/pr-scout/
# /pr-scout
EOF
    created_files=$((created_files + 1))
    return
  fi

  if grep -Fq "${start_marker}" "${gitignore_file}"; then
    return
  fi

  cat >>"${gitignore_file}" <<'EOF'

# pr-scout
.ai/pr-scout/
# /pr-scout
EOF
}

merge_mcp_servers_into_file() {
  local mcp_file="$1"
  local servers_template="${ASSET_ROOT}/templates/vscode/mcp.json"

  mkdir -p "$(dirname "${mcp_file}")"

  python3 - "${mcp_file}" "${servers_template}" <<'PY'
import json
import pathlib
import re
import sys

mcp_path = pathlib.Path(sys.argv[1])
servers_path = pathlib.Path(sys.argv[2])

scout_servers = json.loads(servers_path.read_text(encoding="utf-8"))
if isinstance(scout_servers.get("servers"), dict):
    scout_servers = scout_servers["servers"]


def strip_jsonc(raw: str) -> str:
    out = []
    i = 0
    in_string = False
    escaped = False
    length = len(raw)

    while i < length:
        ch = raw[i]

        if in_string:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue

        if ch == "/" and i + 1 < length:
            nxt = raw[i + 1]
            if nxt == "/":
                i += 2
                while i < length and raw[i] not in "\r\n":
                    i += 1
                continue
            if nxt == "*":
                i += 2
                while i + 1 < length and not (raw[i] == "*" and raw[i + 1] == "/"):
                    i += 1
                i += 2
                continue

        out.append(ch)
        i += 1

    cleaned = "".join(out)
    cleaned = re.sub(r",\s*([}\]])", r"\1", cleaned)
    return cleaned


config = {"servers": {}, "inputs": []}

if mcp_path.exists():
    raw = mcp_path.read_text(encoding="utf-8")
    try:
        config = json.loads(strip_jsonc(raw))
    except Exception:
        print(f"WARN: Could not parse {mcp_path}. Skipping MCP merge to avoid destructive changes.")
        sys.exit(0)

if not isinstance(config, dict):
    config = {"servers": {}, "inputs": []}

server_key = "mcpServers" if isinstance(config.get("mcpServers"), dict) else "servers"

if not isinstance(config.get(server_key), dict):
    config[server_key] = {}
if not isinstance(config.get("inputs"), list):
    config["inputs"] = []


def server_fingerprint(cfg):
    if not isinstance(cfg, dict):
        return None
    if isinstance(cfg.get("url"), str):
        return ("url", cfg["url"])
    cmd = cfg.get("command", "")
    args = tuple(cfg.get("args", []))
    return ("cmd", cmd, args)


existing_fingerprints = {
    server_fingerprint(v)
    for v in config[server_key].values()
    if isinstance(v, dict)
}

added = []
for name, server_config in scout_servers.items():
    if name in config[server_key]:
        continue
    fp = server_fingerprint(server_config)
    if fp is not None and fp in existing_fingerprints:
        continue
    config[server_key][name] = server_config
    existing_fingerprints.add(fp)
    added.append(name)

if added or not mcp_path.exists():
    mcp_path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    if added:
        print("MCP: added servers in " + str(mcp_path) + " -> " + ", ".join(added))
    else:
        print("MCP: created " + str(mcp_path))
else:
    print("MCP: no changes in " + str(mcp_path) + " (all pr-scout servers already present)")
PY
}

merge_mcp_servers() {
  local merged_any=false
  local claude_global_mcp="${HOME}/.claude.json"

  if [[ -d "${TARGET_ROOT}/.vscode" || -f "${TARGET_ROOT}/.vscode/mcp.json" ]]; then
    merge_mcp_servers_into_file "${TARGET_ROOT}/.vscode/mcp.json"
    merged_any=true
  fi

  if [[ -d "${TARGET_ROOT}/.cursor" ]]; then
    if [[ -f "${TARGET_ROOT}/.cursor/mcp.jsonc" ]]; then
      merge_mcp_servers_into_file "${TARGET_ROOT}/.cursor/mcp.jsonc"
    else
      merge_mcp_servers_into_file "${TARGET_ROOT}/.cursor/mcp.json"
    fi
    merged_any=true
  fi

  if [[ -d "${TARGET_ROOT}/.roo" ]]; then
    merge_mcp_servers_into_file "${TARGET_ROOT}/.roo/mcp.json"
    merged_any=true
  fi

  if [[ -f "${TARGET_ROOT}/.windsurfrules" || -d "${TARGET_ROOT}/.windsurf" ]]; then
    merge_mcp_servers_into_file "${TARGET_ROOT}/.windsurf/mcp.json"
    merged_any=true
  fi

  if [[ -f "${TARGET_ROOT}/.mcp.json" ]]; then
    merge_mcp_servers_into_file "${TARGET_ROOT}/.mcp.json"
    merged_any=true
  fi

  if [[ -f "${claude_global_mcp}" ]]; then
    merge_mcp_servers_into_file "${claude_global_mcp}"
    merged_any=true
  elif [[ -f "${TARGET_ROOT}/CLAUDE.md" ]]; then
    echo "MCP: detected CLAUDE.md but ${claude_global_mcp} is missing; skipping global file creation"
  fi

  if [[ "${merged_any}" == "false" ]]; then
    if [[ -f "${TARGET_ROOT}/CLAUDE.md" ]]; then
      merge_mcp_servers_into_file "${TARGET_ROOT}/.mcp.json"
    else
      merge_mcp_servers_into_file "${TARGET_ROOT}/.vscode/mcp.json"
    fi
  fi
}

copy_tree_additive "${ASSET_ROOT}/agents"  "${TARGET_ROOT}/.ai/pr-scout/agents"
copy_tree_additive "${ASSET_ROOT}/prompts" "${TARGET_ROOT}/.ai/pr-scout/prompts"
copy_tree_additive "${ASSET_ROOT}/outputs" "${TARGET_ROOT}/.ai/pr-scout/outputs"

if [[ -d "${TARGET_ROOT}/.github" ]]; then
  copy_tree_additive "${ASSET_ROOT}/templates/github/agents" "${TARGET_ROOT}/.github/agents"
  ensure_pr_scout_paragraph "${TARGET_ROOT}/.github/copilot-instructions.md"
fi

if [[ -d "${TARGET_ROOT}/.cursor" ]]; then
  copy_tree_additive "${ASSET_ROOT}/templates/cursor/skills/pr-scout" "${TARGET_ROOT}/.cursor/skills/pr-scout"
fi

ensure_pr_scout_paragraph "${TARGET_ROOT}/AGENTS.md"

if [[ -f "${TARGET_ROOT}/CLAUDE.md" ]]; then
  ensure_pr_scout_paragraph "${TARGET_ROOT}/CLAUDE.md"
fi

if [[ -d "${TARGET_ROOT}/.claude/rules" ]]; then
  ensure_pr_scout_paragraph "${TARGET_ROOT}/.claude/rules/pr-scout.md"
fi

ensure_gitignore_block
merge_mcp_servers

echo
echo "pr-scout init complete"
echo "- target: ${TARGET_ROOT}"
echo "- created files: ${created_files}"
echo "- skipped existing files: ${skipped_files}"

# Offer to remove the cloned pr-scout source directory.
# Only shown in interactive terminals — CI pipelines (no TTY) skip this automatically.
if [[ -t 0 && "${SOURCE_ROOT}" != "${TARGET_ROOT}" ]]; then
  echo
  read -r -p "Remove the cloned pr-scout folder (${SOURCE_ROOT})? [y/N] " _cleanup_response
  if [[ "${_cleanup_response}" =~ ^[Yy]$ ]]; then
    rm -rf "${SOURCE_ROOT}"
    echo "Removed ${SOURCE_ROOT}"
  fi
fi
