# Setup Guide for Codex

This file is a step-by-step guide for installing and configuring the TradingView MCP server for Codex.

## Windows + Codex (recommended)

If the user is on Windows and wants Codex, use the guided installer:

```powershell
.\setup-codex-windows.bat
```

The installer will:

1. Check `node`, `npm`, and `codex`
2. Run `npm install`
3. Create `rules.json` if needed
4. Open `rules.json` in Notepad so the user can fill in watchlist, bias criteria, and risk rules
5. Register the server with Codex via `codex mcp add`
6. Offer to launch TradingView Desktop with `--remote-debugging-port=9222`
7. Tell the user to restart Codex and run `tv_health_check`

## Codex one-shot prompt

If the user wants a single prompt to paste into Codex instead of following the manual steps, use:

```text
Set up TradingView MCP Codex for me on this machine.
Clone https://github.com/CryptoStig/tradingview-mcp-codex.git into a local folder, run npm install, register the MCP server with Codex using `codex mcp add tradingview -- node <ABSOLUTE_PATH_TO_REPO>\src\server.js`, copy rules.example.json to rules.json if rules.json does not already exist, and open rules.json so I can fill in my watchlist and trading rules. Then tell me the exact next command or prompt to run to verify the TradingView connection with tv_health_check.
```

## Manual setup

## Step 1: Clone and Install

```bash
git clone https://github.com/CryptoStig/tradingview-mcp-codex.git ~/tradingview-mcp-codex
cd ~/tradingview-mcp-codex
npm install
```

If the user specifies a different install path, use that instead of `~/tradingview-mcp-codex`.

## Step 2: Set Up Rules

Copy the example rules file and open it for the user to fill in:

```bash
cp ~/tradingview-mcp-codex/rules.example.json ~/tradingview-mcp-codex/rules.json
```

Tell the user: "Open `rules.json` and fill in your watchlist (the symbols you trade), your bias criteria (what makes something bullish/bearish for you), and your risk rules. This is what the morning brief uses every day."

## Step 3: Add to MCP Config

### Codex

For Codex on Windows, the easiest path is the installer above. If you want to add the server manually instead:

```powershell
codex mcp add tradingview -- node C:\Users\YOUR_USERNAME\tradingview-mcp-codex\src\server.js
```

If a `tradingview` entry already exists in Codex, remove it first:

```powershell
codex mcp remove tradingview
```

Then fully restart Codex so it reloads MCP servers.

### ChatGPT note

ChatGPT on the web is not the recommended runtime for this repository. This project is a local stdio MCP server that controls a local TradingView Desktop app over `localhost:9222`, which makes Codex the practical OpenAI client for day-to-day use.

## Step 4: Launch TradingView Desktop

TradingView Desktop must be running with Chrome DevTools Protocol enabled.

**Auto-detect and launch (recommended):**
After the MCP server is connected, use the `tv_launch` tool — it auto-detects TradingView on Mac, Windows, and Linux.

**Manual launch by platform:**

Mac:
```bash
/Applications/TradingView.app/Contents/MacOS/TradingView --remote-debugging-port=9222
```

Windows:
```bash
%LOCALAPPDATA%\TradingView\TradingView.exe --remote-debugging-port=9222
```

Linux:
```bash
/opt/TradingView/tradingview --remote-debugging-port=9222
# or: tradingview --remote-debugging-port=9222
```

## Step 5: Restart your client

The MCP server only loads when Codex starts. After adding the config:

1. Exit Codex completely
2. Relaunch it
3. The tradingview MCP server should connect automatically

## Step 6: Verify Connection

Use the `tv_health_check` tool. Expected response:

```json
{
  "success": true,
  "cdp_connected": true,
  "chart_symbol": "...",
  "api_available": true
}
```

If `cdp_connected: false`, TradingView is not running with `--remote-debugging-port=9222`.

## Step 7: Run Your First Morning Brief

Ask Codex: *"Run morning_brief and give me my session bias"*

The MCP workflow will scan your watchlist, read your indicators, apply your `rules.json` criteria, and print your bias for each symbol.

To save it: *"Save this brief using session_save"*

To retrieve tomorrow: *"Get yesterday's session using session_get"*

## Step 8: Install CLI (Optional)

To use the `tv` CLI command globally:

```bash
cd ~/tradingview-mcp-codex
npm link
```

Then `tv status`, `tv quote`, `tv pine compile`, etc. work from anywhere.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `cdp_connected: false` | Launch TradingView with `--remote-debugging-port=9222` |
| `ECONNREFUSED` | TradingView isn't running or port 9222 is blocked |
| MCP server not showing in Codex | Run `codex mcp list`, check the `tradingview` entry, then restart Codex |
| `tv` command not found | Run `npm link` from the project directory |
| Tools return stale data | TradingView may still be loading — wait a few seconds |
| Pine Editor tools fail | Open the Pine Editor panel first (`ui_open_panel pine-editor open`) |

## What to Read Next

- `AGENTS.md` - Codex guidance for tool selection
- `rules.json` — Your personal trading rules (fill this in before using morning_brief)
- `README.md` — Full tool reference including morning brief workflow
- `RESEARCH.md` — Research context and open questions
