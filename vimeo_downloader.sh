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

which wget
if [ $? -eq 0 ]; then
	echo "Using wget..."
	GET_CMD="wget -U \"${USER_AGENT}\" -O -"
else
	which curl
	if [ $? -eq 0 ]; then
		echo "Using curl..."
		GET_CMD="curl -L -A ${USER_AGENT} "
	else
		echo "Could not find wget or curl"
		exit 2
	fi
fi

which perl
if [ $? -eq 0 ]; then
	echo "Using perl..."
	USING_PERL=1
else
	echo "Using sed..."
	USING_PERL=0
fi

VIDEO_XML=`${GET_CMD} http://vimeo.com/${VIMEO_ID}`

if [ $USING_PERL -eq 1 ]; then
	REQUEST_SIGNATURE=`echo $VIDEO_XML | perl -e '@text_in = <STDIN>; if (join(" ", @text_in) =~ /"signature":"(.*?)"/i ){ print "$1\n"; }'`
	REQUEST_SIGNATURE_EXPIRES=`echo $VIDEO_XML | perl -e '@text_in = <STDIN>; if (join(" ", @text_in) =~ /"timestamp":(\d*?),/i ){ print "$1\n"; }'`
	CAPTION=`echo $VIDEO_XML | perl -p -e '/^.*?\<meta property="og:title" content="(.*?)"\>.*$/; $_=$1; s/[^\w.]/-/g;'`
	ISHD=`echo $VIDEO_XML |    perl -p -e '/^.*?\<meta itemprop="videoQuality" content="(HD)"\>.*$/; $_=lc($1)||"sd";'`

	FILENAME="${CAPTION}-(${ISHD}-${VIMEO_ID}).flv"
else

	# TODO update the sed code to work with the new site format
	echo "This version requires perl - exiting"
	exit 2
	
	REQUEST_SIGNATURE=`echo $VIDEO_XML | sed -e 's/^.*<request_signature>\([^<]*\)<.*$/\1/g'`
	REQUEST_SIGNATURE_EXPIRES=`echo $VIDEO_XML | sed -e 's/^.*<request_signature_expires>\([^<]*\)<.*$/\1/g'`
	ISHD="sd"
	FILENAME=${VIMEO_ID}.flv
fi

echo
echo "Downloading video ${VIMEO_ID} to ${FILENAME}..."
echo "Request_signature=${REQUEST_SIGNATURE}"
echo "Request_signature_expires=${REQUEST_SIGNATURE_EXPIRES}"
echo "Quality=${QUALITY}"
echo 

EXEC_CMD="${GET_CMD} http://player.vimeo.com/play_redirect?clip_id=${VIMEO_ID}&sig=${REQUEST_SIGNATURE}&time=${REQUEST_SIGNATURE_EXPIRES}&quality=${ISHD}&codecs=H264,VP8,VP6&type=moogaloop_local&embed_location=" 
echo "Executing ${EXEC_CMD}"
${EXEC_CMD} > "${FILENAME}"

echo
echo "Video ${VIMEO_ID} saved to ${FILENAME}"
echo `file "${FILENAME}"`
echo
