# PowerShell脚本用于批量修复Logger.error调用问题
# 只修复Logger.error调用，不处理其他类型的错误

param(
    [string]$Path = "d:/tv/RayTV/raytv/src/main/ets"
)

# 获取所有.ets文件
$etsFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.ets"

$count = 0

# 遍历每个文件
foreach ($file in $etsFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    
    # 修复Logger.error调用问题
    # 匹配模式：Logger.error(TAG, message, error)
    $pattern = 'Logger\.error\(([^,]+),\s*([^,]+),\s*([^)]+)\)'
    
    # 替换为：Logger.error($1, $2, $3 instanceof Error ? $3 : new Error(String($3)))
    $content = $content -replace $pattern, 'Logger.error($1, $2, $3 instanceof Error ? $3 : new Error(String($3)))'
    
    # 如果内容有变化，保存文件
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content
        $count++
        Write-Host "Fixed $($file.Name)"
    }
}

Write-Host "Total files fixed: $count"