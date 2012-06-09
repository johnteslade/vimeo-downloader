#!/bin/sh
#
# Vimeo Downloader
#
# Copyright (C) 2008, 2010  Denver Gingerich
# Copyright (C) 2009  Jori Hamalainen
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
	echo
	echo "Usage: $0 <vimeo_id|vimeo_URL>"
	exit 1
fi
VIMEO_ID=`echo $1 | awk -F / '{print $NF}'`

which wget
if [ $? -eq 0 ]; then
	echo "Using wget..."
	GET_CMD="wget -O -"
else
	which curl
	if [ $? -eq 0 ]; then
		echo "Using curl..."
		GET_CMD="curl -L"
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

VIDEO_XML=`${GET_CMD} http://www.vimeo.com/moogaloop/load/clip:${VIMEO_ID}`

if [ $USING_PERL -eq 1 ]; then
	REQUEST_SIGNATURE=`echo $VIDEO_XML | perl -p -e 's:^.*?\<request_signature\>(.*?)\</request_signature\>.*$:$1:g'`
	REQUEST_SIGNATURE_EXPIRES=`echo $VIDEO_XML | perl -p -e 's:^.*?\<request_signature_expires\>(.*?)\</request_signature_expires\>.*$:$1:g'`
	CAPTION=`echo $VIDEO_XML | perl -p -e 's:^.*?\<caption\>(.*?)\</caption\>.*$:$1:g'`
	ISHD=`echo $VIDEO_XML |  perl -p -e 's:^.*?\<isHD\>(.*?)\</isHD\>.*$:$1:g'`

	if [ ${ISHD} -eq 1 ]; then
		ISHD="hd"
	else
		ISHD="sd"
	fi

	# caption can contain bad characters (like '/') so don't use it for now
	#FILENAME="${CAPTION}-(${ISHD}${VIMEO_ID}).flv"

	FILENAME="${VIMEO_ID}-${ISHD}.flv"
else
	REQUEST_SIGNATURE=`echo $VIDEO_XML | sed -e 's/^.*<request_signature>\([^<]*\)<.*$/\1/g'`
	REQUEST_SIGNATURE_EXPIRES=`echo $VIDEO_XML | sed -e 's/^.*<request_signature_expires>\([^<]*\)<.*$/\1/g'`
	ISHD="sd"
	FILENAME=${VIMEO_ID}.flv
fi

echo "\nDownloading video ${VIMEO_ID} to ${FILENAME}...\nRequest_signature=${REQUEST_SIGNATURE}\nRequest_signature_expires=${REQUEST_SIGNATURE_EXPIRES}\n"
${GET_CMD} "http://www.vimeo.com/moogaloop/play/clip:${VIMEO_ID}/${REQUEST_SIGNATURE}/${REQUEST_SIGNATURE_EXPIRES}/?q=${ISHD}" > "${FILENAME}"
echo "Video ${VIMEO_ID} saved to ${FILENAME}"
echo `file "${FILENAME}"`
echo
