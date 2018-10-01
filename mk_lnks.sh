#!/bin/bash
for f in $(find . -maxdepth 1 ! -name '*.swp' ! -name '.gitignore' ! -name '.git' ! -name '.' -name '.*' -exec basename {} \;); do
		echo "ln -s $(pwd)/$f  /home/$USER/$f  "
		rm -rf /home/$USER/$f
		ln -s $(pwd)/$f  /home/$USER/$f
done

echo "Cloning Vundle"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
