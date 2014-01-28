#!/bin/sh
#
# Vimeo Downloader
#
# Copyright (C) 2008, 2010  Denver Gingerich
# Copyright (C) 2009  Jori Hamalainen
# Copyright (C) 2012  John Slade (http://jtes.net)
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


if [ $# -ne 1 ]; then
	echo "Vimeo Downloader v0.3.1"
	echo "by Denver Gingerich (http://ossguy.com/)"
	echo "    with script improvements by Jori Hamalainen"
	echo "    updated for new Vimeo site by John Slade"
	echo
	echo "Usage: $0 <vimeo_id|vimeo_URL>"
	exit 1
fi
VIMEO_ID=`echo $1 | awk -F / '{print $NF}'`

# Set the user agent ID to use
USER_AGENT="Mozilla/5.0"

# Check we have the tools we need
which wget
if [ $? -eq 1 ]; then
	echo "ERROR: this tool requires wget on the path"
	exit 1
fi

which perl
if [ $? -eq 1 ]; then
	echo "ERROR: this tool requires perl on the path"
	exit 1
fi

# Get the main page
VIDEO_XML=`wget -U \"${USER_AGENT}\" -q -O - http://vimeo.com/${VIMEO_ID}`

# Get the config url
CONFIG_URL=`echo $VIDEO_XML | grep data-config-url | perl -p -e 's/^.*? data-config-url="(.*?)".*$/$1/g' | perl -pe 's/&amp;/&/g'`
VIDEO_CONFIG=`wget -U \"${USER_AGENT}\" -q -O - ${CONFIG_URL}`

# Determine the download url and caption
HD_URL=`echo $VIDEO_CONFIG | perl -pe 's/^.*"hd":{(.*?)}.*$/$1/g' | perl -pe 's/^.*"url":"(.*?)".*$/$1/g'`
SD_URL=`echo $VIDEO_CONFIG | perl -pe 's/^.*"sd":{(.*?)}.*$/$1/g' | perl -pe 's/^.*"url":"(.*?)".*$/$1/g'`
CAPTION=`echo $VIDEO_XML | perl -p -e '/^.*?\<meta property="og:title" content="(.*?)"\>.*$/; $_=$1; s/[^\w.]/-/g;'`

# Select the correct URL
if [ "$HD_URL" ]; then
	DOWNLOAD_URL=$HD_URL
	QUALITY="HD"
elif [ "$SD_URL" ]; then
	DOWNLOAD_URL=$SD_URL
	QUALITY="SD"
else
	echo "ERROR: failed to download vimeo ID ${VIMEO_ID}"
	echo "Please report this error at https://github.com/johnteslade/vimeo-downloader/issues"
fi

# Set the filename output
FILENAME="${CAPTION}-(${QUALITY}-${VIMEO_ID}).flv"

echo
echo "Downloading video ${VIMEO_ID} to ${FILENAME}..."
echo "From URL ${DOWNLOAD_URL}"
echo "Quality=${QUALITY}"
echo 

# Do the download
wget -U \"${USER_AGENT}\" -O ${FILENAME} ${DOWNLOAD_URL}

echo
echo "Video ${VIMEO_ID} saved to ${FILENAME}"
echo `file "${FILENAME}"`
echo

