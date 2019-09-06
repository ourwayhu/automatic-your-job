$foldername = Get-Date -UFormat "%Y_%m"
$filename = Get-Date -UFormat "工作日誌_%Y%m%d.docx"
$Attachment = "\\192.168.x.x\home\#工作日誌\"+$foldername+"\"+$filename
if(Test-Path $Attachment )
{  
    $From = "me@gmail.com"
    $To = "sir@example.com"
    $Bcc = "other@example.com"
    $Subject = Get-Date -UFormat "%Y%m%d 工作日誌"
    # `n` 是換行
    $Body = "Dear Sir, `n`
         附件為"+$Subject+"，請查收。 `n`
    Best Regards,`n`
    "
    $SMTPServer = "smtp.gmail.com"
    $SMTPPort = "587"
    $smtpUsername = "me@gmail.com"
    $smtpPassword = "password"
    $Credentials = new-object Management.Automation.PSCredential $smtpUsername, ($smtpPassword | ConvertTo-SecureString -AsPlainText -Force)   

    # 要加 -Encoding ([System.Text.Encoding]::UTF8) 不然會亂碼

    Send-MailMessage -From $From -to $To -Bcc $Bcc -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $Credentials -Attachments $Attachment -Encoding ([System.Text.Encoding]::UTF8)

}
