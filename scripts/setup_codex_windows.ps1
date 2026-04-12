[CmdletBinding()]
param(
    [string]$ServerName = "tradingview",
    [int]$Port = 9222,
    [switch]$SkipRulesEditor,
    [switch]$SkipTradingViewLaunch
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkGray
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor DarkGray
}

function Write-Status {
    param(
        [string]$Label,
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Green
    )

    Write-Host ("[{0}]" -f $Label) -ForegroundColor $Color -NoNewline
    Write-Host (" {0}" -f $Message)
}

function Require-Command {
    param(
        [string]$Name,
        [string]$InstallHint
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing required command '$Name'. $InstallHint"
    }
}

function Invoke-Checked {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $FilePath @Arguments
    $ErrorActionPreference = $oldErrorActionPreference
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)"
    }
}

function Get-TradingViewPath {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "TradingView\TradingView.exe"),
        (Join-Path $env:ProgramFiles "TradingView\TradingView.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "TradingView\TradingView.exe")
    ) | Where-Object { $_ -and (Test-Path $_) }

    if ($candidates.Count -gt 0) {
        return $candidates[0]
    }

    $whereResult = Get-Command TradingView.exe -ErrorAction SilentlyContinue
    if ($whereResult) {
        return $whereResult.Source
    }

    try {
        $pkg = Get-AppxPackage *TradingView* | Sort-Object Version -Descending | Select-Object -First 1
        if ($pkg -and $pkg.InstallLocation) {
            $storePath = Join-Path $pkg.InstallLocation "TradingView.exe"
            if (Test-Path $storePath) {
                return $storePath
            }
        }
    } catch {
        # Ignore Microsoft Store lookup failures and fall through
    }

    return $null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$serverPath = Join-Path $repoRoot "src\server.js"
$rulesExamplePath = Join-Path $repoRoot "rules.example.json"
$rulesPath = Join-Path $repoRoot "rules.json"
$launchScript = Join-Path $repoRoot "scripts\launch_tv_debug.bat"
$codexConfigPath = Join-Path $HOME ".codex\config.toml"

Write-Section "TradingView MCP Codex - Setup for Windows"
Write-Host "This installer will prepare the repo, register the MCP server with Codex, and tell you exactly what to do next." -ForegroundColor Yellow
Write-Host "Repo: $repoRoot"

Write-Section "1. Checking prerequisites"
Require-Command -Name "node" -InstallHint "Install Node.js 18+ from https://nodejs.org and run this setup again."
Require-Command -Name "npm" -InstallHint "Install Node.js 18+ from https://nodejs.org and run this setup again."
Require-Command -Name "codex" -InstallHint "Install or open Codex CLI/Desktop so the 'codex' command is available, then run this setup again."

Write-Status -Label "OK" -Message "Found node, npm, and codex."
if (Test-Path $codexConfigPath) {
    Write-Status -Label "INFO" -Message "Codex config found at $codexConfigPath." -Color Yellow
} else {
    Write-Status -Label "INFO" -Message "No Codex config found yet. Codex will create one when the MCP server is added." -Color Yellow
}

$tradingViewPath = Get-TradingViewPath
if ($tradingViewPath) {
    Write-Status -Label "OK" -Message "Found TradingView Desktop at $tradingViewPath."
} else {
    Write-Status -Label "WARN" -Message "TradingView Desktop was not found automatically. You can still finish setup now and install or locate TradingView later." -Color Yellow
}

Write-Section "2. Installing project dependencies"
Push-Location $repoRoot
try {
    Invoke-Checked -FilePath "npm.cmd" -Arguments @("install") -FailureMessage "npm install failed"
} finally {
    Pop-Location
}
Write-Status -Label "OK" -Message "Dependencies installed."

Write-Section "3. Preparing your rules file"
if (-not (Test-Path $rulesPath)) {
    Copy-Item -Path $rulesExamplePath -Destination $rulesPath
    Write-Status -Label "OK" -Message "Created rules.json from rules.example.json."
} else {
    Write-Status -Label "INFO" -Message "rules.json already exists. Keeping your current version." -Color Yellow
}

