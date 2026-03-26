$env:NODE_HOME = "C:\Program Files\Huawei\DevEco Studio\tools\node"
$env:PATH = "$env:NODE_HOME;$env:PATH"
Set-Location D:\tv\RayTV\raytv
& "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" -p product=default -p buildType=release default@CompileArkTS *>&1 | Tee-Object -FilePath build_output.log