#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$CodeCommand = "code"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-CodeCommandPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command -Name $Name -CommandType Application,ExternalScript -ErrorAction Stop | Select-Object -First 1
    $path = if ($command.Source) {
        $command.Source
    } elseif ($command.Path) {
        $command.Path
    } else {
        $command.Definition
    }

    if (-not $path) {
        throw "Could not resolve '$Name' to a PowerShell command path."
    }

    [System.IO.Path]::GetFullPath($path)
}

function Get-ScoopVscodeInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandPath
    )

    $path = [System.IO.Path]::GetFullPath($CommandPath)
    $installRoot = $null
    $scoopRoot = $null

    if ($path -match "^(?<scoopRoot>.+?[\\/]scoop)[\\/]apps[\\/]vscode[\\/][^\\/]+[\\/]bin[\\/]code\.(?:cmd|exe)$") {
        $scoopRoot = $Matches.scoopRoot
        $installRoot = Split-Path -Parent (Split-Path -Parent $path)
    } elseif ($path -match "^(?<scoopRoot>.+?[\\/]scoop)[\\/]apps[\\/]vscode[\\/][^\\/]+[\\/]Code\.exe$") {
        $scoopRoot = $Matches.scoopRoot
        $installRoot = Split-Path -Parent $path
    } elseif ($path -match "^(?<scoopRoot>.+?[\\/]scoop)[\\/]shims[\\/]code\.(?:cmd|ps1|exe)$") {
        $scoopRoot = $Matches.scoopRoot
        $installRoot = Join-Path $scoopRoot "apps\vscode\current"
    }

    if (-not $installRoot) {
        return $null
    }

    $codeExe = Join-Path $installRoot "Code.exe"
    if (-not (Test-Path -LiteralPath $codeExe -PathType Leaf)) {
        return $null
    }

    [pscustomobject]@{
        ScoopRoot = $scoopRoot
        InstallRoot = $installRoot
        Executable = $codeExe
        UserDirectory = Join-Path (Join-Path $installRoot "data") "user-data\User"
    }
}

function Get-DefaultVscodeUserDirectory {
    if (-not $env:APPDATA) {
        throw "APPDATA is not set, so the standard VS Code user directory could not be determined."
    }

    Join-Path $env:APPDATA "Code\User"
}

$sourceFiles = @("settings.json", "keybindings.json")
foreach ($fileName in $sourceFiles) {
    $sourcePath = Join-Path $PSScriptRoot $fileName
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing required source file: $sourcePath"
    }
}

$codePath = Get-CodeCommandPath -Name $CodeCommand
$scoopInstall = Get-ScoopVscodeInstall -CommandPath $codePath

if ($scoopInstall) {
    $userDirectory = $scoopInstall.UserDirectory
    Write-Host "Resolved '$CodeCommand' to Scoop VS Code: $($scoopInstall.Executable)"
    Write-Host "Installing configuration to Scoop user directory: $userDirectory"
} else {
    $userDirectory = Get-DefaultVscodeUserDirectory
    Write-Warning "Resolved '$CodeCommand' to '$codePath', which is not the Scoop vscode package."
    Write-Warning "Installing configuration to the standard VS Code user directory: $userDirectory"
}

if ($PSCmdlet.ShouldProcess($userDirectory, "Create VS Code user configuration directory")) {
    New-Item -ItemType Directory -Path $userDirectory -Force | Out-Null
}

foreach ($fileName in $sourceFiles) {
    $sourcePath = Join-Path $PSScriptRoot $fileName
    $destinationPath = Join-Path $userDirectory $fileName

    if ($PSCmdlet.ShouldProcess($destinationPath, "Install $fileName")) {
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
        Write-Host "Installed $fileName"
    }
}
