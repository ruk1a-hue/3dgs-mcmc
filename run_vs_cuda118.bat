@echo off
call D:\VisualStudio\VC\Auxiliary\Build\vcvars64.bat >nul
set DISTUTILS_USE_SDK=1
set MSSdk=1
set CUDA_HOME=D:\anaconda3\envs\pytorch2.2.2
set PATH=D:\anaconda3\envs\pytorch2.2.2\bin;%PATH%
set TORCH_CUDA_ARCH_LIST=8.9
set PYTHONUTF8=1
set TMP=D:\AI WORK\tmp
set TEMP=D:\AI WORK\tmp
%*
