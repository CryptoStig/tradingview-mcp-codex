# TradingView MCP - Codex and OpenAI Guide

Use the `tradingview` MCP server when the user wants to inspect or control TradingView Desktop on this machine.

## Positioning

- Prefer Codex Desktop or Codex CLI as the primary runtime for this repo.
- Treat ChatGPT web as a planning or discussion companion, not the direct runtime for this local MCP server.
- When explaining setup, describe this project as a local OpenAI workflow built around Codex.

## Preferred tool flow

- Start with `chart_get_state` to get the active symbol, timeframe, and indicator list.
- Use `data_get_study_values` for current indicator readings.
- Use `quote_get` for the latest price snapshot.
- Use `data_get_ohlcv` with `summary=true` unless the user explicitly needs raw bars.
- Use `capture_screenshot` when a visual check is more useful than large raw payloads.
- Use `tv_health_check` when the user wants to verify connectivity.
- Use `tv_launch` when TradingView is not running with the debug port enabled.

## Morning brief workflow

- `morning_brief` reads `rules.json`, scans the watchlist, and returns structured data for a session bias.
- `session_save` saves the current brief for later comparison.
- `session_get` retrieves a saved brief, usually from today or yesterday.

## Pine and chart controls

- Use full indicator names with `chart_manage_indicator` such as `Relative Strength Index`.
- Use `study_filter` with Pine drawing tools whenever you know the indicator name.
- Avoid `pine_get_source` unless you need to inspect or edit the script directly because it can be very large.

## Context discipline

- Call `chart_get_state` once at the start and reuse the returned IDs.
- Avoid `verbose=true` unless the user specifically asks for raw data.
- Prefer compact outputs and screenshots over large dumps.
