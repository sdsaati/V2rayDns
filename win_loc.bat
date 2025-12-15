@echo off
setlocal EnableDelayedExpansion

set DNS=127.0.0.1

:: Initialize counter
set count=0

:: Get all adapter names from netsh
for /f "skip=3 tokens=1,2,3,*" %%A in ('netsh interface show interface') do (
    set "name=%%D"
    :: Only store non-empty names
    if not "!name!"=="" (
        set /a count+=1
        set "adapter[!count!]=!name!"
    )
)

:: Check if any adapters were found
if %count%==0 (
    echo No adapters found.
    exit /b
)

:: Iterate over the array and echo adapter names
echo Network Adapters:
for /l %%i in (1,1,%count%) do (
    echo we are setting adaptor: [color=#ffaa00] !adapter[%%i]! [/color]
    netsh interface ip delete dns name="!adapter[%%i]!" all >nul
    netsh interface ip set dns name="!adapter[%%i]!" static %DNS% primary >nul
)

ipconfig /flushdns
echo Primary DNS set to [b] %DNS% [/b]
echo Secondary DNS cleared.






