#!/bin/bash
# shellcheck disable=SC2148,SC1091
# REST API CLI — user-facing wrapper for manual docker exec usage
# Usage: restapicli <command> [args...]

source /includes/colors.sh
source /includes/restapi.sh

VERSION="1.0.0"

print_usage() {
    ei "Usage: restapicli <command> [args]"
    e ""
    e "Commands:"
    e "  info                           Show server info (version, name, description)"
    e "  players                        List connected players (raw JSON)"
    e "  metrics                        Show server metrics (fps, player count, uptime...)"
    e "  save                           Save the world"
    e "  announce <message>             Broadcast a message to all players"
    e "  kick <userid> [msg]            Kick a player by Steam userid (steam_XXXXXXX)"
    e "  ban <userid> [msg]             Ban a player by Steam userid (steam_XXXXXXX)"
    e "  unban <userid>                 Unban a player by Steam userid (steam_XXXXXXX)"
    e "  banlist                        Show the local ban list (reads from disk, no REST API needed)"
    e "  shutdown <seconds> [msg]       Shutdown the server after <seconds> with optional message"
    e "  --version                      Print version and exit"
    e "  help                           Show this help"
}

run_restapicli() {
    local command=${1:-help}
    shift || true

    # Handle version before any env var checks — no server needed
    if [[ "$command" == "--version" ]]; then
        ei "restapicli ${VERSION}"
        exit 0
    fi

    if [[ "$command" == "help" ]]; then
        print_usage
        exit 0
    fi

    if [[ "$command" == "banlist" ]]; then
        local banfile="${GAME_SAVE_PATH}/SaveGames/banlist.txt"
        if [[ ! -f "$banfile" ]]; then
            ew "> Ban list file not found at '${banfile}'"
            exit 1
        fi
        local count
        count=$(wc -l < "$banfile")
        if [[ "$count" -eq 1 ]]; then
            ei "> Ban list (${count} entry):"
        else
            ei "> Ban list (${count} entries):"
        fi
        cat "$banfile"
        exit 0
    fi

    if [[ -z ${RESTAPI_ENABLED+x} ]] || [[ "${RESTAPI_ENABLED,,}" != "true" ]]; then
        ew ">>> REST API is not enabled. Aborting REST API command ..."
        exit 1
    fi

    case "$command" in
        info)
            local output
            output=$(restapi_get "info") || exit 1
            ei_nn "> Server info: "; e "${output}"
            ;;
        players)
            local output
            output=$(restapi_get "players") || exit 1
            ei_nn "> Players: "; e "${output}"
            ;;
        metrics)
            local output
            output=$(restapi_get "metrics") || exit 1
            ei_nn "> Metrics: "; e "${output}"
            ;;
        save)
            ei "> Saving world..."
            restapi_post "save" || exit 1
            es "> World saved."
            ;;
        announce)
            if [[ $# -lt 1 ]]; then
                ee ">>> Missing message argument for 'announce'"
                print_usage
                exit 1
            fi
            local json_body
            json_body=$(jq -n --arg msg "$*" '{"message": $msg}')
            restapi_post "announce" "$json_body" || exit 1
            es "> Announced: $*"
            ;;
        kick)
            if [[ $# -lt 1 ]]; then
                ee ">>> Missing userid argument for 'kick'"
                print_usage
                exit 1
            fi
            local userid=$1; shift || true
            local message="$*"
            local body
            if [[ -n "$message" ]]; then
                body=$(jq -n --arg uid "$userid" --arg msg "$message" '{"userid": $uid, "message": $msg}')
            else
                body=$(jq -n --arg uid "$userid" '{"userid": $uid}')
            fi
            restapi_post "kick" "$body" || exit 1
            es "> Kicked: ${userid}"
            ;;
        ban)
            if [[ $# -lt 1 ]]; then
                ee ">>> Missing userid argument for 'ban'"
                print_usage
                exit 1
            fi
            local userid=$1; shift || true
            local message="$*"
            local body
            if [[ -n "$message" ]]; then
                body=$(jq -n --arg uid "$userid" --arg msg "$message" '{"userid": $uid, "message": $msg}')
            else
                body=$(jq -n --arg uid "$userid" '{"userid": $uid}')
            fi
            restapi_post "ban" "$body" || exit 1
            es "> Banned: ${userid}"
            ;;
        unban)
            if [[ $# -lt 1 ]]; then
                ee ">>> Missing userid argument for 'unban'"
                print_usage
                exit 1
            fi
            local userid=$1
            local body
            body=$(jq -n --arg uid "$userid" '{"userid": $uid}')
            restapi_post "unban" "$body" || exit 1
            es "> Unbanned: ${userid}"
            ;;
        shutdown)
            local waittime=${1:-10}
            shift || true
            local message="$*"
            local json_body
            json_body=$(jq -n --argjson wt "$waittime" --arg msg "$message" '{"waittime": $wt, "message": $msg}')
            ei "> Shutting down server in ${waittime}s..."
            restapi_post "shutdown" "$json_body" || exit 1
            es "> Shutdown issued."
            ;;
        *)
            ee ">>> Unknown command: '${command}'"
            print_usage
            exit 1
            ;;
    esac
}

run_restapicli "$@"
