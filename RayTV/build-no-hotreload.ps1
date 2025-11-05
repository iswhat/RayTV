# PowerShell script for building HarmonyOS application without hot reload
# This avoids the es2abc compilation error in simulated build environment

Write-Host "Building HarmonyOS application (without hot reload)..." -ForegroundColor Green

# Set environment variables
$env:DEVECO_SDK_HOME = "C:\Program Files\Huawei\DevEco Studio\sdk"

# Build command without hot reload parameters
node "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=raytv@default -p product=default assembleHap --analyze=normal

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}