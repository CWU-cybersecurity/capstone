function init {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ip_addr
    )

    process {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Connect-VIServer -Server $ip_addr -Protocol https
    }
}