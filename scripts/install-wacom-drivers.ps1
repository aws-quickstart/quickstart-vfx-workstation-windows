[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Source = 'http://cdn.wacom.com/u/productsupport/drivers/win/professional/WacomTablet_6.3.29-6.exe',

    [Parameter(Mandatory=$false)]
    [string]$Destination = 'C:\cfn\downloads\wacom-installer.exe'
)

try {
    $ErrorActionPreference = "Stop"

    $parentDir = Split-Path $Destination -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType directory -Force | Out-Null
    }

    Write-Verbose "Trying to download Wacom driver from $Source to $Destination"
    $tries = 5
    while ($tries -ge 1) {
        try {
            (New-Object System.Net.WebClient).DownloadFile($Source,$Destination)
            break
        }
        catch {
            $tries--
            Write-Verbose "Exception:"
            Write-Verbose "$_"
            if ($tries -lt 1) {
                throw $_
            }
            else {
                Write-Verbose "Failed download. Retrying again in 5 seconds"
                Start-Sleep 5
            }
        }
    }

    if ([System.IO.Path]::GetExtension($Destination) -eq '.exe') {
       Write-Verbose "Start install of Wacom drivers ..."
       # '/NoPostReboot' - to prevent reboot
       #
       Start-Process -FilePath $Destination -ArgumentList '/S', '/NoPostReboot'  -Wait

    } else {
        throw "Unable to install Wacom drivers, not .exe extension"
    }
    Write-Verbose "Install Wacom drivers complete"
}
catch {
    Write-Verbose "catch: $_"
    $_ | Write-AWSQuickStartException
}
