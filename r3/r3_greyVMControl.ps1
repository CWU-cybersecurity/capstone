function Flag-Gen-Round3 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$uname,
        [Parameter(Mandatory=$true)]
        [string]$passwd
    )

    process{
        
        $red_vms = Get-VM -Name "Blue*" # find all vm starts with Blue
        $sec_pass = ConvertTo-SecureString $passwd -AsPlainText -Force # convert plain text password into secure strings 
        $manage_credential = New-Object System.Management.Automation.PSCredential ($uname, $sec_pass) # generate ps credential object to log in to each vm
        $directory_list = Get-Content -Path ".\round3_init.txt"
        $flag = "FLAG{CAPSTONE_ROUND_3_TARGET}"


        foreach($vm in $red_vms) {
            $random_dir = $directory_list | Get-Random
            $full_path = "$random_dir/flag.txt" 

            try{
                $script_block = "mkdir -p $random_dir && echo '$flag' > $full_path"
                Invoke-VMScript -VM $vm -ScriptText $script_block -GuestCredential $manage_credential -ScriptType Bash
            }
            catch {
                Write-Error "Failed to plant flag in $($vm.Name), check vmware tool status"
            }
        }

        Write-Host "Flag generation complete"
    }

}

function Make-Noise-Round3 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$uname,
        [Parameter(Mandatory=$true)]
        [string]$passwd
    )

    process {

        $sec_pass = ConvertTo-SecureString $passwd -AsPlainText -Force
        $manage_credential = New-Object System.Management.Automation.PSCredential ($uname, $sec_pass)
        $grey_vms = Get-VM -Name "Grey*"
        $blue_vms = Get-VM -Name "Blue*"
        $directory_list = Get-Content -Path ".\round3_noise.txt"

        while($true) {
            $source_vm = $grey_vms | Get-Random
            $target_vm = $blue_vms | Get-Random
            $target_dir = $directory_list | Get-Random

            $target_ip = $target_vm.Guest.IPAddress[0]

            if($null -eq $target_ip) {
                Write-Warning "Skipping $($target_vm.Name), no IP address found"
                continue
            }

            $ssh_cmd = "sshpass -p $passwd ssh -o StrictHostKeyChecking=no -l $uname $target_ip 'ls $target_dir'"

            Invoke-VMScript -VM $source_vm -ScriptText $ssh_cmd -GuestCredential $manage_credential -ScriptType Bash -RunAsync

            # wait a random amount of time (1-30 seconds) before next noise event
            $wait = Get-Random -Minimum 1 -Maximum 30
            Start-Sleep -Seconds $wait
        }
    }
}