#!/bin/bash
for f in $(find . -maxdepth 1 ! -name '*.swp' ! -name '.gitignore' ! -name '.git' ! -name '.' -name '.*' -printf '%P\n'); do
		echo "ln -s $(pwd)/$f  /home/$USER/$f  "
		rm -rf /home/$USER/$f
		ln -s $(pwd)/$f  /home/$USER/$f
done