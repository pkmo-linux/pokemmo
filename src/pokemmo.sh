#!/bin/bash
#
#    (c) Copyright holder 2012-2017 PokeMMO.eu <linux@pokemmo.eu>
#    - The permitted usage of the PokeMMO game client is defined by
#    a non-free license. Visit https://pokemmo.eu/tos
#
#    (c) Copyright 2017 Launch edited by Carlos Donizete Froes [a.k.a coringao]
#    This is free software, licensed under the GPL-3 license.
#
# Modified script name:    'pokemmo-launch' for 'pokemmo.sh'
# Edited version: '1.4.3'

getCanDebug() {

if [[ $(which jps) ]]; then
    PKMO_CREATE_DEBUGS=1 
else
    echo "Debug mode is unavailable. Please install the Java Development Kit and ensure jps is in your PATH"
    return 1
fi

}

getLauncherConfig() {

while read i; do
    case $i in
        installed=1) PKMO_IS_INSTALLED=1 ;;
        debugs=1) getCanDebug ;;
        swr=1) export LIBGL_ALWAYS_SOFTWARE=1 ;;
        *) continue ;;
    esac
done <"$PKMOCONFIGDIR/pokemmo"

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
        [[ $LIBGL_ALWAYS_SOFTWARE ]] && JAVA_OPTS+=(-Dorg.lwjgl.opengl.Display.allowSoftwareOpenGL=true)
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
  rm -f "$PKMOCONFIGDIR/pokemmo"
  find "$POKEMMO" -type f -name "*.TEMPORARY" -exec rm -f {} +

  cp -f /usr/share/games/pokemmo/pokemmo_bootstrapper.jar "$POKEMMO/"

  # Updater exits with 1 on successful update
  getJavaOpts "updater"
  (cd "$POKEMMO" && java ${JAVA_OPTS[*]} -cp ./pokemmo_bootstrapper.jar com.pokeemu.updater.ClientUpdater -install -quick) && exit 1 || echo "installed=1" > "$PKMOCONFIGDIR/pokemmo"
  rm -f "$POKEMMO/pokemmo_bootstrapper.jar"
}

verifyInstallation() {
if [ ! -d "$POKEMMO" ]; then
  if [[ -e "$POKEMMO" || -L "$POKEMMO" ]]; then
    # Could also be a broken symlink
    showMessage --error "(Error 3) Could not install to $POKEMMO\n\n$POKEMMO already exists,\nbut is not a directory.\n\nMove or delete this file and try again."
  else
    mkdir -p "$POKEMMO"
    showMessage --info "PokeMMO is being installed to $POKEMMO"
    downloadPokemmo
    return
  fi
fi

if [[ ! -r "$POKEMMO" || ! -w "$POKEMMO" || ! -x "$POKEMMO" || ! "$PKMO_IS_INSTALLED" || ! -f "$POKEMMO/PokeMMO.exe" || ! -d "$POKEMMO/data" || ! -d "$POKEMMO/lib" ]]; then
    showMessage --warn "(Error 1) The installation is in a corrupt state.\n\nReverifying the game files."
    # Try to fix permissions before erroring out
    (chmod u+rwx "$POKEMMO" && find "$POKEMMO" -type d -exec chmod u+rwx {} + && find "$POKEMMO" -type f -exec chmod u+rw {} +) || showMessage --error "(Error 4) Could not fix permissions of $POKEMMO.\n\nContact PokeMMO support."
    downloadPokemmo
    return
fi

[[ $PKMO_REINSTALL && $PKMO_IS_INSTALLED ]] && downloadPokemmo
}

######################
# Environment checks #
######################

[[ ! "$(command -v java)" ]] && showMessage --error "(Error 6) Java is not installed or is not executable. Exiting.."

if [[ -d "$XDG_CONFIG_HOME" ]]; then
    PKMOCONFIGDIR="$XDG_CONFIG_HOME/pokemmo"
else
    if [[ ! -e "$XDG_CONFIG_HOME" && -L "$XDG_CONFIG_HOME" ]]; then
        showMessage --error "(Error 10) The configuration directory ($XDG_CONFIG_HOME/pokemmo) is disconnected.\n\nPlease update your symlink and restart the program."
    else
        PKMOCONFIGDIR="$HOME/.config/pokemmo"
    fi
