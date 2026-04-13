Stage all changes, commit with today's date, and push to remote for the specified vault.

Usage: /vault-sync [onzyone|yaos-camping|stocks|fishing|all]

> NOTE: This file exists in four vaults. If you update it, update all copies:
> - onzyone: ~/.claude/commands/vault-sync.md (via onzyone vault)
> - yaos-camping: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/yaos-camping/.claude/commands/vault-sync.md
> - stocks: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/stocks/.claude/commands/vault-sync.md
> - fishing: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/.claude/commands/vault-sync.md

Steps:
1. If no vault argument was passed, treat it as `all` and sync every vault.
2. Set the vault path based on the argument:
   - `onzyone` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/onzyone`
   - `yaos-camping` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/yaos-camping`
   - `stocks` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/stocks`
   - `fishing` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing`
   - `all` → sync all four vaults in order: onzyone, yaos-camping, stocks, fishing
3. If syncing `onzyone` (or `all`), run `/brew-list` first to refresh the installed packages list
4. For each vault being synced, run:
```bash
cd "<vault-path>" && git add . && git commit -m "$(date +%Y-%m-%d)" && git push
```
