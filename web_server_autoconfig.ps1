
# 調整時區
tzutil /s "Taipei Standard Time"

# ===關閉IE Enhanced Security Configuration===
# --- Disable-InternetExplorerESC----
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

Disable-InternetExplorerESC

# === 安裝iis & application server ===
add-windowsfeature Application-Server, AS-Web-Support

add-windowsfeature Web-Server, Web-WebServer, Web-Common-Http, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Static-Content, Web-Http-Redirect, Web-Health, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor, Web-Performance, Web-Stat-Compression, Web-Dyn-Compression, Web-Security, Web-Filtering, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Cert-Auth, Web-IP-Security, Web-Url-Auth, Web-Windows-Auth, Web-App-Dev, Web-Net-Ext45, Web-AppInit, Web-Asp-Net45, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-WebSockets

add-windowsfeature Web-Ftp-Server, Web-Ftp-Service, Web-Ftp-Ext

add-windowsfeature Web-Mgmt-Tools, Web-Mgmt-Console, Web-Scripting-Tools, Web-Mgmt-Service

# ===設定Application Pool回收時間===
import-module WebAdministration  
$websiteName = "default web site"  
$appPool = Get-Item IIS:\Sites\$websiteName | Select-Object applicationPool  
$appPoolName = $appPool.applicationPool  
  
Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicRestart -Value  "0"
Add-WebConfiguration /system.applicationHost/applicationPools/applicationPoolDefaults/recycling/periodicRestart/schedule -value (New-TimeSpan -h 1 -m 20)
Set-ItemProperty IIS:\AppPools\$appPoolName -Name processModel.idleTimeout -Value "00:00:00" #0 = No timeout  

# ===修改IIS的Log欄位及存放地點===
New-Item -Path d:\LogFiles -ItemType Directory
set-WebConfigurationProperty -pspath  IIS:\ -filter "system.applicationHost/sites/siteDefaults" -name "logfile.directory" -value "D:\LogFiles"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site/logFile" -name "truncateSize" -value 100000000
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site/logFile" -name "period" -value MaxSize

# iis restart
invoke-command  -scriptblock {iisreset /RESTART}



# === 安裝需求套件 ===
# 安裝WebPlatformInstaller
$url = "https://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi"
$output = "d:\WebPlatformInstaller_amd64_en-US.msi"
$start_time = Get-Date

Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
msiexec  /I d:\WebPlatformInstaller_amd64_en-US.msi /quiet
Start-Sleep -s 10

# 安裝application insights status monitor、url rewrite、web deploy
C:\"Program Files"\Microsoft\"Web Platform Installer"\WebpiCmd.exe /install /products:'application insights status monitor' /accepteula
C:\"Program Files"\Microsoft\"Web Platform Installer"\WebpiCmd.exe /install /products:'url rewrite 2.1' /accepteula
C:\"Program Files"\Microsoft\"Web Platform Installer"\WebpiCmd.exe /install /products:'web deploy 3.6' /accepteula

# === iis apppool加入Performance Monitor Users ===
net localgroup "Performance Monitor Users" "IIS AppPool\DefaultAppPool" /ADD

# === 修改IIS預設網站Default Web Site為 Example ===
rename-item 'IIS:\Sites\Default Web Site'  Example

# === 設定web deploy ===
# 新增目錄
New-Item -Path c:\profiles -ItemType Directory
cd "C:\Program Files\IIS\Microsoft Web Deploy V3\Scripts"
.\SetupSiteForPublish.ps1 -siteName Example -deploymentUserName WebDeploy -deploymentUserPassword pass@1122 -publishSettingSavePath C:\profiles -publishSettingFileName Example.PublishSettings

# === 改系統的密碼複雜度和有效日期 ===
# disabled 密碼複雜度
secedit /export /cfg c:\secpol.cfg 
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

# 密碼最久日期設永久
net accounts /maxpwage:unlimited


