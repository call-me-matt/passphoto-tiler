#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "usage: $0 photo1 [photo2 ...]"
	exit
fi

# Image format "classic" 2:3, 10x15 | 9x13
#  9x13:  89x133px
# 10x15: 102x153px
# 13x18: 127x178px
IMAGE_WIDTH_MM=102
IMAGE_HEIGHT_MM=153

# Passphoto format: 35x45mm
PASSPHOTO_WIDTH_MM=40
PASSPHOTO_HEIGHT_MM=50

# pixel/mm
PIXEL_PER_MM=24
IMAGE_WIDTH=$(expr $IMAGE_WIDTH_MM \* $PIXEL_PER_MM)
IMAGE_HEIGHT=$(expr $IMAGE_HEIGHT_MM \* $PIXEL_PER_MM)
PHOTO_WIDTH=$(expr $PASSPHOTO_WIDTH_MM \* $PIXEL_PER_MM)
PHOTO_HEIGHT=$(expr $PASSPHOTO_HEIGHT_MM \* $PIXEL_PER_MM)
BORDER_X=20
BORDER_Y=20

# create tmp directory
if [ -d tmp ] 
  then
    echo "ERROR: tmp directory already existing"
	exit
fi
mkdir tmp

# crop photos to required dimension
THUMBS=()
for FILE in "$@"
do
	echo $FILE
	thumbname=./tmp/${#THUMBS[@]}.${FILE##*.}
	convert $FILE -thumbnail $PHOTO_WIDTH\x$PHOTO_HEIGHT^ -gravity center -extent $PHOTO_WIDTH\x$PHOTO_HEIGHT -bordercolor black -border 1 $thumbname
	THUMBS+=($thumbname)
done
PHOTO_WIDTH=$(expr $PHOTO_WIDTH + 2) # including borders
PHOTO_HEIGHT=$(expr $PHOTO_HEIGHT + 2) # including borders
PHOTO_BORDER_WIDTH=$(expr $PHOTO_WIDTH + 2 \* $BORDER_X)
PHOTO_BORDER_HEIGHT=$(expr $PHOTO_HEIGHT + 2 \* $BORDER_Y)

# calculate montage
COLS=$(expr $IMAGE_WIDTH / $PHOTO_BORDER_WIDTH)
ROWS=$(expr $IMAGE_HEIGHT / $PHOTO_BORDER_HEIGHT)

# select (or repeat) images:
IMAGES=()
N=$(expr $COLS \* $ROWS - 1)
if [ $N -eq -1 ]
  then
	echo "ERROR: check image dimensions"
	rm -rf ./tmp/
	exit
fi
for i in $(seq 0 $N)
do
	IMAGES+=(${THUMBS[$(expr $i % ${#THUMBS[@]})]})
done

# create montage
montage ${IMAGES[@]} -tile $COLS\x$ROWS -geometry $PHOTO_WIDTH\x$PHOTO_HEIGHT+$BORDER_X+$BORDER_Y ./tmp/montage.jpg

# fit montage to photo format
FRAME_X=$(expr $IMAGE_WIDTH - $COLS \* $PHOTO_WIDTH - $COLS \* 2 \* $BORDER_X)
FRAME_Y=$(expr $IMAGE_HEIGHT - $ROWS \* $PHOTO_HEIGHT - $ROWS \* 2 \* $BORDER_Y)
BORDERCOLOR=white # use lightgrey if your photo printer autocrops white border
convert ./tmp/montage.jpg  -bordercolor $BORDERCOLOR -border $(expr $FRAME_X / 2)\x$(expr $FRAME_Y / 2) passphotos.jpg

# cleanup
rm -rf ./tmp/
eog passphotos.jpg &

