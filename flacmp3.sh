#!/bin/sh

##################################################
#                  FLACMP3 v1.1                  ##
#         Convert FLAC files to MP3 files        ##
#          Requires flac, lame, and sed          ##
#                                                ##
#       Originally created by Trey Hunner        ##
#                                                ##
# Permission is granted to freely distribute     ##
# verbatim or modified copies of this program.   ##
#                                                ##
# This program is distributed in the hope that   ##
# it will be useful, but without any warranty;   ##
# without even the implied warranty of           ##
# merchantability or fitness for a particular    ##
# purpose.                                       ##
###################################################

EXIT=0

assert_dependency() {
    [ "$(whereis $1 | sed 's/^\w*:\W*//')" != "" ] && $1 --help &> /dev/null || { echo "Error: dependency \"$1\" not met." ; exit 1 ; }
}
usage() {
    echo "Usage: $0 flac-file..."
}

# Print usage information if no arguments were given
[ $# -le 0 ] && usage && exit 1

# Make sure flac, lame, and sed are found
assert_dependency "flac"
assert_dependency "lame"
assert_dependency "sed"

# Loop through all parameters and treat each as a file to convert
while [ $# -gt 0 ]
do
    FLAC=$1
    MP3="${FLAC%.[Ff][Ll][Aa][Cc]}.mp3"

    # Make sure file exists
    [ -r "$FLAC" ] || { echo -e "Error: Cannot read file \"$FLAC\"\n\n" >&1; \
    EXIT=1; shift; break; };

    echo "Converting file $FLAC to $MP3"

    # Grab the flac tags and store them in a string as variable declarations
    vars=$(metaflac --show-tag=title --show-tag=tracknumber --show-tag=genre \
    --show-tag=date --show-tag=artist --show-tag=album --show-tag=comment \
    "$FLAC" | sed 's/\(.*\)=\(.*\)/\U\1\E=\"\2\";/')

    # Evaluate the declarations to create needed variables
    eval $vars
    echo -e "TITLE=$TITLE\nTRACKNUMBER=$TRACKNUMBER\nGENRE=$GENRE" \
    "\nDATE=$DATE\nARTIST=$ARTIST\nALBUM=$ALBUM\nCOMMENT=$COMMENT"

    # Create the mp3 file with the proper tags
    flac -dc "$FLAC" | lame -V 0 --vbr-new --tt "$TITLE" \
    --tn "$TRACKNUMBER" \
    --tg "$GENRE" \
    --ty "$DATE" \
    --ta "$ARTIST" \
    --tl "$ALBUM" \
    --tc "$COMMENT" \
    --add-id3v2 \
    - "$MP3" || { echo "Error: conversion error with file \"$FLAC\"" >&1;\
    EXIT=1; }

    echo -e "\n\n"

    # Get the next parameter
    shift 1
done

exit $EXIT
