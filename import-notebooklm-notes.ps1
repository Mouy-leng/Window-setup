<#
.SYNOPSIS
Imports a NotebookLM note export/copy into version control.

.DESCRIPTION
NotebookLM requires Google authentication, so this script avoids automated scraping.
Instead, it copies a local export (txt/md) into `notebooklm/notebooks/<id>/`,
creates a timestamped snapshot under `raw/`, and writes `metadata.json` with hashes.

.EXAMPLE
.\import-notebooklm-notes.ps1 -NotebookUrl "https://notebooklm.google.com/notebook/<id>" -InputPath "C:\Temp\NOTES.md"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$NotebookUrl,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputRoot = (Join-Path $PSScriptRoot "notebooklm/notebooks"),

    [Parameter(Mandatory = $false)]
    [switch]$Overwrite
)

function Write-Status {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][ValidateSet("OK", "INFO", "WARNING", "ERROR")][string]$Level = "INFO"
    )

    $color = "White"
    switch ($Level) {
        "OK" { $color = "Green" }
        "INFO" { $color = "Cyan" }
        "WARNING" { $color = "Yellow" }
        "ERROR" { $color = "Red" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

try {
    if (-not (Test-Path -LiteralPath $InputPath)) {
        throw "InputPath not found: $InputPath"
    }

    $notebookId = $null
    if ($NotebookUrl -match "/notebook/([0-9a-fA-F-]{36})") {
        $notebookId = $Matches[1].ToLowerInvariant()
    }

    if (-not $notebookId) {
        throw "Could not extract a notebook id from URL: $NotebookUrl"
    }

    $outputDir = Join-Path $OutputRoot $notebookId
    $rawDir = Join-Path $outputDir "raw"

    New-Item -ItemType Directory -Path $rawDir -Force | Out-Null

    $timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $inputItem = Get-Item -LiteralPath $InputPath
    $rawName = "$timestamp-$($inputItem.Name)"
    $rawPath = Join-Path $rawDir $rawName

    Copy-Item -LiteralPath $InputPath -Destination $rawPath -Force
    Write-Status "Saved raw snapshot: $rawPath" "OK"

    $canonicalNotesPath = Join-Path $outputDir "NOTES.md"
    if ((Test-Path -LiteralPath $canonicalNotesPath) -and (-not $Overwrite)) {
        Write-Status "NOTES.md already exists (use -Overwrite to replace): $canonicalNotesPath" "WARNING"
    }
    else {
        Copy-Item -LiteralPath $InputPath -Destination $canonicalNotesPath -Force
        Write-Status "Updated canonical notes: $canonicalNotesPath" "OK"
    }

    $hashAlgorithm = "SHA256"
    $rawHash = (Get-FileHash -Algorithm $hashAlgorithm -LiteralPath $rawPath).Hash
    $inputHash = (Get-FileHash -Algorithm $hashAlgorithm -LiteralPath $InputPath).Hash

    $metadataPath = Join-Path $outputDir "metadata.json"
    $metadata = [ordered]@{
        notebookId = $notebookId
        notebookUrl = $NotebookUrl
        importedAt = (Get-Date).ToString("o")
        input = @{
            path = $InputPath
            fileName = $inputItem.Name
            length = $inputItem.Length
            sha256 = $inputHash
        }
        rawSnapshot = @{
            path = $rawPath
            fileName = $rawName
            sha256 = $rawHash
        }
    }

    $metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metadataPath -Encoding UTF8
    Write-Status "Wrote metadata: $metadataPath" "OK"
}
catch {
    Write-Status $_.Exception.Message "ERROR"
    exit 1
}

