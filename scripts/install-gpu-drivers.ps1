[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [string]$GpuDriverBucket = 'ec2-windows-nvidia-drivers',
    [Parameter(Mandatory=$false)]
    [string]$DownloadDir = 'c:\Users\Administrator\Downloads',
    [Parameter(Mandatory=$false)]
    [string]$UnzipDir = 'c:\Users\Administrator\Downloads\gpu-drivers'
)


# AWS instructions for GPU drivers
#
# GpuDriverBucket is set from location specified in docs below
#
# http://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/accelerated-computing-instances.html

# http://www.nvidia.com/Download/index.aspx?lang=en-us
#   Dropdown selections
#       G2: grid->grid series->K520
#       G2: tesla->M60


#
# $Bucket = name of S3 bucket holding driver files for multiple OSes and the License Agreement to be signed
# $OsMatchStr = 'win10' for windows 10 ... this is a substring that will be matched in the s3 object key
#               (equal to filenames for the gpu driver
#
# returns the full pathname of the driver filename
#
function downloadGpuDrivers($Bucket, $OsMatchStr, $DownloadDir) {
    Write-Verbose "Download from $Bucket and match on $OsMatchStr"
    $Destination = "C:\Users\Administrator\Downloads"
    $DriverFilename = '<not found>'
    $Objects = Get-S3Object -BucketName $Bucket
    foreach ($Object in $Objects) {
        Write-Verbose "Object: '$Object.key'"
        $FileName = $Object.Key
        # we want the gpu driver for the required OS as well as the license file
        # from the S3 bucket
        if ($FileName -ne '' -and $Object.Size -ne 0 -and
           ($FileName -match $OsMatchStr -or $FileName -match 'LicenseAgreement')) {
		    $FullFilePath = Join-Path $DownloadDir $FileName
	        $Result = Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $FullFilePath

             if ($FileName -match $OsMatchStr) {
                # filename denotes the os we are looking for
                $DriverFilename = $FullFilePath
            }
        }
    }

    return $DriverFilename
}


# $Filename = full path to gpu drivers
# $Destination = directory where we will unzip the drivers
#
# gpu drivers will be unzipped into
function unzipGpuDrivers($Filename, $Destination) {
    Write-Verbose "Unzip GPU Drivers"
    $parentDir = Split-Path $Destination -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType directory -Force | Out-Null
        Write-Verbose "creating new directory"
    }

    Write-Verbose "Extract GPU drivers ... from $Filename"
    # first extract the setup.exe so we can pass the -noreboot = noreboot and -s = silent cmd line params
    # self extracting installer only excepts /s
    #
    # x = preserve dir structure
    # -aoa = overwrite
    # -o is output dir
    $Result = Start-Process -Verbose -FilePath "c:\Program Files\7-Zip\7z.exe" -ArgumentList 'x',$Filename,'-aoa',"-o$($Destination)" -NoNewWindow -Wait
}


function InstallGpuDrivers($SetupDir) {
    Write-Verbose "Install GPU drivers ... run setup.exe"
    # -noreboot = no reboot
    # -s = silent install, don't pop up a window for input
    # Start-Process -FilePath Join-Path $SetupDir "setup.exe" -ArgumentList '-s -noreboot' -Wait

    # using a ProcessStartInfo object is masking the exit 1
    #
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = Join-Path $SetupDir "setup.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = '-s -noreboot'
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start()
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    Write-Verbose "gpu driver install process stdout: $stdout"
    Write-Verbose "gpu driver install stderr: $stderr"
    Write-Verbose "gpu driver install exit code:"
    $p.ExitCode | Write-Verbose

    Write-Verbose "complete: install GPU drivers"
}


#
# Optimize GPU settings
# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/optimize_gpu.html
function OptimizeGpu() {
    # this is for G3 only
    # need logic to do P2 & P3
    cd "C:\Program Files\NVIDIA Corporation\NVSMI"
    .\nvidia-smi --auto-boost-default=0
    .\nvidia-smi -ac "2505,1177"
}


#
# main
#
# http://nvidia.custhelp.com/app/answers/detail/a_id/2985/~/how-can-i-perform-a-silent-install-of-the-gpu-driver%3F
# https://devtalk.nvidia.com/default/topic/830929/quadro-348-07-driver-silent-installation-unable-to-generate-setup-iss-response-file/
#

try {
    $ErrorActionPreference = "Stop"

    $GpuDriverFilename = downloadGpuDrivers -Bucket $GpuDriverBucket -OsMatchStr 'win10' -DownloadDir $DownloadDir
    Write-Verbose "filename = '$GpuDriverFilename'"
    unzipGpuDrivers -Filename $GpuDriverFilename -Destination 'c:\Users\Administrator\Downloads\gpu-drivers'
    InstallGpuDrivers -SetupDir $UnzipDir
    OptimizeGPU
}
catch {
    Write-Verbose "catch: $_"
   # $_ | Write-AWSQuickStartException
}



