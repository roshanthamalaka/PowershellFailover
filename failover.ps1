Connect-AzAccount -Identity
Set-AzContext -Subscription "Visual Studio Enterprise Subscription – MPN"

# Configuration
$resourceGroup = "Failover-test"
$activeVM = "active"
$passiveVM = "Passive-vm"
$routeTableName = "rt_default"
$routeName = "default"
$activeVMIP = "10.0.0.4"
$passiveVMIP = "10.0.0.5"

function Check-VMStatus {
    param (
        [string]$vmName
    )
    $vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Status
    $status = $vm.Statuses | Where-Object { $_.Code -eq 'PowerState/running' }
    return $status
}

function Update-Route {
    param (
        [string]$newIp
    )
    # Get the route table and update the route
    $routeTable = Get-AzRouteTable -ResourceGroupName $resourceGroup -Name $routeTableName
    $route = $routeTable.Routes | Where-Object { $_.Name -eq $routeName }
    $route.AddressPrefix = "0.0.0.0/0"
    $route.NextHopIpAddress = $newIp

    # Set the updated route
    Set-AzRouteTable -RouteTable $routeTable
    Write-Host "Route updated to IP: $newIp"
}

function Monitor-VMs {
    $isActive = $true

    while ($true) {
        if ($isActive) {
            $activeStatus = Check-VMStatus -vmName $activeVM
            if (-not $activeStatus) {
                Write-Host "Active VM is down. Checking Passive VM..."
                
                $passiveStatus = Check-VMStatus -vmName $passiveVM
                if ($passiveStatus) {
                    Write-Host "Switching to Passive VM."
                    Update-Route -newIp $passiveVMIP
                    $isActive = $false
                } else {
                    Write-Host "Both VMs are down. Please check!"
                }
            } else {
                Write-Host "Active VM is running."
            }
        } else {
            $passiveStatus = Check-VMStatus -vmName $passiveVM
            if (-not $passiveStatus) {
                Write-Host "Passive VM is down. Checking Active VM..."
                
                $activeStatus = Check-VMStatus -vmName $activeVM
                if ($activeStatus) {
                    Write-Host "Switching back to Active VM."
                    Update-Route -newIp $activeVMIP
                    $isActive = $true
                } else {
                    Write-Host "Both VMs are down. Please check!"
                }
            } else {
                Write-Host "Passive VM is running."
            }
        }

        # Sleep for a defined interval before the next check (e.g., 30 seconds)
        Start-Sleep -Seconds 30
    }
}

# Start monitoring VMs
Monitor-VMs
