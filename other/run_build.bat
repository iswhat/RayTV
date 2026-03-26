@echo off
set "NODE_HOME=C:\Program Files\Huawei\DevEco Studio\tools\node"
set "PATH=%NODE_HOME%;%PATH%"
cd /d D:\tv\RayTV
call "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" --mode module -p product=default -p buildType=release :raytv:default@Build --debug 2>&1