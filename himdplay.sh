#!/bin/bash
#
# Set test Variable
test=0
# Set version Variable $ver 
ver=0.2

for udi in $(/usr/bin/hal-find-by-capability --capability storage)
do
    device=$(hal-get-property --udi $udi --key block.device)
    vendor=$(hal-get-property --udi $udi --key storage.vendor)
    model=$(hal-get-property --udi $udi --key storage.model)
    if [[ $(hal-get-property --udi $udi --key storage.bus) = "usb" ]]
    then
        parent_udi=$(hal-find-by-property --key block.storage_device --string $udi)
        mount=$(hal-get-property --udi $parent_udi --key volume.mount_point)
        label=$(hal-get-property --udi $parent_udi --key volume.label)
        media_size=$(hal-get-property --udi $udi --key storage.removable.media_size)
        size=$(( ($media_size/(1000*1000)) ))
        about=$(printf "\nDevice: $vendor\nModel: $model\nMountpoint: $mount/\nDisk-size: ${size}MB\nVersion: ${0##*/} $ver")
fi
done
# Set Variables
OUTPUT="/tmp/output.txt"
INPUT="/tmp/picker.sh"
HIMD="himdcli $mount/"   # Check ur mount point is -->  /media/disk/
#exe=$$
muse=0
clean=0

case "$1" in
  "") ;;
  
                      # No command-line parameters,
                      # or first parameter empty.
		      # Note that ${0##*/} is ${var##pattern} param substitution.
                      # Net result is $0.

  -*) ARG=./$1;; #  If filename passed as argument ($1)
                      #+ starts with a dash,
                      #+ replace it with ./$1
                      #+ so further commands don't interpret it
                      #+ as an option.

  * ) ARG=$1;;     # Otherwise, $1.
esac

case "$2" in "" );;
*) trk=$2;;
esac

case "$3" in "" );;
*) mrl=$3;;
esac

function usage {
# If argument is -v echo version else argument is -h
if [[ $usage == 1 ]]; then
      echo ""
      echo " Version" $ver
      echo ""
   else
      echo "Usage: ${0##*/} <command>"
      echo " -v                           ## Show version "
      echo " -l                           ## to list the himd track list"
      echo " <tracknumber>                ## Plays the track where number equals the tracklist number 1-999"
      echo " -s <track-number> <file>     ## Where <tracknumber> equals a number in the tracklist and <file> is a full path /foo/bar"
      echo " -h                           ## displays this help"
fi
      
}

function about {
#DIALOG=${DIALOG=dialog}
dialog --backtitle "HIMDCLI Interface" --title "Info" --msgbox "$about" 12 50
go
}

function go {
# If no argument is given
if [ -z "$ARG" ]; then
dialog --backtitle "HIMDCLI Interface" --title "State your bussiness" --menu "What should we do:" 20 51 6 \
"1" "listen 1 by 1" \
"2" "Start saving" \
"3" "Listen multiple tracks" \
"4" "Write mp3 to himd" \
"5" "About" \
"6" "EXIT" 2>/tmp/temp
       
_return=$(cat /tmp/temp)

case $? in
  0)
    if [[ $_return = 1 ]]; then 
    ARG=./-l
    go
    elif [[ $_return = 2 ]]; then 
    ARG=./-s save=1
    go
    elif [[ $_return = 3 ]]; then 
    multisel
    elif [[ $_return = 4 ]]; then   
    menuwrite
    elif [[ $_return = 5 ]]; then
    about
    elif [[ $_return = 6 ]]; then 
    echo "" 
    echo "bye" 
    fi;;
  1)
    echo ""; echo "Cancel pressed.";;
  255)
    echo ""; echo "ESC pressed.";;
esac
# Else if argument is -l or --list run command which is in variable $list
elif [[ $ARG == "./-l" || $ARG == "./--list" ]]; then
      picked
# Else if argument is -h or --help goto function usage 
elif [[ $ARG == "./-h" || $ARG == "./--help" ]]; then
      usage
# Else if argument is -v goto function usage
elif [[ $ARG == "./-v" || $ARG == "./--version" ]]; then
# Set Variable usage to 1
      usage=1
      about
# Else if argument is -s 
elif [[ $ARG == "./-s" || $ARG == "./--save" ]]; then
# Set Variable $save to 1 
      save=1
