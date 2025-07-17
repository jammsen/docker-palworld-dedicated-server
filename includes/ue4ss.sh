# shellcheck disable=SC2148,SC1091

source /includes/colors.sh

function download_and_verify_ue4ss() {
    local temp_dir=$1

    # Install UE4SS linux build as per https://github.com/UE4SS-RE/RE-UE4SS/issues/364#issuecomment-2578762122
    local ue4ss_release_zip="${temp_dir}/UE4SS.zip"
    local ue4ss_release_zip_sha256sum=69d619b17596a4244d9af48cf6d690dc9946bc15fab2fd0df540f6ab99598b21
    curl -fsSLo ${ue4ss_release_zip} https://github.com/Yangff/RE-UE4SS/releases/download/linux-experiment/UE4SS_0.0.0.zip
    if ! echo "${ue4ss_release_zip_sha256sum} ${ue4ss_release_zip}" | sha256sum --check --status; then
        ee "> SHA256 Mismatch for ${ue4ss_release_zip}"
        return 1
    fi

    # BPModLoaderMod workaround from Okaetsu/RE-UE4SS logicmod-temp-fix branch
    # https://raw.githubusercontent.com/Okaetsu/RE-UE4SS/refs/heads/logicmod-temp-fix/assets/Mods/BPModLoaderMod/Scripts/main.lua
    local bpmodloadermain_download="${temp_dir}/main.lua"
    local bpmodloadermain_sha256sum=b12077c42f1d3dc8492459c0e051e9664140105b87a817f98adc7ea0bb6bbe40
    curl -fsSLo ${bpmodloadermain_download} https://github.com/Okaetsu/RE-UE4SS/raw/f36e04e5e129423a6d3571357805a7094bb2e586/assets/Mods/BPModLoaderMod/Scripts/main.lua
    if ! echo "${bpmodloadermain_sha256sum} ${bpmodloadermain_download}" | sha256sum --check --status; then
        ee "> SHA256 Mismatch for ${bpmodloadermain_download}"
        return 1
    fi

    # MemberVariableLayout Template from UE4SS-RE/RE-UE4SS main branch
    # https://raw.githubusercontent.com/UE4SS-RE/RE-UE4SS/main/assets/MemberVarLayoutTemplates/MemberVariableLayout_5_01_Template.ini
    local membervariablelayout_download="${temp_dir}/MemberVariableLayout.ini"
    local membervariablelayout_sha256sum=8a9f1437fad5293042e9610d892ab408399e5c5edfe86bfaab24d669148a63a1
    curl -fsSLo ${membervariablelayout_download} https://github.com/UE4SS-RE/RE-UE4SS/raw/14800d383962598183ac635bcf7c70a03ca3734a/assets/MemberVarLayoutTemplates/MemberVariableLayout_5_01_Template.ini
    if ! echo "${membervariablelayout_sha256sum} ${membervariablelayout_download}" | sha256sum --check --status; then
        ee "> SHA256 Mismatch for ${membervariablelayout_download}"
        return 1
    fi
}

function extract_and_patch_ue4ss() {
    local temp_dir=$1
    local ue4ss_root=$2

    unzip -uo ${temp_dir}/UE4SS.zip -d ${ue4ss_root}
    patch -p1 -d ${ue4ss_root} </patches/UE4SS-settings.patch

    local bpmodloadermain="${ue4ss_root}/Mods/BPModLoaderMod/Scripts/main.lua"
    mv ${temp_dir}/main.lua ${bpmodloadermain}

    local membervariablelayout="${ue4ss_root}/MemberVariableLayout.ini"
    mv ${temp_dir}/MemberVariableLayout.ini ${membervariablelayout}
    # Update MemberVariableLayout as per https://github.com/UE4SS-RE/RE-UE4SS/issues/802#issuecomment-2698705933
    patch -p1 -d ${ue4ss_root} </patches/MemberVariableLayout.patch
}

function setup_ue4ss() {
    if [[ -n $ENABLE_UE4SS ]] && [[ $ENABLE_UE4SS == "true" ]]; then
        if [ ! -f "./PalServerUE4SS.sh" ]; then
            ei ">>> Installing UE4SS and setting up LD_PRELOAD"
            local ue4ss_root=${GAME_ROOT}/Pal/Binaries/Linux/ue4ss
            mkdir -p ${ue4ss_root}

            temp_dir=$(mktemp -d)
            trap 'rm -rf "${temp_dir}"' EXIT
            if download_and_verify_ue4ss ${temp_dir}; then
                extract_and_patch_ue4ss ${temp_dir} ${ue4ss_root}

                cp ./PalServer.sh ./PalServerUE4SS.sh
                sed -i 's|^\("$UE_PROJECT_ROOT/Pal/Binaries/Linux/PalServer-Linux-Shipping" Pal "$@"\)|LD_PRELOAD='"${ue4ss_root}"'/libUE4SS.so \1|' ./PalServerUE4SS.sh
            else
                ee "> Failed to install UE4SS, server will run without modding support"
                return 1
            fi
        fi
    fi
    return 0
}
