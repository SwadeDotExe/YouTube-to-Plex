#!/bin/bash

echo "Starting YouTube_Downloader.sh"

# Print blank lines
yes '' | sed 2q

# Read in Variables
VARS=`cat credentials.txt`
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
PAYLOAD=" { \"content\": \"YouTube-DL started downloading the list of links.\" }"
curl -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$WEBHOOK_URL"

trap "exit" INT

# Start loop to read through the links file.
while read CURRENT; do

    # Finds the channel name and link to it.
    NAME=$(echo "$CURRENT" | cut -d, -f1)
    LINK=$(echo "$CURRENT" | cut -d, -f2)
    DOWNLOADTYPE=$(echo "$CURRENT" | cut -d, -f3)

    # Echo out variables
    echo " ----------------------------------"
    echo "|         Current Channel          |"
    echo " ----------------------------------"
    echo "Channel:       $NAME"
    echo "Channel Link:  $LINK"
    echo "Download Type: $DOWNLOADTYPE"

    # Download Type: 1=Video 2=Audio+Video
    # NOTE: All downloads are currently audio+video, mainly 
    #       because I don't use video only right now. 

    # Creates new folders for the channel.
    sudo mkdir -p $DOWNLOAD_DIR
    sudo mkdir -p $DOWNLOAD_DIR/"$NAME"
    sudo mkdir -p $DOWNLOAD_DIR/"$NAME"/Thumbnails

    # # Tells status.txt that the download has started
    # # TODO: Implement a better system to do this locking
    sudo truncate -s 0 $DOWNLOAD_DIR/"$NAME"/status.txt
    sudo echo "downloading" > $DOWNLOAD_DIR/"$NAME"/status.txt

    # Get count of titles file (if exists)
    if [ -f "$DOWNLOAD_DIR/$NAME/titles.txt" ]; then
        TXTNUM=$(wc -l $DOWNLOAD_DIR/"$NAME"/titles.txt | awk '{ print $1 }')
    else
        TXTNUM=0
    fi
    
    # Get count of channel videos
    CHANNELNUM=`yt-dlp $LINK -J --flat-playlist | jq ".entries | length"`
    
    # Check to see if any new videos since last update
    if [ "$CHANNELNUM" -gt "$TXTNUM" ]; then
        echo "New videos detected, running download script."
    

        #Downloads all the new videos and stores the video-id in a file.
        sudo yt-dlp -ciw -o $DOWNLOAD_DIR/"$NAME"/"%(playlist_autonumber)s_%(title)s.%(ext)s" $LINK --playlist-reverse --add-metadata -f bestvideo+bestaudio/best --write-thumbnail --embed-thumbnail --merge-output-format mkv --embed-subs --write-auto-sub --download-archive $DOWNLOAD_DIR/"$NAME"/titles.txt --cookies $SCRIPT_DIR/YouTubeCookie.txt --max-downloads 10

        ################################################
        #   NOTE: Right now yt-dlp is limited to       #
        #        10 downloads per run for testing      #
        ################################################

        # Converts all thumbnails to .JPG
        echo "Converting thumbnails to JPG..."
        cd $DOWNLOAD_DIR/"$NAME"/
        mogrify -format jpg -define webp:lossless=true *.webp
        mogrify -format jpg -define *.png

        # Moves all downloaded thumbnails to a folder.
        echo "Moving thumbnails to folder..."
        sudo find $DOWNLOAD_DIR/"$NAME"/ -name '*jpg' -maxdepth 1 -exec mv -t $DOWNLOAD_DIR/"$NAME"/Thumbnails {} +

        # Deletes all remaining junk files.
        echo "Deleting unconverted thumbnails..."
        cd $DOWNLOAD_DIR/"$NAME"/
        sudo find . \( -name "*.webp" -o -name "*.png" \) -type f -delete

        # Move channel cover to thumbnails
        echo "Moving cover to thumbnails folder..."
        cd $DOWNLOAD_DIR/"$NAME"/Thumbnails
        sudo mv NA_*.jpg channel_cover.jpg

    else
        echo "No new videos detected, going to next channel."
    fi

    # Tells status.txt that the download is done and can now be encoded.
    sudo truncate -s 0 $DOWNLOAD_DIR/"$NAME"/status.txt
    sudo echo "needsencoding" > $DOWNLOAD_DIR/"$NAME"/status.txt

# Ends the loop.
done <List_of_Links.txt

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
