#!/bin/bash
# creates or updates a brain-dead bash script to overload commands by their GNU
# coreutils versions

d=/usr/local/opt/coreutils/libexec/gnubin
l=$( dirname $( $d/realpath "${BASH_SOURCE[0]}" ) )/lib_coreutils.bash
u=""

if [ -e $l ]; then u="$( awk '!/^# /{printf $1}' $l )x"; fi

echo "# source this to avoid having all coreutils in the PATH" >$l
echo "((DEBUG)) && echo -n \"[ . \$BASH_SOURCE \""  >>$l
echo "# uncomment those commands you need" >>$l

ls -1 $d | awk '
    {
        if (index("'$u'",$1)) { c="" } else { c="# " }
        printf "%-13s { %s } ; GNU_%s=\"%s\"\n", c $1 "()", "'$d'/" $1 " \"\$@\";", $1,  "'$d'/" $1
    }
' >>$l

echo "((DEBUG)) && echo \"]\"" >>$l
echo "return 0" >>$l
