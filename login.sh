#!/bin/bash

# @auth 后三排
# @site https://housanpai.com

# 登陆信息配置
# 每个登陆信息为一个数组
# 第一个登陆信息的变量名称必须是「LOGIN_USER_1」，多条登陆信息时需要是 1 的连续整数 
LOGIN_USER_1=(
    'root' # 用户名
    '192.168.171.128' # 主机
    '8686' # 端口
    '' # 密码
    '/Users/admin/.ssh/id_rsa' # 密钥文件的绝对路径
    'key' # 登陆方式。key：密钥方式；pwd：密码方式
    '公司开发服务器' # 备注信息
)

LOGIN_USER_2=(
    'root'
    '192.168.171.120'
    '22'
    '123456'
    ''
    'pwd'
    '本地虚拟机 公司环境'
)

LOGIN_USER_3=(
    'root'
    '192.168.171.129'
    '22'
    '123456'
    ''
    'pwd'
    '本地虚拟机 个人环境'
)

LOGIN_TAG_START=1

login_user_configure_check() {

local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

# 第一个登陆配置数组不存在
if [ ! $(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}}) ]
then
    echo '错误！登陆数组：LOGIN_USER_'${LOCAL_LOGIN_TAG_START}' 不存在'
    exit 1
fi

while [ $(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}}) ]
do

    # 获得配置数组的元素总数
    local length=$(eval echo "\${#LOGIN_USER_${LOCAL_LOGIN_TAG_START}[*]}")

    if [ 7 -ne ${length} ]
    then
        echo 'LOGIN_USER_'${LOCAL_LOGIN_TAG_START}' 配置项必须是 7 项。脚本停止检查、终止执行、退出！'
        exit 1
    fi


    if [[ 'pwd' != "$(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}[5]})" ]] && [[ 'key' != "$(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}[5]})" ]]
    then
        echo 'LOGIN_USER_'${LOCAL_LOGIN_TAG_START}' 配置登陆方式错误，脚本停止检查、终止执行、退出！'
        exit 1
    fi

    if [[ 'key' == "$(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}[5]})" ]] && [[ ! "$(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}[4]})" ]]
    then
        echo 'LOGIN_USER_'${LOCAL_LOGIN_TAG_START}' 配置为密钥登陆，但是没有配置密钥文件，脚本停止检查、终止执行、退出！'
        exit 1
    fi

    for i in ` seq 0 "$((length-1))" `
    do
        if [ 3 -eq "${i}" ] || [ 4 -eq "${i}" ]
        then
            continue
        fi

        if [ ! "$(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}[${i}]})" ]
        then
            local LOGIN_USER_CONFIGURE_NUM=$((i+1))
            echo 'LOGIN_USER_'${LOCAL_LOGIN_TAG_START}' 第 '${LOGIN_USER_CONFIGURE_NUM}' 项配置不能为空'
            exit 1
        fi

    done

    ((LOCAL_LOGIN_TAG_START++))

done

}


# 调用登陆用户配置数组的检查
login_user_configure_check

screen_echo() {

printf "%-7s | " '序号'
printf "%-30s\n" '说明'

local LOCAL_LOGIN_TAG_START=${LOGIN_TAG_START}

while [ $(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}})  ]
do

    printf "\e[31m %-5s\e[0m| " "${LOCAL_LOGIN_TAG_START}" # 颜色为红色
    printf "%-30s\n" "$(eval echo \${LOGIN_USER_${LOCAL_LOGIN_TAG_START}[6]})"

    # 服务器总数 
    USER_SUM=${LOCAL_LOGIN_TAG_START}

    ((LOCAL_LOGIN_TAG_START++))

done

}

# 调用屏幕输出信息函数
screen_echo

while true
do

    # 让使用者选择所需要登陆服务器的所属序号
    read -p '请输入要登陆的服务器所属序号: ' LOGIN_NUM

    if [[ "${LOGIN_NUM}" =~ [^0-9]+ ]]
    then
        echo '序号是数字'
        continue
    fi

    if [ ! ${LOGIN_NUM} ]
    then
        echo '请输入序号'
        continue
    fi

    if [[ "${LOGIN_NUM}" =~ ^0 ]]
    then
        echo '序号不能以 0 开头'
        continue
    fi

    # 用户选择的序号 > 服务器总数、用户选择的序号 < 服务器总数。则提示错误并且重新循环
    if [ ${LOGIN_NUM} -gt ${USER_SUM} ] || [ ${LOGIN_NUM} -lt ${LOGIN_TAG_START} ]
    then
        echo '请输入存在的序号'
        continue
    fi

    break

done

# 登陆的函数

login_exec () {

# 当登陆方式是密码时
if [ 'pwd' == "$(eval echo \${LOGIN_USER_${LOGIN_NUM}[5]})" ]
then
    local mima=$(eval echo \${LOGIN_USER_${LOGIN_NUM}[3]})

    # 密码长度非 0 时
    if [ -n ${mima} ]
    then

        # 对 } 转义
        local mima=${mima//\}/\\\}}

        # 对 ; 转义
        local mima=${mima//\;/\\;}
	
	# 对 [ 转义
	local mima=${mima//\[/\\[}

    fi
fi

# spawn -noecho 不显示登陆信息
# 当登陆后出现「*yes/no*」是，回应「yes」
# ConnectTimeout 连接时超时时间；ConnectionAttempts 连接失败时的重试次数；StrictHostKeyChecking 不提示认证；ServerAliveInterval 客户端每多少秒向服务器发送请求；ServerAliveCountMax 客户端向服务器发送请求失败时的重试次数
# 「exp_continue」继续执行下面的匹配
# 「interact」留在远程终端上面。如果不写此语句，自动退出服务器
expect -c "
switch $(eval echo \${LOGIN_USER_${LOGIN_NUM}[5]}) {
	"pwd" { 

		spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 $(eval echo \${LOGIN_USER_${LOGIN_NUM}[0]})@$(eval echo \${LOGIN_USER_${LOGIN_NUM}[1]}) -p $(eval echo \${LOGIN_USER_${LOGIN_NUM}[2]})
        expect { 
            *yes/no* {
                send yes\r
                exp_continue
            }
            *denied* {
                exit
            }
            *password* {
                send ${mima}\r
            }
        }
		interact
	}
	"key" { 
		spawn -noecho ssh -o ConnectTimeout=15 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -i $(eval echo \${LOGIN_USER_${LOGIN_NUM}[4]}) $(eval echo \${LOGIN_USER_${LOGIN_NUM}[0]})@$(eval echo \${LOGIN_USER_${LOGIN_NUM}[1]}) -p $(eval echo \${LOGIN_USER_${LOGIN_NUM}[2]})
		interact
	}
	default {
		puts "error"
	}
}

";

return 0;

}

# 调用登陆执行函数
login_exec

