#!/bin/bash

# ==============================================================================
# NODE.JS UTILITIES
# ==============================================================================

# rmnm (Remove Node Modules)
# A concise way to recursively delete node_modules with a simple confirmation.
# Usage: rmnm [directory]
rmnm() {
    local dir="${1:-.}"
    local path=$(realpath "$dir" 2>/dev/null || echo "$dir")
    
    echo "🔍 Target: $path"
    
    # Simple one-liner check for existence and size
    local count=$(find "$dir" -name "node_modules" -type d -prune | wc -l)
    
    if [ "$count" -eq 0 ]; then
        echo "✅ No node_modules found."
        return 0
    fi

    echo "📦 Found $count node_modules directories."
    read -p "⚠️  Delete all? [y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        find "$dir" -name "node_modules" -type d -prune -exec rm -rf {} +
        echo "✨ node_modules removed."
    else
        echo "❌ Cancelled."
    fi
}

# Alias for those who prefer the full name
alias rm_node_modules='rmnm'
alias nmrm='rmnm'
