#!/bin/bash

echo "Starting YouTube_Encode.sh"

# Print blank lines
yes '' | sed 2q

# Read in Variables
VARS=`cat /mnt/SSD/Scripts/GitHub/YouTube-to-Plex/credentials.txt`
WEBHOOK_URL=$(echo "$VARS" | cut -d, -f1)
DOWNLOAD_DIR=$(echo "$VARS" | cut -d, -f2)
VIDEO_DIR=$(echo "$VARS" | cut -d, -f3)
PODCAST_DIR=$(echo "$VARS" | cut -d, -f4)
SCRIPT_DIR=$(echo "$VARS" | cut -d, -f5)

# Echo Variables
echo " ----------------------------------"
echo "|           Variables:             |"
echo " ----------------------------------"
echo "Discord Webhook:    $WEBHOOK_URL"
echo "Download Directory: $DOWNLOAD_DIR"
echo "Video Directory:    $VIDEO_DIR"
echo "Podcast Directory:  $PODCAST_DIR"
echo "Script Directory:   $SCRIPT_DIR"

# Print blank lines
yes '' | sed 2q

# Send Discord Notification
SECONDS=0
PAYLOAD=" { \"content\": \"YouTube-DL started encoding the list of links.\" }"
curl -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$WEBHOOK_URL"

trap "exit" INT

# Start loop to read through the links file.
while read CURRENT; do

# Finds the channel name and link to it.
NAME=$(echo "$CURRENT" | cut -d, -f1)
LINK=$(echo "$CURRENT" | cut -d, -f2)
DOWNLOADTYPE=$(echo "$CURRENT" | cut -d, -f3)

# Download Type: 1=Video 2=Audio+Video
# NOTE: All downloads are currently audio+video, mainly 
#       because I don't use video only right now. 

# Get status from file
STATUS=$(<$DOWNLOAD_DIR/"$NAME"/status.txt)

# Verifies that the download has completed
if [ $STATUS = "needsencoding" ]; then

	# Echo out variables
	echo " ----------------------------------"
	echo "|         Current Channel          |"
	echo " ----------------------------------"
	echo "Channel:       $NAME"
	echo "Channel Link:  $LINK"
	echo "Download Type: $DOWNLOADTYPE"

	# Creates new folders for the channel.
	echo "Making directories..."
	sudo mkdir -p $PODCAST_DIR/"$NAME"
	sudo mkdir -p $VIDEO_DIR/"$NAME"
	sudo mkdir -p $VIDEO_DIR/"$NAME"/Thumbnails/

	# Updated status to encoding
	sudo touch $DOWNLOAD_DIR/"$NAME"/status.txt
	sudo echo "encoding" > $DOWNLOAD_DIR/"$NAME"/status.txt

	cd "$DOWNLOAD_DIR/$NAME"/

	# Transcode video loop
	for i in *.mkv *.webm *.avi *.mov;
	do video=`echo "$i" | cut -d'.' -f1`

		yes '' | sed 2q
		echo "Current video: $i"
		yes '' | sed 2q

		# Transcode video
		ffmpeg -y -nostdin -hide_banner -i "$i" -acodec aac -vcodec copy -c:s mov_text "${video}.mp4"
			
		# Add thumbnail to video file
		sudo AtomicParsley "${video}.mp4" --artwork "$DOWNLOAD_DIR/$NAME/Thumbnails/${video}"*.jpg --overWrite

		# Fix date to original
		touch -r "$i" "${video}.mp4"

		# Delete original
		sudo rm "$DOWNLOAD_DIR/$NAME/$i"
	done

	# Transcode audio loop
	if [ $DOWNLOADTYPE = "2" ]; then

		cd "$DOWNLOAD_DIR/$NAME"

		for i in *.mp4;
		do video=`echo "$i" | cut -d'.' -f1`

			yes '' | sed 2q
			echo "Current audio: $i"
			yes '' | sed 2q

			# Extract audio
			ffmpeg -n -nostdin -hide_banner -i "$i" -vn -c:a aac "$PODCAST_DIR/$NAME/${video}.m4a"

			# Add metadata to audio file
			sudo AtomicParsley "$PODCAST_DIR/$NAME/${video}.m4a" --artwork "$DOWNLOAD_DIR/$NAME/Thumbnails/channel_cover.jpg" --overWrite --album "$NAME" --genre "Podcasts" --tracknum `echo "$i" | cut -d'_' -f1` --disk 1

			# Fix date to original
			touch -r "$i" "$PODCAST_DIR/$NAME/${video}.m4a"
		done
	fi

	# Moves the videos to the long-term storage directory
	sudo mv "$DOWNLOAD_DIR/$NAME"/*.mp4 $VIDEO_DIR/"$NAME"/
	sudo mv "$DOWNLOAD_DIR/$NAME"/Thumbnails/* $VIDEO_DIR/"$NAME"/Thumbnails/

	# Tells status.txt that the download is done and can now be uploaded.
	echo "Setting status file to done"
	sudo truncate -s 0 $DOWNLOAD_DIR/"$NAME"/status.txt
	sudo echo "done" > $DOWNLOAD_DIR/"$NAME"/status.txt

# Ends the loop.
else
	echo ""
fi

# Ends the loop.
done <$SCRIPT_DIR/List_of_Links.txt

#End timer function
if (( $SECONDS > 3600 )); then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
elif (( $SECONDS > 60 )); then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "Completed in $SECONDS seconds"
fi
