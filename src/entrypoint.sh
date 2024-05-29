#!/bin/bash

# Copyright (c) DockForge <dockforge@gmail.com>. All rights reserved.
# https://github.com/DockForge/packages
#
# Licensed under the GNU General Public License v3.0.

# Fail script on any error
set -e

# Output file path
OUTPUT_FILE="/workspace/packages.txt"

# Function to append output to file
function append_to_file {
    printf "%-45s %-45s %-10s\n" "$1" "$2" "$3" >> $OUTPUT_FILE
}

# Clear the output file
> $OUTPUT_FILE

# Print header
append_to_file "NAME" "VERSION" "TYPE"

# Capture APT packages if available
if command -v dpkg-query &> /dev/null; then
    dpkg-query -W -f='${binary:Package} ${Version}\n' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "apt"
    done
fi

# Capture APK packages if available
if command -v apk &> /dev/null; then
    apk info -vv | grep -E '^installed|^name|^version' | awk '
    /installed/ { if (pkg) {print pkg}; pkg="" }
    /name/ { pkg=$2 }
    /version/ { ver=$2 }
    END { if (pkg) {print pkg, ver} }' | sort -u | while read -r name version; do
        append_to_file "$name" "$version" "apk"
    done
fi

# Capture RPM packages if available
if command -v rpm &> /dev/null; then
    rpm -qa --qf '%{NAME} %{VERSION}\n' | sort -u | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "rpm"
    done
fi

# Capture Python packages (system-wide)
if command -v pip3 &> /dev/null; then
    pip3 list --format=freeze | while read -r line; do
        package=$(echo $line | awk -F '==' '{print $1}')
        version=$(echo $line | awk -F '==' '{print $2}')
        append_to_file "$package" "$version" "python"
    done
fi

# Capture Node.js packages (global)
if command -v npm &> /dev/null; then
    npm ls -g --depth=0 --json | jq -r '.dependencies | to_entries[] | "\(.key) \(.value.version)"' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "npm"
    done
fi

# Capture Ruby gems
if command -v gem &> /dev/null; then
    gem list | while read -r line; do
        package=$(echo $line | awk '{print $1}')
        version=$(echo $line | awk '{print $2}' | tr -d '()')
        append_to_file "$package" "$version" "gem"
    done
fi

# Capture PHP Composer packages
if command -v composer &> /dev/null; then
    composer global show --format=json | jq -r '.installed[] | "\(.name) \(.version)"' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "composer"
    done
fi

# Output the captured versions to the console (optional)
cat $OUTPUT_FILE
