#This script was written for use on 1 computer with multiple users (ie: a conference room laptop)
#The objective was allow the users to have all there mapped network drives from the logon script
#Without having access to everyone else's material/admin account.
#Pull the users credentials from input and then uses there information to look up there AD account
#And subsequently load in the logon script. We also use a private my documents drive which is prompted
#To open on login. 
#We added this to Task Schedular so it prompts the user for their creds as soon as they login with
#the generic ones used to access the laptop.

$Credential = Get-Credential
$Username = $Credential.UserName
$Script = (Get-ADUser -Identity $Credential.UserName -Properties ScriptPath).ScriptPath
$Path = "\\ServerName\NETLOGON"
$scriptpath = $Path + "\" + $Script
& $scriptpath
ii "\\ServerName\Users\$USERNAME\My Documents"
