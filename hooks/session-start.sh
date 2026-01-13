#!/usr/bin/env bash

# ============================================
# superpowers-tanstack Session Start Hook
# Detects TanStack Start projects and configures environment
# ============================================

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
SKILL_DIR="${PLUGIN_ROOT}/skills/using-tanstack-superpowers"

# ============================================
# 1. TANSTACK START PROJECT DETECTION
# ============================================

detect_tanstack_apps() {
    local search_root="${1:-.}"
    local apps=()

    # Search for package.json with "@tanstack/start" dependency
    while IFS= read -r -d '' pkg_file; do
        if grep -qE '"@tanstack/start":\s*"' "$pkg_file" 2>/dev/null; then
            local app_dir
            app_dir=$(dirname "$pkg_file")
            apps+=("$app_dir")
        fi
    done < <(find "$search_root" \
        -name "package.json" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -print0 2>/dev/null)

    printf '%s\n' "${apps[@]}"
}

# ============================================
# 2. TANSTACK START VERSION DETECTION
# ============================================

get_tanstack_version() {
    local app_dir="$1"
    local version=""

    # Priority 1: package-lock.json
    if [[ -f "$app_dir/package-lock.json" ]]; then
        version=$(grep -A2 '"@tanstack/start":' "$app_dir/package-lock.json" 2>/dev/null | \
            grep '"version"' | head -1 | \
            sed -E 's/.*"version": "([0-9]+\.[0-9]+).*/\1/')
    fi

    # Priority 2: yarn.lock
    if [[ -z "$version" && -f "$app_dir/yarn.lock" ]]; then
        version=$(grep -A1 '"@tanstack/start@' "$app_dir/yarn.lock" 2>/dev/null | \
            grep 'version' | head -1 | \
            sed -E 's/.*version "([0-9]+\.[0-9]+).*/\1/')
    fi

    # Priority 3: pnpm-lock.yaml
    if [[ -z "$version" && -f "$app_dir/pnpm-lock.yaml" ]]; then
        version=$(grep -A5 "@tanstack/start:" "$app_dir/pnpm-lock.yaml" 2>/dev/null | \
            grep "version:" | head -1 | \
            sed -E "s/.*version: '?([0-9]+\.[0-9]+).*/\1/")
    fi

    # Priority 4: package.json
    if [[ -z "$version" && -f "$app_dir/package.json" ]]; then
        version=$(grep '"@tanstack/start"' "$app_dir/package.json" 2>/dev/null | \
            sed -E 's/.*"[\^~]?([0-9]+\.[0-9]+).*/\1/')
    fi

    echo "${version:-unknown}"
}

# ============================================
# 3. PACKAGE MANAGER DETECTION
# ============================================

detect_package_manager() {
    local app_dir="$1"
    local pm_name="npm"
    local pm_command="npm"

    if [[ -f "$app_dir/bun.lockb" ]] || [[ -f "$app_dir/bun.lock" ]]; then
        pm_name="bun"
        pm_command="bun"
    elif [[ -f "$app_dir/pnpm-lock.yaml" ]]; then
        pm_name="pnpm"
        pm_command="pnpm"
    elif [[ -f "$app_dir/yarn.lock" ]]; then
        pm_name="yarn"
        pm_command="yarn"
    elif [[ -f "$app_dir/package-lock.json" ]]; then
        pm_name="npm"
        pm_command="npm"
    fi

    echo "${pm_name}|${pm_command}"
}

# ============================================
# 4. TYPESCRIPT DETECTION
# ============================================

detect_typescript() {
    local app_dir="$1"
    local ts_enabled="false"
    local ts_strict="false"

    if [[ -f "$app_dir/tsconfig.json" ]]; then
        ts_enabled="true"
        if grep -q '"strict":\s*true' "$app_dir/tsconfig.json" 2>/dev/null; then
            ts_strict="true"
        fi
    fi

    echo "${ts_enabled}|${ts_strict}"
}

# ============================================
# 5. VITE CONFIGURATION DETECTION
# ============================================

detect_vite_config() {
    local app_dir="$1"
    local configured="false"
    local version=""

    if [[ -f "$app_dir/vite.config.ts" ]] || [[ -f "$app_dir/vite.config.js" ]] || [[ -f "$app_dir/vite.config.mjs" ]]; then
        configured="true"
    fi

    # Get Vite version from package.json
    if [[ -f "$app_dir/package.json" ]]; then
        version=$(grep '"vite"' "$app_dir/package.json" 2>/dev/null | \
            sed -E 's/.*"[\^~]?([0-9]+\.[0-9]+).*/\1/')
    fi

    echo "${configured}|${version:-unknown}"
}

# ============================================
# 6. TANSTACK INTEGRATIONS DETECTION
# ============================================

