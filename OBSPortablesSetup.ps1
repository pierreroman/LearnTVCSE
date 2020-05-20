function Write-Log 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path='C:\Logs\PowerShellLog.log', 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info", 
         
        [Parameter(Mandatory=$false)] 
        [switch]$NoClobber 
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
    } 
    Process 
    { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
            } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        else { 
            # Nothing to see here yet. 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                Write-Error $Message 
                $LevelText = 'ERROR:' 
                } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = 'WARNING:' 
                } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = 'INFO:' 
                } 
            } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End 
    { 
    } 
}


#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"

$starttime = get-date

$stagingFolder = "c:\learntv\" 
$InstallFile = "c:\install\"
$Logpathandfile = "c:\Scriptoutput.log"
$adminUser=$args[0]
$adminpassword=$args[1]
$storageAccount=$args[2]
$shareName=$args[3]
$storageKey=$args[4]

Write-Log -Message "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message "Start Config Server Creation Process. on $starttime" -Path $Logpathandfile
Write-Log -Message "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message " " -Path $Logpathandfile
Write-Log -Message " " -Path $Logpathandfile
Write-Log -Message "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message "set variables" -Path $Logpathandfile
Write-Log -Message "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message "Setting variables from ARM deployment" -Path $Logpathandfile
Write-Log -Message $adminUser -Path $Logpathandfile
Write-Log -Message $adminpassword -Path $Logpathandfile
Write-Log -Message $storageAccount -Path $Logpathandfile
Write-Log -Message $shareName -Path $Logpathandfile
Write-Log -Message $storageKey -Path $Logpathandfile

Write-Log -Message "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message "Install Powershell Module" -Path $Logpathandfile
Write-Log -Message "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Updating PowerShell modules PsIni and Nuget...." -Path $Logpathandfile

If(-not(Get-InstalledModule PsIni -ErrorAction silentlycontinue)){
    Install-PackageProvider NuGet -Force -Verbose
    Set-PSRepository PSGallery -InstallationPolicy Trusted -Verbose
    Install-Module -Scope CurrentUser PsIni -Confirm:$False -Force -Verbose
}
Write-Log -Message "Updating PowerShell modules Azure...." -Path $Logpathandfile

if (Get-Module -Name Azure -ListAvailable) {
    Write-Log -Message "Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported." -Path $Logpathandfile
    Write-Warning -Message 'Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.'
} else {
    Write-Log -Message "Installing Azure module including allow clobber to AllUsers scope.... " -Path $Logpathandfile
    Install-Module -Name Azure -AllowClobber -Scope AllUsers  -Verbose
}

Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Create temp folders" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

if(!(Test-Path -Path $InstallFile )){
    Write-Log -Message "Creating folder for Installation files..." -Path $Logpathandfile
    New-Item -ItemType directory -Path $InstallFile -Verbose
}
if(!(Test-Path -Path $stagingFolder )){
    Write-Log -Message "Creating folder for Execution files..." -Path $Logpathandfile
    New-Item -ItemType directory -Path $stagingFolder -Verbose
}

# Set AutoLogin for sysadmin
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Set AutoLogin for sysadmin" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Creating Registry update..." -Path $Logpathandfile
Write-Log -Message "Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon -Name DefaultPassword -Value $adminpassword -Verbose" -Path $Logpathandfile
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value $adminpassword -Verbose
Write-Log -Message "Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon -Name DefaultUserName -Value $adminUser -Verbose" -Path $Logpathandfile
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value $adminUser -Verbose
Write-Log -Message "Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon -Name AutoAdminLogon -Value '1' -Verbose" -Path $Logpathandfile
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value '1' -Verbose
Write-Log -Message "Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -Value 1 -Type DWord -Verbose" -Path $Logpathandfile
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name DoNotOpenServerManagerAtLogon -Value 1 -Type DWord -Verbose

# Download AZcopy, C++ Runtime, and Miniconda
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "download AZcopy, C++ Runtime, and Miniconda" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile


Write-Log -Message "Downloading AzCopy...." -Path $Logpathandfile
$OBSuri  = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest $OBSuri -OutFile $outputFile -UseBasicParsing -Verbose
Write-Log -Message "Expanding AzCopy to $stagingFolder...." -Path $Logpathandfile
Expand-Archive -LiteralPath $outputFile -DestinationPath $InstallFile -force -Verbose
$result = Get-ChildItem -Path $InstallFile -Include azcopy.exe -File -Recurse -ErrorAction SilentlyContinue -Verbose
Copy-Item $result.FullName -Destination "c:\learntv" -Force -Verbose

Write-Log -Message "Downloading MiniConda...." -Path $Logpathandfile
$OBSuri  = 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe'
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest -Uri $OBSuri -OutFile $outputFile -UseBasicParsing -Verbose

