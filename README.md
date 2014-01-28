vimeo-downloader
================

Bash script to download a video from Vimeo to your computer.  This is originally based on "Vimeo Downloader 0.3" from http://ossguy.com/?p=841

The complexity of the vimeo site has increased recently and there are several codec and quality options available.  This script will just select the first HD or SD video to download.

I would recommend using the youtube-dl tool (http://rg3.github.io/youtube-dl/) which, despite the name, supports Vimeo downloads.  This tool is available in pypi and in many Linux package repositories.

Usage
-----

Run the following from the command line:

    ./vimeo_downloader.sh http://vimeo.com/1084537

Can also just use the ID

    ./vimeo_downloader.sh 1084537

