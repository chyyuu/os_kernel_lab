#!/bin/bash
#=========================================================================
# vcs-version.sh [options] [src-dir]
#=========================================================================
#
#  -h  Display this message
#  -v  Verbose mode
#
# This script will create a version string by querying a version control
# system. The string is appropriate for use in installations and
# distributions. Currently this script assumes we are using git as our
# version control system but it would be possible to check and see if we
# are using an alternative version control system and create a version
# string appropriately.
# 
# The script uses git describe plus a few other git commands to create a
# version strings in the following format:
#
#  X.Y[-Z-gN][-dirty]
#
# where X is the major release, Y is the minor release, Z is the number
# of commits since the X.Y release, N is an eight digit abbreviated SHA
# hash of the most recent commit and the dirty suffix is appended when
# the working directory used to create the installation or distribution
# is not a pristine checkout. Here are some example version strings:
#
#  0.0                    : initial import
#  0.0-3-g99ef6933        : 3rd commit since initial import (N=99ef6933)
#  1.0                    : release 1.0
#  1.1-12-g3487ab12       : 12th commit since release 1.1 (N=3487ab12)
#  1.1-12-g3487ab12-dirty : 12th commit since release 1.1 (N=3487ab12)
#
# The last example is from a dirty working directory. To find the last
# release, the script looks for the last tag (does not need to be an
# annotated tag, but probably should be) which matches the format rel-*.
# If there is no such tag in the history, then the script uses 0.0 as
# the release number and counts the total number of commits since the
# original import for the commit count.
#
# If the current directory is not within the working directory, then the
# path to the source directory should be supplied on the command line.
#
# Author : Christopher Batten
# Date   : August 5, 2009

set -e

#-------------------------------------------------------------------------
# Command line parsing
#-------------------------------------------------------------------------

if ( test "$1" = "-h" ); then
  echo ""
  sed -n '3p' $0 | sed -e 's/#//'
  sed -n '5,/^$/p' $0 | sed -e 's/#//'
  exit 1
fi

# Source directory command line option

src_dir="."
if ( test -n "$1" ); then
  src_dir="$1"
fi

#-------------------------------------------------------------------------
# Verify source directory
#-------------------------------------------------------------------------
# If the source directory is not a git working directory output a
# question mark. A distribution will not be in a working directory, but
# the build system should be structured such that this script is not
# executed (and instead the version information should probably come
# from configure). If the user does not specify a source directory use
# the current directory.

if !( git rev-parse --is-inside-work-tree &> /dev/null ); then
  echo "?"
  exit 1;
fi

top_dir=`git rev-parse --show-cdup`
cd ./${top_dir}

#-------------------------------------------------------------------------
# Create the version string
#-------------------------------------------------------------------------
# See if we can do a describe based on a tag and if not use a default
# release number of 0.0 so that we always get canonical version number

if ( git describe --tags --match "rel-*" &> /dev/null ); then
  ver_str=`git describe --tags --match "rel-*" | sed 's/rel-//'`
else
  ver_num="0.0"
  ver_commits=`git rev-list --all | wc -l | tr -d " "`
  ver_sha=`git describe --tags --match "rel-*" --always`
  ver_str="${ver_num}-${ver_commits}-g${ver_sha}"
fi

# Add a dirty suffix if working directory is dirty

if !( git diff --quiet ); then
  ver_str="${ver_str}-dirty"
else
  untracked=`git ls-files --directory --exclude-standard --others -t`
  if ( test -n "${untracked}" ); then
    ver_str="${ver_str}-dirty"
  fi  
fi

# Output the final version string

echo "${ver_str}"

# Final exit status

exit 0;

