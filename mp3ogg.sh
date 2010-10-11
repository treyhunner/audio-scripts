#!/bin/sh

##################################################
#                 MP3OGG v2.0.6                  ##
#        convert mp3 files to ogg vorbis         ##
# requires mpg123, mp3info & oggenc              ##
# (c) 2003,2004 Loran Hughes, loran@oldcrank.com ##
# Permission is granted to freely distribute     ##
# as long as this copyright notice is attached.  ##
#                                                ##
# This program is free software; you can         ##
# redistribute it and/or modify it under the     ##
# terms of the GNU General Public License as     ##
# published by the Free Software Foundation.     ##
#                                                ## 
# This program is distributed in the hope that   ##
# it will be useful, but WITHOUT ANY WARRANTY;   ##
# without even the implied warranty of           ##
# MERCHANTABILITY or FITNESS FOR A PARTICULAR    ##
# PURPOSE.                                       ##
###################################################
 ##################################################

# v2.0.6, 6/25/2004
#	- Added "-s" and "-d" parameters
#	- (modified by Trey Hunner)
#	- fixed Mp3 and mP3 case problem

# v2.0.5, 4/11/2004
#	- Added default bitrate input when mp3info not found

# v2.0.4, 4/10/2004
#	- Fixed bug in upper case file type detection
#	- Added convert at median bitrate of original mp3
#	- General code clean up

# v2.0.3, 4/08/2004
# 	- Fixed no parameter "filename with spaces" bug

# v2.0.2, 3/27/2004 
#	- Fixed crash in no parameter conversions
#	- Added check for upper case file type

# COMMAND LINE USAGE: mp3ogg file1.mp3 file2.mp3 "filename with spaces.mp3" ...
# INVOKING MP3OGG WITHOUT PARAMETERS WILL CONVERT
# ALL MP3 FILES IN THE CURRENT DIRECTORY

##### DEFINE FUNCTIONS

### HELP FUNCTION

help ()
{

ext=`echo "$file" | sed s/.*\.[Mm][Pp]3$/mp3/`

if [[ "$ext" == mp3 ]] ; then

	echo ""

	else
		
		echo ""
		echo "mp3ogg v 2.0.6 mp3 to ogg conversion script"
		echo "mp3ogg can be used in two ways, to convert one file and to convert"
		echo "whole directories of files at once."
		echo "Usage: mp3ogg [ file1.mp3 file2.mp3 \"filename with spaces.mp3\" ... ]"
		echo "Usage: mp3ogg -s -d"
		echo "Invoking mp3ogg with the -s parameter will supress error messages"
		echo "in screen output.  The -d parameter will delete all original versions"
		echo "of mp3 files without prompting first."
		echo ""
		exit 0
fi
}

### DELETION QUERY FUNCTION

delete_query ()
{
echo ""
echo "mp3ogg v 2.0.6 mp3 to ogg conversion script"

if [ "$p1" = "-d" ] || [ "$p2" = "-d" ] ; then
	mp3del=y
else
	echo -n "Delete original mp3 files after ogg conversion? [y/N]:"
	read mp3del
	mp3del=${mp3del:0:1}
	mp3del=`echo "$mp3del" | sed s/\\Y/y/`
fi
}

### DEFAULT BITRATE IF NO MP3INFO FUNCTION

detect_mp3info ()
{
if [ "$(type -t mp3info)" = file ] ; then
	echo ""
	
	else
		echo ""
		echo -n "Convert files at what bitrate? [32-192, default = 128]:"
		read bitrate
		bitrate=${bitrate:0:3}

		if [[ "$bitrate" = "" ]] ; then

			bitrate=128
			echo "Conversion bitrate set to 128"
			echo ""
		
		else

			if [[ "$bitrate" < 32 ]] || [[ "$bitrate" > 192 ]] ; then
			
			echo "Bitrate out of range. Setting to 128"
			echo ""
			bitrate=128
		
			fi

		fi

fi
}

### SUPRESSION PARAMETER CHECKING FUNCTION

detect_supress()
{
if [ "$p1" = "-s" ] || [ "$p2" = "-s" ] ; then

	supress="y"

fi
}

### MP3 TO OGG CONVERSION FUNCTION

