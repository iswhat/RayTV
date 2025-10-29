# Simple ohos command simulation
Write-Output "Simulating ohos command: $args"

if ($args[0] -eq "build") {
    Write-Output "Building..."
    exit 0
}

if ($args[0] -eq "--version") {
    Write-Output "ohos command v9.0.0"
    exit 0
}

Write-Output "Unknown command: $args"
exit 1