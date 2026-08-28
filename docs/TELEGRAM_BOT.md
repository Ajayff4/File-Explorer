# Telegram Bot Setup — OpenCode Remote Control

Talk to OpenCode from phone via Telegram. Runs on this machine, no open ports.

## How it works

- [opencode-telegram-bot](https://github.com/grinev/opencode-telegram-bot) (`@grinev/opencode-telegram-bot`, npm) — Telegram client for OpenCode CLI
- Bot talks to local OpenCode server on `http://localhost:4096` + Telegram API only
- Two systemd user services (linger enabled → survive reboot, no login needed)

## Services (already running)

| Service | What | Unit file |
|---|---|---|
| `opencode-server` | OpenCode server on :4096 | `~/.config/systemd/user/opencode-server.service` |
| `opencode-telegram-bot` | Telegram bot (foreground mode) | `~/.config/systemd/user/opencode-telegram-bot.service` |

Bot: `@opencode_ajayff4_bot`. Config: `~/.config/opencode-telegram-bot/.env` (token + user ID whitelist).

## Daily use

Start / stop / check:

```bash
systemctl --user restart opencode-telegram-bot
systemctl --user stop opencode-server
systemctl --user status opencode-server opencode-telegram-bot
journalctl --user -u opencode-telegram-bot -f   # live logs
```

Bot commands (in Telegram): `/status`, `/new`, `/sessions`, `/abort`, `/ls`, `/settings`, `/help` — plus regular prompts work like normal chat.

## Full setup from scratch (new machine)

1. **Create bot** — Telegram → @BotFather → `/newbot` → copy token
2. **Get user ID** — Telegram → @userinfobot → send message → copy numeric ID
3. **Install** — `npm install -g @grinev/opencode-telegram-bot` (Node ≥ 22.14)
4. **Config** — write `~/.config/opencode-telegram-bot/.env`:

   ```env
   TELEGRAM_BOT_TOKEN=<token>
   TELEGRAM_ALLOWED_USER_ID=<numeric-id>
   OPENCODE_API_URL=http://localhost:4096
   OPENCODE_MODEL_PROVIDER=opencode-go
   OPENCODE_MODEL_ID=deepseek-v4-pro
   ```

5. **Systemd units** — copy both service files above to `~/.config/systemd/user/`, adjust paths (`which node`, `which opencode`, `which opencode-telegram`)
6. **Enable linger** — `loginctl enable-linger <user>` (one time)
7. **Start**:

   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now opencode-server opencode-telegram-bot
   ```

## Troubleshooting

- **Bot silent** — wrong user ID in `.env`, or bot daemon stopped. Check `systemctl --user status opencode-telegram-bot`
- **"OpenCode server not available"** — server down: `systemctl --user restart opencode-server`, or run `opencode serve --port 4096`
- **Bot didn't survive reboot** — linger off: `loginctl enable-linger ajay`
- **Reconfigure** — `opencode-telegram config` (interactive wizard)
