DOTFILES = $(PWD)
all:: vim zsh mpv

vim::
	@ln -fs $(DOTFILES)/vimrc		$(HOME)/.vimrc
	@echo Vim is symlinked
zsh::
	@ln -fs $(DOTFILES)/zshrc		$(HOME)/.zshrc
	@ln -fs $(DOTFILES)/zshenv		$(HOME)/.zshenv
	@echo Zsh is symlinked
mpv::
	@ln -fs $(DOTFILES)/mpv/config	$(HOME)/.mpv/config
	@echo Mpv is symlinked
