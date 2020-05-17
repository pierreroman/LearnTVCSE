#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$logfile = "C:\LearnTV\log\Installation.log"
Start-Transcript -Path $Logfile

$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"

Write-Output "---------------------------------------------------------------------"
Write-Output "Install Powershell Module"
Write-Output "---------------------------------------------------------------------"

If(-not(Get-InstalledModule PsIni -ErrorAction silentlycontinue)){
    Install-PackageProvider NuGet -Force -Verbose
    Set-PSRepository PSGallery -InstallationPolicy Trusted -Verbose
    Install-Module -Scope CurrentUser PsIni -Confirm:$False -Force -Verbose
}


if (Get-Module -Name Azure -ListAvailable) {
    Write-Warning -Message 'Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.'
} else {
    Install-Module -Name Azure -AllowClobber -Scope CurrentUser -Verbose
}

Write-Output "---------------------------------------------------------------------"
Write-Output "set variables"
Write-Output "---------------------------------------------------------------------"

$stagingFolder = "c:\learntv\" 
$InstallFile = "c:\install\"

Write-Output "---------------------------------------------------------------------"
Write-Output "Create temp folders"
Write-Output "---------------------------------------------------------------------"

if(!(Test-Path -Path $InstallFile )){
    New-Item -ItemType directory -Path $InstallFile -Verbose
}
if(!(Test-Path -Path $stagingFolder )){
    New-Item -ItemType directory -Path $stagingFolder -Verbose
}

# Set AutoLogin for sysadmin
Write-Output "---------------------------------------------------------------------"
Write-Output "Set AutoLogin for sysadmin"
Write-Output "---------------------------------------------------------------------"

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value 'P@ssw0rd1234' -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value 'sysadmin' -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value '1' -Verbose

# Download AZcopy, C++ Runtime, and Miniconda
Write-Output "---------------------------------------------------------------------"
Write-Output "download AZcopy, C++ Runtime, and Miniconda"
Write-Output "---------------------------------------------------------------------"

$OBSuri  = (curl https://aka.ms/downloadazcopy-v10-windows -MaximumRedirection 0 -ErrorAction silentlycontinue).headers.location
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest $OBSuri -OutFile $outputFile -Verbose
Expand-Archive -LiteralPath $outputFile -DestinationPath $InstallFile -force -Verbose
$result=Get-ChildItem -Path $InstallFile -Include azcopy.exe -File -Recurse -ErrorAction SilentlyContinue -Verbose
Copy-Item $result.FullName -Destination "c:\windows\system32" -Force -Verbose

$OBSuri  = 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe'
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest -Uri $OBSuri -OutFile $outputFile -Verbose

$OBSuri  = 'https://cdn-fastly.obsproject.com/downloads/vc_redist.x64.exe'
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest -Uri $OBSuri -OutFile $outputFile -Verbose


$OBSuri  = 'https://github.com/obsproject/obs-studio/releases/download/25.0.8/OBS-Studio-25.0.8-Full-x64.zip'
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest -Uri $OBSuri -OutFile $outputFile -Verbose
Expand-Archive -LiteralPath $outputFile -DestinationPath $stagingFolder\OBS -force -Verbose

# Extract OBS Config
Write-Output "---------------------------------------------------------------------"
Write-Output "Extract OBS Config"
Write-Output "---------------------------------------------------------------------"

Expand-Archive -LiteralPath "c:\learntv\obs-config.zip" -DestinationPath $stagingFolder\OBS -force -Verbose

# Edit global.ini
Write-Output "---------------------------------------------------------------------"
Write-Output "Edit global.ini"
Write-Output "---------------------------------------------------------------------"

$result=Get-ChildItem -Path $stagingFolder -Include global.ini -File -Recurse -ErrorAction SilentlyContinue -Verbose
$iniContent = Get-IniContent $result.FullName -Verbose
$iniContent["Python"]["Path64bit"] = "C:/ProgramData/Miniconda3/envs/obs"
$iniContent | Out-IniFile -FilePath $result.FullName -Force -Verbose

# Set Run key to start restart.ps1
Write-Output "---------------------------------------------------------------------"
Write-Output "Set Run key to start restart.ps1"
Write-Output "---------------------------------------------------------------------"

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name OBS -Value '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -File c:\learntv\restart.ps1' -Type ExpandString -Verbose


# Install C++ runtimes
Write-Output "---------------------------------------------------------------------"
Write-Output "Install C++ runtimes"
Write-Output "---------------------------------------------------------------------"

cmd /c "c:\install\vc_redist.x64.exe /install /quiet /norestart"

# Install Miniconda
Write-Output "---------------------------------------------------------------------"
Write-Output "Install Miniconda"
Write-Output "---------------------------------------------------------------------"

cmd /c "c:\install\Miniconda3-latest-Windows-x86_64.exe /InstallationType=AllUsers /AddToPath=1 /RegisterPython=1 /S /D=C:\ProgramData\Miniconda3"

# Reload Path
Write-Output "---------------------------------------------------------------------"
Write-Output "Reload Path"
Write-Output "---------------------------------------------------------------------"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

# Update conda & Create Conda env for OBS
Write-Output "---------------------------------------------------------------------"
Write-Output "Update conda & Create Conda env for OBS"
Write-Output "---------------------------------------------------------------------"

cmd /c "conda update -n base -c defaults conda -y"
cmd /c "conda create -n obs python=3.6 pip -y"


# Copy ZSwitcher files
Write-Output "---------------------------------------------------------------------"
Write-Output "Copy ZSwitcher files"
Write-Output "---------------------------------------------------------------------"

azcopy.exe copy "https://learnadminfiles.blob.core.windows.net/adminfiles/learntv.zip?sv=2019-02-02&st=2020-05-17T02%3A59%3A51Z&se=2021-02-01T02%3A59%3A00Z&sr=c&sp=racwdl&sig=GJUuamVcPPHcCkF8YGeEYHFOeiINHzaLotHwCUPvln4%3D" $stagingFolder
Expand-Archive -LiteralPath "c:\learntv\learntv.zip" -DestinationPath $stagingFolder -force


# start process 'run.cmd'
Write-Output "---------------------------------------------------------------------"
Write-Output "start process 'run.cmd'"
Write-Output "---------------------------------------------------------------------"

Set-Location c:\learntv
Start-Process .\run.cmd | Wait-Process


# Restart Server
Write-Output "---------------------------------------------------------------------"
Write-Output "Restart Server"
Write-Output "---------------------------------------------------------------------"
Restart-Computer