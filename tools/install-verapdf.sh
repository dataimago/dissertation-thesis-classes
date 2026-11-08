#!/bin/sh
# Installs veraPDF Greenfield (pinned release, SHA-256 checked) into $HOME/verapdf for T14.
# Needs a Java runtime (GitHub's ubuntu runners ship one). MIT licensed (this script).
set -eu
VERSION=1.30.1
SHA256=9f03fc5da454348329f4054256351aa6c6a91683329978e8294f21fe8a5d7abc
URL="https://software.verapdf.org/rel/1.30/verapdf-greenfield-$VERSION-installer.zip"
DEST=${VERAPDF_HOME:-$HOME/verapdf}
TMP=$(mktemp -d)
cd "$TMP"
curl -fsSL -o installer.zip "$URL"
echo "$SHA256  installer.zip" | shasum -a 256 -c -
unzip -q installer.zip
cat > auto-install.xml <<EOX
<AutomatedInstallation langpack="eng">
  <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/>
  <com.izforge.izpack.panels.target.TargetPanel id="install_dir">
    <installpath>$DEST</installpath>
  </com.izforge.izpack.panels.target.TargetPanel>
  <com.izforge.izpack.panels.packs.PacksPanel id="sdk_pack_select">
    <pack index="0" name="veraPDF GUI" selected="false"/>
    <pack index="1" name="veraPDF Mac and *nix Scripts" selected="true"/>
    <pack index="2" name="veraPDF Validation model" selected="false"/>
    <pack index="3" name="veraPDF Documentation" selected="false"/>
    <pack index="4" name="veraPDF Sample Plugins" selected="false"/>
  </com.izforge.izpack.panels.packs.PacksPanel>
  <com.izforge.izpack.panels.install.InstallPanel id="install"/>
  <com.izforge.izpack.panels.finish.FinishPanel id="finish"/>
</AutomatedInstallation>
EOX
java -jar "verapdf-greenfield-$VERSION/verapdf-izpack-installer-$VERSION.jar" auto-install.xml
"$DEST/verapdf" --version | head -1
