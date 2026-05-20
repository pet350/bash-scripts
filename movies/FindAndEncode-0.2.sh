#! /bin/sh
## Script to find $1 files and encode them as AVI files
## Version 0.2

FILE="find.info"
find . -name  $1 >$FILE

# read $FILE using the file descriptors
exec 3<&0
exec 0<$FILE
while read line
do
	# use $line variable to process line
	output=${line%.*}.avi
	echo Starting 1st pass of 2 pass AVI encoding
	echo Input file:	$line
	echo Output File:	$output
	mencoder "$line" -nosub -noautosub -ovc xvid -xvidencopts pass=1:bitrate=1000:trellis:chroma_opt:vhq=4:bvhq=1:quant_type=mpeg:max_bframes=0:nogmc:noqpel -vf scale=720:480 -af volnorm=1 -oac pcm -o "/dev/null"
	echo
	echo Starting 2nd pass of 2 pass AVI encoding
	mencoder "$line" -nosub -noautosub -ovc xvid -xvidencopts pass=2:bitrate=1000:trellis:chroma_opt:vhq=4:bvhq=1:quant_type=mpeg:max_bframes=0:nogmc:noqpel -vf scale=720:480 -af volnorm=1 -oac mp3lame -lameopts cbr:br=192 -o "$output"
	echo
	rm -v "divx2pass.log"
	echo
done
exec 0<&3

rm -v $FILE

