param(
    [Parameter(Mandatory=$false)]
    [string] $InstallSoftware = "True",
    
    [Parameter(Mandatory=$false)]
    [string] $ChromeUrlPath = "https://dl.google.com/chrome/install/chrome_installer.exe"
)

$ChromeFileName = "ChromeInstaller.exe"

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

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Downloading Chrome Browser installation file"
$ChromeInstaller = Join-Path -Path "$($ENV:temp)" -ChildPath $ChromeFileName
if (-not (Test-Path $ChromeInstaller)) {
    Download-File $ChromeUrlPath $ChromeInstaller
}

# This binary is fetched over the network and then executed, so its authenticity has to come from
# the file itself rather than from the transport: $ChromeUrlPath is caller supplied, and HTTPS
# proves who served the file but not what it is. Refuse to run anything not validly signed by Google.
# The organisation is matched as a whole RDN rather than as a substring, so that a certificate
# carrying the text "O=Google LLC" inside some other attribute (an OU, say) cannot satisfy the check.
$ChromeExpectedSigner = '(^|,\s*)O=Google LLC(,|$)'
$ChromeSignature = Get-AuthenticodeSignature -FilePath $ChromeInstaller
if ($ChromeSignature.Status -ne "Valid" -or $ChromeSignature.SignerCertificate.Subject -notmatch $ChromeExpectedSigner) {
    Remove-Item -Path $ChromeInstaller -Force -ErrorAction SilentlyContinue
    # An unsigned file has no SignerCertificate at all, so the signer is resolved defensively -
    # otherwise reporting the failure would itself throw and bury the real reason.
    $ChromeSigner = if ($ChromeSignature.SignerCertificate) { $ChromeSignature.SignerCertificate.Subject } else { "<none>" }
    $errorMsg = "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Chrome Browser installer failed Authenticode validation (status: $($ChromeSignature.Status), signer: $($ChromeSigner)); refusing to execute it"
    Write-Host $errorMsg
    throw $errorMsg
}
Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Chrome Browser installer signature verified: $($ChromeSignature.SignerCertificate.Subject)"

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Chrome Browser installation started"
Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Executing: $ChromeInstaller"

Start-Process $ChromeInstaller "/silent /install" 

$i = 0
while($i -lt 100) {
    $Running = [Diagnostics.Process]::GetProcesses() | where { $_.ProcessName -eq "Chrome_Installer" } | foreach { $_.ProcessName }

    if ($Running.Count -gt 0) {
        Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Installation process still running"
        Sleep -Milliseconds 5000
    } else {
        break
   }
   $i++
}

Remove-Item -Path $ChromeInstaller -Force -ErrorAction SilentlyContinue
Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Chrome Browser installation completed"
