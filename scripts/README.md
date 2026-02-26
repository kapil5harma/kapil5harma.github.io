# Scripts

## capture.sh

Creates a new draft article with today's date.

Usage:
- `./scripts/capture.sh` — creates a daily log draft
- `./scripts/capture.sh ai-code-review` — creates a draft with a specific topic slug

The draft is created with `draft: true` frontmatter so it won't publish until you remove that flag.

## Workflow

1. Run `./scripts/capture.sh [topic]` at end of day
2. Fill in your notes (or use Claude Code to help draft)
3. Review, edit, add your voice
4. Remove `draft: true` when ready to publish
5. `git add . && git commit -m "post: [title]" && git push`
