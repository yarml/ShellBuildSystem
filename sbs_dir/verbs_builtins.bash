#!/bin/bash

SBS_INSTALLATION="${HOME}/.local/share/sbs/"

source ${SBS_INSTALLATION}/colors.bash
source ${SBS_INSTALLATION}/term.bash

help() {
    print ${bold}${fg_green} "Welcome to sbs version ${fg_yellow}$(cat ${SBS_INSTALLATION}/sbs.version)${fg_green}!"
    print ${bold}${fg_green} "SBS is a build system for C/C++/Assembly projects"
    print ${bold}${fg_green} "Currently it is preferable to use GNU C/C++ compilers and NASM to assemble"
    print ""
    print ${bold}${fg_green} "Documentation for SBS is still in progress"
    print ""
    print ${bold}${fg_green}  "Those are the builtin verbs: "
    print ${bold}${fg_yellow} "\thelp${reset}${fg_green}      : " "Display this menu"
    print ${bold}${fg_yellow} "\tversion${reset}${fg_green}   : " "Display installed SBS version"
    print ${bold}${fg_yellow} "\tupdate${reset}${fg_green}    : " "Check if an update is available and install it"
    print ${bold}${fg_yellow} "\tnew${reset}${fg_green}       : " "Create a new project basic layout"
    print ${bold}${fg_yellow} "\tproj-setup${reset}${fg_green}: " "Interactive menu to configure the project"
    print ${bold}${fg_yellow} "\tbuild${reset}${fg_green}     : " "Build the project using the configuration"
    print ${bold}${fg_yellow} "\tclean${reset}${fg_green}     : " "Clean builds"
}

version() {
    print ${bold}${fg_green} "SBS version ${fg_yellow}$(cat ${SBS_INSTALLATION}/sbs.version)"
}

new() {
    AUTO_SETUP=${2:-"no-setup-guide"}
    cp ${SBS_INSTALLATION}/default_sbs_verbs ./sbs.verbs
    if [[ ${AUTO_SETUP} = "setup-guide" ]]; then
        proj-setup
    elif [[ ${AUTO_SETUP} = "no-setup-guide" ]]; then
        print ${bold}${fg_green} "You can launch project setup guide with 'sbs proj-setup'"
    else
        print ${bold}${fg_green} "Unknown parameter: ${2}"
        exit 1
    fi
    touch sbs.project
}

proj-setup() {
    read -p "C Compiler[/bin/gcc]            : " CC
    read -p "C++ Compiler[/bin/g++]          : " CXX
    read -p "Assembler[/bin/nasm]            : " AS
    read -p "Linker[/bin/g++]                : " LINKER
    read -p "Static Linker[/bin/ar]          : " STATIC_LINKER
    read -p "C Flags                         : " CFLAGS
    read -p "C++ Flags                       : " CXXFLAGS
    read -p "C/C++ Flags                     : " CCFLAGS
    read -p "Assembler Flags                 : " ASFLAGS
    read -p "Linker Flags                    : " LINKFLAGS
    read -p "Source directories[src]         : " SRC
    read -p "Include directories[include]    : " INCLUDE
    read -p "Additional sources              : " ADDITIONAL_SOURCES
    read -p "Output type(exec|lib|slib)[exec]: " TYPE
    read -p "Subprojects path                : " SUB_PROJECTS
    read -p "Libraries                       : " LIBRARIES
    read -p "Library directories             : " LIB_DIRS
    print ${bold}${fg_green} "Writing configuration to sbs.project"
    print ${bold}${fg_green} "# This file was auto generated, you may need to adjust it to your needs
CC=${CC}
CXX=${CXX}
AS=${AS}
LINKER=${LINKER:-"/bin/g++"}
STATIC_LINKER=${STATIC_LINKER}
CFLAGS=${CFLAGS}
CXXFLAGS=${CXXFLAGS}
CCFLAGS=${CCFLAGS}
ASFLAGS=${ASFLAGS}
LINKFLAGS=${LINKFLAGS}
CEXTENSIONS=${CEXTENSIONS}
CXXEXTENSIONS=${CXXEXTENSIONS}
ASEXTENSIONS=${ASEXTENSIONS}
SRC=${SRC}
ADDITIONAL_SOURCES=${ADDITIONAL_SOURCES}
INCLUDE=${INCLUDE}
TARGET=${TARGET}
TYPE=${TYPE}
BUILD_TYPE=${BUILD_TYPE}
BUILD_DIR=${BUILD_DIR}
SUB_PROJECTS=${SUB_PROJECTS}
LIBRARIES=${LIBRARIES}
LIB_DIRS=${LIB_DIRS}" > sbs.project
}

build() {
    source ${SBS_INSTALLATION}/sbs.bash
}

