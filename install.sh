#!/bin/bash

mkdir -p ${HOME}/.local/share/sbs/
\cp -rf sbs_dir/* ${HOME}/.local/share/sbs/
if [[ $? -ne 0 ]]; then
    echo "Problem while trying to copy sbs files"
    rm -rf ${HOME}/.local/share/sbs
    exit 1
fi

sudo cp -rf sbs /usr/bin/sbs
if [[ $? -ne 0 ]]; then
    echo "Problem while trying to install sbs command"
    echo "Perhaps run the command as super user"
    rm -rf ${HOME}/.local/share/sbs
    rm -rf /usr/bin/sbs
    exit 1
fi

echo "Done."
echo "You can execute 'sbs delete' to remove sbs"