Write-Log -Message "Downloading C++ runtimes...." -Path $Logpathandfile
$OBSuri  = 'https://cdn-fastly.obsproject.com/downloads/vc_redist.x64.exe'
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest -Uri $OBSuri -OutFile $outputFile -UseBasicParsing -Verbose

Write-Log -Message "Downloading Portable OBS...." -Path $Logpathandfile
$OBSuri  = 'https://github.com/obsproject/obs-studio/releases/download/25.0.8/OBS-Studio-25.0.8-Full-x64.zip'
$outputFileName = Split-Path $OBSuri -leaf
$outputFile = $InstallFile + $outputFileName
Invoke-WebRequest -Uri $OBSuri -OutFile $outputFile -UseBasicParsing -Verbose
Write-Log -Message "Expanding Portable OBS to $stagingFolder\OBS...." -Path $Logpathandfile
Expand-Archive -LiteralPath $outputFile -DestinationPath c:\learntv\OBS -force -Verbose

# Copy ZSwitcher files
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Copy ZSwitcher files" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Downloading Learntv.zip Package...." -Path $Logpathandfile
C:\learntv\azcopy.exe copy "https://learnadminfiles.blob.core.windows.net/adminfiles/learntv.zip?sv=2019-02-02&st=2020-05-17T02%3A59%3A51Z&se=2021-02-01T02%3A59%3A00Z&sr=c&sp=racwdl&sig=GJUuamVcPPHcCkF8YGeEYHFOeiINHzaLotHwCUPvln4%3D" $stagingFolder
Write-Log -Message "Expanding Learntv.zip Package to $stagingFolder...." -Path $Logpathandfile
Expand-Archive -LiteralPath "c:\learntv\learntv.zip" -DestinationPath $stagingFolder -force


Expand-Archive -LiteralPath "c:\learntv\obs-config.zip" -DestinationPath c:\learntv\OBS -force -Verbose

Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Update download.json with admin file url" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

$a = Get-Content 'c:\learntv\download_example.json' -raw | ConvertFrom-Json
$a.url="https://learnadminfiles.blob.core.windows.net/adminfiles/learntv.zip?sv=2019-02-02&st=2020-05-17T02%3A59%3A51Z&se=2021-02-01T02%3A59%3A00Z&sr=c&sp=racwdl&sig=GJUuamVcPPHcCkF8YGeEYHFOeiINHzaLotHwCUPvln4%3D"
$a | ConvertTo-Json -depth 32| set-content 'c:\learntv\download.json'

# Edit global.ini
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Edit global.ini" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Modifying Global.ini to update Python env path...." -Path $Logpathandfile
$result=Get-ChildItem -Path $stagingFolder -Include global.ini -File -Recurse -ErrorAction SilentlyContinue -Verbose
$iniContent = Get-IniContent $result.FullName -Verbose
$iniContent["Python"]["Path64bit"] = "C:/ProgramData/Miniconda3/envs/obs"
$iniContent | Out-IniFile -FilePath $result.FullName -Force -Verbose

# Set Run key to start restart.ps1
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Set Run key to start restart.ps1" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Add Restart.ps1 command to registry run key...." -Path $Logpathandfile
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OBS" -Value "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Unrestricted -File c:\learntv\restart.ps1" -Type ExpandString -Verbose

# Install C++ runtimes
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Install C++ runtimes" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Installing C++ runtimes..." -Path $Logpathandfile
cmd /c "c:\install\vc_redist.x64.exe /install /quiet /norestart"

# Install Miniconda
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Install Miniconda" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Installing MiniConda..." -Path $Logpathandfile
cmd /c "c:\install\Miniconda3-latest-Windows-x86_64.exe /InstallationType=AllUsers /AddToPath=1 /RegisterPython=1 /S /D=C:\ProgramData\Miniconda3"

# Reload Path
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Reload Path" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Reset environment system path after MiniConda install..." -Path $Logpathandfile
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

# Update conda & Create Conda env for OBS
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "Update conda & Create Conda env for OBS" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Update MiniConda & create OBS environment..." -Path $Logpathandfile
cmd /c "conda update -n base -c defaults conda -y"
cmd /c "conda create -n obs python=3.6 pip -y"

# start process 'run.cmd'
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile
Write-Log -Message  "start process 'run.cmd'" -Path $Logpathandfile
Write-Log -Message  "---------------------------------------------------------------------" -Path $Logpathandfile

Write-Log -Message "Starting the Run.CMD command..." -Path $Logpathandfile

Set-Location $stagingFolder
Start-Process .\run.cmd | Wait-Process

Write-Log -Message "Restarting server..." -Path $Logpathandfile
Restart-Computer