convert ()
{
# MAKE SURE FILE IS AN MP3
	ext=`echo "$file" | sed s/.*\.[Mm][Pp]3$/mp3/`

	if [[ "$ext" == mp3 ]] ; then

# FILE IS AN MP3, NOW TEST IF MP3INFO EXISTS

		if [ "$(type -t mp3info)" = file ] ; then

# MP3INFO EXISTS... GET BITRATE & ID3 INFO
			if [ "$supress" = "y" ] ; then
				bitrate=`mp3info -rm -p %r "$file" 2> /dev/null`
				title=`mp3info -p %t "$file" 2> /dev/null`
				artist=`mp3info -p %a "$file" 2> /dev/null`
				album=`mp3info -p %l "$file" 2> /dev/null`
				genre=`mp3info -p %g "$file" 2> /dev/null`
			else
				bitrate=`mp3info -rm -p %r "$file"`
				title=`mp3info -p %t "$file"`
				artist=`mp3info -p %a "$file"`
				album=`mp3info -p %l "$file"`
				genre=`mp3info -p %g "$file"`
			fi
# CONVERT MP3 TO OGG FORMAT WITH ID3 INFO

			if [ "$supress" = "y" ] ; then
				wavfile=`echo "$file" | sed s/\\.[Mm][Pp]3/.wav/ 2> /dev/null`
			else
				wavfile=`echo "$file" | sed s/\\.[Mm][Pp]3/.wav/`
			fi
			echo ""
			echo "** Converting \""$file"\" at median bitrate" $bitrate 
			echo ""
			mpg123 -q -w "$wavfile" "$file"
			if [ "$supress" = "y" ] ; then
				oggfile=`echo "$wavfile" | sed s/\\.wav/.ogg/ 2> /dev/null`
			else
				oggfile=`echo "$wavfile" | sed s/\\.wav/.ogg/`
			fi
			if [ "$supress" = "y" ] ; then
				oggenc "$wavfile" -o "$oggfile" -b $bitrate -t "$title" -a "$artist" -l "$album" -G "$genre" 2> /dev/null
			else
				oggenc "$wavfile" -o "$oggfile" -b $bitrate -t "$title" -a "$artist" -l "$album" -G "$genre"
			fi

		else

# MP3INFO NOT INSTALLED - CONVERT MP3 TO OGG FORMAT WITHOUT ID3 INFO

			if [ "$supress" = "y" ] ; then
				wavfile=`echo "$file" | sed s/\\.[Mm][Pp]3/.wav/ 2> /dev/null`
			else
				wavfile=`echo "$file" | sed s/\\.[Mm][Pp]3/.wav/`
			fi
			echo ""
			echo "** Converting \""$file"\" at bitrate" $bitrate
			echo ""
			mpg123 -q -w "$wavfile" "$file"
			if [ "$supress" = "y" ] ; then
				oggfile=`echo "$wavfile" | sed s/\\.wav/.ogg/ 2> /dev/null`
			else
				oggfile=`echo "$wavfile" | sed s/\\.wav/.ogg/`		
			fi	
			if [ "$supress" = "y" ] ; then	
				oggenc "$wavfile" -o "$oggfile" -b $bitrate 2> /dev/null
			else
				oggenc "$wavfile" -o "$oggfile" -b $bitrate
			fi

		fi

# CLEAN UP TEMP FILES AND OPTIONALLY DELETE ORIGINAL MP3

				if [ "$mp3del" = "y" ] ; then
					rm -f "$file" "$wavfile"
				else
					rm -f "$wavfile"					
				fi
		fi
}

##### END FUNCTIONS

##### BEGIN MAIN SCRIPT

# TEST FOR COMMAND LINE PARAMETERS

if [ "$1" ] && [ "$1" != "-d" ] && [ "$1" != "-s" ] ; then

	for file in "$@" ; do
		help
	done

	delete_query
	detect_mp3info
	
	for file in "$@" ; do
		convert
	done
	exit 0
fi

# NO COMMAND LINE PARAMETERS (BESIDES "-s" or "-d")
# CONVERT ENTIRE DIRECTORY

p1=$1
p2=$2

delete_query
detect_mp3info
detect_supress

	for file in * ; do
		convert
	done
exit 0
