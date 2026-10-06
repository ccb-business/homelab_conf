# Connecting to the Network

## Desktop (Windows, Mac, or Linux)

1. Download this whole folder.
2. Run the script for your system:
   - **Windows:** double-click `connect-windows.ps1` → choose "Run with PowerShell" (if Windows blocks it, right-click → Run as Administrator)
   - **Mac/Linux:** open a terminal in this folder and run:
     ```
     chmod +x connect-mac-linux.sh
     ./connect-mac-linux.sh
     ```
3. A browser window will open. Log in with the username and temporary password you were given, then set your own password when prompted.
4. That's it, the script already handles the subnet routing setting for you.

Once connected, Minecraft should be reachable at:
```
10.10.10.10
```

## Manual Install

1. Install the Tailscale app.
2. Do nothing with the actual client - it does not allow connections to custom-hosted networks.
3. Open a command prompt and run: tailscale down; tailscale logout; `tailscale up --login-server=vpn.home.eluusive.com --accept-routes`
4. This will spit out an authentication url titled: `https://vpn.home.eluusive.com`
6. Log in with your username and temporary password when prompted.
7. Once successfully logged in, you should get a redirect back and the command will terminate.
8. You can check the status now by opening the Tailscale app (should be in your tray or your start menu)
9. In Settings, make sure **"Accept routes"** (or similarly named) is turned **on**.

    
## Troubleshooting

- **Script says Tailscale isn't found after installing:** close and reopen the terminal/PowerShell window, then run the script again.
- **Browser login never loads:** double check your internet connection, and that you typed the server address correctly if entering it manually.
- **Connected, but can't reach the game server:** on mobile, check the "Accept routes" setting from step 5 above. The login script already sets this, so try disconnecting and reconnecting (`tailscale down` then re-run the script).
- If you're still stuck, just PM me.
