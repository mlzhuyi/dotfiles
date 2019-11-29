# brew
which brew || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# oh-my-zsh
which zsh || sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
ln -sf `pwd`/self.zsh-theme ~/.oh-my-zsh/themes/self.zsh-theme
ln -sf `pwd`/zshrc ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone git://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone git://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze && ~/.scm_breeze/install.sh
brew install autojump &> /dev/null
echo "Successfully deploy zsh config"

# gotty
ln -sf `pwd`/gotty ~/.gotty

# neovim
which nvim || brew install neovim
which gotags || brew install gotags
[ -e ~/.config/nvim ] && rm -rf ~/.config/nvim
mkdir ~/.config/nvim/
ln -sf `pwd`/vimrc ~/.config/nvim/init.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +q +q
vim +GoInstallBinaries +q
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
