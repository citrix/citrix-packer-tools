param(
    [Parameter(Mandatory=$true)]
    [string] $OptimizerDownloadUri,
	
    [Parameter(Mandatory=$true)]
    [string] $Template
)

$OptimizerFileName = "CtxOptimizerEngine.ps1"
$OptimizerExtractPath = "CitrixOptimizer"
$ZipperdFileName = "CitrixOptimizer.zip"
$ZippedInstaller = Join-Path -Path "$($ENV:temp)" -ChildPath $ZipperdFileName
$ZippedPath = Join-Path -Path "$($ENV:temp)" -ChildPath $OptimizerExtractPath
$Optimizer = Join-Path -Path $ZippedPath -ChildPath $OptimizerFileName
$TemplatePath = Join-Path -Path "$($ZippedPath)\Templates" -ChildPath $Template
$LogPath = Join-Path -Path $ZippedPath -ChildPath $Template

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
            throw $_
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

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Downloading Citrix Optimizer from blob storage"

if (-not (Test-Path $ZippedInstaller)) {
	Add-Type -Assembly System.IO.Compression.FileSystem
    Download-File $OptimizerDownloadUri $ZippedInstaller

    Add-Type -assembly "System.IO.Compression.FileSystem"
    [IO.Compression.Zipfile]::ExtractToDirectory($ZippedInstaller, $ZippedPath)
}

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Executing: $Optimizer, Template: $($Template)"

& $Optimizer -Source $TemplatePath -Mode execute 

Write-Host "Script: $(Get-Date -Format "dd-MM-y hh:mm:ss") - Optimization script completed"