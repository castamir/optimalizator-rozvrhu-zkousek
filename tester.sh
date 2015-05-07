#!/bin/bash

pocet_procesu=1
max_penalizace=100
min_penalizace=0
timeout=20  # 20* 30sec = 600sec = 10min

printf "Pocet procesu [$pocet_procesu]: " ; read -r p ; p=`echo $p | grep "^[1-9]\+[0-9]*$"`
printf "Minimalni penalizace [$min_penalizace]: " ; read -r mip ; mip=`echo $mip | grep "^[1-9]\+[0-9]*$"`
#printf "Maximalni (rozsah) penalizace [$max_penalizace]: " ; read -r mp ; mp=`echo $mp | grep "^[1-9]\+[0-9]*$"`
mp=$(($p-1))

# oprava chybnych vstupu nebo nastaveni vychozich hodnot
if [ "$p" = "" ]; then
	p=$pocet_procesu
fi
if [ "$mip" = "" ]; then
	mip=$min_penalizace
fi
if [ "$mp" = "" ]; then
	mp=$max_penalizace
fi

# vytvoreni adresarove struktury
NOW=$(date +"%m-%d-%Y--%H-%M")
echo "start: $NOW"

min=$mip
for ((n=1;n<=$p;n++))
do
	dirname=test-$NOW/proces-$n
	mkdir -p $dirname
	cp src/* $dirname
	cd $dirname
	max=$(($mp * $n / $p + $mip))
	sed s/set_penale_limits\([0-9]*,[0-9]*\)/set_penale_limits\($min,$max\)/g dpdata.pl > dpdata2.pl
	mv dpdata2.pl dpdata.pl
	make >/dev/null
	./diplomka > output.txt &
	pid=$!
	pids[$n]=$pid
	pidsp[$pid]=$n
	min=$(($max+1))
	cd ../..
	sleep 5
done
echo "vsechny procesy spusteny"


# uklid procesu
while [[ ( $timeout -gt "0" ) ]]; do
	running=0
	failed=0
	for pid in ${pids[*]}
	do
		if [[ ( -d /proc/$pid ) && ( -z `grep zombie /proc/$pid/status` ) ]]; then
			running=$(($running+1))
		else
			proces=${pidsp[$pid]}
			dirname=test-$NOW/proces-$proces
			status=`tail -1 $dirname/output.txt | grep -c "Celkova penalizace"`
			if [ $status -eq "1" ]; then
				echo proces $proces byl dokoncen
			else
				failed=$(($failed+1))
			fi
		fi
	done
	if [ $failed -eq $p ]; then
		echo "Tester skoncil neuspesne - rozvrh nenalezen"
		timeout=0
	elif [ $running -eq $p ]; then
		sleep 30
		timeout=$(($timeout-1))
	else
		echo "Vyprsel casovy limit - rozvrh nenalezen"
		timeout=0
	fi
done

for pid in ${pids[*]}
do
	kill -9 $pid 2>/dev/null
done

