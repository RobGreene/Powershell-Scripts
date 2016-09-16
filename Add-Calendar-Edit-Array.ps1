$User = Read-Host 'Enter UserName'
$UserArray = 'Enter User Names Here' 
ForEach ($User in $UserArray){
    Add-Mailboxfolderpermission -Identity ${_.User}:\Calendar -User $User -AccessRights editor}
         
