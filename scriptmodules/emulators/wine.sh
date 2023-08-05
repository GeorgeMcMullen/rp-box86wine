#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="wine"
rp_module_desc="WINEHQ - Wine Is Not an Emulator"
rp_module_help="ROM Extensions: .sh .conf\n\nUse your app's installer and use a .sh/.conf file to run it."
rp_module_licence="LGPL https://wiki.winehq.org/Licensing"
rp_module_section="exp"
rp_module_flags="rpi4"
# TODO: Currently only tested on RPI4 platform. Other RPI platforms should also work.
#       X86 platform requires some modification in the Ports scripts so that the custom Mesa path is removed.

function _latest_ver_wine() {
    echo "6.0.0"
}

function _release_type_wine() {
    echo stable
}

function _release_distribution() {
    echo "$(_os_codename)-1_i386"
}

function _os() {
    if [ $__os_ubuntu_codename ]; then
        echo "ubuntu"
    else
        echo "debian"
    fi
}

function _os_codename() {
    if [ $__os_ubuntu_codename ]; then
        echo $__os_ubuntu_codename
    else
        echo $__os_debian_codename
    fi
}

function depends_wine() {
    if compareVersions $__version lt 4.7.7; then
        md_ret_errors+=("Sorry, you need to be running RetroPie v4.7.7 or later")
        return 1
    fi

    if compareVersions $__os_debian_ver lt 8; then
        md_ret_errors+=("Sorry, you need to be running a more recent operating system version")
        return 1
    fi

    # On ARM based systems, we need to make sure Box86 is installed.
    if isPlatform "arm"; then
        if ! rp_isInstalled "box86" ; then
            md_ret_errors+=("Sorry, you need to install the Box86 scriptmodule")
            return 1
        fi
    fi
    
    # Timidity is to enable MIDI output from Wine
    getDepends timidity fluid-soundfont-gm
}

