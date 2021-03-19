#!/bin/bash

new() {
    AUTO_SETUP=${2:-"no-auto-setup"}
    cp ${HOME}/.local/share/default_sbs_verbs ./sbs.verbs
    if [[ ${AUTO_SETUP} = "setup-guide" ]]; then
        proj-setup
    elif [[ ${AUTO_SETUP} = "no-setup-guide" ]]; then
        echo "You can launch project setup guide with 'sbs proj-setup'"
    else
        echo "Unknown parameter: ${2}"
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
    echo "Writing configuration to sbs.project"
    echo "# This file was auto generated, you may need to adjust it to your needs
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
    source ${HOME}/.local/share/sbs/sbs.bash
}

clean() {
    echo "Cleaning objects and temporary files"
    if [[ -f ${PROJECT_FILE} ]]; then
        source ${PROJECT_FILE}
    else
        echo "Project file not found!"
        exit 1
    fi
    BUILD_DIR=${BUILD_DIR:-"${PROJECT_DIR}/build/"}
    _RBDIR=${_RBDIR:-"${BUILD_DIR}/"}
    [[ -d "${_RBDIR}/debug/obj" ]] && rm -rf "${_RBDIR}/debug/obj"
    [[ -d "${_RBDIR}/release/obj" ]] && rm -rf "${_RBDIR}/release/obj"
    [[ -d "${HOME}/.local/share/sbs/tmp" ]] && rm -rf "${HOME}/.local/share/sbs/tmp"
    echo "Cleaned!"
}

remove_update_files() {
    echo "Removing temporary file..."
    cd ${PROJECT_DIR}
    rm -rf ${TMP_DIR}
    if [[ $? -ne 0 ]]; then
        echo "Problem while trying to delete temporary files!"
        echo "Try deleting '${TMP_DIR}' by yourself, it should be deleted automatically after reboot"
        exit 1
    fi
}

update() {
    TMP_DIR=$(mktemp -d)
    cd ${TMP_DIR}

    if [[ ! $(command -v jq) ]]; then
        echo "Cannot find command jq, please install it first"
        exit 1
    fi

    GITHUB_API_LATEST="https://api.github.com/repos/TheCoderCrab/ShellBuildSystem/releases/latest"

    echo "Fetching update meta-data from: \"${GITHUB_API_LATEST}\"..."

    if [[ $(command -v wget) ]]; then
        TAG_NAME=$(wget -O - -q ${GITHUB_API_LATEST} | jq -r ".tag_name")
    elif [[ $(command -v curl) ]]; then
        TAG_NAME=$(curl -s ${GITHUB_API_LATEST} | jq -r ".tag_name")
    else
        echo "Please install wget or curl before trying to update"
        cd ${PROJECT_DIR}
        remove_update_files
        exit 1
    fi

    
    if [[ -f ${HOME}/.local/share/sbs/sbs.version ]]; then
        CURRENT_VERSION=$(cat ${HOME}/.local/share/sbs/sbs.version)
    else
        CURRENT_VERSION="unknown"
    fi

    echo "Latest version: ${TAG_NAME}"
    echo "Current version: ${CURRENT_VERSION:-"unknown"}"

    if [[ ${CURRENT_VERSION} != ${TAG_NAME} ]]; then
        echo "Installing new update..."
    else
        echo "Latest update already installed"
        exit 0
    fi

    UPDATE_URL="https://github.com/TheCoderCrab/ShellBuildSystem/archive/${TAG_NAME}.tar.gz"
    
    echo "Downloading update..."
    
    if [[ $(command -v wget) ]]; then
        CMD="wget -q"
    elif [[ $(command -v curl) ]]; then
        CMD="curl -s -L -o ${TAG_NAME}.tar.gz"
    fi
    ${CMD} ${UPDATE_URL}
    if [[ $? -ne 0 ]]; then
        echo "Problem while downloading the update files!"
        remove_update_files
        exit 1
    fi
    echo "Extracting files..."
    tar -xzf ${TAG_NAME}.tar.gz
    if [[ $? -ne 0 ]]; then
        echo "Problem while extracting the update files!"
        remove_update_files
        exit 1
    fi
    echo "Copying new files to sbs directory..."
    \cp -r ShellBuildSystem*/sbs_dir/* ${HOME}/.local/share/sbs
    if [[ $? -ne 0 ]]; then
        echo "Problem while copying the update files!"
        remove_update_files
        exit 1
    fi
    \cp ShellBuildSystem*/sbs /usr/bin/sbs
    if [[ $? -ne 0 ]]; then
        echo "Problem while copying the update files!"
        echo "Perhaps try to run the command as super user"
        remove_update_files
        exit 1
    fi
    cd ${PROJECT_DIR}
    remove_update_files
    echo ${TAG_NAME} > ${HOME}/.local/share/sbs/sbs.version
    echo "Updated sbs!"
}

NOT_VERB+=(remove_update_files)

