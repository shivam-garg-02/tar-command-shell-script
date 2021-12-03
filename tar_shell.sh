#! /bin/bash
echo "Enter the command"
read command
read -r -a parsed_cmds <<< "$command" 

cmd_size=${#parsed_cmds[@]} 

flags=${parsed_cmds[1]}

num_flags=${#parsed_cmds[1]}

if [ ${flags:0:1} = "-" ]
then
    num_flags=$(($num_flags-1))
    flags=${flags:1:$num_flags}
fi

tar_file=${parsed_cmds[2]}


if [ "${flags:0:1}" = "c" ] || [ "${flags:0:1}" = "r" ]
then
    files=()
    for i in $(seq 3 $(($cmd_size-1)))
    do
        for file in ${parsed_cmds[i]}
        do
            files+=($file)
        done
    done
    num_files=${#files[@]}
    num_lines=()
    for i in $(seq 0 $((num_files-1)))
    do
        num_lines+=($(wc -l < ${files[i]}))
    done

    for i in $(seq 0 $(($num_files-1)))
    do
        if [ "${flags:0:1}" = "c" ] && [ $i -eq 0 ]
        then
            printf "${files[i]##*/} ${num_lines[i]}\n$(ls -l ${files[i]})\n" > $tar_file
        else
            printf "${files[i]##*/} ${num_lines[i]}\n$(ls -l ${files[i]})\n" >> $tar_file
        fi
        cat ${files[i]} >> $tar_file
        printf "\n" >> $tar_file

        if [ "${flags:1:1}" = "v" ]
        then
            echo ${files[i]##*/}
        fi
    done
fi

files=()
num_lines=()
metadata=()
if [ "${flags:0:1}" = "t" ] || [ "${flags:0:1}" = "x" ]
then
    i=1
    yes=1
    yes2=2
    k=0
    while IFS= read -r line
    do
        if [ $i -eq $yes ]
        then
            j=1
            for word in $line
            do
                if [ $j -eq 1 ]
                then
                    files+=($word)
                else
                    num_lines+=($word)
                    yes=$(($yes+$word))
                    yes=$(($yes+3))
                fi
                j=$(($j+1))
            done
        fi
        if [ $i -eq $yes2 ]
        then
            metadata+=("$line")
            yes2=$(($yes2+${num_lines[k]}))
            yes2=$(($yes2+3))
            k=$(($k+1))
        fi
        i=$(($i+1))
    done < $tar_file
fi 

num_files=${#files[@]}

if [ "${flags:0:1}" = "t" ]
then 
    for i in $(seq 0 $(($num_files-1)))
    do
        if [ "${flags:1:1}" = "v" ]
        then
            echo ${metadata[i]}
        else
            echo ${files[i]}
        fi
    done
fi

if [ "${flags:0:1}" = "x" ]
then 
    total_line=$(wc -l < $tar_file)
    i=3
    for j in $(seq 0 $(($num_files-1)))
    do
        temp=$((${num_lines[j]}))
        temp=$(($temp+$i))
        sed -n ''$i','$temp' p' $tar_file > ${files[j]}
        i=$(($i+${num_lines[j]}))
        i=$(($i+3))
    done
    if [ "${flags:1:1}" = "v" ]
    then
        for j in $(seq 0 $(($num_files-1)))
        do
            echo ${files[j]}
        done
    fi
fi