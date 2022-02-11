#!/bin/bash -i

# Author:	Jake Crawford
# Created:	07 Feb 2022
# Updated:	11 Feb 2022
# Details:	Streamlines Sceptre installation based on the installation README


# Variables
file=$1
target_dir="/opt"
sym_name="sceptre"
sym_full="$target_dir/$sym_name"
sym_target=""
sym_internal="/bin/sceptregui"
backup_dir="$target_dir/${sym_name:0:3}_backup"
bashrc="*.bashrc"
exit_status=0

# Pre-checks
# - Check for Root access
if (($EUID != 0)); then
	echo "The installer must be run as root/sudo. (Example: sudo ./sceptre_installer.sh sceptre-#.##.#-os-version-info.tar)"
	exit 1
fi

# - Validate file input
if (($# == 0)); then
	read -p "The file to be installed must be specified. Please enter the file now: " $file
fi

# Installation
echo "Beginnning installation of '$sym_name' from '$file'..."
# - Sym Link
echo "- Checking for old Symbolic Links..."
if test -f "$sym_full"; then
	echo "-- Found old Symbolic Link. Removing..."
	sym_target=$(readlink $sym_full)
	rm $sym_full
	echo "-- Removed old Sym Link '$sym_full'."
fi
echo "- Checked for old Symbolic Links."

# - ID tar extraction method
echo "- Identifying tar file extraction method..."
target_ext="xf"
if [ "$file" == "*.gz" ]; then
	target_ext="xzf"
fi
echo "- Identified tar file extraction method '$target_ext'."

# - Backup old installations if found
echo "- Backing up any old '$sym_name' copies to '$backup_dir'..."
if mkdir $backup_dir >/dev/null 2>/dev/null; then
	echo "-- Backup folder created '$backup_dir'."
else
	echo "-- Backup folder '$backup_dir' already exists."
fi
if mv $target_dir/*${sym_name}* $backup_dir/ >/dev/null 2>/dev/null; then
	echo "-- Moved old '${sym_name}' copies."
else
	echo "-- No old '${sym_name}' copies found."
fi
echo "- Backup complete."

# - Extact tar file
echo "- Extracting tar file..."
if tar -$target_ext $file -C $target_dir; then
	sym_target="$(ls -t $target_dir | grep ${sym_name} | head -1)"
	echo "- Extracted tar file to '${target_dir}/$sym_target'."
else
	echo "- Extraction failed."
	echo "- Replacing backups..."
	mv $backup_dir/* $target_dir
	echo "-	Replaced backups."
	exit_status=1
fi

# - Create Symbolic Link
echo "- Creating sym link at '$sym_full'..."
ln -s ${sym_target}${sym_internal} $sym_full
chmod 777 $sym_full
echo "- Created sym link."

# - Check PATH for Target Directory
echo "- Checking if '$target_dir' is on PATH '$PATH'..."
addToPath () {
	cur_bash=$(find $1/ -name "$bashrc")
	echo "Current bashrc: $cur_bash"
	if [ ! "$(grep $target_dir $cur_bash)" ]; then
		echo "-- No '${target_dir}' on PATH for '$1'. Adding..."
		echo "export PATH=$PATH:${target_dir}" >> $cur_bash
		source $cur_bash
	fi
	if [[ $PATH != *":${target_dir}"* ]]; then
		echo "-- Add failed."
		exit_status=1
	else
		echo "-- Added '$target_dir' to file '$cur_bash' PATH '$PATH'."
	fi
}
addToPath ~
for dir in /home/*/; do
	addToPath $dir
done

echo "- Checked for '$target_dir' on PATH."

# Finalize Installation
completion="complete!"
if [ $exit_status == 1 ]; then
	completion="failed."
fi
echo "Installation of '$file' $completion"

if [ $exit_status == 0 ]; then
	echo "Current version: $($sym_name --version)"
	echo "Runnable with command: ${sym_name}"
fi
exit $exit_status

