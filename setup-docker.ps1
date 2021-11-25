param(
   [Parameter(Mandatory=$false)]
   [switch]$shouldAssumeToBeElevated,

   [Parameter(Mandatory=$false)]
   [String]$workingDirOverride
)

if(-not($PSBoundParameters.ContainsKey('workingDirOverride')))
{
   $workingDirOverride = (Get-Location).Path
}

function Test-Admin {
   $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
   $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
   if ($shouldAssumeToBeElevated) {
       Write-Output "Starting powershell script with admin rights did not work. Setup cancelled"
   } else {
       Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -shouldAssumeToBeElevated -workingDirOverride "{1}"' -f ($myinvocation.MyCommand.Definition, "$workingDirOverride"))
   }
   exit
}

function Green {
    process { Write-Host $_ -ForegroundColor Green }
}

function Yellow {
    process { Write-Host $_ -ForegroundColor Yellow }
}

Set-Location "$workingDirOverride"

Write-Output "Installing docker in default WSL distro..." | Green
bash setup-docker-bash.sh
Write-Output "done" | Green

Write-Output "Get WSL IP-Address and set proxy to WSL docker for host..." | Green
$wslIp = (wsl sh -c "ifconfig eth0 | grep 'inet '").trim().split()| where {$_}
$regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

$ipArray = $regex.Matches($wslIp) | %{ $_.value }
$wslIp = $ipArray[0]

netsh interface portproxy add v4tov4 listenport=2375 connectport=2375 connectaddress=$wslIp

$env:DOCKER_HOST = 'tcp://localhost:2375'
Write-Output "done" | Green

$binPath = "C:\bin"
if(![System.IO.Directory]::Exists($binPath)) {
    New-Item -Path "c:\" -Name "bin" -ItemType "directory"
}

$dockerExePath = "$binPath\docker.exe"
if(![System.IO.File]::Exists($dockerExePath)) {
    $dockerExeReleasePath = "https://github.com/StefanScherer/docker-cli-builder/releases"
    Write-Output "Downloading latest docker.exe from $dockerExeReleasePath into $dockerExePath ..." | Green
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("$dockerExeReleasePath/latest/download/docker.exe", $dockerExePath)
    Write-Output "download finished" | Green
}

$dockerComposeExePath = "$binPath\docker-compose.exe"
if(![System.IO.File]::Exists($dockerComposeExePath)) {
    $dockerComposeExeReleasePath = "https://github.com/docker/compose/releases"
    Write-Output "Downloading latest docker-compose.exe from $dockerComposeExeReleasePath into $dockerComposeExePath ..." | Green
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile("$dockerComposeExeReleasePath/latest/download/docker-compose-windows-x86_64.exe", $dockerComposeExePath)
    Write-Output "download finished" | Green
}

$pathEnv = [System.Environment]::GetEnvironmentVariable('Path', 'Machine').TrimEnd(';')
$pathEnvContainsBinPath = $pathEnv -split ';' -contains $binPath
if (-not $pathEnvContainsBinPath)
{
    $pathEnv += ";$binPath"
    [Environment]::SetEnvironmentVariable("Path", $pathEnv, "Machine")
}

$nl = [Environment]::NewLine

Write-Output $nl
Write-Output "Docker has been installed successfully. You can now execute docker commands with 'docker' or 'docker-compose'" | Green
Write-Output $nl

Write-Output $nl
Write-Output "Suggested UI tools:" | Yellow
Write-Output "lazydocker: https://github.com/jesseduffield/lazydocker" | Yellow
Write-Output "VSC: https://code.visualstudio.com/docs/containers/overview" | Yellow
Write-Output "dockly: https://github.com/lirantal/dockly" | Yellow
Write-Output $nl

$confirmStartDocker = Read-Host "Start docker now? (y/n)"
if ($confirmStartDocker -eq 'y') {
    $confirmInstallPortainer = Read-Host "Install portainer? (y/n)"
    start powershell .\start-docker.ps1
    
    if ($confirmInstallPortainer -eq 'y') {
        .\install-portainer.ps1
    }
} else {
    Read-Host -Prompt "Execute startup-docker.ps1 to start docker"
}