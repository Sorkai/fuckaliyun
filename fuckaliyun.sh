#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
###export###
export PATH
export SH_VER=0.1.0
export SH_URL="https://www.wangkai88.com/archives/201/"
export GITHUB_URL="https://github.com/wangkai6688/fuckaliyun"
export Supported_system="CentOS(32bit/64bit)"
export WK_RE_VER="测试版"
#======================================================================
#   System Required: 见上方export Supported_system
#   Description:  A tool to auto delete the Aliyun Security Service on Linux
#   Author : kai233
#======================================================================
  echo ""
  echo "+------------------------------------------------------------+"
  echo "| A tool to auto delete the Aliyun Security Service on Linux |"
  echo "|本脚本为暴力删除阿里云内置安全组件工具，使用软硬兼施的方法进行卸载|"
  echo "|说明地址: ${SH_URL} "
  echo "|当前为 ${WK_RE_VER}                                              |"
  echo "|GitHub项目地址 ${GITHUB_URL}"
  echo "+------------------------------------------------------------+"
  echo ""

#set OS=OK
Enforce_run(){
OS=OK
}

# Choose whether to force operation
C_W_T_F_O(){
	echo && read -e -p "强制运行请输入1，其余值退出！" num
		case "$num" in
		1)
		Enforce_run
		;;
		*)
		echo -e "当前版本: ${SH_VER}"
        echo -e "暂时只确定支持${Supported_system}系统，其他系统未经测试，如一定要使用请强制启用!(其实理论通用，就是没测试~~)"
		echo -e "或在 ${SH_URL} 检查是否存在更新版本"
		exit 1
		;;
	esac
}

# Check OS
CheckOS(){
	if  grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
    OS=OK
    else
		echo "当前版本: ${SH_VER}"
        echo "暂时只确定支持${Supported_system}系统，其他系统未经测试，如一定要使用请强制启用!(其实理论通用，就是没测试~~)"
		echo "或在 ${SH_URL} 检查是否存在更新版本"
		C_W_T_F_O
    fi
}

# Check ROOT
if [ `id -u` -eq 0 ];then
	echo ":)"
	CheckOS;
else
	echo "请使用root用户运行本脚本"
	exit 1
fi

#check linux Gentoo os
var=`lsb_release -a | grep Gentoo`
if [ -z "${var}" ]; then
	var=`cat /etc/issue | grep Gentoo`
fi

if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
	LINUX_RELEASE="GENTOO"
else
	LINUX_RELEASE="OTHER"
fi

#运行阿里云官方卸载程序↓(此行以下，至下一标识)

stop_aegis(){
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 aegis_update >/dev/null 2>&1
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 AliYunDun >/dev/null 2>&1
	killall -9 AliHids >/dev/null 2>&1
	killall -9 AliHips >/dev/null 2>&1
	killall -9 AliYunDunUpdate >/dev/null 2>&1

    if [ -d /usr/local/aegis/aegis_debug ];then
        if [ -d /usr/local/aegis/aegis_debug/tracing/instances/aegis ];then
            echo > /usr/local/aegis/aegis_debug/tracing/instances/aegis/set_event
        else
            echo > /usr/local/aegis/aegis_debug/tracing/set_event
        fi
    fi

    if [ -d /sys/kernel/debug ];then
        if [ -d /sys/kernel/debug/tracing/instances/aegis ];then
            echo > /sys/kernel/debug/tracing/instances/aegis/set_event
        else
            echo > /sys/kernel/debug/tracing/set_event
        fi
    fi

    printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
}

remove_aegis(){
if [ -d /usr/local/aegis ];then
    rm -rf /usr/local/aegis/aegis_client
    rm -rf /usr/local/aegis/aegis_update
	rm -rf /usr/local/aegis/alihids
fi

if [ -d /usr/local/aegis/aegis_debug ];then
    umount /usr/local/aegis/aegis_debug
    rm -rf /usr/local/aegis/aegis_debug
fi
}

uninstall_service() {

   if [ -f "/etc/init.d/aegis" ]; then
		/etc/init.d/aegis stop  >/dev/null 2>&1
		rm -f /etc/init.d/aegis
   fi

	if [ $LINUX_RELEASE = "GENTOO" ]; then
		rc-update del aegis default 2>/dev/null
		if [ -f "/etc/runlevels/default/aegis" ]; then
			rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
		fi
    elif [ -f /etc/init.d/aegis ]; then
         /etc/init.d/aegis  uninstall
	    for ((var=2; var<=5; var++)) do
			if [ -d "/etc/rc${var}.d/" ];then
				 rm -f "/etc/rc${var}.d/S80aegis"
		    elif [ -d "/etc/rc.d/rc${var}.d" ];then
				rm -f "/etc/rc.d/rc${var}.d/S80aegis"
			fi
		done
    fi

}

stop_quartz(){
	killall -9 aegis_quartz >/dev/null 2>&1
        printf "%-40s %40s\n" "Stopping quartz" "[  OK  ]"
}

remove_quartz(){
if [ -d /usr/local/aegis ];then
	rm -rf /usr/local/aegis/aegis_quartz
fi
}

#官方卸载方法完毕↑
#下方继续强力清除

#停止并删除安骑士(服务)
fuck_aegis_service(){
service aegis stop
chkconfig --del aegis
}

#停止并删除云监控Go语言版本插件
fuck_cloudmonitor_CmsGoAgent(){
/usr/local/cloudmonitor/CmsGoAgent.linux-${ARCH} stop && \
/usr/local/cloudmonitor/CmsGoAgent.linux-${ARCH} uninstall && \
rm -rf /usr/local/cloudmonitor
}

#停止并删除云监控java语言版本插件
fuck_cloudmonitor_JavaAgent(){
/usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh stop
/usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh remove && \
rm -rf /usr/local/cloudmonitor
}

#快速二次清理(将执行两遍，不要问，问就是我怕~[笑哭])
fuck_all(){
systemctl stop aliyun.service
pkill aliyun-service
pkill AliYunDun
pkill agetty
pkill AliYunDunUpdate
rm -rf /etc/init.d/aegis
rm -rf /etc/init.d/agentwatch
rm -rf /etc/systemd/system/aliyun.service
rm -rf /usr/sbin/aliyun_installer
rm -rf /usr/sbin/aliyun-service
rm -rf /usr/sbin/aliyun-service.backup
rm -rf /usr/sbin/agetty
rm -rf /usr/local/aegis
rm -rf /usr/local/share/aliyun-assist
rm -rf /usr/local/cloudmonitor
}

#Main Program
if OS=OK ;then
	systemctl daemon-reload
	stop_aegis
	remove_aegis
	uninstall_service
	stop_quartz
	remove_quartz
	echo "官方清理完成"
	echo "开始强力清理"
	fuck_aegis_service
	fuck_cloudmonitor_CmsGoAgent
	fuck_cloudmonitor_JavaAgent
	fuck_all
	echo "强力清理完成"
	fuck_all
	echo "二次强删执行完毕"
	echo "工具已全部运行完毕，理论应该清理干净了"
	echo "请重启服务器来解决残留进程！！！！！！！！！"
	echo "后续可能会增加防火墙屏蔽IP的功能，但我个人感觉没有必要"
	echo "欢迎到 ${SH_URL} 下给我留言呢 :)"
else
	echo -e "E:??????????????????"
	echo "这个错误真是奇怪的呢，请到 ${SH_URL} 给我留言吧~"
	exit 1
fi
