#check if port 1024 is open, netstat /a | findstr -i 1024
$port = 1024

# check if ssh server is installed
$installed =  Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | select State | findstr -i present

# checks if openssh server is installed, if not then it will install it before proceeding 
if ($installed -eq 'NotPresent')

	# assign OpenSSH installer to variable
	$openssh = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | select Name | findstr -i open

	# install OpenSSH Server
	Add-WindowsCapability -Online -Name $openssh

	# start service to create the sshd_config file
	Start-Service sshd

	# set service to start automatically
	Set-Service -Name sshd -StartupType 'Automatic'

# maybe pause statement here so admin can create key on local compute and push it
Write-Host "Press enter to continue configuring the server once you generate and push your ssh-key to the server"

pause

if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
	Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
	New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort $port # create to correct port if rule doesn't exist
}
else
{ 
	Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
	Set-NetFirewallRule  -Name 'OpenSSH-Server-In-TCP' -Direction Inbound -Protocol TCP -Action Allow -LocalPort $port #change to the correct port if rule exists
}

# double quotes, "Port $($port)", so that the variable is encased in the string
((Get-Content -Path "C:\ProgramData\ssh\sshd_config" -Raw) -Replace '#Port 22', "Port $($port)") | Set-Content -Path "C:\ProgramData\ssh\sshd_config"

# set to only allow passwordless
((Get-Content -Path "C:\ProgramData\ssh\sshd_config" -Raw) -Replace '#PasswordAuthentication yes', "PasswordAuthentication no") | Set-Content -Path "C:\ProgramData\ssh\sshd_config"

# disable root (administrative) login
((Get-Content -Path "C:\ProgramData\ssh\sshd_config" -Raw) -Replace '#PermitRootLogin prohibit-password', "PermitRootLogin no") | Set-Content -Path "C:\ProgramData\ssh\sshd_config"

# set max authentication tries before lockout to 3
((Get-Content -Path "C:\ProgramData\ssh\sshd_config" -Raw) -Replace '#MaxAuthTries 6', "MaxAuthTries 3") | Set-Content -Path "C:\ProgramData\ssh\sshd_config"

# short login grace period to 20 seconds from 2 minutes
((Get-Content -Path "C:\ProgramData\ssh\sshd_config" -Raw) -Replace '#LoginGraceTime 2m', "LoginGraceTime 20") | Set-Content -Path "C:\ProgramData\ssh\sshd_config"
	
# allow public key authentication
((Get-Content -Path "C:\ProgramData\ssh\sshd_config" -Raw) -Replace '#PubkeyAuthentication yes', "PubkeyAuthentication yes") | Set-Content -Path "C:\ProgramData\ssh\sshd_config"

# so that the 'keyboard-interactive' error goes away, as it's set to yes by default
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'KbdInteractiveAuthentication no'

# restart ssh server so configuration changes are applied
Restart-Service sshd

Write-Host "sshd_config port setting:"
# verifies that the port has been changed in the sshd_config 
type C:\ProgramData\ssh\sshd_config | findstr /r ^Port

Write-Host "SSH server firewall rule port:"
# verifies that firewall port has been set correct one 
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' | Get-NetFirewallPortFilter | findstr LocalPort

<#
SOURCES:

https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration
https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
https://man.openbsd.org/ssh_config

#>