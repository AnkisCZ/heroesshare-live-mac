# heroesshare-live-mac
Heroes Share Live client (macOS)

Heroes Share Live lets players view live game information and MMR previews for their games, or for anyone that uses the Heroes Share Live client.

How it works

Users need to install the Heroes Share Live client on their computer. The client watches for new games in progress and parses the replay file stubs to load game details. This happens in two stages:

BattleLobby: available at loading screen (after draft); includes players in the upcoming match, which can be used to fetch MMR
Rejoin: available about one minute into the game; includes map, gamemode, heroes, and more extensive game details
Once the files have been processed and uploaded anyone can visit the live games list to see game details, or use the latest game tracker to keep open match previews as new games load.

What goes on your computer

The client is very "thin" as most of the processing happens on our website. The code is all open source and can be reviewed on GitHub (macOS, Windows). Below is a summary of what each file does.

macOS

/Library/Application Support/Heroes Share - All service files, process details, and logs are stored here.
/Library/Application Support/Heroes Share/heroprotocol - This is Blizzard's own replay parsing library. Full code and details are available on GitHub: https://github.com/Blizzard/heroprotocol
As replay protocols change this library will need ot be updated to read local replay files and rejoin stubs.
/Library/Application Support/Heroes Share/watcher.sh - This is the actual service that watches for Battle Lobby and Rejoin files, parses relevant data, and uploads it to the Heroes Share website.
/Library/LaunchDaemons/net.heroesshare.watcher.plist - This Apple property list file defines how macOS' service manager should handle the watcher service, launching it and keeping it running in case of errors.
/usr/local/bin/share - This is a debug script for troubleshooting issues. This lets users open Terminal and type "share" to check on the service status.

Disclaimer

Blizzard's EULA	states:

Data Mining: Use any unauthorized process or software that intercepts, collects, reads, or “mines” information generated or stored by the Platform; provided, however, that Blizzard may, at its sole and absolute discretion, allow the use of certain third-party user interfaces.
Blizzard has stated	they are conditionally okay with this method of gathering in-game information, but you are ultimately responsible for what you install and use. Heroes Share is not responsible for account violations related to inappropriate use of non-Blizzard software.

Contact: By using this client during the beta test you agree to be contacted about product updates via the email associated with your account.

Privacy

Using the Heroes Share Live client includes sharing up-to-date information about you and the other people in your game. We take privacy very seriously (see our Privacy Page) and information gathered from the live client is handled with the same sensitivity and security as the rest of this site.
By using the client, as well as this site, you agree to our privacy policy. Read the policy