# === 設定Examplelogs權限wwwroot目錄權限===
$Path = 'C:\inetpub\Examplelogs'
 
# 新增目錄
$null = New-Item -Path $Path -ItemType Directory
 
$acl = Get-Acl -Path $path
 
# 增加新權限
$permission = 'Authenticated Users', 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
$acl.SetAccessRule($rule)
 
$acl | Set-Acl -Path $path

$Path = 'C:\inetpub\wwwroot'

$acl | Set-Acl -Path $path

# === 在IIS新增FTP站台 ===
# 新增目錄
New-Item -Path C:\Example\imagemanagement -ItemType Directory
New-WebFtpSite -name "ExampleFTP" -port 21 -PhysicalPath C:\Example\imagemanagement

## SET PERMISSIONS

## Allow SSL connections 
Set-ItemProperty "IIS:\Sites\ExampleFTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\ExampleFTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0

## Enable Basic Authentication
Set-ItemProperty "IIS:\Sites\ExampleFTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true


# === 在IIS設定FTP站台Firewall Support ===
Set-WebConfigurationProperty -PSPath IIS:\ -Filter system.ftpServer/firewallSupport -Name lowDataChannelPort -Value 62001
Set-WebConfigurationProperty -PSPath IIS:\ -Filter system.ftpServer/firewallSupport -Name highDataChannelPort -Value 63000

# 抓外部ip
$extip = (invoke-webrequest -uri "http://ifconfig.co/ip").content
# 字串去頭尾空白
$extip = $extip.Trim()
# ip前後加上雙引號
$extip = "`"$extip`""

C:\Windows\System32\inetsrv\appcmd.exe set config /section:system.applicationHost/sites /siteDefaults.ftpServer.firewallSupport.externalIp4Address:$extip /commit:apphost

## Restart the FTP site for all changes to take effect
Restart-WebItem "IIS:\Sites\ExampleFTP"

# === 確認IIS服務設定 ===
Set-ItemProperty IIS:\Sites\Example -name physicalPath -value "C:\inetpub\wwwroot"

# === 在IIS設定壓縮json ===
Add-WebConfigurationProperty -pspath iis:\  -filter "system.webServer/httpCompression/dynamicTypes" -name "." -value @{mimeType='application/json; charset=utf-8';enabled='True'}
Add-WebConfigurationProperty -pspath iis:\  -filter "system.webServer/httpCompression/dynamicTypes" -name "." -value @{mimeType='application/json';enabled='True'}

# === 調整Windows TCP/IP參數 ===
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d 30 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\Tcpip\Parameters" /v "MaxUserPort" /t REG_DWORD /d 65500 /f


# === 更改framework / machine.config  ===
((Get-Content -path C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config -Raw) -replace 'autoConfig="true"','autoConfig="true" minWorkerThreads="40" minIoThreads="40"') | Set-Content -Path C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config

# === 執行Windows Update後關閉自動更新 ===
# 下載安裝WebPlatformInstaller
$url = "https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc/file/41459/47/PSWindowsUpdate.zip"
$output = "d:\PSWindowsUpdate.zip"
$start_time = Get-Date
Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# 解壓縮的Function
Function Unzip-File()
            {
                param([string]$ZipFile,[string]$TargetFolder)
                if(!(Test-Path $TargetFolder))
                {
                 mkdir $TargetFolder
                }
                    $shellApp = New-Object -ComObject Shell.Application
                    $files = $shellApp.NameSpace($ZipFile).Items()
                    $shellApp.NameSpace($TargetFolder).CopyHere($files)
            }
# 解壓縮
Unzip-File -ZipFile D:\PSWindowsUpdate.zip -TargetFolder C:\Windows\System32\WindowsPowerShell\v1.0\Modules

# 載入 Windows Update PowerShell Module
Import-Module PSWindowsUpdate

# 下載所有更新並重開機
Get-WUInstall -All -AutoReboot
