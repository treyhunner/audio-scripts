#!/bin/bash

##################################################
#                  FFPGEN v1.0                   ##
#      Fingerprint directories of FLAC files     ##
#        Requires metaflac, find, and bash       ##
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
    [ "$(whereis $1 | sed 's/^\w*:\W*//')" != "" ] && $1 --help &> /dev/null ||
    $1 -h 1> /dev/null ||
    {
      echo "Error: dependency \"$1\" not met."
      exit 1
    }
}
usage() {
    echo "Usage: $0 [OPTION] [DIRECTORY]..."
    echo "Generate FLAC Fingerprint (FFP) files for directories containing FLAC files."
    echo
    echo "  -R  Create FFP files for directories recursively"
    echo "  -i  Compare current files to ffp files (do not create new files)"
    echo
    echo "If no directory is specified the current directory is used"
}
generate_ffp() {
    cd "$1" || exit 1

    FILE=fingerprint
    if [ $INTEGRITY_CHECK -ne 0 ] ; then
        if [ $(ls *.ffp 2> /dev/null | wc -l) -ne 0 ] ; then
            for file in *.ffp ; do
                if [ $(diff <(metaflac --show-md5sum *.flac) "$file" | wc -l) -eq 0 ] ; then
                    echo "FLAC files in $(pwd) match with $file"
                else
                    echo "Error: FLAC files in $(pwd) do not match with $file" >&2
                    EXIT=1
                fi
            done
        fi
    elif [ -s "$FILE.ffp" ] ; then
        echo "File $(pwd)/$FILE.ffp already exists."
    elif [ $(ls *.flac 2> /dev/null | wc -l) -ne 0 ] ; then
        if [ ! $(metaflac --show-md5sum *.flac > $FILE.ffp) ] ; then
            echo "FLAC Fingerprint file generated for directory $(pwd)"
        else
            echo "Error generating $(pwd)/$DATE.ffp" >&2
            EXIT=1
        fi
    fi

    if [ $RECURSIVE -ne 0 ] ; then
        IFS=$'\n'
        find . -mindepth 1 -maxdepth 1 -type d |
        while read DIR ; do
            generate_ffp "$DIR" || exit 1
        done
    fi

    cd - >> /dev/null
}


# Make sure metaflac and find are found
assert_dependency "metaflac"
assert_dependency "find"

trap "exit" SIGINT SIGTERM
set -e -o pipefail

# Identify all switches specified
DATESTAMP=0
RECURSIVE=0
INTEGRITY_CHECK=0
while [[ $# -gt 0 && $1 == -* ]]
do
  [ $1 == "-i" ] && INTEGRITY_CHECK=1
  [ $1 == "-R" ] && RECURSIVE=1
  [ $1 == "-D" ] && DATESTAMP=1
  [ $1 == "-h" ] && usage && exit
  shift
done

# Print usage information if no arguments were given
[ $# -le 0 ] && generate_ffp . || EXIT=1

# Loop through all parameters and treat each as a directory filled with flac files
while [ $# -gt 0 ] ; do
    generate_ffp "$1" || (EXIT=1 && break)
    shift
done

if [ $INTEGRITY_CHECK -ne 0 -a $EXIT -eq 0 ] ; then
    echo "All files matched."
fi
exit $EXIT
