#!/bin/sh
#set -e
CUR_PATH=$(dirname $(readlink -f $0))
SED_CUR_PATH="$(echo "$CUR_PATH" | sed "s/\//\\\\\//g")"

NERD_FONT_NAME="JetBrainsMono"
NERD_FONT_EXT=".zip"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/$NERD_FONT_NAME$NERD_FONT_EXT"

#NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage"
NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.appimage"

NEOVIM_CONFIG_USERNAME="mageOfStructs"
NEOVIM_CONFIG_REPO_NAME="derg.nvim"
NEOVIM_CONFIG_URL="https://codeberg.org/$NEOVIM_CONFIG_USERNAME/$NEOVIM_CONFIG_REPO_NAME"
ALT_NEOVIM_CONFIG_URL="https://github.com/$NEOVIM_CONFIG_USERNAME/$NEOVIM_CONFIG_REPO_NAME"

UNHOLY_KITTY_COMMAND="$CUR_PATH/root/bin/kitty --hold -o \"font_family=JetBrainsMono Nerd Font\" $CUR_PATH/nvim.appimage"

readonly LUA_VERSION="5.1.5"

# install rust
#curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#. "$HOME/.cargo/env"

#cargo install ripgrep yazi-cli yazi-fmt &

# download and install nerd font
mkdir -p ~/.fonts/$NERD_FONT_NAME
curl -sL $NERD_FONT_URL -o $CUR_PATH/$NERD_FONT_NAME$NERD_FONT_EXT
# tar xpvf $CUR_PATH/$NERD_FONT_NAME.tar.xz --acls -C ~/.fonts/$NERD_FONT_NAME
unzip -d ~/.fonts/$NERD_FONT_NAME $CUR_PATH/$NERD_FONT_NAME$NERD_FONT_EXT

# THIS SINGLE COMMAND MUTILATES THE FONT FILES (which it doesn't even touch) BEYOND ANY TERMINAL'S RECOGNITION!!!
#chmod 644 ~/.fonts/* # just as a sanity check

# clone neovim config
git clone $NEOVIM_CONFIG_URL ~/.config/nvim
if test $? -eq 128 ; then
    git clone $ALT_NEOVIM_CONFIG_URL ~/.config/nvim
fi

curl -sL $NVIM_APPIMAGE_URL -o $CUR_PATH/nvim.appimage
chmod +x $CUR_PATH/nvim.appimage

mkdir -p "$CUR_PATH/root/usr"

# Install kitty
curl -sL https://github.com/kovidgoyal/kitty/releases/download/v0.35.1/kitty-0.35.1-x86_64.txz -o $CUR_PATH/kitty.txz
tar Jxvf $CUR_PATH/kitty.txz -C "$CUR_PATH/root/usr"

ln -s "$CUR_PATH/root/usr/bin" "$CUR_PATH/root/bin"
ln -s "$CUR_PATH/root/usr/lib" "$CUR_PATH/root/lib"

git clone https://github.com/gnu-mirror-unofficial/readline
cd readline
./configure
make
sed -i Makefile -e "s/DESTDIR =/DESTDIR = ..\/root/"
make install
cd ..

# Setup library stuff
export C_INCLUDE_PATH="$CUR_PATH/root/usr/local/include"
export CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUR_PATH/root/lib:$CUR_PATH/root/usr/local/lib"
export DT_RUNPATH="$LD_LIBRARY_PATH"
echo "export C_INCLUDE_PATH=\"$C_INCLUDE_PATH\"" >> ~/.bashrc
echo "export CPLUS_INCLUDE_PATH=\"$CPLUS_INCLUDE_PATH\"" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\"" >> ~/.bashrc
echo "export LUA_PATH=\"?;?.lua;/usr/local/lua/?/?.lua;$CUR_PATH/root/usr/local/share/lua/5.1/?.lua\"" >> ~/.bashrc
ln -s $CUR_PATH/root/lib/libncursesw.so.6 $CUR_PATH/root/lib/libncurses.so
ln -s $CUR_PATH/root/lib/libreadline.so.8 $CUR_PATH/root/lib/libreadline.so
export PATH="$PATH:$CUR_PATH/root/bin"

# Lua 5.1
curl -sL https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz -o $CUR_PATH/lua.tar.gz
tar xf lua.tar.gz && cd lua-$LUA_VERSION
sed -i src/Makefile -e "s/-lreadline/-L $SED_CUR_PATH\/root\/lib -L $SED_CUR_PATH\/root\/usr\/local\/lib -lreadline/"
make linux
sed -i Makefile -e "s/\/usr\/local/$SED_CUR_PATH\/root\/usr/"
make install
cd ..

curl -sL https://luarocks.github.io/luarocks/releases/luarocks-3.11.1.tar.gz -o $CUR_PATH/luarocks.tar.gz
tar xf luarocks.tar.gz && cd luarocks-3.11.1
./configure --with-lua-include=$CUR_PATH/root/usr/include
make
DESTDIR="$CUR_PATH/root" make install
cd ..

curl -sL https://github.com/jesseduffield/lazygit/releases/download/v0.46.0/lazygit_0.46.0_Linux_x86_64.tar.gz -o $CUR_PATH/lazygit.tar.gz
tar xf lazygit.tar.gz
mv lazygit/lazygit root/bin/

mkdir -p ~/.local
ln -sf $CUR_PATH/root/bin /home/$USER/.local/bin
export PATH="$PATH:/home/$USER/.local/bin:$CUR_PATH/root/usr/local/bin"
echo "PATH=$PATH" >>~/.bashrc
echo "alias nvim=$PWD/nvim.appimage" >>~/.bashrc

echo $UNHOLY_KITTY_COMMAND >>$CUR_PATH/start_kitty.sh
chmod +x $CUR_PATH/start_kitty.sh
ln -sf $CUR_PATH/start_kitty.sh /home/$USER/.local/bin/ks

echo All done! You may need to restart NeoVim a few times

echo If you accidentally closed the kitty terminal \(you weren\'t supposed to do that\). Just run the \'start_kitty.sh\' script, provided for your convenience
bash
