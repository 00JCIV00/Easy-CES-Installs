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
	cur_bashrc=$(find $1 -maxdepth 1 -name "$bashrc" -type f)
	path_add="export PATH=$PATH:${target_dir}"	
	if [ ! "$(grep "export PATH=" $cur_bashrc | grep "${target_dir}")" ]; then
		echo "-- No '${target_dir}' on PATH for '$cur_bashrc'. Adding..."
		echo $path_add >> $cur_bashrc
		source $cur_bashrc
		if [[ $PATH != *":${target_dir}"* ]]; then
			echo "-- Add failed."
			exit_status=1
		else
			echo "-- Added '$target_dir' to file '$cur_bashrc' PATH '$PATH'."
		fi	
	else 
		echo "-- Found '${target_dir}' on PATH for '$cur_bashrc'."
	fi
}
addToPath /etc/
addToPath ~/
for dir in /home/*/; do
	addToPath $dir
done

echo "- Checked for '$target_dir' on PATH."

# Finalize Installation
completion="complete!"
if [ $exit_status == 1 ]; then
	completion="failed."
else
	echo "- Removing old copies of '$sym_name'..."
	if rm -rf $backup_dir >/dev/null 2>/dev/null; then
		echo "- Removed old copies of '$sym_name'."
	else
		echo "- Failed to remove old copies of '$sym_name'. (Possibly due to a fresh install with no backups.)"
	fi

	echo "Current version: $($sym_name --version)"
	echo "Runnable with command: ${sym_name}"
      	echo "(May require a new terminal for PATH changes to take effect.)"
fi
echo "Installation of '$file' $completion"

exit $exit_status

