#### 安裝zabbix-agent ####
msiexec.exe /i d:\zabbix_agent-4.0.11-win-amd64-openssl.msi server=zabbix.example.com serveractive=zabbix.example.comt    /qn

# === 更改zabbix-agent.conf內容 ===
((Get-Content -path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw) -replace '# LogType=file','LogType=file') | Set-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
((Get-Content -path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw) -replace '# EnableRemoteCommands=0','EnableRemoteCommands=1') | Set-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
((Get-Content -path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw) -replace '# Timeout=3','Timeout=30') | Set-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
((Get-Content -path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw) -replace '# TLSConnect=unencrypted','TLSConnect=psk') | Set-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
((Get-Content -path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw) -replace '# TLSAccept=unencrypted','TLSAccept=psk') | Set-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
((Get-Content -path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw) -replace '# TLSPSKIdentity=',$proj) | Set-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
((Get-Content -path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf' -Raw) -replace '# TLSPSKFile=','TLSPSKFile=C:\Program Files\Zabbix Agent\zabbix_agentd.psk') | Set-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'

# === 產生zabbix_agentd.psk檔 ===
# === https://gallery.technet.microsoft.com/scriptcenter/Get-StringHash-aa843f71 ===
Function Get-StringHash([String] $String,$HashName = "MD5")
{
$StringBuilder = New-Object System.Text.StringBuilder
[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{
[Void]$StringBuilder.Append($_.ToString("x2"))
}
$StringBuilder.ToString()
}

$psk = Get-StringHash "example" "SHA256"
Add-Content -Path 'C:\Program Files\Zabbix Agent\zabbix_agentd.psk' -Value $psk
