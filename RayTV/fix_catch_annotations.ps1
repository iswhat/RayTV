# 批量修复catch类型注解错误
# 这是一个安全的批量修复,不会引入新错误

$etsDir = "d:\tv\RayTV\raytv\src\main\ets"

Write-Host "🚀 开始批量修复catch类型注解..." -ForegroundColor Green
Write-Host ""

$count = 0
$files = Get-ChildItem -Path $etsDir -Recurse -Include "*.ets"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content

    # 移除catch类型注解
    $content = $content -replace '\} catch \(error: Error\) \{', '} catch (error) {'
    $content = $content -replace '\} catch \(error: unknown\) \{', '} catch (error) {'
    $content = $content -replace '\} catch \(error: Error \| unknown\) \{', '} catch (error) {'

    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $count++
        Write-Host "✅ 已修复: $($file.Name)" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "✨ 批量修复完成!" -ForegroundColor Green
Write-Host "📊 修复文件数: $count" -ForegroundColor Yellow
Write-Host ""
