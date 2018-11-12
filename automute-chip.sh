#!/bin/bash

sudo sh -c 'echo 1020 > /sys/class/gpio/export'
sudo sh -c 'echo out > /sys/class/gpio/gpio1020/direction'
sudo sh -c 'echo 0 > /sys/class/gpio/gpio1020/value'

prev=$(cat /proc/asound/card*/pcm*/sub*/status | grep "RUNNING" >/dev/null)$?
while :;do
        status=$(cat /proc/asound/card*/pcm*/sub*/status | grep "RUNNING" >/dev/null)$?
        if [ $status -ne $prev ];then
                prev=$status
                if [ $status -eq 1 ];then
                        #Schalte Anlage aus
                        sudo sh -c 'echo 1 > /sys/class/gpio/gpio1020/value'
                else
                        #Schalte Anlage ein
                        sudo sh -c 'echo 0 > /sys/class/gpio/gpio1020/value'
                fi
        fi
       sleep 0.5
done