# See is the 3rd argument is given the directory to save 
      if [ -z "$mrl" ]; then
      DIALOG=${DIALOG=dialog}
      mrl=`$DIALOG --backtitle "HIMDCLI Interface" --title "Please choose a directory to save the file" --dselect $HOME/ 14 48`

case $? in
	0)
		echo ""; go;;
	1)
		echo ""; echo "Cancel pressed."; save=0 ARG="" go;;
	255)
		echo ""; echo "Box closed."; save=0 ARG="" go;;
esac
# See if 2nd argument is given the tracknumber 
      elif [ -z "$trk" ]; then
      picked
      else
      FILENAME=$trk
      nameit
      fi
# See if the 1st argument is a number 
elif [[ $ARG = *[[:digit:]]* ]]; then
#dialog --timeout 2 --backtitle "HIMDCLI Interface" --msgbox "\nSearching Track: $ARG" 12 100
      FILENAME=$ARG
      picked
      else
# If a unknown argument is given 
echo "unknown"
fi
}

function nameit {
if [[ $FILENAME == "9999" || $FILENAME == "" ]]; then
clean=0
ARG=""
FILENAME=""
go
else
clean=1
fi
# Get the file to play
dialog --timeout 1 --backtitle "HIMDCLI Interface" --msgbox "\nSearching Track: $FILENAME" 12 100
# Trying to get the Track you choose, from the list 
track=$($HIMD tracks | grep " $FILENAME: " | sed -n 1p)
infile="/tmp/temp.txt"
echo $track > $infile
sed -i 's/\[uploadable\]//g' $infile
list=$(cat $infile | awk '{print $2, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17}' | sed -e  's/:/ /2')
title=$(cat $infile | sed -e "s/.*://;s/(.*//")
album=$(cat $infile | sed -e "s/.*(//;s/).*//;s/0//")
#artist=$(cat $infile | sed -e "s/.*3//;s/:.*//")
arr=($list)
artist="${arr[1]} ${arr[2]}"
time="${arr[0]}"
dialog --timeout 1 --backtitle "HIMDCLI Interface" --msgbox "\nSearching Track: $FILENAME\nFound: $list\nArtist: $artist\nTitle: $title\nAlbum: $album\nTrack-time: $time min" 12 100
# Dump the track in /tmp
cd /tmp
# Check file container
if [[ $track =~ "AT3+" && $test != "1" ]]; then
echo " NOT SUPPORTED YET "
picked
elif [[ $track =~ AT3 && $test != "1" ]]; then
artist=$(cat $infile | sed -e "s/.*AT3//;s/:.*//")
dialog --timeout 1 --backtitle "HIMDCLI Interface" --msgbox "\nSearching Track: $FILENAME\nFound: $list\nArtist: $artist\nTitle: $title\nAlbum: $album\nTrack-time: $time min\nCodec: $codec" 12 100
$HIMD dumpnonmp3 $FILENAME 
# Set variable $exe for file extension
codec=ATRAC3
exe=oma
save
elif [[ $track =~ MPEG && $test != "1" ]]; then
artist=$(cat $infile | sed -e "s/.*MPEG//;s/:.*//")
dialog --timeout 1 --backtitle "HIMDCLI Interface" --msgbox "\nSearching Track: $FILENAME\nFound: $list\nArtist: $artist\nTitle: $title\nAlbum: $album\nTrack-time: $time min\nCodec: $codec" 12 100
$HIMD dumpmp3 $FILENAME
# Set variable $exe for file extension
codec=MPEG
exe=mp3
save
elif [ $test == "1" ]; then
save
else
echo " It screwed up! "
fi
}

function save {
clean=1
# Set temp file 
file="/tmp/stream."$exe
# Set location for save file 
nfile=$mrl/"Convert."$exe

if [[ $test == "1" ]]; then
echo "test saving"
echo "temp stream=" $file
echo "Save Location=" $nfile
play
elif [[ $save == "1" ]]; then
dialog --timeout 2 --backtitle "HIMDCLI Interface" --msgbox "Copying: $FILENAME\nFound: $list\nArtist: $artist\nTrack-time: $time min\nCopying: $file\nTo: $nfile" 12 100
cp $file $nfile
cleanup
else
play
fi
}

