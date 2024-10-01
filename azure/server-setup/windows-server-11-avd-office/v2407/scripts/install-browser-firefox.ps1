param(
    [Parameter(Mandatory=$false)]
    [string] $InstallSoftware = "True",
    
    [Parameter(Mandatory=$false)]
    [string] $FirefoxUrlPath = "https://download.mozilla.org/?product=firefox-stub&os=win&lang=en-US"
)

$FirefoxFileName = "FirefoxInstaller.exe"

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
            Write-Host $errorMsg
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
                Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Failed to download url: $($url) using WebClient: $($_)"
                $ex = $_
                Start-Sleep -Seconds 5
            }
        }
        throw $ex
    }
}

$InstallSoftwareBool = $null
[bool]::TryParse($InstallSoftware, [ref]$InstallSoftwareBool);
if ($InstallSoftwareBool -NE $True) {

    Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Chrome Browser installation skipped"
    return

}

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Downloading Firefox Browser installation file"
$FirefoxInstaller = Join-Path -Path $($ENV:temp) -ChildPath $FirefoxFileName

if (-not (Test-Path $FirefoxInstaller)) {
    Download-File $FirefoxUrlPath $FirefoxInstaller
}

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Firefox Browser installation started"
Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Executing: $FirefoxInstaller"

Start-Process $FirefoxInstaller "-ms"

$i = 0
while($i -lt 100) {
    $Running = [Diagnostics.Process]::GetProcesses() | where { $_.ProcessName -eq "Firefox Installer" } | foreach { $_.ProcessName }

    if ($Running.Count -gt 0) {
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation process still running"
        Sleep -Milliseconds 5000
    } else {
        break
   }
   $i++
}

Remove-Item -Path $FirefoxInstaller -Force -ErrorAction SilentlyContinue
Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Firefox Browser installation completed"