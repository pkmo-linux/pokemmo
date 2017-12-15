#!/bin/bash
# (c) Copyright 2017 PokeMMO.eu <linux@pokemmo.eu>
# GPL v3 https://www.gnu.org/licenses/gpl-3.0.en.html

getLauncherConfig() {
    while read i; do
        case $i in
            installed=1) PKMO_IS_INSTALLED=1 ;;
            debugs=1) PKMO_CREATE_DEBUGS=1 ;;
            homedir=*) POKEMMO=$(echo "$i" | cut -c9-) ;;
            *) continue ;;
        esac
    done <"$PKMOLAUNCHERCONFIG"
}

getJavaOpts() {

JAVA_OPTS=()

case "$1" in
    client)
        if [[ ! $SKIPJAVARAMOPTS ]]; then
            JAVA_OPTS=(-Xms128M)

            if [ -f "$POKEMMO/PokeMMO.l4j.ini" ]; then
                JAVA_OPTS+=($(grep -oE "\-Xmx[0-9]{1,4}(M|G)" "$POKEMMO/PokeMMO.l4j.ini" || echo -- "-Xmx384M"))
            else
                JAVA_OPTS+=(-Xmx384M)
            fi
        fi

        [[ $PKMO_CREATE_DEBUGS ]] && JAVA_OPTS+=(-XX:+UnlockDiagnosticVMOptions -XX:+LogVMOutput -XX:LogFile=client_jvm.log)
        [[ $PKMO_CREATE_DEBUGS && $LIBGL_ALWAYS_SOFTWARE ]] && JAVA_OPTS+=(-Dorg.lwjgl.opengl.Display.allowSoftwareOpenGL=true)
    ;;
    updater)
        [[ ! $SKIPJAVARAMOPTS ]] && JAVA_OPTS=(-Xms64M -Xmx128M)
        [[ $PKMO_CREATE_DEBUGS ]] && JAVA_OPTS+=(-XX:+UnlockDiagnosticVMOptions -XX:+LogVMOutput -XX:LogFile=updater_jvm.log)
    ;;
esac

echo "Java options were ${JAVA_OPTS[*]}"
}

showMessage() {
  if [ "$(command -v zenity)" ]; then
    case "$1" in
      --info) zenity --info --text="$2" ; echo "INFO: $2" ;;
      --error) zenity --error --text="$2" ; echo "ERROR: $2" ; exit 1 ;;
      --warn) zenity --warning --text="$2" ; echo "WARNING: $2" ;;
    esac
  elif [ "$(command -v kdialog)" ]; then
    case "$1" in
      --info) kdialog --passivepopup "$2" ; echo "INFO: $2" ;;
      --error) kdialog --error "$2" ; echo "ERROR: $2" ; exit 1 ;;
      --warn) kdialog --sorry "$2" ; echo "WARNING: $2" ;;
    esac
  else
    case "$1" in
      --info) echo "INFO: $2" ;;
      --error) echo "ERROR: $2" ; exit 1 ;;
      --warn) echo "WARNING: $2" ;;
    esac
  fi
}

downloadPokemmo() {
  rm -f "$PKMOLAUNCHERCONFIG"
  find "$POKEMMO" -type f -name "*.TEMPORARY" -exec rm -f {} +
  cp -f /usr/share/games/pokemmo-launcher/pokemmo_bootstrapper.jar "$POKEMMO/"

  # Updater exits with 1 on successful update
  getJavaOpts "updater"
  (cd "$POKEMMO" && java ${JAVA_OPTS[*]} -cp ./pokemmo_bootstrapper.jar com.pokeemu.updater.ClientUpdater -install -quick) && exit 1 || echo "installed=1" >> "$PKMOLAUNCHERCONFIG"
  rm -f "$POKEMMO/pokemmo_bootstrapper.jar"

  if [[ $PKMO_IS_INSTALLED ]]; then
      # Rebuild the launcher config
      [[ $PKMO_CREATE_DEBUGS ]] && echo "debugs=1" >> "$PKMOLAUNCHERCONFIG"
      [[ $POKEMMO ]] && echo "homedir=$POKEMMO" >> "$PKMOLAUNCHERCONFIG"
  fi
}

