$env:NODE_HOME = "C:\Program Files\Huawei\DevEco Studio\tools\node"
$env:PATH = "$env:NODE_HOME;$env:PATH"
Set-Location D:\tv\RayTV
& "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap -p product=default -p buildType=release *>&1 | Tee-Object -FilePath build_output.log