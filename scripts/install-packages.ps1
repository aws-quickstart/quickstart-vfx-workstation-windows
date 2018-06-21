[cmdletbinding()]
Param()


try {
    $ErrorActionPreference = "Stop"

    #
    # Install packages
    #
    Write-Verbose "Install Chocolatey"
    $url = 'https://chocolatey.org/install.ps1'
    iex ((new-object net.webclient).DownloadString($url))

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




