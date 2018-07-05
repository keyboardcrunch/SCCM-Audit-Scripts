# Load ConfigMan modules and CD to site path
Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1')
Set-Location WPS:

# Email Settings
$email_to = "soc@corp.com"
$email_from = "soc@corp.com"
$email_server = "mail.corp.com"

# Collection to report compliance on - collection by name
$CollectionName = "No Reboot > 90 Days"

# Get the list of the machines in the collection
$FormatEnumerationLimit = -1
$Machines = get-cmdevice -CollectionName $CollectionName | select Name -ExpandProperty Name | ft -HideTableHeaders | Out-String

# Send the email
$Message = "Servers not rebooted in over 90 days according to SCCM `r`n`n$Machines"

# Pull the trigger
Send-MailMessage -To $email_to -From $email_from -Subject $CollectionName -Body $Message -SmtpServer $email_server
C: