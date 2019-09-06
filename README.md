pc_owner_signin_only.bat  
這台電腦只能給某個帳號用，其他人無法登入，並且給予這個帳號在該電腦有最高權限．

powershell_install_zabbix-agent.ps1   
Zabbix Windows Agent Powershell install script  
用Powershell Script 在Windows 安裝Zabbix-agent  

web_server_autoconfig.ps1    
environment : windows 2012 R2 
用script 自動建iis 及其相關設定 

azure_create_VM.bat  
environment : azure cloud shell (bash)     
用Script 自動建VM 
要注意的地方是 
1. 若要建Lord Balance ，LB 要先在建網卡(NIC)先建好 
2. 在建VM前，最好按照 PublicIP -> NIC -> VM ，這個順序來建，原因是有一些參數沒有在 az vm create 內

automail.ps1  
利用gmail 發工作日誌給主管，放到工作排程器，就可以每天自動發工作日誌給主管了
