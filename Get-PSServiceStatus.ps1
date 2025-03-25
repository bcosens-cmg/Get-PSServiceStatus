function Get-PSServiceStatus {
param (
    [string[]]$ServiceName,
    [string]$Path,
    [string]$FromAddress,
    [string]$ToAddress,
    [string]$SmtpServer
)
    foreach ($Service in $ServiceName)
    {
    $NewPath = Join-Path -Path $Path -ChildPath $Service
        #Get previous status
        if (Test-Path -Path $NewPath)
        {
            $PreviousStatus = 'Not Running'
        }
        else 
        {
            $PreviousStatus = 'Running'    
        }

        #Get current status
        $CurrentStatus = Get-Service -Name $Service | Where-Object {$_.Status -eq 'Running'}
        if ($CurrentStatus)
        {
            $CurrentStatus = 'Running'
        }
        else 
        {
            $CurrentStatus = 'Not Running'
			Start-Service -Name $Service    
        }
        
        #Current status running and previous up
        if ($PreviousStatus -eq 'Running' -and $CurrentStatus -eq 'Running')
        {
            Write-Output "$Service still running"
            Continue
        }

        #Current status running and previous down
        if ($PreviousStatus -eq 'Not Running' -and $CurrentStatus -eq 'Running')
        {
            Write-Warning -Message "$Service now running"
            Remove-Item -Path $NewPath -Force | Out-Null
            Send-MailMessage -Body ' ' -From $FromAddress -SmtpServer $SmtpServer -Subject "$Service is now running" -To $ToAddress 
            Continue
        }

        #Current status down and previous down 
        if ($PreviousStatus -eq 'Not Running' -and $CurrentStatus -eq 'Not Running')
        {
            Write-Warning -Message "$Service still not running"
            New-Item -Path $NewPath -ItemType File -Force | Out-Null
            Continue
        }

        #Current status down and previous up 
        if ($PreviousStatus -eq 'Running' -and $CurrentStatus -eq 'Not Running')
        {
            Write-Warning -Message "$Service is not running"
            New-Item -Path $NewPath -ItemType File -Force | Out-Null
            Send-MailMessage -Body ' ' -From $FromAddress -SmtpServer $SmtpServer -Subject "$Service is not running, attempting restart" -To $ToAddress 
            Continue
        }
    }
}
