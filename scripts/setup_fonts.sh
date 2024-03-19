mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

# can't decide yet between these four
for f in FiraMono Inconsolata FiraCode UbuntuMono; do
  (
    mkdir -p $f &&
    cd $f &&
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$f.zip &&
    unzip $f.zip
  )
done

# update font cache on linux
if hash fc-cache 2>/dev/null; then
  fc-cache ~/.local/share/fonts
fi
