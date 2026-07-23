## Installation

```sh
git clone https://github.com/mlzhuyi/dotfiles.git
cd dotfiles
./setup.sh --dry-run
./setup.sh
```

The installer is safe to rerun. Existing files that conflict with managed
dotfiles are moved once to a sibling `*.before-dotfiles` backup instead of
being deleted. `--dry-run` prints planned commands without changing the system.
