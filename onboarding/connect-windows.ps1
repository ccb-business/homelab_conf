# Connects this machine to the homelab network.
# Right-click this file -> "Run with PowerShell" (may need to run as Administrator).
# Safe to run more than once.


$LoginServer = "https://vpn.home.eluusive.com"

Write-Host "== Connecting to the Eluusive Network =="
$input = Read-Host "Press Enter to Install Tailscale"

$tailscale = Get-Command tailscale -ErrorAction SilentlyContinue
if (-not $tailscale) {
    Write-Host "Tailscale not found, installing..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install -e --id Tailscale.Tailscale
        Write-Host "Install finished. If this is the first install, you may need to"
        Write-Host "close this window and re-run the script so Windows can find tailscale.exe."
        Read-Host "Press Enter to exit"
        exit
    } else {
        Write-Host "winget not found. Please install Tailscale manually from:"
        Write-Host "  https://tailscale.com/download/windows"
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "Tailscale already installed."
}

Write-Host "Flushing existing Tailscale connection."

tailscale down
tailscale logout

Write-Host "Connecting to VPN: Redirecting to Authentication URL"

$authUrl = $null

tailscale up --login-server=$LoginServer --accept-routes --reset 2>&1 |
    ForEach-Object {

        $line = $_.ToString()

        Write-Host $line

        if (-not $authUrl -and $line -match 'https?://[^\s\r\n]+') {

            $authUrl = $Matches[0]

            Write-Host ""
            Write-Host "Authentication URL found:"
            Write-Host $authUrl
            Write-Host ""
            Write-Host "Opening authentication URL..."

            Start-Process $authUrl
        }
    }

Write-Host ""
Write-Host "Tailscale authentication process finished."
Write-Host ""

Write-Host "Checking connection status:"
tailscale status

Read-Host "Press Enter to close"