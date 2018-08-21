[cmdletbinding()]
Param()


try {
    $ErrorActionPreference = "Stop"

    #
    # Install packages
    #

    # Download choclatey installer
    Write-Verbose "Install Chocolatey"
    $url = 'https://chocolatey.org/install.ps1'
    $Source = "https://chocolatey.org/install.ps1"
    $Destination = "c:\cfn\scripts\choclatey-install.ps1"
    Write-Verbose "Trying to download Choclatey from $Source to $Destination"
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
    # Run choclatey installer
    invoke-expression -Command $Destination

    echo "aws: Install 7zip"
    Write-Verbose "Install 7zip"
    choco install --limit-output -y 7zip

    Write-Verbose "Install awscli"
    choco install --limit-output -y awscli

    Write-Verbose "choco installs complete"
}
catch {
    Write-Verbose "catch: $_"
    $_ | Write-AWSQuickStartException
}




