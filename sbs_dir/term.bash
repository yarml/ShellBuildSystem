#!/bin/bash

print() {
    echo "${reset} ${@} ${reset}"
}

debug() {
    if [[ ${SBS_DEBUG} = 0 ]]; then
        print "${bold}${fg_magenta}Debug${reset}: ${@}" 
    fi
}

warn() {
    print "${bold}${fg_yellow}Warning${reset}: " ${@}
}

error() {
    print "${bold}${fg_red}Error${reset}: " ${@} 
}