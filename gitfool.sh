#!/bin/bash
set -e -u

# 操作
action=${1:-'help'}

# colors
unset OFF GREEN RED
OFF='\e[1;0m'
GREEN='\e[1;32m'
RED='\e[1;31m'
readonly OFF GREEN RED

function error
{
	printf "$RED"
	echo $@
	printf "$OFF"
}

# 更新文件
function update
{
	exec git pull origin dev
}

function update2
{
	stash=$(git status -s |wc -l)
	if [ "$stash" != "0" ]; then
		exec git stash
	fi
	exec git fetch origin dev
	exec git rebase origin/dev
	if [ "$stash" != "0" ];then
		exec git stash pop
	fi
}


# 执行命令
function exec
{
	echo "$@"
	$@
}

# 还原版本
function reset
{
	echo "以下为最近10次提交历史"
	git log -n 10 --pretty=format:"%h \"%s\" (%cn) %C(yellow)%d%Creset" | while read line
	do
		echo $line
	done
	read -p "请输入要还原到哪次提交(第一列): " comId
	realComId=''
	for line in $(git log -n 10 --pretty=format:"%h")
	do
		if [ "$line" = "$comId" ];then
			realComId=$line
			break
		fi
	done
	if [ "$realComId" = "" ]; then
		error "没有找到对应的提交ID，请重新选择"
		reset
	else
		read -p "要保留最新的文件内容吗？(Y): " file
		if [ "$file" = "Y" -o "$file" = "y" -o "$file" = "" ];then
			exec git reset $realComId
		else
			exec git reset --hard $realComId
		fi
	fi
}

# 查看历史
function log
{
	params=$(echo "$@"|sed s/\"/\\\"/g)
	exec git log --graph --pretty=format:"%Cred%h%Creset%C(yellow)%d%Creset%nAuthor:%cn<%ce>%nDate:%cd%Cblue(%cr)%Creset%n%nSubject:%Cgreen%s%Creset%n" --name-status "$params"
}

# 切换分支
function checkout
{
	if [ "$#" = "1" -a "$1" != "--" ];then
		new="1"
		for line in $(git branch)
		do
			if [ "$line" = "$1" ];then
				new="0"
			fi
		done
		if [ "$new" = "1" ];then
			exec git checkout -b $1 origin/dev
		else
			exec git checkout $1
		fi
	else
		params=$(echo "$@"|sed s/\"/\\\"/g)
		exec git checkout "$params"
	fi
}

# 回滚到远端最新文件
function revert
{
    git status -s| while read line
   	do
   		echo $line
   	done
    params=$(echo "$@")
	if [ "$params" = "" ];then
    	error "请填写回滚文件"
        exit
    fi
    exec rm -rf $params
    exec git -c core.quotepath=false -c log.showSignature=false rm --cached -f -- $params
    exec git -c core.quotepath=false -c log.showSignature=false checkout HEAD -- $params
}

# 恢复数据
function revertAll
{
	git status -s $@|awk '{print $2}'  | while read line 
	do
		exec rm -f $line
	done
	exec git rm --cached -f -r -- $@
	exec git checkout HEAD -- $@
}

uid=`id -u`
if [ "$uid" = "0" ];then
	error "不能使用root~"
	exit
fi

ver=$(git --version|awk '{print $3}'|awk -F '.' '{print $1}')
if [ "$ver" = "1" ];then
	error "请升级git到2.0以上版本(https://git-scm.com/download/)"
	exit
fi

# 重构参数
params=''
if [ "$#" != "0" ];then
	shift
	for i in "$@";do
		tmp=$(echo "$i"|sed s/\"/\\\\\"/g)
		params=$params" \"$tmp\""
	done
fi
echo "git $action $params" >> /tmp/c
case $action in
	update)
		update
		;;
	reset)
		reset
		;;
	checkout)
		cmd=$(echo checkout $params)
		eval $cmd
		;;
	log)
		cmd=$(echo log $params)
		eval $cmd
		;;
	revertAll)
		cmd=$(echo revertAll $params)
		eval $cmd
		;;
	revert)
		cmd=$(echo revert $params)
		eval $cmd
		;;
	help)
		echo "以下为GIT默认用法"
		printf "$OFF"
		git help
		echo "Usage: $0 {update|reset|checkout|log|revert|revertAll}"
		printf "$GREEN"
		echo ""
		printf "%5s %-10s %s\n" '' "update  获取最新内容到本地分支 示例：gitfool update"
		printf "%5s %-10s %s\n" '' "reset  撤销提交记录到指定状态  示例：gitfool reset"
		printf "%5s %-10s %s\n" '' "checkout 检出一个分支或路径到工作区 示例：gitfool checkout"
		printf "%5s %-10s %s\n" '' "log 显示提交日志 示例：gitfool log"
		printf "%5s %-10s %s\n" '' "revertAll 恢复数据为远程最新版 示例：gitfool revertAll . "
		printf "%5s %-10s %s\n" '' "revert 恢复某个文件为远程最新版代码 示例：gitfool revert aa "
		echo ""
		exit 1;;
	*)
		git $action "$@"
esac
