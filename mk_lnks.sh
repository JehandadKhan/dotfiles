#!/bin/bash
sudo apt update
sudo apt -y install vim
for f in $(find . -maxdepth 1 ! -name '*.swp' ! -name '.gitignore' ! -name '.git' ! -name '.' -name '.*' -exec basename {} \;); do
		echo "ln -s $(pwd)/$f  $HOME/$f  "
		rm -rf $HOME/$f
		ln -s $(pwd)/$f  $HOME/$f
done

echo "Cloning Vundle"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
echo "Installing trash-cli"
sudo apt -y install trash-cli
echo "Installing exuberant-ctags"
sudo apt -y install exuberant-ctags
# install code query
echo "Installing CodeQuery (No GUI)"
sudo apt-get -y install g++ git cmake sqlite3 libsqlite3-dev qt4-dev-tools cscope exuberant-ctags
git clone https://github.com/ruben2020/codequery.git /tmp/codequery/
mkdir /tmp/codequery/build
cd /tmp/codequery/build
cmake -G "Unix Makefiles" -DNO_GUI=ON ..
sudo make -j install 
