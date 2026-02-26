#!/bin/bash
# Daily dev experience capture script
# Usage: ./scripts/capture.sh [optional-topic]

set -euo pipefail

BLOG_DIR="$(cd "$(dirname "$0")/.." && pwd)/src/content/articles"
DATE=$(date +%Y-%m-%d)
TOPIC="${1:-daily-log}"
SLUG="${DATE}-${TOPIC}"
FILE="${BLOG_DIR}/${SLUG}.md"

if [ -f "$FILE" ]; then
  echo "File already exists: $FILE"
  echo "Opening for editing..."
else
  cat > "$FILE" << EOF
---
title: '${TOPIC}'
description: ''
pubDate: '${DATE}'
tags: []
draft: true
---

## What I Worked On

## Key Learnings

## Tools & Techniques

## Raw Notes

EOF
  echo "Created draft: $FILE"
fi

# Open in default editor
${EDITOR:-code} "$FILE"
