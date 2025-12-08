# Simple build script
Write-Host "Starting build process..."

# Run the build command directly
Write-Host "Executing: hvigorw assembleHap"
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" assembleHap

# Check the result
if ($LASTEXITCODE -eq 0) {
  Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
  Write-Host "Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}