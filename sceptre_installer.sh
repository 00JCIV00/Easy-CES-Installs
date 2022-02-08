#!/bin/bash

# Author:	Jake Crawford
# Created:	07 Feb 2022
# Updated:	08 Feb 2022
# Details:	Streamlines Sceptre installation based on the installation README


# Variables
file=$1
target_dir="/opt"
sym_name="sceptre"
sym_full="$target_dir/$sym_name"
sym_target=""

# Pre-checks
# - Check for Root access
if (($EUID != 0)); then
	echo "The installer must be run as root/sudo."
	exit 1
fi

# - Validate file input
if (($# == 0)); then
	read -p "The file to be installed must be specified. Please enter the file now: " $file
fi

# Installation
echo "Beginnning installation of ($file)..."
# - Sym Link
if test -f "$sym_full"; then
	echo "Old sym link found. Removing..."
	$sym_target=$(readlink $sym_full)
	rm $sym_name
	echo "Removed sym old link."
fi

echo "- Identifying tar file extraction method..."
target_ext="xf"
if [ "$file" == "*.gz" ]; then
	$target_ext="xzf"
fi
echo "- Identified tar file extraction method ($target_ext)."

echo "- Extracting tar file..."
# if extract_file=`tar -$target_ext $file -C $target_dir`; then
# 	$sym_target=`echo $extract_file | head -1 | cut -f1 -d"/"`
# else
	echo "- Extraction of tar file failed."
# 	exit 1
# fi
extract_file=`tar -$target_ext $file -C $target_dir` #&& $sym_target=`$extract_file | head -1 | cut -f1 -d"/"`
echo "- Extracted tar file ($extract_file) to ($sym_target)."

echo "- Creating sym link at '$sym_full'..."
ln -s $sym_target $sym_full
echo "- Created sym link."


echo "Installation of '$file' complete!"
exit 0

