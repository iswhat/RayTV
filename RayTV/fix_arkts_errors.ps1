# PowerShell脚本用于批量修复ArkTS构建错误
# 修复以下类型的错误：
# 1. Logger.error调用问题：将第三个参数转换为Error对象
# 2. 对象字面量问题：为对象字面量添加明确的类型注解
# 3. any/unknown类型问题：将any/unknown类型转换为明确的类型

param(
    [string]$Path = "d:/tv/RayTV/raytv/src/main/ets"
)

# 获取所有.ets文件
$etsFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.ets"

$loggerErrorCount = 0
$objectLiteralCount = 0
$anyUnknownCount = 0

# 遍历每个文件
foreach ($file in $etsFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    
    # 1. 修复Logger.error调用问题
    # 匹配模式：Logger.error(TAG, message, error)
    $loggerPattern = 'Logger\.error\(([^,]+),\s*([^,]+),\s*([^)]+)\)'
    $content = $content -replace $loggerPattern, 'Logger.error($1, $2, $3 instanceof Error ? $3 : new Error(String($3)))'
    
    if ($content -ne $originalContent) {
        $loggerErrorCount++
    }
    
    # 2. 修复对象字面量问题
    # 匹配模式：const obj = { ... };
    $objectLiteralPattern = 'const\s+([a-zA-Z0-9_]+)\s*=\s*\{[^}]+\};'
    $content = $content -replace $objectLiteralPattern, 'const $1: Record<string, string | number | boolean | null> = { ... };'
    
    if ($content -ne $originalContent) {
        $objectLiteralCount++
    }
    
    # 3. 修复any类型问题
    $anyPattern = ':\s*any\b'
    $content = $content -replace $anyPattern, ': Record<string, string | number | boolean | null>'
    
    # 修复unknown类型问题
    $unknownPattern = ':\s*unknown\b'
    $content = $content -replace $unknownPattern, ': Record<string, string | number | boolean | null>'
    
    if ($content -ne $originalContent) {
        $anyUnknownCount++
    }
    
    # 如果内容有变化，保存文件
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content
        Write-Host "Fixed $($file.Name)"
    }
}

Write-Host "Total files processed: $($etsFiles.Count)"
Write-Host "Logger.error calls fixed: $loggerErrorCount"
Write-Host "Object literals fixed: $objectLiteralCount"
Write-Host "any/unknown types fixed: $anyUnknownCount"