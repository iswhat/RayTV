$env:NODE_HOME = "C:\Program Files\Huawei\DevEco Studio\tools\node"
$env:PATH = "$env:NODE_HOME;$env:PATH"
Set-Location D:\tv\RayTV
& "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" taskTree --mode module -p product=default *>&1