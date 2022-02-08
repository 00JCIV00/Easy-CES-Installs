#!/bin/bash

# Author:	Jake Crawford
# Created:	07 Feb 2022
# Updated:	07 Feb 2022
# Details:	Streamlines Sceptre installation

# Pre-checks
# - Check for Root access
if (($EUID != 0)); then
	echo "The installer must be run as root/sudo."
	exit 1
fi

# - Validate file input
if (($# == 0)); then
	echo "File to be installed must be specified."
	exit 1
fi

# Variables
target_dir="/opt"
sym_name="sceptre"
sym_full="$target_dir/$sym_name"
sym_target=""

# Installation
echo "Beginnning installation of '$1'..."
# - Sym Link
if test -f "$sym_full"; then
	echo "Old sym link found. Removing..."
	$sym_target=$(readlink $sym_full)
	rm $sym_name
	echo "Removed sym old link."
fi

target_ext="xf"
if ("$1" == "*.gz"); then
	$target_ext="xzf"
fi

if extract_file=$(tar -$target_ext $1 -C $target_dir); then
	$sym_target = $(echo $extract_file | cut -f1 -d" ")
fi

echo "Creating sym link at '$sym_full'..."
ln -s $sym_target $sym_full
echo "Created sym link."


echo "Installation of '$1' complete."
exit 0

