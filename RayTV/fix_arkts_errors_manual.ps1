# PowerShell脚本用于手动修复ArkTS构建错误
# 仅修复指定文件中的指定类型错误

$Path = "d:/tv/RayTV/raytv/src/main/ets"

# 定义要修复的文件和错误类型
$filesToFix = @(
    "pages/MediaDetailPage.ets",
    "pages/SearchPage.ets",
    "pages/SettingsPage.ets",
    "service/playback/PlaybackService.ets",
    "data/repository/SQLiteDatabaseRepository.ets"
)

# 遍历每个要修复的文件
foreach ($filePath in $filesToFix) {
    $fullPath = $Path + "\" + $filePath
    
    if (!(Test-Path -Path $fullPath)) {
        Write-Host "File not found: $fullPath"
        continue
    }
    
    $content = Get-Content -Path $fullPath -Raw
    $originalContent = $content
    
    # 修复Logger.error调用问题
    $pattern = 'Logger\.error\(([^,]+),\s*([^,]+),\s*([^)]+)\)'
    $content = $content -replace $pattern, 'Logger.error($1, $2, $3 instanceof Error ? $3 : new Error(String($3)))'
    
    # 如果内容有变化，保存文件
    if ($content -ne $originalContent) {
        Set-Content -Path $fullPath -Value $content
        Write-Host "Fixed Logger.error calls in $filePath"
    }
}

Write-Host "Manual fix completed"