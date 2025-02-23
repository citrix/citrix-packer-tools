param(
    [Parameter(Mandatory=$true)]
    [string] $VdaSetupDownloadUri
)

$ServiceName = 'BrokerAgent'
$RegName = "!XenDesktopSetup"
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$VdaFileName = "VDASetup.exe"
$VdaInstaller = Join-Path -Path "$($ENV:temp)" -ChildPath $VdaFileName
$XenInstaller = "$($ENV:ProgramData)\Citrix\XenDesktopSetup\XenDesktopVdaSetup.exe"


function Download-File {
    Param (
        [string]$url,
        [string]$localFile,
        [int]$retries = 3
    )
    $dlup = "..\..\dlup.exe"
    if (Test-Path -Path $dlup) {

        $result = &$dlup -p $url -o $localFile -r $retries 2>Out-Null
        if (-not $?) {
            $errorMsg = "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Download using dlup failed: $result"
            LogMessage $errorMsg $true
            throw $errorMsg
        }
    } else {
        $ex = ""
        for ($i=0; $i -lt $retries; $i++) {
            try {
                $client = New-Object System.Net.WebClient
                $client.DownloadFile($url, $localFile)
                return
            } catch {
                LogMessage "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Failed to download url: $($url) using WebClient: $($_)" $true
                $ex = $_
                Start-Sleep -Seconds 5
            }
        }
        throw $ex
    }
}

function Open-Firewall-Ports {

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Adding firewall allow rules for ports 80, 443, 1494, 2598, 8008"
    New-NetFirewallRule -DisplayName 'TCP 80 Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('80') | Out-Null
    New-NetFirewallRule -DisplayName 'TCP 443 Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('443') | Out-Null
    New-NetFirewallRule -DisplayName 'UDP 443 Inbound' -Direction Inbound -Action Allow -Protocol UDP -LocalPort @('443') | Out-Null
    New-NetFirewallRule -DisplayName 'TCP 1494 Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('1494') | Out-Null
    New-NetFirewallRule -DisplayName 'UDP 1494 Inbound' -Direction Inbound -Action Allow -Protocol UDP -LocalPort @('1494') | Out-Null
    New-NetFirewallRule -DisplayName 'TCP 2598 Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('2598') | Out-Null
    New-NetFirewallRule -DisplayName 'UDP 2598 Inbound' -Direction Inbound -Action Allow -Protocol UDP -LocalPort @('2598') | Out-Null
    New-NetFirewallRule -DisplayName 'TCP 8008 Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('8008') | Out-Null
    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Finished adding firewall allow rules for ports 80, 443, 1494, 2598, 8008"
}

function Set-Gct-Registration {

    try {

        $gctRegistration = $(Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent' -Name 'GctRegistration' -ErrorAction SilentlyContinue)
        if ($gctRegistration -EQ 1) {

            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - GctRegistration already enabled"

        } else {
        
            Set-ItemProperty -Path HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent -Name GctRegistration -Value 1 -ErrorAction SilentlyContinue
            $gctRegistration = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Citrix\VirtualDesktopAgent -Name GctRegistration -ErrorAction SilentlyContinue
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - GctRegistration enabled with value ($($gctRegistration))"
	
	}

    } catch {
        
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - GctRegistration was not found"

    }
    
}

function Initiate-Installation {

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Downloading VDASetup file from blob storage"  
    if (-not (Test-Path $VdaInstaller)) {
        Download-File $VdaSetupDownloadUri $VdaInstaller
    }

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Executing: $VdaInstaller, Components: VDA"
    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Parameters: /quiet /noreboot /masterimage /enable_real_time_transport /enable_hdx_ports /components vda /includeadditional ""Citrix MCS IODriver"""

    Start-Process $VdaInstaller "/quiet /noreboot /masterimage /enable_real_time_transport /enable_hdx_ports /components vda /includeadditional ""Citrix MCS IODriver"""

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - XenDesktopVDA installation started"
    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Waiting few seconds to make sure the process extracts and starts"
    Sleep -Milliseconds 120000

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Checking if XenDesktopVdaSetup process is running"
    $i = 0

    while($i -lt 100) {
        $Running = [Diagnostics.Process]::GetProcesses() | where { $_.ProcessName -eq "XenDesktopVdaSetup" } | foreach { $_.ProcessName }

        if ($Running.Count -gt 0) {

            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation process still running"
            Sleep -Milliseconds 30000

        } else {

            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation process completed"
            break

       }

       $i++
    }
}

function Continue-Installation {

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - XenDesktopVdaSetup is found at $($ENV:ProgramData)\Citrix\XenDesktopSetup"
    
    try {

        if (Get-ItemProperty -Path $RegPath $RegName -ErrorAction SilentlyContinue)
        {

            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Windows registry value is found for XenDesktopVdaSetup"
        
        } else {
        
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Windows registry value is not found for XenDesktopVdaSetup"
        
        }
    } catch {
        
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Windows registry value is not found for XenDesktopVdaSetup"
    
    }

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Executing: $XenInstaller"
    Start-Process $XenInstaller

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Waiting few seconds to make sure the process resumes"
    Sleep -Milliseconds 60000

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Checking if XenDesktopVdaSetup process is running"
    $i = 0
    while($i -lt 50) {
    
        $running = [Diagnostics.Process]::GetProcesses() | where { $_.ProcessName -eq "XenDesktopVdaSetup" } | foreach { $_.ProcessName }
    
        if ($running.Count -gt 0) {
    
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation process still running"
    
            Sleep -Milliseconds 30000
    
        } else {
    
	        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation process completed"
            break
    
        }
    
        $i++
    }
}

function Verify-Broker-Running {

    if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {

        Set-Gct-Registration

        if ((Get-Service $ServiceName).Status -eq 'Running') {
    
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - $ServiceName found and it is running."
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation of XenDesktopVDA completed with success"
            return

        } else {
            
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - $ServiceName found, but it is not running."
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation of XenDesktopVDA completed with success"
            return

        }
    } else {
        try {
            
            if (Get-ItemProperty -Path $RegPath $RegName -ErrorAction SilentlyContinue)
            {
            
                Remove-ItemProperty $RegPath $RegName -ErrorAction SilentlyContinue
                Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - $ServiceName not found"
                Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Windows registry value is found for XenDesktopVdaSetup"
            
            } else {
            
                Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - $ServiceName not found"
                Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Windows registry value is not found"
            
            }
        } catch {
    
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - $ServiceName not found"
            Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Windows registry value is not found"
    
        }
    }
}

if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
    
    Set-Gct-Registration

    if ((Get-Service $ServiceName).Status -eq 'Running') {
    
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - $ServiceName found and it is running."
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation of XenDesktopVDA completed with success"
        return
    
    } else {
    
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - $ServiceName found, but it is not running."
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation of XenDesktopVDA completed with success"
        return
    
    }

}

if (Test-Path $XenInstaller) {

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Continuing Citrix VDA installation."
    Continue-Installation
    Verify-Broker-Running
    
} else {

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Initiating Ctrix VDA installation."
    Open-Firewall-Ports
    Initiate-Installation
    Verify-Broker-Running
}
