# brew
which brew || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# You can set HOMEBREW_NO_AUTO_UPDATE=1 to speed up `brew install`

# oh-my-zsh
which zsh || sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
ln -sf `pwd`/self.zsh-theme ~/.oh-my-zsh/themes/self.zsh-theme
ln -sf `pwd`/zshrc ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone git://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone git://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze && ~/.scm_breeze/install.sh
brew install autojump &> /dev/null
echo "Successfully deploy zsh config"

# ag
which ag || brew install ag

# go
which go || brew install go

# gotty
which gotty || brew install yudai/gotty/gotty
ln -sf `pwd`/gotty ~/.gotty

# ctags
brew install ctags-exuberant

# neovim
which nvim || (brew install neovim && pip3 install neovim)
which gotags || brew install gotags
[ -e ~/.config/nvim ] && rm -rf ~/.config/nvim
mkdir ~/.config/nvim/
ln -sf `pwd`/vimrc ~/.config/nvim/init.vim
ln -sf `pwd`/coc-settings.json ~/.config/nvim/coc-settings.json
curl https://github.com/Karmenzind/monaco-nerd-fonts/blob/master/fonts/Monaco%20Nerd%20Font%20Complete%20Mono.otf > ~/Library/Fonts/'Monaco Nerd Font Complete Mono.otf'
curl https://gist.github.com/ymjing/c788f85a654b2d7581d8/file-monaco-for-powerline-ttf > ~/Library/Fonts/'Monaco for Powerline.otf'
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +q +q
vim +GoInstallBinaries +q
vim +"CocInstall coc-lists" +q
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
echo "Successfully install related tools for git"
echo "You can edit your package.json to enable lint-staged or other commit linter"

# gsed
which gsed || brew install gnu-sed

echo "Finished all config tasks"
exec /bin/zsh
