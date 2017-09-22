param
(
    [parameter(mandatory=$true)][string]$CSVPath = ".\Nodes.csv",
    [parameter(mandatory=$false)][Boolean]$HealthCheck = $True,
    [parameter(mandatory=$false)][switch]$TestHash
)

Function Write-TNTTestHash {
    $JSON = @{
    "hashes" = [array]"1957db7fe23e4be1740ddeb941ddda7ae0a6b782e536a9e00b5aa82db1e84547"
    } | ConvertTo-Json

    $Uri = 'http://{0}/hashes' -f $Node.IP
    return Invoke-RestMethod -Method post -uri $Uri -Body $JSON -ContentType "application/json"
}

Function Check-TNTNodeHealth {
    param
    (
       [parameter(mandatory=$true)][pscustomobject]$Node
    )

    $Uri = 'http://a.chainpoint.org/nodes/{0}' -f $Node.Address
    return (Invoke-RestMethod -Method get -Uri $Uri).recent_audits[0]
}

$Nodes = Import-CSV -Path $CSVPath -Delimiter ';'

if ($HealthCheck){
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

if ($TestHash){
    foreach ($Node in $Nodes) {
        Write-TNTTestHash -Node $Node
    }
}