fi

if [ ! -d "$PKMOCONFIGDIR" ]; then
    if [[ -e "$PKMOCONFIGDIR" || -L "$PKMOCONFIGDIR" ]]; then
        showMessage --error "(Error 9) The configuration directory ($PKMOCONFIGDIR) already exists,\nbut is not a directory.\n\nMove or delete this file and try again."
    else
        mkdir -p "$PKMOCONFIGDIR"
    fi
fi

while getopts "vhH:-:" opt; do
    case $opt in
        -) case "$OPTARG" in
               skip-java-ram-opts) SKIPJAVARAMOPTS=1 ;;
               reverify) PKMO_REINSTALL=1 ;;
               debug) getCanDebug ;;
               swr) export LIBGL_ALWAYS_SOFTWARE=1 ;;
           esac
        ;;
        v) set -x
           PS4='Line ${LINENO}: '
        ;;
        h) printf "\
 PokeMMO Linux Launcher v1.4\n\
 https://pokemmo.eu/\n\n\
 Usage: pokemmo [option...]\n\n\
 -h                     Display this dialogue\n\
 -H <dir>               Set the PokeMMO directory (Default: $HOME/.local/share/pokemmo).
                        This option is persistent and may be modified in $PKMOCONFIGDIR/pokemmodir \n\
 -v                     Print verbose status to stdout\n
 --debug                Enable java debug logs\n\
 --swr                  Try to fallback to an available software renderer\n\
 --reverify             Reverify the game files\n\
 --skip-java-ram-opts   Use the operating system's default RAM options instead of the suggested values\n"
           exit
        ;;
        H) mkdir -p "$OPTARG" || continue
           echo "$OPTARG" > "$PKMOCONFIGDIR/pokemmodir" ;;
        *) continue ;;
    esac
done

#################
# Start PokeMMO #
#################

[[ -f "$PKMOCONFIGDIR/pokemmo" ]] && getLauncherConfig

if [[ -f "$PKMOCONFIGDIR/pokemmodir" ]]; then
    POKEMMO=$(head -n1 "$PKMOCONFIGDIR/pokemmodir")
    [[ ! -d "$POKEMMO" ]] && showMessage --error "(Error 8) The configured directory ($POKEMMO) has become unavailable. Bailing!"
else
    if [[ -d "$XDG_DATA_HOME" ]]; then
        POKEMMO="$XDG_DATA_HOME/pokemmo"
    else
        if [[ ! -e "$XDG_DATA_HOME" && -L "$XDG_DATA_HOME" ]]; then
            showMessage --error "(Error 11) The XDG_DATA_HOME directory ($XDG_DATA_HOME/pokemmo) is disconnected.\n\nPlease update your symlink and restart the program."
        else
            POKEMMO="$HOME/.local/share/pokemmo"
        fi
    fi
fi

verifyInstallation

getJavaOpts "client"

if [[ $PKMO_CREATE_DEBUGS ]]; then
    cd "$POKEMMO" && ( java ${JAVA_OPTS[*]} -cp ./lib/*:PokeMMO.exe com.pokeemu.client.Client > /dev/null ) &

    rm -f "$POKEMMO/client_jvm.log"

    v=0
    while [ -z "$(jps | grep Client)" ]; do
        if (( v < 30 )); then
            sleep 1
            echo "DEBUG: Slept for $v seconds while waiting for the client to start"
            v=$(( v + 1 ))
        else
            echo "Failed to detect main class Client during debug setup"
            exit 1
        fi
    done

    CLIENT_PID="$(jps | grep Client | tr -d '[:space:][a-zA-Z]')"

    while :; do
        sleep 3
        kill -3 "$CLIENT_PID" || break
        echo "DEBUG: Threads dumped for Client JVM. Sleeping for 3 seconds.."
    done
else
        cd "$POKEMMO" && java ${JAVA_OPTS[*]} -cp ./lib/*:PokeMMO.exe com.pokeemu.client.Client > /dev/null
fi
