@echo off
chcp 65001
@echo off
:menu
cls
echo.
echo  ====================================
echo.      
echo    
echo.
echo  ====================================
echo.
set /p account="Please input domain account: "

rem if %account% exist 
wmic useraccount where (name='%account%' and domain='exampledomain') get SID | findstr /b S-  > tmp.txt
set /p aa=<tmp.txt

rem account check
findstr "\<S" tmp.txt
if errorlevel 1 goto p1
if errorlevel 0 goto p2

:p1
cls
echo.
echo    *******************************
echo    *                             *
echo    *          ERROR!!            *
echo    *                             *
echo    *******************************
echo.
echo.
pause
goto menu


:p2
rem disable account : administrator 、 guest
net user administrator /active:no
net user guest /active:no

rem user account join to administrators group 
net localgroup administrators %account%  /add


echo [version] >> rr.inf
echo signature="$CHICAGO$" >> rr.inf

rem 把administrator、domain admin、dylocaladmin及自己的帳號放到本機群組原則中的"電腦設定/Windows設定/安全性設定/本機原則/使用者權限指派/允許本機登入"
echo [Privilege Rights] >> rr.inf
echo SeInteractiveLogonRight = *%aa%,*S-1-5-21-3681503898-3011527370-457787210-512,localadmin,*S-1-5-32-544  >> /rr.inf


rem 執行seceidt 把帳號寫入本機登入
secedit /configure /db rr.sdb /cfg rr.inf /log rr.log

del rr.*
del tmp.txt


rem create localadmin
net localgroup administrators localadmin /delete
net user localadmin /delete
net user localadmin * /add /passwordchg:no
net localgroup administrators localadmin /add
wmic useraccount where name='localadmin' set passwordexpires=false

pause
