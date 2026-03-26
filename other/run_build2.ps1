$env:NODE_HOME = "C:\Program Files\Huawei\DevEco Studio\tools\node"
$env:PATH = "$env:NODE_HOME;$env:PATH"
Set-Location D:\tv\RayTV
& "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" --mode module -p product=default -p buildType=release :raytv:default@CompileArkTS *>&1 | Tee-Object -FilePath build_output.log