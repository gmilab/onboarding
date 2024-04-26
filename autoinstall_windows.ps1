
function Confirm-ExistAndVersion {
    # Helper function to determine if a required package is installed and if it is the correct version
    param (
        [string]$command,
        [string]$version
    )

    $cmdexist = Get-Command $command -ErrorAction SilentlyContinue
    if (!$cmdexist) {
        return $false
    }

    # if no version specified, then just check if command exists
    if ((!$version) -or ($version -eq "")) {
        return $true
    }

    $command_version = Invoke-Expression "$command --version" | Out-String
    $command_version = [regex]::Replace($command_version, "[^\.0-9]", "")
    $command_version = [regex]::Replace($command_version, "\.\.", ".")

    if ([System.Version]$command_version -lt [System.Version]$version) {
        return $false
    }

    return $true
}

# PREREQUISITE: winget
Write-Output ">>> winget <<<"
if (!(Confirm-ExistAndVersion winget 1.6)) {
    Write-Warning "winget version 1.6 or newer is required to install the course software. Please update App Installer in the Microsoft Store and try running this script again."
    Read-Host -Prompt “Press ENTER to quit...”
    exit 1
} 


###################################################################################
# install windows terminal
Write-Output ">>> Windows Terminal <<<"
if (Confirm-ExistAndVersion wt) {
    Write-Host "Windows Terminal: Installed"
}
else {
    Write-Host "Windows Terminal: ... installing!"
    winget install --id Microsoft.WindowsTerminal -e -s winget --accept-source-agreements --accept-package-agreements
}

###################################################################################
# check for git
Write-Output ">>> Git <<<"
if (Confirm-ExistAndVersion git 2.39) {
    Write-Host "Git: Installed"
}
else {
    Write-Host "Git: ... installing!"
    winget install --id Git.Git --scope user -e -s winget --accept-source-agreements --accept-package-agreements
}

###################################################################################
# update path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 

# add Git Bash to Windows Terminal using JSON Fragments
$git_dir = Split-Path -parent (Split-Path -parent (Get-Command git.exe).Source)
$terminal_settings = @{guid = "{" + [guid]::NewGuid().ToString() + "}"; name = "Git Bash"; commandline = $git_dir + "\bin\bash.exe -i -l"; icon = $git_dir + "\mingw64\share\git\git-for-windows.ico"; hidden = $false; startingDirectory = "%USERPROFILE%" }
$terminal_settings = @{ profiles = @($terminal_settings) }
$terminal_settings = $terminal_settings | ConvertTo-Json
if (!(Test-Path "C:\Users\$env:UserName\AppData\Local\Microsoft\Windows Terminal\Fragments\Git")) {
    mkdir "C:\Users\$env:UserName\AppData\Local\Microsoft\Windows Terminal\Fragments\Git"
}
$terminal_settings | Out-File -FilePath "C:\Users\$env:UserName\AppData\Local\Microsoft\Windows Terminal\Fragments\Git\gitbash.json" -Encoding Utf8


###################################################################################
# check for vscode
Write-Output ">>> VSCode <<<"
if (Confirm-ExistAndVersion code) {
    Write-Host "VSCode: Installed"
}
else {
    Write-Host "VSCode: ... installing!"
    winget install --id Microsoft.VisualStudioCode -e -s winget --accept-source-agreements --accept-package-agreements
}

# update path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") 

# install remote/wsl extension    
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter


###################################################################################
# install Anaconda
$userprofile = [System.Environment]::GetFolderPath("UserProfile")
$minicondabin = $userprofile + '\miniconda3\python.exe'
$anacondabin = $userprofile + '\anaconda3\python.exe'

Write-Output ">>> Anaconda <<<"
if (Confirm-ExistAndVersion $minicondabin -or (Confirm-ExistAndVersion $anacondabin)) {
    Write-Host "Anaconda: Installed"
}
else {
    Write-Host "Anaconda: ... installing!"
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe -out miniconda.exe
    Start-Process miniconda.exe -Wait /S
    Remove-Item miniconda.exe
}

# initialize anaconda
$userprofile = [System.Environment]::GetFolderPath("UserProfile")
$conda_hook = $userprofile+'\miniconda3\shell\condabin\conda-hook.ps1'
& $conda_hook
conda activate
conda init bash

# install python packages
Write-Host "Python packages: Checking and installing required packages"
pip install numpy pandas matplotlib seaborn scikit-learn jupyter pyyaml

###################################################################################
# install RealVNC
winget install --id RealVNC.VNCViewer -e --accept-source-agreements --accept-package-agreements


###################################################################################
Write-Output @"
** INSTALLATION COMPLETE! **
"@
