#!/bin/bash

source /opt/crankshaft/crankshaft_default_env.sh
source /opt/crankshaft/crankshaft_system_env.sh

IGN_COUNTER=0

# check gpio pin if activated
if [ $REARCAM_PIN -ne 0 ] || [ $IGNITION_PIN -ne 0 ] || [ $DAYNIGHT_PIN -ne 0 ]; then
    while true; do
        if [ $REARCAM_PIN -ne 0 ]; then
            REARCAM_GPIO=`gpio -g read $REARCAM_PIN`
            if [ $REARCAM_GPIO -ne 1 ] ; then
                if [ ! -f /tmp/rearcam_enabled ]; then
                    touch /tmp/rearcam_enabled
                    touch /tmp/blackscreen
                    PARAMS=""
                    if [ $USBCAM_USE -eq 1 ]; then
                        if [ "$USBCAM_CUSTOM_PARAMS" != "" ]; then
                            cd /opt/crankshaft/cam_overlay
                            log_echo "cam_overlay.bin - Custom param set:"
                            log_echo "cam_overlay.bin $USBCAM_CUSTOM_PARAMS &"
                            ./cam_overlay.bin -s $USBCAM_CUSTOM_PARAMS &
                        else
                            if [ $USBCAM_HFLIP -eq 1 ]; then

                                PARAMS="$PARAMS -h"
                            fi
                            if [ $USBCAM_VFLIP -eq 1 ]; then
                                PARAMS="$PARAMS -v"
                            fi
                            if [ $USBCAM_ROTATION -eq 1 ]; then
                                PARAMS="$PARAMS -R"
                            fi
                            cd /opt/crankshaft/cam_overlay
                            log_echo "cam_overlay.bin $PARAMS &"
                            ./cam_overlay.bin -s $PARAMS &
                        fi
                    else
                        /opt/crankshaft/cameracontrol.py Rearcam &
                    fi
                fi
            else
                if [ -f /tmp/rearcam_enabled ]; then
                    if [ $USBCAM_USE -eq 1 ]; then
                        sudo killall cam_overlay.bin >/dev/null 2>&1
                    else
                        /opt/crankshaft/cameracontrol.py DashcamMode &
                    fi
                    rm /tmp/rearcam_enabled >/dev/null 2>&1
                    sleep 0.5
                    rm /tmp/blackscreen >/dev/null 2>&1
                fi
            fi
        fi
        if [ $DAYNIGHT_PIN -ne 0 ]; then
            if [ ! -f /tmp/daynight_gpio ]; then
                touch /tmp/daynight_gpio
            fi
            DAYNIGHT_GPIO=`gpio -g read $DAYNIGHT_PIN`
            if [ $DAYNIGHT_GPIO -ne 1 ] ; then
                if [ ! -f /tmp/night_mode_enabled ]; then
                    touch /tmp/night_mode_enabled
                    crankshaft brightness restore &
                fi
            else
                if [ -f /tmp/night_mode_enabled ]; then
                    rm /tmp/night_mode_enabled >/dev/null 2>&1
                    crankshaft brightness restore &
                fi
            fi
        else
            if [ -f /tmp/daynight_gpio ]; then
                rm /tmp/daynight_gpio >/dev/null 2>&1
            fi
        fi
        if [ $IGNITION_PIN -ne 0 ]; then
            IGNITION_GPIO=`gpio -g read $IGNITION_PIN`
            if [ $IGNITION_GPIO -ne 0 ] ; then
                IGN_COUNTER=$((IGN_COUNTER+1))
                if [ $IGN_COUNTER -gt $IGNITION_DELAY ]; then
                    if [ ! -f /tmp/android_device ] && [ ! -f /tmp/btdevice ]; then
                        if [ ! -f /tmp/external_exit ]; then
                            touch /tmp/external_exit
                        fi
                    else
                        IGN_COUNTER=0
                    fi
                fi
            else
                IGN_COUNTER=0
            fi
        fi
        sleep 1
    done
fi

exit 0
