#!/bin/sh

##################################################
#                 FLACALAC v1.1                  ##
#        Convert FLAC files to ALAC files        ##
#       Requires metaflac, ffmpeg, and sed       ##
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

# CH-CH-CHANGES
# v1.1, 2010-09-30
# - Added -y flag

EXIT=0

assert_dependency() {
    [ "$(whereis $1 | sed 's/^\w*:\W*//')" != "" ] && $1 --help &> /dev/null ||
    $1 -h 1> /dev/null ||
    {
      echo "Error: dependency \"$1\" not met."
      exit 1
    }
}
usage() {
    echo "Usage: $0 [OPTION] FILE..."
    echo "Convert FLAC files to ALAC files."
    echo
    echo "  -y  Overwrite output files automatically"
}

# Make sure metaflac, ffmpeg, and sed are found
assert_dependency "metaflac"
assert_dependency "ffmpeg"
assert_dependency "sed"

# Enable overwriting of output files if -y parameter is specified
FFMPEG_PARAM=""
while [[ $# -gt 0 && $1 == -* ]]
do
  [ $1 == "-y" ] && FFMPEG_PARAM="-y"
  [ $1 == "-h" ] && usage && exit
  shift
done

# If no arguments were given print usage information 
[ $# -le 0 ] && usage && exit 1

# Loop through all parameters and treat each as a file to convert
while [ $# -gt 0 ]
do
    FLAC=$1
    ALAC="${FLAC%.[Ff][Ll][Aa][Cc]}.m4a"

    # Make sure file exists
    [ -r "$FLAC" ] ||
    {
      echo -e "Error: Cannot read file \"$FLAC\"\n\n" >&1
      EXIT=1
      shift
      break
    }

    echo "Converting file $FLAC to $ALAC"

    # Grab the flac tags and store them in a string as variable declarations
    vars=$(metaflac --show-tag=title --show-tag=tracknumber --show-tag=genre \
    --show-tag=date --show-tag=artist --show-tag=album --show-tag=comment \
    "$FLAC" | sed 's#\(.*\)=\(.*\)#\U\1\E=\"\2\";#')

    # Evaluate the declarations to create needed variables
    eval $vars

    # Create the alac file with the proper tags
    ffmpeg $FFMPEG_PARAM -i "$FLAC" -acodec alac \
    -metadata title="$TITLE" \
    -metadata album="$ALBUM" \
    -metadata author="$ARTIST" \
    -metadata track="$TRACKNUMBER" \
    -metadata year="$DATE" \
    -metadata genre="$GENRE" \
    -metadata comment="$COMMENT" \
    "$ALAC" ||
    {
      echo "Error: conversion error with file \"$FLAC\"" >&1
      EXIT=1
    }

    echo -e "\n\n"

    # Get the next parameter
    shift
done

exit $EXIT # If any failures occurred the exit status will show it
