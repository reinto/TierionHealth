param
(
    [parameter(mandatory=$true)][string]$CSVPath = $(".\Nodes.csv"), #Put the csv file in the same directory as this script
    [parameter(mandatory=$false)][Boolean]$HealthCheck = $True,
    [parameter(mandatory=$false)][switch]$TestHash # NOTE: This function actually uses one of your credits!
)

Function Write-TNTTestHash {
    $JSON = @{
    "hashes" = [array]"1957db7fe23e4be1740ddeb941ddda7ae0a6b782e536a9e00b5aa82db1e84547" # Example hash as used on the Chainpoint API guide
    } | ConvertTo-Json # ConvertTo-Json was introduced in Powershell 3.0

    $Uri = 'http://{0}/hashes' -f $Node.IP
    return Invoke-RestMethod -Method post -uri $Uri -Body $JSON -ContentType "application/json" # Invoke-RestMethod was introduced in Powershell 3.0
}

Function Check-TNTNodeHealth {
    param
    (
       [parameter(mandatory=$true)][pscustomobject]$Node
    )

    $Uri = 'http://b.chainpoint.org/nodes/{0}' -f $Node.Address # At one point you may have queried to many times. Then try another node, a, b or c.
    return (Invoke-RestMethod -Method get -Uri $Uri).recent_audits[0]
}

$Nodes = Import-CSV -Path $CSVPath -Delimiter ';'

if ($HealthCheck){ # On by default
    foreach ($Node in $Nodes) {
        $Health = Check-TNTNodeHealth -Node $Node
        if ($Health) {
            if ($Health.public_ip_test -eq "True" -and $Health.time_test -eq "True" -and $Health.calendar_state_test -eq "True" -and $Health.minimum_credits_test -eq "True") {
                Write-Host -ForegroundColor Green "At $(([datetime]"1/1/1970 00:00:00").AddmilliSeconds($Health.time)) $($Node.Name) is completely healthy!"
            }
            else {
                Write-Host -ForegroundColor Red "At $(([datetime]"1/1/1970").AddSeconds($Health.time)) Node $($Node.Name) is not healthy!"
                $Health | select *_test
            }
        }
        else {
            Write-Host -ForegroundColor Red "Your check produced an error or node $($Node.Name) could not be found."
        }
    }
}

if ($TestHash){ # If switched, will incur credits for saving a hash to the blockchain
    foreach ($Node in $Nodes) {
        Write-TNTTestHash -Node $Node
    }
}
