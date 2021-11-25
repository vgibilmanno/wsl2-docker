$wslIp = (wsl sh -c "ifconfig eth0 | grep 'inet '").trim().split()| where {$_}
$regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

$ipArray = $regex.Matches($wslIp) | %{ $_.value }
$wslIp = $ipArray[0]

Write-Host "WSL Machine IP: ""$wslIp"""

#wsl sh -c "YOURSUDOPASSWORD' | sudo -S dockerd -H tcp://$wslIp"
wsl sh -c "sudo -S dockerd -H tcp://$wslIp"