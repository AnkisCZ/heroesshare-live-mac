# heroesshare-live-mac
Heroes Share Live client (macOS)

Heroes Share Live lets players view live game information and MMR previews for their games, or for anyone that uses the Heroes Share Live client.

About Heroes Share Live
Download macOS installer
Download macOS uninstaller
Getting started

You will need to download and install the Live client on your computer.

Be sure to read our privacy policy and disclaimer
Download HeroesShareLive.pkg
Open your Downloads folder, right-click HeroesShareLive.pkg and select "Open" (don't just double click)
If warned about an "unidentified developer", click Open anyways
When prompted, enter your password to complete the install
Once the client is installed, play your first game! During the loading screen (picture of the map with both teams) your Battle Lobby file will be sent to our server. You can then find your game on the Live games index, or you can keep open a browser that will always watch for your latest game here:
https://heroesshare.net/live

Troubleshooting

Heroes Share Live is still very new and in its beta phase. There are bound to be issues that come up, and when they do, you can help by reporting them. Visit our Contact page to report issues and ask for help.
Some general steps to try:

Always make sure you have the latest version of the client installed
Check your log file! It is in the Application Support folder (see below)
Use our diagnostic tool to check for error messages and ensure the script is running (see below)
If no games are showing, try adjusting your Firewall and Antivirus settings
If your games are showing in "Preview mode" only, you probably need to update your client
If you are still experiencing issues please send a copy of the log file "watcher.log" to us along with a description of the issue. See the Contact page for ways to reach us.

To check on basic issues:

Navigate to Applications > Utilities
Launch Terminal
Type "share" and press enter
Output should be as follows:
Script status and process ID
Timestamp for last replay check
Timestamp for last upload
Last few lines of the current log file
Where is the client installed?

The Heroes Share client is installed in the Application Support folder of your root Library: /Library/Application Support/Heroes Share 
In addition to the application data Heroes Share includes a LaunchDaemon to keep the script watching for new games. Should you need to adjust this, you can find it located here: /Library/LaunchDaemons/net.heroesshare.watcher.plist 
To assist with diagnosing issues we've included a small script that you can run from Terminal (see above): /usr/local/bin/share

Privacy

Using the Heroes Share Live client includes sharing up-to-date information about you and the other people in your game. We take privacy very seriously (see our Privacy Page) and information gathered from the live client is handled with the same sensitivity and security as the rest of this site.
By using the client, as well as this site, you agree to our privacy policy. Read the policy
