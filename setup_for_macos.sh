# brew
which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
# You can set HOMEBREW_NO_AUTO_UPDATE=1 to speed up `brew install`

# oh-my-zsh
if [ ! -d "${HOME}/.oh-my-zsh" ];then
 sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
ln -sf `pwd`/self.zsh-theme ~/.oh-my-zsh/themes/self.zsh-theme
ln -sf `pwd`/zshrc ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze && ~/.scm_breeze/install.sh
brew install autojump &> /dev/null
echo "Successfully deploy zsh config"

# ag
which ag || brew install ag

# go
which gvm || $(zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)) && source $GVM_ROOT/scripts/gvm
which go || gvm use 1.17.11 --default
which dot || brew install graphviz

# rust
which rustc || curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
ln -sf `pwd`/rust.config.toml ~/.cargo/config.toml

# gotty
which gotty || brew install yudai/gotty/gotty
ln -sf `pwd`/gotty ~/.gotty

# ctags
brew install ctags-exuberant

# thefuck
brew install thefuck

# neovim
which nvim || (brew install neovim && pip3 install neovim)
which gotags || brew install gotags
[ -e ~/.config/nvim ] && rm -rf ~/.config/nvim
mkdir ~/.config/nvim/
ln -sf `pwd`/vimrc ~/.config/nvim/init.vim
ln -sf `pwd`/coc-settings.json ~/.config/nvim/coc-settings.json
cp `pws`/"Monaco Nerd Font Complete Mono.otf" ~/Library/Fonts/
cp `pws`/"Monaco for Powerline.ttf" ~/Library/Fonts/
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +q +q
vim +"CocInstall coc-lists coc-go coc-diagnostic cpc-highlight coc-rust-analyzer" +q
npm -g install instant-markdown-d
echo "Successfully deploy neovim config"
ln -sf `pwd`/UltiSnips ~/.vim/UltiSnips

# tmux
which tmux || brew install tmux
ln -sf `pwd`/tmux.conf ~/.tmux.conf
echo "Successfully deploy tmux config"

# git
which npm || brew install npm
npm install -g commitizen
npm install -g lint-staged husky
ln -sf `pwd`/czrc ~/.czrc
brew install tig
echo "Successfully install related tools for git"
echo "You can edit your package.json to enable lint-staged or other commit linter"

# gsed
which gsed || brew install gnu-sed

echo "Finished all config tasks"
exec /bin/zsh
