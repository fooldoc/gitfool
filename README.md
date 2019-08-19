# gitfool

## 软连接
## sudo ln -s gitfool.sh /usr/local/bin/gitfool

## gitfool-(git傻瓜工具)

update   获取最新内容到本地分支 示例：gitfool update 
reset  撤销提交记录到指定状态  示例：gitfool reset 
resetAdd  撤销add某个文件的状态(不会删除本地记录)  示例：gitfool resetAdd file
checkout 检出一个分支或路径到工作区 示例：gitfool checkout 
log 显示提交日志可以看到远程分支的位置还有彩色 示例：gitfool log 
revertAll 恢复数据为远程最新版 示例：gitfool revertAll .  
revert 恢复某个文件为远程最新版代码 示例：gitfool revert aa  

###另外git其他命令可以统一用这个脚本使用比如:
gitfool status 与git status效果一样