verifyInstallation() {
if [ ! -d "$POKEMMO" ]; then
  if [[ -e "$POKEMMO" || -L "$POKEMMO" ]]; then
    # Could also be a broken symlink
    showMessage --error $"(Error 3) Could not install to $POKEMMO\n\n$POKEMMO already exists,\nbut is not a directory.\n\nMove or delete this file and try again."
  else
    mkdir -p "$POKEMMO"
    showMessage --info $"PokeMMO is being installed to $POKEMMO"
    downloadPokemmo
    return
  fi
fi

if [[ ! -r "$POKEMMO" || ! -w "$POKEMMO" || ! -x "$POKEMMO" || ! "$PKMO_IS_INSTALLED" || ! -f "$POKEMMO/PokeMMO.exe" || ! -d "$POKEMMO/data" || ! -d "$POKEMMO/lib" ]]; then
    showMessage --warn $"(Error 1) The installation is in a corrupt state.\n\nReverifying the game files."
    # Try to fix permissions before erroring out
    (find "$POKEMMO" -type d -exec chmod u+rwx {} + && find "$POKEMMO" -type f -exec chmod u+rw {} +) || showMessage --error $"(Error 4) Could not fix permissions of $POKEMMO.\n\nContact PokeMMO support."
    downloadPokemmo
    return
fi

[[ $PKMO_REINSTALL && $PKMO_IS_INSTALLED ]] && downloadPokemmo
}

######################
# Environment checks #
######################

if [[ ! -z "$XDG_CONFIG_HOME" ]]; then
    PKMOLAUNCHERCONFIG="$XDG_CONFIG_HOME/pokemmo-launcher"
else
    PKMOLAUNCHERCONFIG="$HOME/.config/pokemmo-launcher"
fi

export TEXTDOMAIN=pokemmo-launcher
export TEXTDOMAINDIR="/usr/share/locale/"

if [[ ! -d "$HOME" || ! -r "$HOME" || ! -w "$HOME" || ! -x "$HOME" ]]; then showMessage --error $"(Error 5) $HOME is not accessible. Exiting.." ; fi

[[ ! "$(command -v java)" ]] && showMessage --error $"(Error 6) Java is not installed or is not executable. Exiting.."

while getopts "vhH:-:" opt; do
    case $opt in
        -) case "$OPTARG" in
               skip-java-ram-opts) SKIPJAVARAMOPTS=1 ;;
               reverify) PKMO_REINSTALL=1 ;;
               debug) PKMO_CREATE_DEBUGS=1 ;;
               swr) export LIBGL_ALWAYS_SOFTWARE=1 ;;
           esac
        ;;
        v) set -x
           PS4='Line ${LINENO}: '
        ;;
        h) printf "\
 PokeMMO Linux Launcher v1.3\n\
 https://pokemmo.eu/\n\n\
 Usage: pokemmo-launcher [option...]\n\n\
 -h                     Display this dialogue\n\
 -H <dir>               Set the PokeMMO directory (Default: $HOME/.pokemmo). 
                        This option is persistent and may be modified in $PKMOLAUNCHERCONFIG \n\
 -v                     Print verbose status to stdout\n
 --debug                Enable java debug logs\n\
 --swr                  Try to fallback to an available software renderer\n\
 --reverify             Reverify the game files\n\
 --skip-java-ram-opts   Use the operating system's default RAM options instead of the suggested values\n"
           exit
        ;;
        H) POKEMMO="$OPTARG"
           echo "homedir=$OPTARG" >> "$PKMOLAUNCHERCONFIG";;
    esac
done

#################
# Start PokeMMO #
#################

getLauncherConfig

[[ -z "$POKEMMO" ]] && POKEMMO="$HOME/.pokemmo"

verifyInstallation

getJavaOpts "client"
cd "$POKEMMO" && java ${JAVA_OPTS[*]} -cp ./lib/*:PokeMMO.exe com.pokeemu.client.Client
