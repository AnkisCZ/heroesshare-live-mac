#!/bin/sh
#
# Build 1.2
# Copyright Heroes Share
# https://heroesshare.net
#

appdir="/Library/Application Support/Heroes Share"

# make sure application directory exists
if [ ! -d "$appdir" ]; then
	echo "[`date`] Application directory missing: '$appdir'. Quitting."
	exit 1
fi

# get local version
installed=`cat "$appdir/version.txt"`

# get latest version from website
latest=`/usr/bin/curl --silent https://heroesshare.net/clients/check/mac`

if [ -z "$latest" -o "$latest" = "error" ]; then
	echo "[`date`] Error loading version from website."
	exit 2
fi

# compare versions
if [ "$latest" = "$installed" ]; then
	exit 0
fi
echo "[`date`] Latest version $latest differs from current $installed"

# download latest installer
tmpfile=`mktemp`
/usr/bin/curl --output "$tmpfile" https://heroesshare.net/clients/update/mac
echo "[`date`] Download complete: $tmpfile"

# get correct hash from website
hash=`/usr/bin/curl --silent https://heroesshare.net/clients/hash/mac`

# test it against download
test=`/sbin/md5 -q "$tmpfile"`
if [ "$test" != "$hash" ]; then
	echo "[`date`] Hash on downloaded file is incorrect:"
	echo "$test versus $hash"
	
	rm -f "$tmpfile"
	exit 3
fi

# rename it and install - installer handles launchd stops/starts
mv "$tmpfile" "$tmpfile.pkg"
/usr/sbin/installer -target / -package "$tmpfile.pkg"
result=$?
rm -f "$tmpfile.pkg"

# verify installer succeeded
if [ $result -ne 0 ]; then
	echo "[`date`] Installation failed. Try a manual update:"
	echo "https://heroesshare.net/clients/install/mac"
	exit 4
fi

# confirm new version
installed=`cat "$appdir/version.txt"`
if [ "$latest" != "$installed" ]; then
	echo "[`date`] Installation complete but version mismatch. Try a manual update:"
	echo "https://heroesshare.net/clients/install/mac"
	exit 5
fi

echo "[`date`] Installation complete! Updated to $latest"
exit 0