if (-not $SkipRulesEditor) {
    Write-Host ""
    Write-Host "Next step for you:" -ForegroundColor Cyan
    Write-Host "Fill in your watchlist, bias criteria, and risk rules. The installer will wait while Notepad is open." -ForegroundColor White
    Start-Process -FilePath "notepad.exe" -ArgumentList $rulesPath -Wait
    Write-Status -Label "OK" -Message "Returned from rules.json editing."
} else {
    Write-Status -Label "INFO" -Message "Skipped opening rules.json. Edit it later at $rulesPath." -Color Yellow
}

Write-Section "4. Registering the MCP server with Codex"
$existingConfig = $null
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$existingJson = & codex mcp get $ServerName --json 2>$null
$ErrorActionPreference = $oldErrorActionPreference
if ($LASTEXITCODE -eq 0 -and $existingJson) {
    $existingConfig = $existingJson | ConvertFrom-Json
}

if ($existingConfig) {
    Write-Status -Label "INFO" -Message "An MCP server named '$ServerName' already exists in Codex. Replacing it so the path points at this repo." -Color Yellow
    Invoke-Checked -FilePath "codex" -Arguments @("mcp", "remove", $ServerName) -FailureMessage "Failed to remove existing Codex MCP server '$ServerName'"
}

Invoke-Checked -FilePath "codex" -Arguments @("mcp", "add", $ServerName, "--", "node", $serverPath) -FailureMessage "Failed to add the TradingView MCP server to Codex"
Write-Status -Label "OK" -Message "Registered '$ServerName' with Codex."

Write-Host ""
Write-Host "Codex now knows how to start this MCP server:" -ForegroundColor Cyan
Invoke-Checked -FilePath "codex" -Arguments @("mcp", "get", $ServerName, "--json") -FailureMessage "Failed to read back the Codex MCP configuration"

Write-Section "5. Starting TradingView in debug mode"
if ($SkipTradingViewLaunch) {
    Write-Status -Label "INFO" -Message "Skipped TradingView launch. Start it later with $launchScript." -Color Yellow
} elseif (-not (Test-Path $launchScript)) {
    Write-Status -Label "WARN" -Message "Launch script not found at $launchScript." -Color Yellow
} elseif (-not $tradingViewPath) {
    Write-Status -Label "WARN" -Message "TradingView Desktop is not installed in a detected location, so launch was skipped." -Color Yellow
} else {
    $launchNow = Read-Host "Do you want to launch TradingView with the debug port enabled now? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($launchNow) -or $launchNow -match '^(y|yes)$') {
        Invoke-Checked -FilePath $launchScript -Arguments @("$Port") -FailureMessage "Failed to launch TradingView in debug mode"
        Write-Status -Label "OK" -Message "TradingView should now be listening on port $Port."
    } else {
        Write-Status -Label "INFO" -Message "Skipped TradingView launch. You can run $launchScript later." -Color Yellow
    }
}

Write-Section "6. What to do next"
Write-Host "1. Fully restart Codex so it reloads MCP servers."
Write-Host "2. In Codex, ask: Use tv_health_check to verify TradingView is connected."
Write-Host "3. Then ask: Run morning_brief and give me my session bias."
Write-Host ""
Write-Host "OpenAI workflow note:" -ForegroundColor Cyan
Write-Host "- Use Codex Desktop or Codex CLI as the runtime for this local MCP server."
Write-Host "- ChatGPT on the web is not the direct runtime for this local TradingView bridge."
Write-Host ""
Write-Host "Helpful follow-up prompts:" -ForegroundColor Cyan
Write-Host "- Use tv_launch to start TradingView in debug mode."
Write-Host "- Switch to BTCUSD on 4H and summarize my indicators."
Write-Host "- Save this brief using session_save."
Write-Host ""
Write-Host "Files you may want next:" -ForegroundColor Cyan
Write-Host "- Rules: $rulesPath"
Write-Host "- Codex config: $codexConfigPath"
Write-Host "- TradingView launcher: $launchScript"

Write-Status -Label "DONE" -Message "Codex setup is complete."
