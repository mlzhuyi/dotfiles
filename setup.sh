# neovim
[ -e ~/.config/nvim ] && rm -rf ~/.config/nvim
ln -sf `pwd`/vim ~/.config/nvim
ln -sf `pwd`/vimrc ~/.config/nvim/init.vim
echo "Successfully deploy neovim config"

# vim, macvim
[ -e ~/.vim ] && rm -rf ~/.vim
ln -sf `pwd`/vim ~/.vim
ln -sf `pwd`/vimrc ~/.vimrc
echo "Successfully deploy vim or macvim config"

# tmux
ln -sf `pwd`/tmux.conf ~/.tmux.conf
echo "Successfully deploy tmux config"

# oh-my-zsh
ln -sf `pwd`/self.zsh-theme ~/.oh-my-zsh/themes/self.zsh-theme
ln -sf `pwd`/zshrc ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone git://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone git://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze && ~/.scm_breeze/install.sh
brew install autojump &> /dev/null

echo "Successfully deploy zsh config"

echo "Finished all config tasks"
exec /bin/zsh
