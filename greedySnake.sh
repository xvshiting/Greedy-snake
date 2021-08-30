#!/bin/bash
# @ Author:xvshiting 
# @e-mail: xvshiting@live.com
# ctrl+c 取消
trap 'proc_exit' EXIT INT
# 获取终端大小， 设置游戏区域
lines=`tput lines`
column=`tput cols`
left=2
right=$[column/2]
top=2
bottom=$[lines/2]
middle_col=$[(right+left)/2]
middle_row=$[(top+bottom)/2]


direction=1 #1→，-1👈🏻，2上，-2下， 通过绝对值就可以判断相矛盾的当前不可采取的方向
key_direction=0
snake_comp_char="x"
heart_comp_char="❤️"
base_speed=3
max_speed=20
global_cur_speed=$base_speed
accelerate_speed_ratio=0.5

function max(){
    if [ $1 -gt $2 ];then
        global_max_num=$1
    else
        global_max_num=$2
    fi
}

function min(){
    if [ $1 -lt $2 ];then
        global_min_num=$1
    else
        global_min_num=$2
    fi
}

function get_speed(){
    local snake_body_length=${#snake_body[@]}
    local added_speed=$((snake_body_length/4+base_speed))
    min $max_speed $added_speed
    local speed=$global_min_num
    if [ $key_direction -eq $direction ];then
        global_cur_speed=`echo "scale=4;(1/${speed})*(1-${accelerate_speed_ratio})"|bc`

    else
        global_cur_speed=`echo "scale=4;1/${speed}"|bc`
    fi;
}

#行列坐标用_拼接 方便放入数组
function get_location_rep(){
    global_local_rep_var="${1}_${2}"
}
# 解析坐标表达
function parse_location_from_rep(){
    OLD_IFS=$IFS
    IFS="_"
    array=($1)
    IFS=$OLD_IFS
    global_loc_row=${array[0]}
    global_loc_col=${array[1]}
}

get_location_rep ${middle_row} ${middle_col}
snake_head=${global_local_rep_var} #记录蛇头
snake_body=($snake_head) #蛇的整个身体

function draw_snake_part(){
    # 初始时蛇身体长是一
    tput civis
    echo -e "\e[$1;$2H${snake_comp_char}\e[0m"
}

function erase_snake_part(){
    echo -e "\e[$1;$2H\e[37m \e[0m"
}

function draw_heart(){
    tput civis
    echo -e "\e[$1;$2H\e[1;31m${heart_comp_char}\e[0m"
}
function erase_heart(){
    echo -e "\e[$1;$2H\e[37m \e[0m"
}

function is_over_itself(){
    local arr=(${snake_body[@]})
    local arr1=($(awk -v RS=' ' '!a[$1]++' <<< ${arr[@]}))
    local arrlen=${#arr[@]}
    local arrlen1=${#arr1[@]}
    if [[ $arrlen -eq $arrlen1 ]];then
        over_itself_flag=0
    else 
        over_itself_flag=1
    fi
}

function snake_move(){
    local head=${snake_body[-1]}
    local tail=${snake_body[0]}
    parse_location_from_rep $tail
    local tail_row=$global_loc_row
    local tail_col=$global_loc_col
    parse_location_from_rep $head 
    local head_row=$global_loc_row
    local head_col=$global_loc_col
    local new_head_col=$head_col
    local new_head_row=$head_row

    if [[ $key_direction -ne 0 && (${direction}*-1 -ne ${key_direction}) ]];then
                direction=$key_direction
    fi

    if [[ $direction -eq 1 || $direction -eq -1 ]];then
        new_head_col=$((head_col+direction))
    elif [[ $direction -eq 2 || $direction -eq -2 ]];then
        new_head_row=$((head_row+(direction/-2)))
    fi

    get_location_rep $new_head_row $new_head_col
    local new_head_rep=$global_local_rep_var
    draw_snake_part $new_head_row $new_head_col
    snake_body="${snake_body[@]} $new_head_rep"
    snake_body=($snake_body)

    #如果吃了❤️,运动方向涨一个，并且不erase 掉尾巴
   if [[ (${head_row} -eq ${heart_row}) && (${head_col} -eq ${heart_col}) ]];then
        echo -e "\e[1HScore: ${#snake_body[@]}" #更新分数
        rand_heart # 随机下一个❤️
    else
        erase_snake_part $tail_row $tail_col   
        local snake_body_len=${#snake_body[@]}
        snake_body="${snake_body[@]:1:snake_body_len}"
        snake_body=($snake_body)    
    fi

    #判断是否越界
    if [[ ${new_head_row} -le ${top} || ${new_head_row} -ge ${bottom} || ${new_head_col} -le ${left} || ${new_head_col} -ge ${right} ]];then
        proc_exit
    fi
    is_over_itself 
    if [[ $over_itself_flag -eq 1 ]];then 
        proc_exit
    fi

}

function rand_heart(){
    heart_row=$[RANDOM%(bottom-top)+top+1]
    heart_col=$[RANDOM%(right-left)+left+1]
    max $heart_row $((top+1))
    heart_row=$global_max_num
    min $heart_row $((bottom-1))
    heart_row=$global_min_num
    max $heart_col $((left+1))
    heart_col=$global_max_num
    min $heart_col $((right-1))
    heart_col=$global_min_num
    draw_heart $heart_row $heart_col
}

# 显示围墙 $1宽 $2长
function draw_wall(){
    #top 和 bottom画一行#
    save_property=$(stty -g)
    tput clear
    tput civis
    for x in `seq $left $right`
    do
        echo -e "\e[$top;${x}H\e[37;42m#\e[0m"
        echo -e "\e[$bottom;${x}H\e[37;42m#\e[0m"
    done
    #left 和right 画一列#
    for x in `seq $top $bottom`
    do
        echo -e "\e[${x};${left}H\e[37;42m#\e[0m"
        echo -e "\e[${x};${right}H\e[37;42m#\e[0m"
    done
}


function proc_exit(){
    tput cnorm
    stty $save_property
    echo "Game Over."
    exit
}

function get_key(){
    while :
    do
        stty -echo
        read -t 0.001 -s -n 1 key
        if [[ ${key} == "q" || ${key} == "Q" ]]
        then
            proc_exit
        elif [[ ${key} == "w" || ${key} == "W" ]];then 
                # echo "上键"
                key_direction=2
        elif [[ ${key} == "s" || ${key} == "S" ]];then
                # echo "向下"
                key_direction=-2
        elif [[ ${key} == "a" || ${key} == "A" ]];then
                # echo "向左"
                key_direction=-1
        elif [[ ${key} == "d" || ${key} == "D" ]];then
                # echo "向右"
                key_direction=1
        fi
        snake_move
        get_speed
        sleep $global_cur_speed
        key_direction=0
    done
}

draw_wall
draw_snake_part $global_loc_row $global_loc_col
rand_heart
get_speed
get_key
