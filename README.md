# YouTube to Plex
These scripts are use to download YouTube videos and store them in Plex, and also extracts the audio to store in a podcast format. The scripts automatically imports metadata in a format that Plex is expecting, and also embeds video thumbnails so Plex shows exactly what YouTube would.

NOTE: Right now, ``YouTube_Downloader.sh`` has a flag on line 84 to limit the max downloads per execution of the script. This is because I have a data limit on the network where this server is running, and since I have been executing this script a lot during its creation, I added it temporarily to prevent reaching the data cap. After all the channels I initially add get entirely downloaded and I'm only downloading the deltas, I will probably increase this cap to 100 or something just to ensure the Cronjobs don't overlap (even though there is code in place to handle this).

For the script to run, a ``credentials.txt`` file needs to be placed in the directory of the scripts. The format of this file is:
```
Discord_Url,/temp/download/directory,/storage/directory,/music/directory,/script/directory
```

Also, a ``list_of_links.txt`` file needs to be created with the following format (each channel gets 1 line):
```
Channel Name,Link_To_Channel,1(Video) or 2(Video and Audio)
Example: Computerphile,https://www.youtube.com/user/Computerphile/videos,2
```

I used Cron to schedule the download script to run at 3am daily, and then the encoding script to run at 3pm daily. This gives the downloading script enough time to finish, but there is checking in place to make sure the encoding doesn't start until the download is finished.

Right now I don't think the audio only part is working, because I solely use the combined setting (2). I am going to take a look at that in the coming days.
