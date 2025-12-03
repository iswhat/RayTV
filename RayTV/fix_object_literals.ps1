# PowerShell脚本用于批量修复对象字面量问题
# 为对象字面量添加明确的类型注解

param(
    [string]$Path = "d:/tv/RayTV/raytv/src/main/ets"
)

# 获取所有.ets文件
$etsFiles = Get-ChildItem -Path $Path -Recurse -Filter "*.ets"

$count = 0

# 遍历每个文件
foreach ($file in $etsFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # 修复常见的对象字面量模式
    # 1. 修复DatabaseResult对象字面量
    $content = $content -replace '\{\s*success:\s*true\s*(,\s*data:\s*[^}]+)?\s*\}', '$0 as DatabaseResult<any>'
    $content = $content -replace '\{\s*success:\s*false\s*(,\s*message:\s*[^}]+)?\s*(,\s*error:\s*[^}]+)?\s*\}', '$0 as DatabaseResult<any>'
    
    # 2. 修复Response对象字面量
    $content = $content -replace '\{\s*status:\s*[^,]+,\s*statusText:\s*[^,]+,\s*data:\s*[^,]+,\s*headers:\s*[^}]+\s*\}', '$0 as Response<any>'
    
    # 3. 修复NavigationParams对象字面量
    $content = $content -replace '\{\s*id:\s*[^,]+,\s*siteKey:\s*[^,]+,\s*type:\s*[^}]+\s*\}', '$0 as NavigationParams'
    
    # 如果内容有变化，保存文件
    if ($content -ne (Get-Content -Path $file.FullName -Raw)) {
        Set-Content -Path $file.FullName -Value $content
        $count++
        Write-Host "Fixed $($file.Name)"
    }
}

Write-Host "Total files fixed: $count"