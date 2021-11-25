$code= @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
Add-Type -TypeDefinition $code -Language CSharp
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

function Green {
    process { Write-Host $_ -ForegroundColor Green }
}

Write-Output "Checking if docker is running..." | Green

$StopLoop = $false
[int] $RetryCount = "0"
do {
        docker ps
        if ($LASTEXITCODE -eq 0) {
                Write-Output "Starting portainer..." | Green
                docker volume create portainer_data
                docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data cr.portainer.io/portainer/portainer-ce:2.9.3
                
                $wslIp = (wsl sh -c "ifconfig eth0 | grep 'inet '").trim().split()| where {$_}
                $regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

                $ipArray = $regex.Matches($wslIp) | %{ $_.value }
                $wslIp = $ipArray[0]
                $address = 'URL="tcp://' + $wslIp + ':2375"'

                Invoke-WebRequest -Uri https://localhost:9443/api/users/admin/init -Method POST -Body '{"Username": "admin", "Password": "adminpassword"}'
                $response = Invoke-WebRequest -Uri https://localhost:9443/api/auth -Method POST -Body '{"Username": "admin", "Password": "adminpassword"}'
                $token = ConvertFrom-Json $([String]::new($response.Content)) | Select-Object -expand "jwt"
                $headers = "Authorization: Bearer $token"

                curl.exe -k --location --request POST 'https://localhost:9443/api/endpoints' --header $headers --form 'Name="local"' --form $address --form 'EndpointCreationType="1"'
                Write-Output "Portainer installed!" | Green
                Write-Output "Open https://localhost:9443 in your browser" | Green
                Write-Output "User: admin pw: adminpassword" | Green
                Read-Host -Prompt "Press key to exit"
                exit
        } 

        if ($RetryCount -gt 5) {
                $StopLoop = $true
        } else {
                Start-Sleep -Seconds 2
                $RetryCount = $RetryCount + 1
        }
} while ($StopLoop -ne $true)


Read-Host -Prompt "Couldn't install portainer because docker is not running. Execute install-portainer.ps1 to install portainer"