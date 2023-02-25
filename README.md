# YouTube to Plex
These scripts are use to download YouTube videos and store them in Plex, and also extracts the audio to store in a podcast format. The format for the list_of_links.txt file is:
```
Channel Name,Link_To_Channel,1(Video) or 2(Video and Audio)
Example: Computerphile,https://www.youtube.com/user/Computerphile/videos,2
```

For the script to run, a ``credentials.txt`` file needs to be placed in the directory of the scripts. The format of this file is:
```
Discord_Url,/temp/download/directory,/storage/directory,/music/directory,/script/directory
```

I used Cron to schedule the download script to run at 3am daily, and then the encoding script to run at 3pm daily. This gives the downloading script enough time to finish, but there is checking in place to make sure the encoding doesn't start until the download is finished.

Right now I don't think the audio only part is working, because I solely use the combined setting (2). I am going to take a look at that in the coming days.
