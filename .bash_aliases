echo ".bash_aliases"
echo "Caller: $(ps -o comm= $PPID)"
# This is a cheat to launch .profile via .bashrc
. "$HOME/.profile"
