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
if [ $? -eq 1 ]; then
	echo "ERROR: this tool requires wget on the path"
	exit 1
fi

which perl
if [ $? -eq 1 ]; then
	echo "ERROR: this tool requires perl on the path"
	exit 1
fi

GET_CMD="wget -U \"${USER_AGENT}\" -O"

VIDEO_XML=`${GET_CMD} - http://vimeo.com/${VIMEO_ID}`

CONFIG_URL=`echo $VIDEO_XML | grep data-config-url | perl -p -e 's/^.*? data-config-url="(.*?)".*$/$1/g' | perl -pe 's/&amp;/&/g'`
echo "Look for config at $CONFIG_URL"

VIDEO_CONFIG=`${GET_CMD} - ${CONFIG_URL}`

HD_URL=`echo $VIDEO_CONFIG | perl -pe 's/^.*"hd":{(.*?)}.*$/$1/g' | perl -pe 's/^.*"url":"(.*?)".*$/$1/g'`
SD_URL=`echo $VIDEO_CONFIG | perl -pe 's/^.*"sd":{(.*?)}.*$/$1/g' | perl -pe 's/^.*"url":"(.*?)".*$/$1/g'`

echo HD $HD_URL
echo SD $SD_URL

exit

REQUEST_SIGNATURE=`echo $VIDEO_CONFIG | perl -e '@text_in = <STDIN>; if (join(" ", @text_in) =~ /"signature":"(.*?)"/i ){ print "$1\n"; }'`
REQUEST_SIGNATURE_EXPIRES=`echo $VIDEO_CONFIG | perl -e '@text_in = <STDIN>; if (join(" ", @text_in) =~ /"timestamp":(\d*?),/i ){ print "$1\n"; }'`
CAPTION=`echo $VIDEO_XML | perl -p -e '/^.*?\<meta property="og:title" content="(.*?)"\>.*$/; $_=$1; s/[^\w.]/-/g;'`
ISHD=`echo $VIDEO_XML | perl -p -e '/^.*?\<meta itemprop="videoQuality" content="(HD)"\>.*$/; $_=lc($1)||"sd";'`

FILENAME="${CAPTION}-(${ISHD}-${VIMEO_ID}).flv"

echo
echo "Downloading video ${VIMEO_ID} to ${FILENAME}..."
echo "Request_signature=${REQUEST_SIGNATURE}"
echo "Request_signature_expires=${REQUEST_SIGNATURE_EXPIRES}"
echo "Quality=${QUALITY}"
echo 

EXEC_CMD="${GET_CMD} --post-data 'id=${VIMEO_ID}&sig=${REQUEST_SIGNATURE}&time=${REQUEST_SIGNATURE_EXPIRES}&quality=${ISHD}&codecs=H264,VP8,VP6&type=moogaloop_local&embed_location=' http://player.vimeo.com/v2/log/play" 
EXEC_CMD="${GET_CMD} --post-data 'referrer=http%3A%2F%2Fvimeo.com%2F1084537&embed=false&context=clip.main&id=1084537&userId=0&userAccountType=none&ownerId=508904&privacy=anybody&rating=null&type=html&videoFileId=24130451&delivery=progressive&quality=hd&duration=596&seconds=0&signature=bba9539b684b68a669df61672fdaa620&session=b33ffe835f53dff6f965d079b45c57e2&time=1389393290&expires=1496' - http://player.vimeo.com/v2/log/play" 
echo "Executing ${EXEC_CMD}"
${EXEC_CMD} > "${FILENAME}"

echo
echo "Video ${VIMEO_ID} saved to ${FILENAME}"
echo `file "${FILENAME}"`
echo
