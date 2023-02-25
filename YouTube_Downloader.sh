#!/bin/bash

# Read in Variables
VARS=`cat credentials.txt`
WEBHOOK_URL=$(echo "$VARS" | cut -d, -f1)
DOWNLOAD_DIR=$(echo "$VARS" | cut -d, -f2)
VIDEO_DIR=$(echo "$VARS" | cut -d, -f3)
PODCAST_DIR=$(echo "$VARS" | cut -d, -f4)
SCRIPT_DIR=$(echo "$VARS" | cut -d, -f5)

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

# Creates new folders for the channel.
sudo mkdir -p $DOWNLOAD_DIR
sudo mkdir -p $DOWNLOAD_DIR/"$NAME"
sudo mkdir -p $DOWNLOAD_DIR/"$NAME"/Thumbnails

# Tells status.txt that the download is done and can now be uploaded.
echo "Setting status file to done"
sudo truncate -s 0 $DOWNLOAD_DIR/"$NAME"/status.txt
sudo echo "downloading" > $DOWNLOAD_DIR/"$NAME"/status.txt

# Downloads all the new videos and stores the video-id in a file.
sudo yt-dlp -ciw -o $DOWNLOAD_DIR/"$NAME"/"%(playlist_autonumber)s_%(title)s.%(ext)s" $LINK --playlist-reverse --add-metadata -f bestvideo+bestaudio/best --write-thumbnail --embed-thumbnail --merge-output-format mkv --embed-subs --write-auto-sub --download-archive $DOWNLOAD_DIR/"$NAME"/titles.txt --cookies /mnt/SSD/Scripts/DormScripts/YouTube_Scripts/YouTubeCookie.txt

# Converts all thumbnails to .JPG
cd $DOWNLOAD_DIR/"$NAME"/
mogrify -format jpg -define webp:lossless=true *.webp
mogrify -format jpg -define *.png


# Moves all downloaded thumbnails to a folder.
sudo find $DOWNLOAD_DIR/"$NAME"/ -name '*jpg' -maxdepth 1 -exec mv -t $DOWNLOAD_DIR/"$NAME"/Thumbnails {} +

# Deletes all remaining junk files.
sudo find . \( -name "*.webp" -o -name "*.png" \) -type f -delete

cd $DOWNLOAD_DIR/"$NAME"/Thumbnails
sudo mv NA_*.jpg channel_cover.jpg

# Tells status.txt that the download is done and can now be uploaded.
echo "Setting status file to done"
sudo truncate -s 0 $DOWNLOAD_DIR/"$NAME"/status.txt
sudo echo "needsencoding" > $DOWNLOAD_DIR/"$NAME"/status.txt

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