detect_tanstack_integrations() {
    local app_dir="$1"
    local has_query="false"
    local has_form="false"
    local has_table="false"

    if [[ -f "$app_dir/package.json" ]]; then
        if grep -q '"@tanstack/react-query"' "$app_dir/package.json" 2>/dev/null; then
            has_query="true"
        fi
        if grep -q '"@tanstack/react-form"' "$app_dir/package.json" 2>/dev/null; then
            has_form="true"
        fi
        if grep -q '"@tanstack/react-table"' "$app_dir/package.json" 2>/dev/null; then
            has_table="true"
        fi
    fi

    echo "${has_query}|${has_form}|${has_table}"
}

# ============================================
# 7. TEST FRAMEWORK DETECTION
# ============================================

detect_test_framework() {
    local app_dir="$1"
    local framework="none"

    if [[ -f "$app_dir/package.json" ]]; then
        if grep -q '"vitest"' "$app_dir/package.json" 2>/dev/null; then
            framework="vitest"
        fi

        # Check for Playwright
        if grep -q '"@playwright/test"' "$app_dir/package.json" 2>/dev/null; then
            if [[ "$framework" != "none" ]]; then
                framework="${framework}+playwright"
            else
                framework="playwright"
            fi
        fi
    fi

    echo "$framework"
}

# ============================================
# 8. STYLING DETECTION
# ============================================

detect_styling() {
    local app_dir="$1"
    local styling="css"

    if [[ -f "$app_dir/tailwind.config.js" ]] || [[ -f "$app_dir/tailwind.config.ts" ]] || [[ -f "$app_dir/tailwind.config.mjs" ]]; then
        styling="tailwind"
    elif grep -q '"styled-components"' "$app_dir/package.json" 2>/dev/null; then
        styling="styled-components"
    fi

    echo "$styling"
}

# ============================================
# MAIN EXECUTION
# ============================================

main() {
    local cwd="${PWD}"
    local apps

    # Detect TanStack Start applications
    mapfile -t apps < <(detect_tanstack_apps "$cwd")

    if [[ ${#apps[@]} -eq 0 ]]; then
        # No TanStack Start application detected
        exit 0
    fi

    # Determine active application
    local active_app=""
    for app in "${apps[@]}"; do
        if [[ "$cwd" == "$app"* ]]; then
            active_app="$app"
            break
        fi
    done
    [[ -z "$active_app" ]] && active_app="${apps[0]}"

    # Collect information
    local tanstack_version
    local pm_info
    local ts_info
    local vite_info
    local integrations
    local test_framework
    local styling

    tanstack_version=$(get_tanstack_version "$active_app")
    pm_info=$(detect_package_manager "$active_app")
    ts_info=$(detect_typescript "$active_app")
    vite_info=$(detect_vite_config "$active_app")
    integrations=$(detect_tanstack_integrations "$active_app")
    test_framework=$(detect_test_framework "$active_app")
    styling=$(detect_styling "$active_app")

    # Parse package manager info
    IFS='|' read -r pm_name pm_command <<< "$pm_info"

    # Parse TypeScript info
    IFS='|' read -r ts_enabled ts_strict <<< "$ts_info"

    # Parse Vite info
    IFS='|' read -r vite_configured vite_version <<< "$vite_info"

    # Parse integrations
    IFS='|' read -r has_query has_form has_table <<< "$integrations"

    # Determine if latest version
    local is_latest="false"
    if [[ "$tanstack_version" == "1"* ]]; then
        is_latest="true"
    fi

    # Generate commands
    local dev_cmd="${pm_command} run dev"
    local build_cmd="${pm_command} run build"
    local test_cmd="${pm_command} run test"
    local lint_cmd="${pm_command} run lint"

    if [[ "$pm_name" == "bun" ]]; then
        dev_cmd="bun dev"
        build_cmd="bun run build"
        test_cmd="bun test"
        lint_cmd="bun lint"
    fi

    # Determine guidance
    local guidance=""
    if [[ "$has_query" == "false" ]]; then
        guidance="Consider adding @tanstack/react-query for advanced data fetching and caching"
    fi

    # Output JSON context for Claude
    cat <<EOF
{
  "plugin": "superpowers-tanstack",
  "detected_apps": ${#apps[@]},
  "active_app": "$active_app",
  "tanstack_start": {
    "version": "$tanstack_version",
    "is_latest": $is_latest
  },
  "integrations": {
    "tanstack_query": $has_query,
    "tanstack_form": $has_form,
    "tanstack_table": $has_table
  },
  "vite": {
    "configured": $vite_configured,
    "version": "$vite_version"
  },
  "typescript": {
    "enabled": $ts_enabled,
    "strict": $ts_strict
  },
  "package_manager": {
    "name": "$pm_name",
    "command": "$pm_command"
  },
  "test_framework": "$test_framework",
  "styling": "$styling",
  "commands": {
    "dev": "$dev_cmd",
    "build": "$build_cmd",
    "test": "$test_cmd",
    "lint": "$lint_cmd"
  },
  "guidance": $(if [[ -n "$guidance" ]]; then echo "\"$guidance\""; else echo "null"; fi)
}
EOF

}

main "$@"
