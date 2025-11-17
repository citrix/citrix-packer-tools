param(
    [Parameter(Mandatory=$true)]
    [string] $Username,
    [Parameter(Mandatory=$true)]
    [string] $LocationPath
)

$ExecutionPolicy = Get-ExecutionPolicy
Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - ExecutionPolicy : $($ExecutionPolicy)"
$PSVersion = $PSVersionTable.PSVersion.Major
Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - PS Version      : $($PSVersion)"

$versionKey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Citrix Virtual Desktop Agent' -Name DisplayVersion -ErrorAction SilentlyContinue  
if ($versionKey -eq $null `
    -OR [string]::IsNullOrEmpty($versionKey.DisplayVersion) `
    -OR [string]::IsNullOrEmpty($versionKey.DisplayVersion.Trim()) `
    -OR [version]($versionKey.DisplayVersion) -lt [version]"7.11") {
        
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Major Version   : $($($versionKey.DisplayVersion.Split('.'))[0]). Only VDA 7.11+ are supported."
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Full Version    : $($versionKey.DisplayVersion)"
        throw "CTX ERROR: Version $($versionKey.DisplayVersion). Only VDA 7.11+ are supported"

} else {

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Major Version   : $($($versionKey.DisplayVersion.Split('.'))[0])"
    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Full Version    : $($versionKey.DisplayVersion)"

}

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Checking MCSIO  :"
Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\CVhdFilter

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - GctRegistration : $(Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent' -Name 'GctRegistration' -ErrorAction SilentlyContinue)"

if($PSVersion -lt 5) {
	Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Version of PowerShell does not support disabling user via Disable-LocalUser"
	Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Removing user using ADSI[WinNT] command"

	$ObjectUser = [ADSI]"WinNT://$($ENV:COMPUTERNAME)/$($Username)"
	$ObjectUser.userflags=2
	$ObjectUser.setinfo()

	Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - ADSI[WinNT] command executed"
} else {
    $Users = Get-LocalUser
    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - All local users : $Users"
        
	$DisabledUser = Get-LocalUser -Name $Username
	Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Packer user enabled : $($DisabledUser.Enabled)"
	Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Disabling Packer user"
	Disable-LocalUser -Name $Username
	
	$DisabledUser = Get-LocalUser -Name $Username
	Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Packer user enabled : $($DisabledUser.Enabled)"
	Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Packer user now disabled"
}

Remove-Item -Path $LocationPath -Recurse -Force 
if (-not (Test-Path $LocationPath)) {
    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Package removed"
}

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Process completed"
