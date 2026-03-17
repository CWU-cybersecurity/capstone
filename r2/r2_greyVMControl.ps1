function Noise-Gen-Round2 {
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
        $blue_vms = @(Get-VM -Name "$TargetPrefix*" -ErrorAction SilentlyContinue)
        $grey_vms = @(Get-VM -Name "$SourcePrefix*" -ErrorAction SilentlyContinue)
        $sec_pass = ConvertTo-SecureString $passwd -AsPlainText -Force
        $guest_cred = New-Object System.Management.Automation.PSCredential($uname, $sec_pass)

        while($true) {
            # 1. Select Random Attacker and Target
            $attacker = $grey_vms | Get-Random
            $target   = $blue_vms | Get-Random
            $targetIP = $target.Guest.IPAddress[0]
            
            if (!$targetIP) { continue }

            # 2. Generate Random Port Data
            $pStart = Get-Random -Minimum 21 -Maximum 100
            $pEnd   = Get-Random -Minimum 101 -Maximum 1024
            $pList  = "$(Get-Random -Minimum 20 -Maximum 25),$(Get-Random -Minimum 80 -Maximum 443),$(Get-Random -Minimum 3000 -Maximum 8080)"
            
            # Extract Network (e.g., 192.168.10.5 -> 192.168.10.0)
            $network = $targetIP.Substring(0, $targetIP.LastIndexOf('.')) + ".0"

            # 3. Load a random command template
            $cmd = Get-Content $TemplateFile | Get-Random

            # 4. Perform the "Multi-Swap"
            $finalCmd = $cmd.Replace("TARGET_IP", $targetIP).Replace("TARGET_NETWORK", $network).Replace("TARGET_PORT_START", $pStart).Replace("TARGET_PORT_END", $pEnd).Replace("TARGET_PORT_1", (Get-Random -Minimum 21 -Maximum 25)).Replace("TARGET_PORT_2", (Get-Random -Minimum 80 -Maximum 443)).Replace("TARGET_PORT_3", (Get-Random -Minimum 3000 -Maximum 9000)).Replace("TARGET_PORT", (Get-Random -Minimum 20 -Maximum 1024))

            Write-Host "[$($attacker.Name)] -> $finalCmd" -ForegroundColor Gray

            try {
                Invoke-VMScript -VM $attacker -ScriptText $finalCmd -GuestCredential $guest_cred -ScriptType Bash
            }
            catch {
                Write-Warning "Failed to execute command on $($attacker.Name)"
            }

            Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 15)
        }
    }
}