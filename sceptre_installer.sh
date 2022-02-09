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
backup_dir="$target_dir/${sym_name:0:3}_backup"
exit_status=0

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
	echo "Removed sym old link to ($sym_target)."
fi

# - ID tar extraction method
echo "- Identifying tar file extraction method..."
target_ext="xf"
if [ "$file" == "*.gz" ]; then
	target_ext="xzf"
fi
echo "- Identified tar file extraction method ($target_ext)."

# - Backup old installations if found
echo "- Backing up any old ($sym_name) copies to ($backup_dir)..."
mkdir $backup_dir
mv $target_dir/*${sym_name}* $backup_dir
echo "- Backup complete."

# - Extact tar file
echo "- Extracting tar file..."
# if extract_file=`tar -$target_ext $file -C $target_dir`; then
# 	$sym_target=`echo $extract_file | head -1 | cut -f1 -d"/"`
# else
	# echo "- Extraction of tar file failed."
# 	exit 1
# fi
# extract_file=`tar -$target_ext $file -C $target_dir` #&& $sym_target=`$extract_file | head -1 | cut -f1 -d"/"`i
if tar -$target_ext $file -C $target_dir; then
	sym_target="$(ls -t $target_dir | grep ${sym_name} | head -1)"
	echo "- Extracted tar file to ($sym_target)"
else
	echo "- Extraction failed."
	echo "- Replacing backups..."
	mv $backup_dir/* $target_dir
	echo "-	Replaced backups."
	exit_status=1
fi

# - Create Symbolic Link
echo "- Creating sym link at ($sym_full)..."
ln -s $sym_target $sym_full
echo "- Created sym link."

# Finalize
completion="complete!"
if [ $exit_status == 1 ]; then
	completion="failed."
fi
echo "Installation of '$file' $completion"
exit $exit_status

