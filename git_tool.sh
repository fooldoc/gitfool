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
function isDev
{
	branch=$(git branch|grep '*'|awk '{print $2}')
	if [ "$branch" != "dev" ];then
		error "当前非dev分支"
		exit
	fi
}

# 更新文件
function update
{
	isDev
	exec git pull origin dev
}

# 提交文件
function checkCommit
{
	info=$(commitMsg "$@")
	if [ "$info" = "" ];then
		error "请填写提交描述~"
		exit
	elif echo $info| grep '#[0-9]\{1,9\}' > /dev/null; then
		return
	else
		error "提交描述里要保含分支号哦~"
		exit
	fi
}

# 提交内容
function commitMsg
{
	if [ "$#" = "0" ];then
		return
	fi
	param=''
	while true
	do
		if [ "$1" = "-m" ];then
			param="$2"
			break;
		fi
		shift
		if [ "$#" = "0" ];then
			break
		fi
	done
	echo $param
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
	isDev
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
    params=$(echo "$@")
    echo $params
	if [ "$params" = "" ];then
    	error "请填写回滚文件"
        exit
    fi
    exec git -c core.quotepath=false -c log.showSignature=false rm --cached -f -- $params
    exec git -c core.quotepath=false -c log.showSignature=false checkout HEAD -- $params
}

# 恢复数据
function sync
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
	commit)
		update
		cmd=$(echo checkCommit $params)
		eval $cmd
		cmd=$(echo git commit $params)
		eval $cmd
		exec git push origin dev
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
	sync)
		cmd=$(echo sync $params)
		eval $cmd
		;;
	revert)
		cmd=$(echo revert $params)
		eval $cmd
		;;
	help)
		echo "Usage: $0 {update|commit|reset|checkout|log|revert}"
		echo ""
		printf "%5s %-10s %s\n" '' update 获取最新内容到本地分支
		printf "%5s %-10s %s\n" '' commit 记录变更到版本库并更新远程引用和相关的对象
		printf "%5s %-10s %s\n" '' reset  撤销提交记录到指定状态
		printf "%5s %-10s %s\n" '' checkout 检出一个分支或路径到工作区
		printf "%5s %-10s %s\n" '' log 显示提交日志
		printf "%5s %-10s %s\n" '' sync 恢复数据为最新版
		printf "%5s %-10s %s\n" '' revert 恢复某个文件的最新代码
		echo ""
		printf "$GREEN"
		echo "以下为GIT默认用法"
		printf "$OFF"
		git help
		exit 1;;
	*)
		git $action "$@"
esac
