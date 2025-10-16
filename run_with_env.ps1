# Load environment variables from .env file and run Flutter app
# สำหรับ Windows PowerShell

Write-Host "Loading environment variables from .env file..." -ForegroundColor Green

if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -and !$_.StartsWith("#")) {
            $key, $value = $_.Split("=", 2)
            if ($key -and $value) {
                [Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim(), "Process")
                Write-Host "Set $($key.Trim())=$($value.Trim())" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "`nEnvironment variables loaded successfully!" -ForegroundColor Green
    Write-Host "`nRunning Flutter app..." -ForegroundColor Cyan
    
    # Run Flutter app
    flutter run
} else {
    Write-Host "Error: .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file from .env.example" -ForegroundColor Yellow
}
