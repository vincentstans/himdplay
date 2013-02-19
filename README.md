himdplay
========

What works:  Playback of Atrac3 and MPEG

Writing MP3 to disk  # This results that my mz-nh700 is unable to read the disk but still mountable on pc SonicStage doesn't reconize the disk but who uses SonicStage :P
Listing tracks
playing multiple tracks
             
             

himdcli interface

Funny it's late for now i just wanted to share my code and maybe find some bash fan that is willing to contribute. 

I know the existense of qhimdtransfer but i can only download files with it. himdcli gives this same option so 

I decided to write a script around it. then stumbled on dialog and had some fun the last days. now i stumble on git 

which i've visited before but did not know what i came to do here, now i want to use it so i will investigate asap.


And now the script  i run ubuntu  i used avplay formal ffplay for playback i tried mplayer but prefer avplay ok
basic things like awk cat sed are needed but also bc is used and ofcource dialog 

Feb 19 2013
Today I started recording by playback and using line-in to record ATRAC3+ this aside, I found a fix to surpress the
warning from ffplay by adding 2>/dev/null to the output 
ill be working on saving atrac3 and mpeg files to the pc with decent names
