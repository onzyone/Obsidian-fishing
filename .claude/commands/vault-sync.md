Stage all changes, commit with today's date, and push to remote for the specified vault.

Usage: /vault-sync [onzyone|yaos-camping|yaos-hledger|stocks|fishing|claude-stocks|claude-fishing|claude-config|all]

> NOTE: This file exists in six vaults. If you update it, update all copies:
> - onzyone: ~/.claude/commands/vault-sync.md (via onzyone vault)
> - yaos-camping: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/yaos-camping/.claude/commands/vault-sync.md
> - yaos-hledger: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/yaos-hledger/.claude/commands/vault-sync.md
> - stocks: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/stocks/.claude/commands/vault-sync.md
> - fishing: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing/.claude/commands/vault-sync.md
> - onzyone-skills: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/onzyone/Hobbies/40 Home Lab/49 Claude Skills/vault-sync.md

Steps:
1. If no vault argument was passed, treat it as `all` and sync every vault.
2. Set the vault path based on the argument:
   - `onzyone` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/onzyone`
   - `yaos-camping` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/yaos-camping`
   - `yaos-hledger` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/yaos-hledger`
   - `stocks` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/stocks`
   - `fishing` → `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fishing`
   - `claude-stocks` → `~/projects/onzyone/claude/stocks`
   - `claude-fishing` → `~/projects/onzyone/claude/fishing`
   - `claude-config` → `~/.claude`
   - `all` → sync all eight in order: onzyone, yaos-camping, yaos-hledger, stocks, fishing, claude-stocks, claude-fishing, claude-config
3. If syncing `onzyone` (or `all`), run `/brew-list` first to refresh the installed packages list
4. For each vault being synced, run:
```bash
cd "<vault-path>" && git add . && git commit -m "$(date +%Y-%m-%d)" && git push
```
