$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Starting NextGen AI app..." -ForegroundColor Cyan

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Node.js is not installed or not available in PATH. Install Node.js first."
}

if (-not (Test-Path "$scriptDir\node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

$devServer = Start-Process powershell -ArgumentList @(
    '-NoLogo',
    '-NoExit',
    '-Command',
    "Set-Location '$scriptDir'; npm run dev"
) -PassThru

$maxAttempts = 30
$ready = $false
for ($i = 0; $i -lt $maxAttempts; $i++) {
    try {
        $response = Invoke-WebRequest -Uri 'http://localhost:3000' -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
            $ready = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    Write-Host "The app did not become ready on http://localhost:3000 within 30 seconds." -ForegroundColor Red
    Write-Host "Check the dev server window and the logs above." -ForegroundColor Yellow
    exit 1
}

Write-Host "Local app is ready at http://localhost:3000" -ForegroundColor Green

if (-not (Get-Command ngrok -ErrorAction SilentlyContinue)) {
    Write-Host "ngrok is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Install ngrok from https://ngrok.com/download and add it to PATH, then run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting ngrok tunnel to port 3000..." -ForegroundColor Cyan
Start-Process ngrok -ArgumentList @('http','3000','--host-header','localhost:3000')

Write-Host "" 
Write-Host "Your app should now be accessible from the ngrok public URL." -ForegroundColor Green
Write-Host "Open the forwarded URL shown in the ngrok terminal window." -ForegroundColor Green
Write-Host "If required, keep the ngrok window open while using the app." -ForegroundColor Yellow
