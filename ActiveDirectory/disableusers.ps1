$File=import-csv c:\users\yourusername\desktop\disable.csv 
foreach ($user in $File) 
{ 
    Set-ADUser -Identity $($user.name) -Enabled $false 
}
