# Detailed build script with debugging information
Write-Host "Starting detailed build process..." -ForegroundColor Green

# Print current directory
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Cyan

# Check if required files exist
$requiredFiles = @(
    "hvigorfile.ts",
    "build-profile.json5",
    "oh-package.json5"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ Found required file: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing required file: $file" -ForegroundColor Red
    }
}

# Print environment information
Write-Host "`nEnvironment Information:" -ForegroundColor Cyan
Write-Host "NODE_PATH: $env:NODE_PATH" -ForegroundColor Yellow
Write-Host "PATH: $env:PATH" -ForegroundColor Yellow

# List available tasks
Write-Host "`nListing available tasks..." -ForegroundColor Cyan
node "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" tasks

# Try to build with debug information
Write-Host "`nAttempting to build with debug information..." -ForegroundColor Cyan
node "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=raytv@default -p product=default --debug

# Check the result
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}