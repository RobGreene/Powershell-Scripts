$User = Read-Host 'Enter UserName'
$UserArray = 'ccodjoe','binnis','kwoollery','zkashif' 
ForEach ($User in $UserArray){
    Add-Mailboxfolderpermission -Identity ${_.User}:\Calendar -User $User -AccessRights editor}
         