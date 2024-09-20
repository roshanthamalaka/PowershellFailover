Write-Host "Check VM and Up and running"

Get-AzVM -ResourceGroupName "Failover-test" -Name "active" -Status | Select-Object -ExpandProperty PowerState
