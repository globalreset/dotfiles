#!/bin/bash

# get the expanded dotfiles directory path, removing scripts/setup.sh from the end
DOTFILES_DIR=$(dirname $(dirname $(realpath $0)))

# Function to create symlinks
create_symlink() {
    local src=$1
    # remove DOTFILES_DIR from the beginning of this argument
    local rel_path=${src#$DOTFILES_DIR}
    local filename=${rel_path##*/}      # Extract the filename
    local dst=${HOME}/${rel_path/.symlink/} # Destination path with '.symlink' removed

    # Ensure the parent directory of the destination exists
    mkdir -p "$(dirname "$dst")"

    # Create the symlink, after removing any existing destination file
    echo "linking $src to $dst"
    #ln -sf "$src" "$dst"
}

# Export the function so it's available to find -exec
export -f create_symlink

cd $DOTFILES_DIR
# Find all .symlink files and create corresponding symlinks in the home directory
find . -type f -name "*.symlink" -exec bash -c 'create_symlink "$0"' {} \;

