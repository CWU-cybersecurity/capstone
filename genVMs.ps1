function Gen-VM {
    param (
        [int]$ram_in_gb = 4,
        [int]$cpu_num_cores = 2,
        [Parameter(Mandatory=$true)]
        [int]$count,
        [Parameter(Mandatory=$true)]
        [string]$gold_image_name,
        [Parameter(Mandatory=$true)]
        [string]$Datastore,
        [Parameter(Mandatory=$true)]
        [string]$vm_host,
        [Parameter(Mandatory=$true)]
        [string]$network_name,
        [Parameter(Mandatory=$true)]
        [string]$gen_folder_loc,
        [Parameter(Mandatory=$true)]
        [string]$Basename
    )

    process {
        $DiskspaceGB = 40
        
        # Resolve all strings to actual PowerCLI Objects first
        $template = Get-Template -Name $gold_image_name -ErrorAction SilentlyContinue
        $folder   = Get-Folder -Name $gen_folder_loc -ErrorAction SilentlyContinue
        $target_ds = Get-Datastore -Name $Datastore -ErrorAction SilentlyContinue
        $target_host = Get-VMHost -Name $vm_host -ErrorAction SilentlyContinue
        
        # Correct way to get the Resource Pool from a Host
        $pool = $target_host | Get-ResourcePool -Name "Resources" -ErrorAction SilentlyContinue
        # Fallback: if "Resources" named pool isn't found, just get the first one assigned to that host
        if (!$pool) { $pool = Get-ResourcePool -Location $target_host | Select-Object -First 1 }

        # Safety Checks
        if (!$template) { Write-Error "Template $gold_image_name not found."; return }
        if (!$folder) { Write-Error "Folder '$gen_folder_loc' not found."; return }
        if (!$target_host) { Write-Error "Host '$vm_host' not found."; return }
        if (!$pool) { Write-Error "Could not resolve Resource Pool for $vm_host."; return }
        if (!$target_ds) { Write-Error "Datastore '$Datastore' not found."; return }

        for($i = 1; $i -le $count; $i++) {
            $new_vm_name = "{0}-{1:D2}" -f $Basename, $i
            Write-Host "--- Deploying $new_vm_name ---" -ForegroundColor Cyan

            try {
                # Use the ResourcePool and Datastore OBJECTS, not strings
                $vm = New-VM -Name $new_vm_name `
                            -Template $template `
                            -Location $folder `
                            -ResourcePool $pool `
                            -Datastore $target_ds `
                            -Confirm:$false

                Write-Host "Setting CPU to $cpu_num_cores and RAM to ${ram_in_gb}GB..."
                Set-VM -VM $vm -MemoryGB $ram_in_gb -NumCpu $cpu_num_cores -Confirm:$false

                Write-Host "Expanding Hard Disk to ${DiskspaceGB}GB..."
                Get-HardDisk -VM $vm | Select-Object -First 1 | Set-HardDisk -CapacityGB $DiskspaceGB -Confirm:$false

                Write-Host "Connecting to network: $network_name"
                Get-NetworkAdapter -VM $vm | Set-NetworkAdapter -NetworkName $network_name -Confirm:$false

                Write-Host "Successfully configured $new_vm_name" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to create or configure $new_vm_name. Error: $_"
            }
        }
    }
}

function Remove-Lab-VM {
    param(
        [Parameter(Mandatory=$true)]
        [string]$NamePrefix
    )

    process {
        # Force the result into an array so .Count always works
        $vmsFound = @(Get-VM -Name "$NamePrefix*" -ErrorAction SilentlyContinue)

        if($vmsFound.Count -eq 0) {
            Write-Warning "No target VM found starting with $NamePrefix"
            return
        }

        Write-Host "$($vmsFound.Count) VMs found to remove" -ForegroundColor Yellow
        
        foreach($vm in $vmsFound) {
            if($vm.PowerState -eq "PoweredOn") {
                Write-Host "Stopping $($vm.Name)..." -ForegroundColor Cyan
                # -Kill forces a power off (hard pull of the plug) 
                # Use this if you don't care about a graceful OS shutdown
                Stop-VM -VM $vm -Kill -Confirm:$false 
            }
            
            Write-Host "Deleting $($vm.Name) from disk..." -ForegroundColor Red
            Remove-VM -VM $vm -DeletePermanently -Confirm:$false
        }
        Write-Host "Cleanup complete." -ForegroundColor Green
    }
}
