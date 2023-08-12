# assign OpenSSH installer to variable
$openssh = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | select Name | findstr -i open

# install OpenSSH Server
Add-WindowsCapability -Online -Name $openssh

# start service
Start-Service sshd

# set service to start automatically
Set-Service -Name sshd -StartupType 'Automatic'

# check if FW rule was created, if not, make it
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
	Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
	New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
else
{ 
	Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}