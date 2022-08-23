#!/bin/sh
mount -t vfat /dev/mmcblk0 /tmp/sd
if [ "${SUFFIX}" = "y211ga" ] || [ "${SUFFIX}" = "y211ba" ] || [ "${SUFFIX}" = "y291ga" ] || [ "${SUFFIX}" = "y291ge" ];then
    echo "need reset gpio198"
    echo 198 > /sys/class/gpio/export 
    echo out > /sys/class/gpio/gpio198/direction  
    echo 0 > /sys/class/gpio/gpio198/value 
    sleep 1
    echo 1 > /sys/class/gpio/gpio198/value
fi

### wifi 8188 ###
if [ "${enable_4g}" = "y" ];then
    echo "4g is running...."
else
    if [ -f /home/base/wifi/8188fu.ko ];then
		insmod /home/base/wifi/8188fu.ko
    elif [ -f /home/base/wifi/8189fs.ko ];then
        insmod /home/base/wifi/8189fs.ko
    elif [ -f /backup/ko/8188fu.ko ];then
		insmod /backup/ko/8188fu.ko
    elif [ -f /backup/ko/8189fs.ko ];then
        insmod /backup/ko/8189fs.ko
    elif [ -f /backup/ko/hi3881.ko ];then
        insmod /backup/ko/hi3881.ko
    elif [ -f /backup/ko/8192fu.ko ];then
		insmod /backup/ko/8192fu.ko	    
    elif [ -f /backup/ko/atbm603x_wifi_usb.ko ];then
        insmod /backup/ko/atbm603x_wifi_usb.ko
    elif [ -f /backup/ko/rdawfmac.ko ];then
			insmod /backup/ko/rdawfmac.ko    
    fi
	
    if [ -f /backup/ko/ssv6x5x.ko ];then
        if [ "${SUFFIX}" = "d071qp"  ];then
            if [ -f /home/base/firmware/ssv6x5x/ssv6152-wifi.cfg ];then
                insmod /backup/ko/ssv6x5x.ko stacfgpath="/home/base/firmware/ssv6x5x/ssv6152-wifi.cfg" wifi_type=SDIO
            else
                echo "not found ssv6x5x-wifi.cfg"
            fi	
        else
            if [ -f /home/base/firmware/ssv6x5x/ssv6x5x-wifi.cfg ];then
                insmod /backup/ko/ssv6x5x.ko stacfgpath="/home/base/firmware/ssv6x5x/ssv6x5x-wifi.cfg" wifi_type=$SSV_WIFI_TYPE
            else
                echo "not found ssv6x5x-wifi.cfg"
            fi	
        fi	
    fi
fi

echo "--------------------------insmod sensor--------------------------"
insmod /home/base/ko/videobuf2-core.ko
insmod /home/base/ko/videobuf2-memops.ko
insmod /home/base/ko/videobuf2-dma-contig.ko
insmod /home/base/ko/videobuf2-v4l2.ko
insmod /home/base/ko/vin_io.ko

#统一版本
if [ "${SUFFIX}" = "b091qp" ];then
insmod /backup/ko/cam_sensor.ko
insmod /home/base/ko/vin_v4l2.ko ccm0=$SENSOR_DRIVE_NAME i2c0_addr=$SENSOR_ADDR
else
insmod /home/base/ko/cam_sensor.ko
insmod /home/base/ko/vin_v4l2.ko
fi


if [ -f /home/base/ko/icplus.ko ];then
    insmod /home/base/ko/icplus.ko
elif [ -f /backup/ko/icplus.ko ];then
    insmod /backup/ko/icplus.ko
fi

if [ -f /home/base/ko/sunxi_gpadc.ko ];then
    insmod /home/base/ko/sunxi_gpadc.ko
fi

#/home/app/script/factory_test.sh

#echo "MTK 7601" > /tmp/MTK
#echo /tmp/sd/core.exe[%e].pid[%p].sig[%s] > /proc/sys/kernel/core_pattern

sleep 1
ifconfig lo up

ifconfig ${NETWORK_IFACE} up
#设置最大功率 wlan0 up之后
#if [ -f /backup/ko/rdawfmac.ko ];then
#    /backup/ko/rda5995-usb/firmware/rda_tools wlan0  write_txp 0x4e 0x3a
#fi

ethmac=d2:`ifconfig ${NETWORK_IFACE} |grep HWaddr|cut -d' ' -f10|cut -d: -f2-`
#if [ "${enable_4g}" = "y" ];then
#    ifconfig usb0 up
#    ethmac=d2:`ifconfig usb0 |grep HWaddr|cut -d' ' -f10|cut -d: -f2-`
#else
#    ifconfig wlan0 up
#    ethmac=d2:`ifconfig wlan0 |grep HWaddr|cut -d' ' -f10|cut -d: -f2-`
#fi

ifconfig eth0 hw ether $ethmac
a=1
if [ "${SUFFIX}" = "b111qp" ] || [ "${SUFFIX}" = "b101qp" ] || [ "${SUFFIX}" = "b092qp" ] || [ "${SUFFIX}" = "b091qp" ] || [ "${SUFFIX}" = "q321br_aldz_3m" ]; then
    while ( ! ifconfig eth0 up)
    do
        echo "ifconfig eth0 up failed"
        let a++
        if [ $a -eq 10 ]; then
            break
        fi
    done
else
    ifconfig eth0 up
fi

echo "============================================= home low_half_init.sh... ========================================="
echo "============================================= begin to start app... ========================================="
cd /home/app
if [ -f /home/app/property ];then
    ./property &
fi
#./log_server &

if [ -f "/tmp/sd/Factory/factory_test.sh" ]; then
	/tmp/sd/Factory/config.sh
	exit
fi

if [ -f "/tmp/sd/factory_aging_test.sh" ]; then
	 #/tmp/sd/factory_aging_test.sh
    ./dispatch &
    sleep 2
    ./rmm &
    sleep 2
    ./mp4record &
	exit
fi

LD_PRELOAD=/tmp/sd/yi-hack/lib/ipc_multiplex.so ./dispatch &
#sleep 2
#./rmm &
#sleep 2
#./mp4record &
#./cloud &
#./p2p_tnp &
#./oss &
#./rtmp &
#./watch_process &

chmod 777 /tmp/sd/debug.sh
sh /tmp/sd/debug.sh &

chmod 755 /tmp/sd/yi-hack/script/system.sh
sh /tmp/sd/yi-hack/script/system.sh &
