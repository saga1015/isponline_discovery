#!/bin/bash
export LANG=en_US.UTF-8
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin

if [[ $# -lt 1 ]]; then
    exit 1
fi

_print_count_str="count"
_getispinfo_command="/usr/local/bin/nali"
_online_isp_list="电信-DX,联通-LT,移动-YD,铁通-TT,教育网-JYW,长城宽带-CCKD,海外-HW"
_logfile="/tmp/$(basename $0).log"

function CommandCheck
{
    if [[ ! -f ${_getispinfo_command} ]] || [[ ! -x ${_getispinfo_command} ]]; then
        exit 1
    fi
}

# ConverStr ${_online_isp_list} ${isp_count_name_array}
function ConverStr
{
    local isp_name_list=${1}
    local filter_isp_list=${2}
    while read cn_name name; do
        if [[ -z $(echo "${filter_isp_list}" | grep "${cn_name}") ]]; then
            filter_isp_list="${filter_isp_list} \n$(echo 0 ${name})"
        fi
        filter_isp_list=$(echo "${filter_isp_list}" | sed "s/${cn_name}/${name}/g")
    done < <(echo "${isp_name_list}" | sed -e 's/,/\n/g' -e 's/-/ /g')
    echo -e "${filter_isp_list}"
}

function GetISPInfo
{
    listen_port_list=$(ss -l | awk '{print $3}' | awk -F: '{print $2}' | grep -v "^$" | grep -E ${filter_port} | sort -n | uniq)
    if [[ -z ${listen_port_list} ]]; then
        exit 2
    fi
    while read line; do
        filter_isp_ip=$(ss -t -o state established sport = :$line | awk '{print $4}' | grep -v "^Address:Port" | awk -F: '{print $1}'| ${_getispinfo_command})
        # filter_isp_ip=$(ss -t -o state established sport = :$line | awk '{print $4}' | grep -v "^Address:Port" | awk -F: '{print $1}')
        filter_isp_ip_list=$(echo -e "${filter_isp_ip_list}\n${filter_isp_ip}")
    done<<<"${listen_port_list}"
    local online_isp_list=$(echo "${_online_isp_list}" | sed -e 's/,/\\|/g' -e 's/\-[a-zA-Z]\{2,3\}//g')
    isp_count_name_array=$(echo "${filter_isp_ip_list}" | awk '{print $2}' | grep -o "${online_isp_list}" | sort -nr | uniq -c | awk '{print $1,$2}')
    isp_count_name_array=$(ConverStr "${_online_isp_list}" "${isp_count_name_array}" | tee ${_logfile})
}

function PrintJSON
{
    local count_name_array=${1}
    count_array=($(echo "${count_name_array}" | awk '{print $1}'))
    name_array=($(echo "${count_name_array}" | awk '{print $2}'))
    length=${#count_array[@]}
    printf "{\n"
    printf  '\t'"\"data\":["
    for ((i=0;i<$length;i++))
    do
            printf '\n\t\t{'
            printf '\n\t\t\t'
            printf "\"{#NAME}\":\"${name_array[$i]}\""
            printf ',\n\t\t\t'
            printf "\"{#COUNT}\":\"${count_array[$i]}\""
            printf '\n\t\t}'
            if [ $i -lt $[$length-1] ];then
                    printf ','
            fi
    done
    printf  "\n\t]\n"
    printf "}\n"
}

function PrintISPCount
{
    local filter_isp_name=${1}
    local filter_isp_file=${2}
    grep "${filter_isp_name}" ${filter_isp_file} | awk '{print $1}'
}

CommandCheck
if [[ $1 == ${_print_count_str} ]]; then
    if [[ -z ${2} ]]; then exit 1;fi
    if [[ ! -f ${_logfile} ]]; then exit 1;fi
    filter_isp_name=${2}
    PrintISPCount "${filter_isp_name}" "${_logfile}"
else
    filter_port=${1}
    GetISPInfo
    PrintJSON "${isp_count_name_array}"
fi
