#!/bin/bash

# Dynamically determine the full path of the dotfiles directory
DOTFILES_DIR=$(realpath ~/dotfiles)
echo "Dotfiles directory: $DOTFILES_DIR"

# Function to create symlinks in the user's home directory
create_symlink() {
  local src=$1
  local dst=$HOME/`echo $src | sed "s/\.symlink//" | sed "s/.*dotfiles\///"`

  # Ensure the parent directory of the destination exists
  mkdir -p "$(dirname "$dst")"

  # Check if the destination file already exists
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "File exists, skipping: $dst"
  else
    echo "Linking $src to $dst"
    ln -sf "$src" "$dst"
  fi
}

export -f create_symlink

# Find and process all .symlink files within the dotfiles directory
find "$DOTFILES_DIR" -type f -name "*.symlink" -exec bash -c 'create_symlink "{}"' \;
