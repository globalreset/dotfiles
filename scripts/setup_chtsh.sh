
mkdir -p ~/bin ~/.zsh.d ~/.bash.d


curl https://cht.sh/:cht.sh > ~/bin/cht.sh
chmod +x ~/bin/cht.sh

curl https://cheat.sh/:bash_completion > ~/.bash.d/cht.sh
curl https://cheat.sh/:zsh > ~/.zsh.d/_cht
# Open a new shell to load the plugin