function play {
clean=1
# check if the file is copied 
if [[ $test == "1" ]]; then
echo "test playing"
echo "Play file=" $file
cleanup
elif [[ -e $file ]]; then
#calculate time
min=$(echo $time | awk -F ":" '{print $1}')
tsec=$(echo $time | awk -F ":" '{print $2}')
if [ $tsec -lt 10 ]; then
tsec=$(echo $tsec | awk -F0 '{print $2}');
else
sec=$(( $min * 60 + $tsec ));
fi

# set counter to 0 
counterp=0

#mplayer -slave -quiet -nolirc -noautosub $file |
avplay -nodisp -autoexit -v 0 $file 2>/dev/null |
(
# set infinite while loop
while :

do
cat <<EOF
XXX
$counter


Now Playing $list ( $counterp sec of $sec):

Artist: $artist
Title: $title
Album: $album
Track-time: $time min
Codec: $codec



							Time Remaining $min:$rsec
							CTRL+C Skips track
XXX
EOF
# increase counter by amount of time the loop sleeps 1
(( counterp+=1 ))
(( tsec-=1 ))
if [ $tsec -eq 0 ]; then
(( min-=1 ))
(( tsec+=60 ))
else
counter=$(echo "100 / $sec * $counterp" | bc -l | awk -F. '{print $1}') # Calculating a precentage 100% devided by total seconds %sec multiplyed by the times the loop ran %counterp. the value is nn.nnnnnnn so we search with awk for " . " and print the first word found $1
[[ $counter -gt 100 ]] && break 
# delay it a specified amount of time i.e 1 sec for the loop to run 
sleep 1
if [ $tsec -lt 10 ]; then
rsec=$(echo 0$tsec);
else
rsec=$tsec
fi
fi
done
) | dialog --clear --title "File Playing" --gauge "Please wait" 20 100 $sec

  cleanup    
elif [ $save == 2 ]; then 
cleanup
else
	echo "Setting Parameters"
	file=$nfile
	save=2
        # Sleep until file does exists/is created
        for i in {3..1}; do 
        printf '\r%2d' $i
        sleep 1
        done
        printf '\n'
        play
fi 
}

function mplay {
clean=1
sed -i 's/\s\+/\n/g' $OUTPUT
FILENAME=$(cat $OUTPUT | sed -n 1p | tr -d "\"\"")
if [[ `ls -l $OUTPUT | awk '{print $5}'` -eq 0 ]]; then
#echo "file is 0 bytes"
muse=0
cleanup
else
sed -i '1d' $OUTPUT
nameit
fi;
}

function cleanup {
# Remove the file from /tmp
#if [[ $save == "2" ]]; then
#echo " The End "
if [[ $muse == 1 && $test == 0 ]]; then
        rm -f $file
        clean=0
        mplay
elif [[ $test == 1 ]]; then
        echo "Fake Removing"
	echo $INPUT $OUTPUT $file
        if [[ $muse == 1 ]]; then
        rm -f $file
        mplay
        else
	rm -f $file
	rm -f $INPUT
	rm -f $OUTPUT
	rm -f $infile
#	sleep 2
	clean=0
	ARG=""
	FILENAME=""
	go
	fi
elif [[ $save == 1 ]]; then
dialog --title "Play it now" \
--backtitle "HIMDCLI Interface" \
--yesno "Do you want to play it now?" 7 60
response=$?
case $response in
   0) echo "";
      echo "oke here we go." 
      play ;;
   1) echo ""
      echo "No More Music."; save=0 ARG="" cleanup;;
   255) echo "[ESC] key pressed."; save=0  ARG="" cleanup;;
esac
elif [[ $clean == 1 ]]; then
        #echo " Removing files" $file $INPUT $OUTPUT
        rm -f $file
        rm -f $INPUT
        rm -f $OUTPUT
        clean=0
        ARG=""
        FILENAME=""
        cleanup         

else
dialog --title "Play More" \
--backtitle "HIMDCLI Interface" \
--yesno "Do you want to play more?" 7 60

case $? in
   0) echo "oke here we go." ; FILENAME="" ARG="" go ;;
   1) echo "No More Music."; ARG=""; echo "Bye" ;;
   255) echo "[ESC] key pressed."; ARG="" go;;
esac
fi

}

