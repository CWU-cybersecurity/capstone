function New-VM {
    param (
        [int]$ram_in_gb = 4,    # size of the ram, default 4gb
        [int]$cpu_num_cores = 2,    # number of cores, default 2
        [Parameter(Mandatory=$true)]
        [int]$count,    # number of VMs

        [Parameter(Mandatory=$true)]
        [string]$gold_image_name,    # name of the template for the VM

        [Parameter(Mandatory=$true)]
        [string]$Datastore,   # location to store the vm
        [Parameter(Mandatory=$true)]
        [string]$vm_host,    # ESXi hostname
        [Parameter(Mandatory=$true)]
        [string]$network_name,   # name of the network for the vm
        [string]$gen_folder_loc, # location of the GUI folder

        [Parameter(Mandatory=$true)]
        [string]$Basename
    )

    process{
        $Diskspace = 40

        $template = Get-Template -Name $gold_image_name -ErrorAction SilentlyContinue
        if (!$template) {
            Write-Error "Template $gold_image_name not found."
            return
        }

        for($i = 1; $i -le $count; $i++) {
            $new_vm_name = "{0}-{1:D2}" -f $Basename, $i     # set up the VM's name as "Red-1, Red-2" or "Blue-1 or Blue-2"

            Write-Host "Creating $new_vm_name with $cpu_num_cores cores and $ram_in_gb GB"  # print information of the VM
            # in order to save ESXi server storage space, each VM will be thin provisioned
            New-VM  -Name $new_vm_name -Template $template -Location $gen_folder_loc -VMHost $vm_host -Datastore $Datastore -MemoryGB $ram_in_gb -NumCpu $cpu_num_cores -DiskGB $Diskspace -NetworkName $network_name -ThinProvisioned -RunAsync
            
        }
    }
}

function Remove-Lab-VM {
    param(
        [Parameter(Mandatory=$true)]
        [string]$NamePrefix # pass "Red-" or "Blue-" as prefix
    )

    process{
        $vmsFound = Get-VM -Name "$NamePrefix*" -ErrorAction SilentlyContinue

        if($vmsFound.Count -eq 0) {
            Write-Warning "No target VM found starts with $NamePrefix"
            return
        }

        Write-Host "$($vmsFound.Count) VMs found to remove"
        foreach($vm in $vmsFound) {
            if($vm.PowerState -eq "PoweredOn") {    # turning off the targeted VM if it is turned on.
                Write-Host "Stopping $($vm.Name)"
                Stop-VM -VM $vm -Confirm:$false
            }
            Write-Host "Deleting $($vm.Name) from inventory"
            Remove-VM -VM $vm -DeleteFromDisk -Confirm:$false   # removing target VM
            Start-Sleep -Seconds 1
        }
    }
}