function install_bin_wine() {
    local version="$(_latest_ver_wine)"
    local releaseType="$(_release_type_wine)"
    local releaseDist="$(_release_distribution)"
    local baseURL="https://dl.winehq.org/wine-builds/$(_os)/dists/$(_os_codename)/main/binary-i386/"

    local workingDir="$__tmpdir/wine-${releaseType}-${version}/"

    mkdir -p ${workingDir}
    pushd ${workingDir}

    for i in wine-${releaseType}-i386 wine-${releaseType}
    do
      local package="${i}_${version}~$releaseDist.deb"
      local getdeb="${baseURL}${package}"

      echo "Downloading ${getdeb}"
      wget -nv -O "$package" $getdeb

      mkdir "$i"
      pushd "$i"
  
      ar x ../${i}_${version}~$releaseDist.deb
      tar xvf data.tar.xz

      cp -R opt/wine-${releaseType}/* $md_inst
      popd
    done
    
    # Return to working directory
    popd
}

function configure_wine() {
    local system="wine"
    
    #
    # Names of launch scripts
    #
    local winedesktoplauncher="Wine Desktop.sh"
    local wineexplorerlauncher="Wine Explorer.sh"
    local wineconfiglauncher="Wine Config.sh"
    local winetrickslauncher="Winetricks.sh"
    
    #
    # Create a new Wine prefix directory
    #
    sudo -u $user WINEDEBUG=-all setarch linux32 -L $md_inst/bin/wine winecfg /v winxp
    
    # needs software synth for midi; limit to ARM based systems for now
    if isPlatform "arm"; then
        local needs_synth="1"
    fi

    mkRomDir "wine"
    
    # Download and install Winetricks into the roms directory
    wget -nv -O winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    cp winetricks $romdir/wine/Winetricks.sh
    chown $user:$user "$romdir/wine/Winetricks.sh"
    chmod a+rx $romdir/wine/Winetricks.sh


    if [[ "$md_mode" == "install" ]]; then
        cat > "$romdir/wine/$winedesktoplauncher" << _EOF_
#!/bin/bash

[[ ! -n "\$(aconnect -o | grep -e TiMidity -e FluidSynth)" ]] && needs_synth="$needs_synth"

function midi_synth() {
    [[ "\$needs_synth" != "1" ]] && return

    case "\$1" in
        "start")
            echo "Starting TiMidity"
            timidity -Os -iAD &
            i=0
            until [[ -n "\$(aconnect -o | grep TiMidity)" || "\$i" -ge 10 ]]; do
                sleep 1
                ((i++))
            done
            ;;
        "stop")
            echo "Stopping TiMidity"
            killall timidity
            ;;
        *)
            ;;
    esac
}

#
# Key lookup function from: https://stackoverflow.com/a/40646371
#
function configValueForKey() {
    if [[ -z "\$1" ]] ; then
        echo ""
    else
        echo "\$2" | /usr/bin/awk -v "id=\$1" 'BEGIN { FS = "=" } \$1 == id { print \$2 ; exit }'
    fi
}

#
# Default variable values
#
WINEDEBUG=-all
LD_LIBRARY_PATH="/opt/retropie/supplementary/mesa/lib/" 
WINEPREFIX=""
cd $romdir/wine/

params=("\$@")
echo "Launching Wine with params: \${params}"
if [[ -z "\${params[0]}" || "\${params[0]}" == *"Wine Desktop.sh" ]]; then
    echo "Launching Wine Desktop"
    xset -dpms s off s noblank
    matchbox-window-manager &
    setarch linux32 -L $md_inst/bin/wine explorer /desktop=shell,\`xrandr | grep current | sed 's/.*current //; s/,.*//; s/ //g'\`
elif [[ "\${params[0]}" == *Winetricks.sh ]]; then
    echo "Launching Winetricks"
    xset -dpms s off s noblank
    matchbox-window-manager &
    PATH="\$PATH:$md_inst/bin/:$romdir/wine/" BOX86_NOBANNER=1 setarch linux32 -L $romdir/wine/Winetricks.sh
elif [[ "\${params[0]}" == *.sh ]]; then
    echo "Launching with script"
    midi_synth start
    bash "\${params[@]}"
    midi_synth stop
    exit
elif [[ "\${params[0]}" == *.conf ]]; then
    configFile=\$(cat "\${params[@]}")
    WINEPREFIX=\$(configValueForKey WINEPREFIX "\$configFile")
    DIRECTORY=\$(configValueForKey DIRECTORY "\$configFile")
    PROGRAM=\$(configValueForKey PROGRAM "\$configFile")
    OPTIONS=\$(configValueForKey OPTIONS "\$configFile")

    echo "Launching with config file"
    echo "WINEPREFIX: \$WINEPREFIX"
    echo "DIRECTORY: \$DIRECTORY"
    echo "PROGRAM: \$PROGRAM"
    echo "OPTIONS: \$OPTIONS"

    if [[ "\$DIRECTORY" ]]; then
        cd "\$DIRECTORY"
    fi

    midi_synth start
    xset -dpms s off s noblank
    matchbox-window-manager &
    setarch linux32 -L $md_inst/bin/wine "\${PROGRAM}" \$OPTIONS
    midi_synth stop
fi
_EOF_
        chmod +x "$romdir/wine/$winedesktoplauncher"
        chown $user:$user "$romdir/wine/$winedesktoplauncher"


        cat > "$romdir/wine/$wineexplorerlauncher" << _EOFEXPLORER_
#!/bin/bash
xset -dpms s off s noblank
matchbox-window-manager &
WINEDEBUG=-all LD_LIBRARY_PATH="/opt/retropie/supplementary/mesa/lib/" setarch linux32 -L $md_inst/bin/wine explorer /desktop=shell,\`xrandr | grep current | sed 's/.*current //; s/,.*//; s/ //g'\` explorer
_EOFEXPLORER_
        chmod +x "$romdir/wine/$wineexplorerlauncher"
        chown $user:$user "$romdir/wine/$wineexplorerlauncher"

        cat > "$romdir/wine/$wineconfiglauncher" << _EOFCONFIG_
#!/bin/bash
xset -dpms s off s noblank
matchbox-window-manager &
WINEDEBUG=-all LD_LIBRARY_PATH="/opt/retropie/supplementary/mesa/lib/" setarch linux32 -L $md_inst/bin/wine explorer /desktop=shell,\`xrandr | grep current | sed 's/.*current //; s/,.*//; s/ //g'\` winecfg
_EOFCONFIG_
        chmod +x "$romdir/wine/$wineconfiglauncher"
        chown $user:$user "$romdir/wine/$wineconfiglauncher"
        
    fi

    addEmulator 1 "$md_id" "wine" "XINIT:$romdir/wine/${winedesktoplauncher// /\\ } %ROM%"
    addSystem "wine" "Wine is Not an Emulator" ".sh .conf"
}
