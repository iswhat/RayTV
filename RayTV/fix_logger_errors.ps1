# PowerShell脚本用于批量修复Logger.error调用问题
# 将Logger.error(TAG, message, error as any)转换为Logger.error(TAG, message, error as Error)

param(
    [string]$Path = "d:/tv/RayTV/raytv/src/main/ets"
)

# 获取所有.ets文件
$etsFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.ets"

$count = 0

# 遍历每个文件
foreach ($file in $etsFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # 使用正则表达式匹配Logger.error调用
    # 匹配模式：Logger.error(TAG, message, error)
    $pattern = 'Logger\.error\(([^,]+),\s*([^,]+),\s*([^)]+)\)'
    
    # 替换为：Logger.error($1, $2, $3 instanceof Error ? $3 : new Error(String($3)))
    $newContent = $content -replace $pattern, 'Logger.error($1, $2, $3 instanceof Error ? $3 : new Error(String($3)))'
    
    # 如果内容有变化，保存文件
    if ($newContent -ne $content) {
        Set-Content -Path $file.FullName -Value $newContent
        $count++
        Write-Host "Fixed $($file.Name)"
    }
}

Write-Host "Total files fixed: $count"