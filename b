#!/bin/bash
prompt="Select usb to serial port:"
options=( $(find /dev/*cu.usbserial* | xargs -0) )

if (( ${#options[@]} == 1 )) ; then
    opt1=$options
    echo "Using $options"
else
    PS3="$prompt "
    echo ""
    select opt1 in "${options[@]}" "Quit" ; do 
        if (( REPLY == 1 + ${#options[@]} )) ; then
            exit

        elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
            echo  "Selected usb to serial: $opt1"
            break

        else
            echo "Invalid option. Try another one."
        fi
    done
fi

prompt="Select hex file:"
options=( $(find *.hex | xargs -0) )

PS3="$prompt "
echo ""
select opt2 in "${options[@]}" "Quit" ; do 
    if (( REPLY == 1 + ${#options[@]} )) ; then
        exit

    elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo  "Selected hex file: $opt2"
        ./pdex -p$opt1 $opt2
        break

    else
        echo "Invalid option. Try another one."
    fi
done

echo ""
