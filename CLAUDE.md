# TradingView MCP - Legacy Compatibility Notes

This repository is maintained as a Codex-first, OpenAI-oriented local MCP project.

If another assistant reads this file, use the same operating model:

- prefer the local `tradingview` MCP server
- keep outputs compact and tool-driven
- treat Codex setup and docs as the source of truth

68 tools for reading and controlling a live TradingView Desktop chart via CDP (port 9222).

## Decision Tree - Which Tool When

### "What's on my chart right now?"
1. `chart_get_state` -> symbol, timeframe, chart type, list of all indicators with entity IDs
2. `data_get_study_values` -> current numeric values from all visible indicators
3. `quote_get` -> real-time price, OHLC, volume for current symbol

### "What levels, lines, labels, or tables are showing?"
1. `data_get_pine_lines`
2. `data_get_pine_labels`
3. `data_get_pine_tables`
4. `data_get_pine_boxes`

Use `study_filter` whenever you know the indicator name.

### "Give me price data"
- `data_get_ohlcv` with `summary: true`
- `data_get_ohlcv` without summary when raw bars are truly needed
- `quote_get`

### "Analyze my chart"
1. `quote_get`
2. `data_get_study_values`
3. `data_get_pine_lines`
4. `data_get_pine_labels`
5. `data_get_pine_tables`
6. `data_get_ohlcv` with `summary: true`
7. `capture_screenshot`

### "Change the chart"
- `chart_set_symbol`
- `chart_set_timeframe`
- `chart_set_type`
- `chart_manage_indicator`
- `chart_scroll_to_date`
- `chart_set_visible_range`

### "Work on Pine Script"
1. `pine_set_source`
2. `pine_smart_compile`
3. `pine_get_errors`
4. `pine_get_console`
5. `pine_get_source`
6. `pine_save`
7. `pine_new`
8. `pine_open`

### "Practice trading with replay"
1. `replay_start`
2. `replay_step`
3. `replay_autoplay`
4. `replay_trade`
5. `replay_status`
6. `replay_stop`

### "TradingView isn't running"
- `tv_launch`
- `tv_health_check`

## Context Management Rules

1. Always use `summary: true` on `data_get_ohlcv` unless you need individual bars.
2. Always use `study_filter` on pine tools when you know which indicator you want.
3. Never use `verbose: true` on pine tools unless raw data is explicitly requested.
4. Avoid calling `pine_get_source` on complex scripts unless you need to edit the code.
5. Use `capture_screenshot` for visual context instead of pulling large datasets.
6. Call `chart_get_state` once at the start and reuse returned IDs.

## Architecture

```text
OpenAI Codex <-> MCP Server (stdio) <-> CDP (localhost:9222) <-> TradingView Desktop (Electron)
```
