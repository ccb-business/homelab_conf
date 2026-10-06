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

## Mobile (iOS / Android)

Mobile can't run these scripts, so it's a couple of manual steps:

1. Install the Tailscale app from your app store.
2. Open it → Settings → look for **"Use custom coordination server"** or **"Alternate server"**.
3. Enter: `https://vpn.home.yourdomain.com`
4. Log in with your username and temporary password when prompted.
5. In Settings, make sure **"Accept routes"** (or similarly named) is turned **on**. This is the one step mobile doesn't do automatically.

## Something not working?

- **Script says Tailscale isn't found after installing:** close and reopen the terminal/PowerShell window, then run the script again.
- **Browser login never loads:** double check your internet connection, and that you typed the server address correctly if entering it manually.
- **Connected, but can't reach the game server:** on mobile, check the "Accept routes" setting from step 5 above. On desktop, the script already sets this, so try disconnecting and reconnecting (`tailscale down` then re-run the script).
- **Still stuck:** send a screenshot of what you're seeing.
