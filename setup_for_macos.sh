which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
# You can set HOMEBREW_NO_AUTO_UPDATE=1 to speed up `brew install`

# oh-my-zsh
if [ ! -d "${HOME}/.oh-my-zsh" ];then
 sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
ln -sf `pwd`/self.zsh-theme ~/.oh-my-zsh/themes/self.zsh-theme
[[ -f `pwd`/zshrc.local ]] && ln -sf `pwd`/zshrc.local ~/.zshrc.local
ln -sf `pwd`/zshrc ~/.zshrc
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
brew install autojump &> /dev/null
echo "Successfully deploy zsh config"
# if you run `omz udpate` failed with error `unable to connect to github.com`, you can run following command
# git config --global url."https://".insteadOf git://

# ag
which ag || brew install ag

# go

which gvm ||brew install mercurial &&  $(zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/13b10b604255360a9a559c2ea23ba42e75cb536e/binscripts/gvm-installer)) && source $GVM_ROOT/scripts/gvm
which go || gvm install go1.20.0 && gvm use go1.20.0 --default
which dot || brew install graphviz
which dlv || brew install delve
which golangci-lint || brew install golangci-lint

# rust
which rustc || curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
ln -sf `pwd`/rust.config.toml ~/.cargo/config.toml

# gotty
which gotty || brew install yudai/gotty/gotty
ln -sf `pwd`/gotty ~/.gotty

# ctags
brew install ctags

# thefuck
brew install thefuck

# neovim
which nvim || (brew install neovim && pip3 install neovim)
which gotags || brew install gotags
[ -e ~/.config/nvim ] && rm -rf ~/.config/nvim
mkdir ~/.config/nvim/
ln -sf `pwd`/vimrc ~/.config/nvim/init.vim
ln -sf `pwd`/coc-settings.json ~/.config/nvim/coc-settings.json
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +q +q
vim +"CocInstall coc-lists coc-go coc-diagnostic coc-highlight coc-rust-analyzer" +q
npm -g install instant-markdown-d
echo "Successfully deploy neovim config"
ln -sf `pwd`/UltiSnips ~/.vim/UltiSnips
mkdir ~/.config/nvim/lua
ln -sf `pwd`/avante_config.lua ~/.config/nvim/lua/avante_config.lua

# scm_breeze - exists conflict command cd with gvm
# gvm may have problem with scm_breeze with, so install scm_breeze later than gvm
git clone https://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze && ~/.scm_breeze/install.sh

# fonts
cp `pwd`/"Monaco Nerd Font Mono.otf" ~/Library/Fonts/
# then set font of iterm: settings -> profiles -> text -> font


# tmux
which tmux || brew install tmux
ln -sf `pwd`/tmux.conf ~/.tmux.conf
ln -sf `pwd`/tmux.conf.local ~/.tmux.conf.local
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

# claude-code
npm install -g @anthropic-ai/claude-code
ln -sf `pwd`/CLAUDE.md ~/CLAUDE.md

# codex
npm i -g @openai/codex
