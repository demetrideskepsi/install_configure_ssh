$installed =  Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*' | select State | findstr -i present

# checks if openssh is installed, if not then it will install it before proceeding 
if ($installed -eq 'NotPresent')

	# assign OpenSSH installer to variable
	$openssh = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*' | select Name | findstr -i open

	# install OpenSSH Server
	Add-WindowsCapability -Online -Name $openssh

	# start service to create the sshd_config file
	Start-Service sshd

	# set service to start automatically
	Set-Service -Name sshd -StartupType 'Automatic'

# By default the ssh-agent service is disabled. Configure it to start automatically.
# Make sure you're running as an Administrator.
Get-Service ssh-agent | Set-Service -StartupType Automatic

# Start the service
Start-Service ssh-agent

# This should return a status of Running
Get-Service ssh-agent