clean() {
    print ${bold}${fg_green} "Cleaning objects and temporary files"
    if [[ -f ${PROJECT_FILE} ]]; then
        source ${PROJECT_FILE}
    else
        print ${bold}${fg_green} "Project file not found!"
        exit 1
    fi
    BUILD_DIR=${BUILD_DIR:-"${PROJECT_DIR}/build/"}
    _RBDIR=${_RBDIR:-"${BUILD_DIR}/"}
    [[ -d "${_RBDIR}/debug/obj" ]] && rm -rf "${_RBDIR}/debug/obj"
    [[ -d "${_RBDIR}/release/obj" ]] && rm -rf "${_RBDIR}/release/obj"
    [[ -d "${SBS_INSTALLATION}/tmp" ]] && rm -rf "${SBS_INSTALLATION}/tmp"
    print ${bold}${fg_green} "Cleaned!"
}

remove_update_files() {
    print ${bold}${fg_green} "Removing temporary file..."
    cd ${PROJECT_DIR}
    rm -rf ${TMP_DIR}
    if [[ $? -ne 0 ]]; then
        print ${bold}${fg_green} "Problem while trying to delete temporary files!"
        print ${bold}${fg_green} "Try deleting '${TMP_DIR}' by yourself, it should be deleted automatically after reboot"
        exit 1
    fi
}

update() {
    TMP_DIR=$(mktemp -d)
    cd ${TMP_DIR}

    if [[ ! $(command -v jq) ]]; then
        print ${bold}${fg_green} "Cannot find command jq, please install it first"
        exit 1
    fi

    GITHUB_API_LATEST="https://api.github.com/repos/TheCoderCrab/ShellBuildSystem/releases/latest"

    print ${bold}${fg_green} "Fetching update meta-data from: \"${GITHUB_API_LATEST}\"..."

    if [[ $(command -v wget) ]]; then
        TAG_NAME=$(wget -O - -q ${GITHUB_API_LATEST} | jq -r ".tag_name")
    elif [[ $(command -v curl) ]]; then
        TAG_NAME=$(curl -s ${GITHUB_API_LATEST} | jq -r ".tag_name")
    else
        print ${bold}${fg_green} "Please install wget or curl before trying to update"
        cd ${PROJECT_DIR}
        remove_update_files
        exit 1
    fi

    
    if [[ -f ${SBS_INSTALLATION}/sbs.version ]]; then
        CURRENT_VERSION=$(cat ${SBS_INSTALLATION}/sbs.version)
    else
        CURRENT_VERSION="unknown"
    fi

    print ${bold}${fg_green} "Latest version: ${TAG_NAME}"
    print ${bold}${fg_green} "Current version: ${CURRENT_VERSION:-"unknown"}"

    if [[ ${CURRENT_VERSION} != ${TAG_NAME} ]]; then
        print ${bold}${fg_green} "Installing new update..."
    else
        print ${bold}${fg_green} "Latest update already installed"
        exit 0
    fi

    UPDATE_URL="https://github.com/TheCoderCrab/ShellBuildSystem/archive/${TAG_NAME}.tar.gz"
    
    print ${bold}${fg_green} "Downloading update..."
    
    if [[ $(command -v wget) ]]; then
        CMD="wget -q"
    elif [[ $(command -v curl) ]]; then
        CMD="curl -s -L -o ${TAG_NAME}.tar.gz"
    fi
    ${CMD} ${UPDATE_URL}
    if [[ $? -ne 0 ]]; then
        print ${bold}${fg_green} "Problem while downloading the update files!"
        remove_update_files
        exit 1
    fi
    print ${bold}${fg_green} "Extracting files..."
    tar -xzf ${TAG_NAME}.tar.gz
    if [[ $? -ne 0 ]]; then
        print ${bold}${fg_green} "Problem while extracting the update files!"
        remove_update_files
        exit 1
    fi
    print ${bold}${fg_green} "Copying new files to sbs directory..."
    \cp -r ShellBuildSystem*/sbs_dir/* ${SBS_INSTALLATION}
    if [[ $? -ne 0 ]]; then
        print ${bold}${fg_green} "Problem while copying the update files!"
        remove_update_files
        exit 1
    fi
    sudo cp ShellBuildSystem*/sbs /usr/bin/sbs
    if [[ $? -ne 0 ]]; then
        print ${bold}${fg_green} "Problem while copying the update files!"
        print ${bold}${fg_green} "Perhaps try to run the command as super user"
        remove_update_files
        exit 1
    fi
    cd ${PROJECT_DIR}
    remove_update_files
    print ${bold}${fg_green} "Updated sbs!"
}

delete() {
    TMP=$(mktemp)
    print ${bold}${fg_green} "rm -rf ${SBS_INSTALLATION}/
sudo rm -rf /bin/sbs
rm -rf ${TMP}" > ${TMP}
    source ${TMP}
}

NOT_VERB+=(remove_update_files print debug warn error)

