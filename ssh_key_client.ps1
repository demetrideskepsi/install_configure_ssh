$username = $env:USERNAME
$userprofile = $env:USERPROFILE
$remoteserver = "testbox"

$dirpath = "'$($userprofile)\.ssh'"
$contpath = "'$($userprofile)\.ssh\authorized_keys'"

# generate the key
ssh-keygen -t ed25519

# Now load your key files into ssh-agent
ssh-add "$($userprofile)\.ssh\id_ed25519" # NEED TO TEST THAT $env:USERPROFILE will work since this must be elevated to work

# Get the public key file generated previously on your client
$authorizedKey = Get-Content -Path "$($userprofile)\.ssh\id_ed25519.pub"

Write-Host "type 'user' for normal user and 'admin' for administrator user:"
$answer = Read-Host

$notselected = $True

while ($notselected -eq $True) {

    if ($answer -eq 'user'){
        # REGULAR USER
        # Generate the PowerShell to be run remote that will copy the public key file generated previously on your client to the authorized_keys file on your server
        $remotePowershell = "powershell New-Item -Force -ItemType Directory -Path $dirpath; Add-Content -Force -Path $contpath -Value '$authorizedKey'"
        $notselected = $False
    }
    elseif  ($answer -eq 'admin'){
        # ADMIN USER
        # Generate the PowerShell to be run remote that will copy the public key file generated previously on your client to the authorized_keys file on your server
        $remotePowershell = "powershell Add-Content -Force -Path $env:ProgramData\ssh\administrators_authorized_keys -Value '$authorizedKey';icacls.exe ""$env:ProgramData\ssh\administrators_authorized_keys"" /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F"""
        $notselected = $False
    }
    else {
        Write-Host "Incorrect input"
    }
}


# Connect to your server and run the PowerShell using the $remotePowerShell variable
ssh "$($username)@$($remoteserver)" $remotePowershell


Write-Host "Press enter to continue after finishing SSH Server configuration:"
pause

ssh "$($username)@$($remoteserver)" -p 1024

<#

SOURCES:
https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement

#>