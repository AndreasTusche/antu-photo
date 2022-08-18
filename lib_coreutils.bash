#
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   lib_coreutils.bash - source this to avoid having all coreutils in the PATH
#
# SYNOPSIS
#   source lib_coreutils.bash
#
# DESCRIPTION
#	This library replaces command calls by function calls to the coreutils in
#   /usr/local/opt/coreutils/libexec/gnubin
#
#   To recreate this library, run make_lib_coreutils.bash
#
# AUTHOR
#	@author     Andreas Tusche <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2021-2022, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2022-08-18 auto created

(( ${coreutils_lib_loaded:-0} )) && return 0     # load me only once
((DEBUG)) && echo -n "[ . $BASH_SOURCE "

coreutils_DEVELOP=1                              # special settings for while developing
coreutils_MY_VERSION='$Revision: 22.0818 $'      # version of this library

# uncomment those commands you need
# [()         { /usr/local/opt/coreutils/libexec/gnubin/[ "$@"; } ; GNU_[="/usr/local/opt/coreutils/libexec/gnubin/["
# b2sum()     { /usr/local/opt/coreutils/libexec/gnubin/b2sum "$@"; } ; GNU_b2sum="/usr/local/opt/coreutils/libexec/gnubin/b2sum"
# base32()    { /usr/local/opt/coreutils/libexec/gnubin/base32 "$@"; } ; GNU_base32="/usr/local/opt/coreutils/libexec/gnubin/base32"
# base64()    { /usr/local/opt/coreutils/libexec/gnubin/base64 "$@"; } ; GNU_base64="/usr/local/opt/coreutils/libexec/gnubin/base64"
# basename()  { /usr/local/opt/coreutils/libexec/gnubin/basename "$@"; } ; GNU_basename="/usr/local/opt/coreutils/libexec/gnubin/basename"
# basenc()    { /usr/local/opt/coreutils/libexec/gnubin/basenc "$@"; } ; GNU_basenc="/usr/local/opt/coreutils/libexec/gnubin/basenc"
# cat()       { /usr/local/opt/coreutils/libexec/gnubin/cat "$@"; } ; GNU_cat="/usr/local/opt/coreutils/libexec/gnubin/cat"
# chcon()     { /usr/local/opt/coreutils/libexec/gnubin/chcon "$@"; } ; GNU_chcon="/usr/local/opt/coreutils/libexec/gnubin/chcon"
# chgrp()     { /usr/local/opt/coreutils/libexec/gnubin/chgrp "$@"; } ; GNU_chgrp="/usr/local/opt/coreutils/libexec/gnubin/chgrp"
# chmod()     { /usr/local/opt/coreutils/libexec/gnubin/chmod "$@"; } ; GNU_chmod="/usr/local/opt/coreutils/libexec/gnubin/chmod"
# chown()     { /usr/local/opt/coreutils/libexec/gnubin/chown "$@"; } ; GNU_chown="/usr/local/opt/coreutils/libexec/gnubin/chown"
# chroot()    { /usr/local/opt/coreutils/libexec/gnubin/chroot "$@"; } ; GNU_chroot="/usr/local/opt/coreutils/libexec/gnubin/chroot"
# cksum()     { /usr/local/opt/coreutils/libexec/gnubin/cksum "$@"; } ; GNU_cksum="/usr/local/opt/coreutils/libexec/gnubin/cksum"
# comm()      { /usr/local/opt/coreutils/libexec/gnubin/comm "$@"; } ; GNU_comm="/usr/local/opt/coreutils/libexec/gnubin/comm"
# cp()        { /usr/local/opt/coreutils/libexec/gnubin/cp "$@"; } ; GNU_cp="/usr/local/opt/coreutils/libexec/gnubin/cp"
# csplit()    { /usr/local/opt/coreutils/libexec/gnubin/csplit "$@"; } ; GNU_csplit="/usr/local/opt/coreutils/libexec/gnubin/csplit"
# cut()       { /usr/local/opt/coreutils/libexec/gnubin/cut "$@"; } ; GNU_cut="/usr/local/opt/coreutils/libexec/gnubin/cut"
date()        { /usr/local/opt/coreutils/libexec/gnubin/date "$@"; } ; GNU_date="/usr/local/opt/coreutils/libexec/gnubin/date"
# dd()        { /usr/local/opt/coreutils/libexec/gnubin/dd "$@"; } ; GNU_dd="/usr/local/opt/coreutils/libexec/gnubin/dd"
# df()        { /usr/local/opt/coreutils/libexec/gnubin/df "$@"; } ; GNU_df="/usr/local/opt/coreutils/libexec/gnubin/df"
# dir()       { /usr/local/opt/coreutils/libexec/gnubin/dir "$@"; } ; GNU_dir="/usr/local/opt/coreutils/libexec/gnubin/dir"
# dircolors() { /usr/local/opt/coreutils/libexec/gnubin/dircolors "$@"; } ; GNU_dircolors="/usr/local/opt/coreutils/libexec/gnubin/dircolors"
# dirname()   { /usr/local/opt/coreutils/libexec/gnubin/dirname "$@"; } ; GNU_dirname="/usr/local/opt/coreutils/libexec/gnubin/dirname"
# du()        { /usr/local/opt/coreutils/libexec/gnubin/du "$@"; } ; GNU_du="/usr/local/opt/coreutils/libexec/gnubin/du"
# echo()      { /usr/local/opt/coreutils/libexec/gnubin/echo "$@"; } ; GNU_echo="/usr/local/opt/coreutils/libexec/gnubin/echo"
# env()       { /usr/local/opt/coreutils/libexec/gnubin/env "$@"; } ; GNU_env="/usr/local/opt/coreutils/libexec/gnubin/env"
# expand()    { /usr/local/opt/coreutils/libexec/gnubin/expand "$@"; } ; GNU_expand="/usr/local/opt/coreutils/libexec/gnubin/expand"
# expr()      { /usr/local/opt/coreutils/libexec/gnubin/expr "$@"; } ; GNU_expr="/usr/local/opt/coreutils/libexec/gnubin/expr"
# factor()    { /usr/local/opt/coreutils/libexec/gnubin/factor "$@"; } ; GNU_factor="/usr/local/opt/coreutils/libexec/gnubin/factor"
# false()     { /usr/local/opt/coreutils/libexec/gnubin/false "$@"; } ; GNU_false="/usr/local/opt/coreutils/libexec/gnubin/false"
# fmt()       { /usr/local/opt/coreutils/libexec/gnubin/fmt "$@"; } ; GNU_fmt="/usr/local/opt/coreutils/libexec/gnubin/fmt"
# fold()      { /usr/local/opt/coreutils/libexec/gnubin/fold "$@"; } ; GNU_fold="/usr/local/opt/coreutils/libexec/gnubin/fold"
# groups()    { /usr/local/opt/coreutils/libexec/gnubin/groups "$@"; } ; GNU_groups="/usr/local/opt/coreutils/libexec/gnubin/groups"
# head()      { /usr/local/opt/coreutils/libexec/gnubin/head "$@"; } ; GNU_head="/usr/local/opt/coreutils/libexec/gnubin/head"
# hostid()    { /usr/local/opt/coreutils/libexec/gnubin/hostid "$@"; } ; GNU_hostid="/usr/local/opt/coreutils/libexec/gnubin/hostid"
# id()        { /usr/local/opt/coreutils/libexec/gnubin/id "$@"; } ; GNU_id="/usr/local/opt/coreutils/libexec/gnubin/id"
# install()   { /usr/local/opt/coreutils/libexec/gnubin/install "$@"; } ; GNU_install="/usr/local/opt/coreutils/libexec/gnubin/install"
# join()      { /usr/local/opt/coreutils/libexec/gnubin/join "$@"; } ; GNU_join="/usr/local/opt/coreutils/libexec/gnubin/join"
# kill()      { /usr/local/opt/coreutils/libexec/gnubin/kill "$@"; } ; GNU_kill="/usr/local/opt/coreutils/libexec/gnubin/kill"
# link()      { /usr/local/opt/coreutils/libexec/gnubin/link "$@"; } ; GNU_link="/usr/local/opt/coreutils/libexec/gnubin/link"
# ln()        { /usr/local/opt/coreutils/libexec/gnubin/ln "$@"; } ; GNU_ln="/usr/local/opt/coreutils/libexec/gnubin/ln"
# logname()   { /usr/local/opt/coreutils/libexec/gnubin/logname "$@"; } ; GNU_logname="/usr/local/opt/coreutils/libexec/gnubin/logname"
ls()          { /usr/local/opt/coreutils/libexec/gnubin/ls "$@"; } ; GNU_ls="/usr/local/opt/coreutils/libexec/gnubin/ls"
# md5sum()    { /usr/local/opt/coreutils/libexec/gnubin/md5sum "$@"; } ; GNU_md5sum="/usr/local/opt/coreutils/libexec/gnubin/md5sum"
# mkdir()     { /usr/local/opt/coreutils/libexec/gnubin/mkdir "$@"; } ; GNU_mkdir="/usr/local/opt/coreutils/libexec/gnubin/mkdir"
# mkfifo()    { /usr/local/opt/coreutils/libexec/gnubin/mkfifo "$@"; } ; GNU_mkfifo="/usr/local/opt/coreutils/libexec/gnubin/mkfifo"
# mknod()     { /usr/local/opt/coreutils/libexec/gnubin/mknod "$@"; } ; GNU_mknod="/usr/local/opt/coreutils/libexec/gnubin/mknod"
# mktemp()    { /usr/local/opt/coreutils/libexec/gnubin/mktemp "$@"; } ; GNU_mktemp="/usr/local/opt/coreutils/libexec/gnubin/mktemp"
mv()          { /usr/local/opt/coreutils/libexec/gnubin/mv "$@"; } ; GNU_mv="/usr/local/opt/coreutils/libexec/gnubin/mv"
# nice()      { /usr/local/opt/coreutils/libexec/gnubin/nice "$@"; } ; GNU_nice="/usr/local/opt/coreutils/libexec/gnubin/nice"
# nl()        { /usr/local/opt/coreutils/libexec/gnubin/nl "$@"; } ; GNU_nl="/usr/local/opt/coreutils/libexec/gnubin/nl"
# nohup()     { /usr/local/opt/coreutils/libexec/gnubin/nohup "$@"; } ; GNU_nohup="/usr/local/opt/coreutils/libexec/gnubin/nohup"
# nproc()     { /usr/local/opt/coreutils/libexec/gnubin/nproc "$@"; } ; GNU_nproc="/usr/local/opt/coreutils/libexec/gnubin/nproc"
# numfmt()    { /usr/local/opt/coreutils/libexec/gnubin/numfmt "$@"; } ; GNU_numfmt="/usr/local/opt/coreutils/libexec/gnubin/numfmt"
# od()        { /usr/local/opt/coreutils/libexec/gnubin/od "$@"; } ; GNU_od="/usr/local/opt/coreutils/libexec/gnubin/od"
# paste()     { /usr/local/opt/coreutils/libexec/gnubin/paste "$@"; } ; GNU_paste="/usr/local/opt/coreutils/libexec/gnubin/paste"
# pathchk()   { /usr/local/opt/coreutils/libexec/gnubin/pathchk "$@"; } ; GNU_pathchk="/usr/local/opt/coreutils/libexec/gnubin/pathchk"
# pinky()     { /usr/local/opt/coreutils/libexec/gnubin/pinky "$@"; } ; GNU_pinky="/usr/local/opt/coreutils/libexec/gnubin/pinky"
# pr()        { /usr/local/opt/coreutils/libexec/gnubin/pr "$@"; } ; GNU_pr="/usr/local/opt/coreutils/libexec/gnubin/pr"
# printenv()  { /usr/local/opt/coreutils/libexec/gnubin/printenv "$@"; } ; GNU_printenv="/usr/local/opt/coreutils/libexec/gnubin/printenv"
# printf()    { /usr/local/opt/coreutils/libexec/gnubin/printf "$@"; } ; GNU_printf="/usr/local/opt/coreutils/libexec/gnubin/printf"
# ptx()       { /usr/local/opt/coreutils/libexec/gnubin/ptx "$@"; } ; GNU_ptx="/usr/local/opt/coreutils/libexec/gnubin/ptx"
# pwd()       { /usr/local/opt/coreutils/libexec/gnubin/pwd "$@"; } ; GNU_pwd="/usr/local/opt/coreutils/libexec/gnubin/pwd"
# readlink()  { /usr/local/opt/coreutils/libexec/gnubin/readlink "$@"; } ; GNU_readlink="/usr/local/opt/coreutils/libexec/gnubin/readlink"
# realpath()  { /usr/local/opt/coreutils/libexec/gnubin/realpath "$@"; } ; GNU_realpath="/usr/local/opt/coreutils/libexec/gnubin/realpath"
# rm()        { /usr/local/opt/coreutils/libexec/gnubin/rm "$@"; } ; GNU_rm="/usr/local/opt/coreutils/libexec/gnubin/rm"
# rmdir()     { /usr/local/opt/coreutils/libexec/gnubin/rmdir "$@"; } ; GNU_rmdir="/usr/local/opt/coreutils/libexec/gnubin/rmdir"
# runcon()    { /usr/local/opt/coreutils/libexec/gnubin/runcon "$@"; } ; GNU_runcon="/usr/local/opt/coreutils/libexec/gnubin/runcon"
# seq()       { /usr/local/opt/coreutils/libexec/gnubin/seq "$@"; } ; GNU_seq="/usr/local/opt/coreutils/libexec/gnubin/seq"
# sha1sum()   { /usr/local/opt/coreutils/libexec/gnubin/sha1sum "$@"; } ; GNU_sha1sum="/usr/local/opt/coreutils/libexec/gnubin/sha1sum"
# sha224sum() { /usr/local/opt/coreutils/libexec/gnubin/sha224sum "$@"; } ; GNU_sha224sum="/usr/local/opt/coreutils/libexec/gnubin/sha224sum"
# sha256sum() { /usr/local/opt/coreutils/libexec/gnubin/sha256sum "$@"; } ; GNU_sha256sum="/usr/local/opt/coreutils/libexec/gnubin/sha256sum"
# sha384sum() { /usr/local/opt/coreutils/libexec/gnubin/sha384sum "$@"; } ; GNU_sha384sum="/usr/local/opt/coreutils/libexec/gnubin/sha384sum"
# sha512sum() { /usr/local/opt/coreutils/libexec/gnubin/sha512sum "$@"; } ; GNU_sha512sum="/usr/local/opt/coreutils/libexec/gnubin/sha512sum"
# shred()     { /usr/local/opt/coreutils/libexec/gnubin/shred "$@"; } ; GNU_shred="/usr/local/opt/coreutils/libexec/gnubin/shred"
# shuf()      { /usr/local/opt/coreutils/libexec/gnubin/shuf "$@"; } ; GNU_shuf="/usr/local/opt/coreutils/libexec/gnubin/shuf"
# sleep()     { /usr/local/opt/coreutils/libexec/gnubin/sleep "$@"; } ; GNU_sleep="/usr/local/opt/coreutils/libexec/gnubin/sleep"
# sort()      { /usr/local/opt/coreutils/libexec/gnubin/sort "$@"; } ; GNU_sort="/usr/local/opt/coreutils/libexec/gnubin/sort"
# split()     { /usr/local/opt/coreutils/libexec/gnubin/split "$@"; } ; GNU_split="/usr/local/opt/coreutils/libexec/gnubin/split"
# stat()      { /usr/local/opt/coreutils/libexec/gnubin/stat "$@"; } ; GNU_stat="/usr/local/opt/coreutils/libexec/gnubin/stat"
# stdbuf()    { /usr/local/opt/coreutils/libexec/gnubin/stdbuf "$@"; } ; GNU_stdbuf="/usr/local/opt/coreutils/libexec/gnubin/stdbuf"
# stty()      { /usr/local/opt/coreutils/libexec/gnubin/stty "$@"; } ; GNU_stty="/usr/local/opt/coreutils/libexec/gnubin/stty"
# sum()       { /usr/local/opt/coreutils/libexec/gnubin/sum "$@"; } ; GNU_sum="/usr/local/opt/coreutils/libexec/gnubin/sum"
# sync()      { /usr/local/opt/coreutils/libexec/gnubin/sync "$@"; } ; GNU_sync="/usr/local/opt/coreutils/libexec/gnubin/sync"
# tac()       { /usr/local/opt/coreutils/libexec/gnubin/tac "$@"; } ; GNU_tac="/usr/local/opt/coreutils/libexec/gnubin/tac"
# tail()      { /usr/local/opt/coreutils/libexec/gnubin/tail "$@"; } ; GNU_tail="/usr/local/opt/coreutils/libexec/gnubin/tail"
# tee()       { /usr/local/opt/coreutils/libexec/gnubin/tee "$@"; } ; GNU_tee="/usr/local/opt/coreutils/libexec/gnubin/tee"
# test()      { /usr/local/opt/coreutils/libexec/gnubin/test "$@"; } ; GNU_test="/usr/local/opt/coreutils/libexec/gnubin/test"
# timeout()   { /usr/local/opt/coreutils/libexec/gnubin/timeout "$@"; } ; GNU_timeout="/usr/local/opt/coreutils/libexec/gnubin/timeout"
# touch()     { /usr/local/opt/coreutils/libexec/gnubin/touch "$@"; } ; GNU_touch="/usr/local/opt/coreutils/libexec/gnubin/touch"
# tr()        { /usr/local/opt/coreutils/libexec/gnubin/tr "$@"; } ; GNU_tr="/usr/local/opt/coreutils/libexec/gnubin/tr"
# true()      { /usr/local/opt/coreutils/libexec/gnubin/true "$@"; } ; GNU_true="/usr/local/opt/coreutils/libexec/gnubin/true"
# truncate()  { /usr/local/opt/coreutils/libexec/gnubin/truncate "$@"; } ; GNU_truncate="/usr/local/opt/coreutils/libexec/gnubin/truncate"
# tsort()     { /usr/local/opt/coreutils/libexec/gnubin/tsort "$@"; } ; GNU_tsort="/usr/local/opt/coreutils/libexec/gnubin/tsort"
# tty()       { /usr/local/opt/coreutils/libexec/gnubin/tty "$@"; } ; GNU_tty="/usr/local/opt/coreutils/libexec/gnubin/tty"
# uname()     { /usr/local/opt/coreutils/libexec/gnubin/uname "$@"; } ; GNU_uname="/usr/local/opt/coreutils/libexec/gnubin/uname"
# unexpand()  { /usr/local/opt/coreutils/libexec/gnubin/unexpand "$@"; } ; GNU_unexpand="/usr/local/opt/coreutils/libexec/gnubin/unexpand"
# uniq()      { /usr/local/opt/coreutils/libexec/gnubin/uniq "$@"; } ; GNU_uniq="/usr/local/opt/coreutils/libexec/gnubin/uniq"
# unlink()    { /usr/local/opt/coreutils/libexec/gnubin/unlink "$@"; } ; GNU_unlink="/usr/local/opt/coreutils/libexec/gnubin/unlink"
# uptime()    { /usr/local/opt/coreutils/libexec/gnubin/uptime "$@"; } ; GNU_uptime="/usr/local/opt/coreutils/libexec/gnubin/uptime"
# users()     { /usr/local/opt/coreutils/libexec/gnubin/users "$@"; } ; GNU_users="/usr/local/opt/coreutils/libexec/gnubin/users"
# vdir()      { /usr/local/opt/coreutils/libexec/gnubin/vdir "$@"; } ; GNU_vdir="/usr/local/opt/coreutils/libexec/gnubin/vdir"
# wc()        { /usr/local/opt/coreutils/libexec/gnubin/wc "$@"; } ; GNU_wc="/usr/local/opt/coreutils/libexec/gnubin/wc"
# who()       { /usr/local/opt/coreutils/libexec/gnubin/who "$@"; } ; GNU_who="/usr/local/opt/coreutils/libexec/gnubin/who"
# whoami()    { /usr/local/opt/coreutils/libexec/gnubin/whoami "$@"; } ; GNU_whoami="/usr/local/opt/coreutils/libexec/gnubin/whoami"
# yes()       { /usr/local/opt/coreutils/libexec/gnubin/yes "$@"; } ; GNU_yes="/usr/local/opt/coreutils/libexec/gnubin/yes"
coreutils_lib_loaded=1; ((DEBUG)) && echo "]"
return 0