function picked {
$HIMD tracks > $OUTPUT
sed -i 's/^\w*\ *//' $OUTPUT
sed -i 's/:/  "/' $OUTPUT
sed -i 's/$/" \\/' $OUTPUT
sed -i 's/\[uploadable\]//g' $OUTPUT
cp $OUTPUT $INPUT
list="$(cat $INPUT)"
sed -i '1i\ #!/bin/bash/\ndialog --title "Search - Selection" --backtitle "HIMDCLI Interface" --menu "Choose track " 23 110 18 \\' $INPUT
sed -i '$ a\9999 "END OF LIST" 2>/tmp/output.txt' $INPUT
chmod +x $INPUT

if [[ $FILENAME != "" ]]; then
nameit
else
/tmp/picker.sh

respose=$?
FILENAME=$(<$OUTPUT)
case $respose in
  0) 	
  	ARG=$FILENAME
  	go;;
  1) 
        echo ""
  	echo "Cancel pressed."; ARG="" go;;
  255) 
   echo ""
   echo "[ESC] key pressed."; ARG="" go;;
esac
fi
}

function multisel {
muse="1"
$HIMD tracks > $OUTPUT
sed -i 's/^\w*\ *//' $OUTPUT  # Strip first space or word
sed -i 's/:/  "/' $OUTPUT  # Replace first : with a [space][space]"
sed -i 's/$/" off \\/' $OUTPUT  # Places this string to the end of each line "[space]off[space]\  
sed -i 's/\[uploadable\]//g' $OUTPUT  # Strips the value [uploadable] found anywhere
cp $OUTPUT $INPUT
list="$(cat $INPUT)"
sed -i '1i\ #!/bin/bash/\ndialog --backtitle "HIMDCLI Interface" --title "Multi Search Selection" --clear --checklist "Choose multiple songs " 23 110 18 \\' $INPUT
sed -i '$ a\9999 "END OF FILE" off 2>/tmp/output.txt ' $INPUT
chmod +x $INPUT
$INPUT
retval=$?

FILENAME=$(<$OUTPUT)
case $retval in
  0)
    mplay;;
  1)
    echo "Cancel pressed."; go;;
  255)
    echo "ESC pressed."; go;;
esac
}

function menuwrite {
# If no argument is given
DIALOG=${DIALOG=dialog}

$DIALOG --backtitle "HIMDCLI Interface" --title "Writing Menu" --menu "What should we do:" 20 51 6 \
"1" "Write songs 1 by 1" \
"2" "#Multi select" \
"3" "Change source directory" \
"4" "About" \
"5" "Back" 2>temp
       
_return=$(cat temp)

case $? in
  0)
    if [[ $_return = 1 ]]; then 
    dowrite
    elif [[ $_return = 2 ]]; then 
    go
    elif [[ $_return = 3 ]]; then 
    change=1
    dowrite
    elif [[ $_return = 4 ]]; then
    about
    elif [[ $_return = 5 ]]; then 
    go 
    else 
    dialog --backtitle "HIMDCLI Interface" --msgbox "\n\n USE THE OPTION 5 BACK" 10 60
    menuwrite
    fi;;
  1)
    echo ""; echo "Cancel pressed." ;;
  255)
    echo ""; echo "ESC pressed.";;
esac

}

function dowrite {
if [[ $dmrl == "" || $change == 1 ]]; then
dialog --backtitle "HIMDCLI Interface" --title "From What Directory" --dselect ~/ 10 60 2>temp
dmrl=`cat temp`
   if [ $change == 1 ]; then
   change=0
   menuwrite
      else
      dowrite
   fi
else
dialog --backtitle "HIMDCLI Interface" --title "Which MP3 to Store on HiMD" --fselect $dmrl 10 60 2>temp

respose=$?
umrl=`cat temp`
#umrl=$(<$temp)
case $respose in 
        0)
		start=$($HIMD tracks | cat -n | awk 'END{print $1}')
		#avconv -i "$umrl" -ab 128000 -acodec ac3 -y "$umrl.ac3"
		$HIMD writemp3 "$umrl"
		stop=$($HIMD tracks | cat -n | awk 'END{print $1}')

		if [[ $(($start+1)) ==  $stop ]]; then
		dialog --timeout 10 --backtitle "HIMDCLI Interface" --title "File Copied" --msgbox "Transfer of:\n$umrl \nCompleted" 10 40
		menuwrite
		else
		echo "Error"
        sleep 5
		change=1
		menuwrite
		fi;;
	1)
		echo ""; echo "Cancel pressed."; menuwrite;;
	255)
		echo ""; echo "Box closed."; menuwrite;;
esac
fi
}

go
