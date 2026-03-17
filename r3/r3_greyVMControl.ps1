function Flag-Gen-Round3 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$uname,
        [Parameter(Mandatory=$true)]
        [string]$passwd,
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        [Parameter(Mandatory=$true)]
        [string]$TargetPrefix
    )

    process {
        $blue_vms = @(Get-VM -Name "$TargetPrefix*" -ErrorAction SilentlyContinue)
        $sec_pass = ConvertTo-SecureString $passwd -AsPlainText -Force
        $guest_cred = New-Object System.Management.Automation.PSCredential ($uname, $sec_pass)
        
        $flag_base = "FLAG{CAPSTONE_ROUND_3_TARGET"
        $idx = 0
        foreach($vm in $blue_vms) {
            $flag_gen_num = Get-Random -Minimum 1 -Maximum 4
            
            for($i = 0; $i -lt $flag_gen_num; $i++) {
                $final_flag = $flag_base + "_" + $idx + "_" + $i + "}"
                $random_dir = Get-Content $TemplateFile | Get-Random
                $final = $random_dir.Replace("USER", $uname)
                $full_path = "$final/flag.txt"

                # Use -- to handle paths starting with '-' and use single quotes for safety
                $script_block = "mkdir -p -- '$final' && echo '$final_flag' | tee -- '$full_path' > /dev/null"

                try {
                    Invoke-VMScript -VM $vm -ScriptText $script_block -GuestCredential $guest_cred -ScriptType Bash -ErrorAction Stop
                    Write-Host "Successfully planted flag in $($vm.Name) at $full_path" -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to plant flag in $($vm.Name). Error: $($_.Exception.Message)"
                }
            }
            $idx++
        }
        Write-Host "Flag generation complete" -ForegroundColor Cyan
    }
}
 
function Make-Noise-Round3 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$uname,
        [Parameter(Mandatory=$true)]
        [string]$passwd,
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        [Parameter(Mandatory=$true)]
        [string]$TargetPrefix,
        [Parameter(Mandatory=$true)]
        [string]$SourcePrefix
    )

    process {

        $sec_pass = ConvertTo-SecureString $passwd -AsPlainText -Force
        $manage_credential = New-Object System.Management.Automation.PSCredential ($uname, $sec_pass)
        $grey_vms = @(Get-VM -Name "$SourcePrefix*" -ErrorAction SilentlyContinue)
        $blue_vms = @(Get-VM -Name "$TargetPrefix*" -ErrorAction SilentlyContinue)

        while($true) {
            $source_vm = $grey_vms | Get-Random
            $target_vm = $blue_vms | Get-Random
            $target_dir = Get-Content $TemplateFile | Get-Random
            $target_ip = $target_vm.Guest.IPAddress[0]

            if($null -eq $target_ip) {
                Write-Warning "Skipping $($target_vm.Name), no IP address found"
                continue
            }
            
            $wait = Get-Random -Minimum 1 -Maximum 10
            $ssh_cmd = "sshpass -p '$passwd' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -o ConnectTimeout=5 -l $uname $target_ip 'sleep $wait;cd $target_dir; ls -lia'"
            Invoke-VMScript -VM $source_vm -ScriptText $ssh_cmd -GuestCredential $manage_credential -ScriptType Bash 
            # wait a random amount of time (1-10 seconds) before next noise event
            
            Start-Sleep -Seconds $wait
        }
    }
}