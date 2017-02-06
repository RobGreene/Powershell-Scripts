#Import Active Directory and Exchange Modules
$Creds = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://exchange/PowerShell/ -Authentication Kerberos -Credential $Creds
import-pssession $session
import-module activedirectory

#Disable User account and assign permissions to the mailbox 
$Users = Read-Host -Prompt 'Enter Disabled User Name'
$Managers = Read-host -Prompt 'Enter User Taking Over Mailbox'
$ManagerEmail = ((Get-ADUser -Filter {displayName -like $Managers} -Properties *).emailAddress)
Get-ADUser -Filter{displayName -like $Users} | Disable-ADAccount
Add-MailboxBrPermission -Identity $Users -User $Managers -AccessRights FullAccess -InheritanceType All

#Email manager and inform them how to set out of office
$From = "email"
$To = $ManagerEmail
$Subject = "Setting Users out of Office Message"
$Body = "
Dear $Managers, 
To setup the out of office message for $Users, go to https://webmailaddress/owa and sign in using your username and password,
in the upper right hand corner click your name, and in the open mailbox type $Users name and select open mailbox,
Then select options and hit Set Automatic Replies
Thank you,
IS Support
"
Send-MailMessage -to $To -From $From -Subject $Subject -Body $Body -SmtpServer smtpaddress -Priority High
