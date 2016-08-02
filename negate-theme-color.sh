#!/bin/bash


# Usefull fonctions
exit_err()
{
	echo "$1" 1>&2
	exit $2
}

###########################
# Basic usage/safety check
###########################

test $# -ne 1 && exit_err "Usage: $0 [theme directory]" 1
! test -d $1 && exit_err "$1 is not a directory!" 2

SRC_DIR="$(readlink -f $1)"
DST_DIR="$HOME/.themes/${SRC_DIR##*/}_negate"

test -d "$DST_DIR" && exit_err "$DST_DIR already exist! Remove or rename it to continue." 3

echo "You're about to copy $SRC_DIR to $DST_DIR, are you sure? (Y/N)"
( read R && echo $R | grep -qi "y" ) || exit 0

cp -r $SRC_DIR $DST_DIR || exit_err "Failed to copy $SRC_DIR to $DST_DIR" 4
cd $DST_DIR || exit_err "Failed to go to $DST_DIR" 5

############################
# Serious things start here
############################

# List text files to update
FILES=$( find . -regex ".*css\|.*rc\|.*theme\|.*xml" )

# Exchange black and white keywords
sed -i 's/black/w_h_i_t_e/g' $FILES
sed -i 's/white/b_l_a_c_k/g' $FILES
sed -i 's/w_h_i_t_e/white/g' $FILES
sed -i 's/b_l_a_c_k/black/g' $FILES

# Negate color defined like #123456789ABC
for COLOR in $( cat $FILES | grep -oE "#[0-9a-fA-F]{12}" | tr -d '#' | sort | uniq); do	
	sed -i "s/#$COLOR/__N_E_W__C_O_L_O_R__$( printf %012X $(( 0xffffffffffff - 0x$COLOR )) )/g" $FILES
done

# Negate color defined like #123456
for COLOR in $( cat $FILES | grep -E "#[0-9a-fA-F]{6}[^0-9a-fA-F]" | grep -oE "#[0-9a-fA-F]{6}" | tr -d '#' | sort | uniq); do	
	sed -i "s/#$COLOR\([^0-9A-Fa-f]\|$\)/__N_E_W__C_O_L_O_R__$( printf %06X $(( 0xffffff - 0x$COLOR )) )\1/g" $FILES
done

# Negate color defined like #123
for COLOR in $( cat $FILES | grep -E "#[0-9a-fA-F]{3}[^0-9a-fA-F]" | grep -oE "#[0-9a-fA-F]{3}" | tr -d '#' | sort | uniq); do	
	sed -i "s/#$COLOR\([^0-9A-Fa-f]\|$\)/__N_E_W__C_O_L_O_R__$( printf %03X $(( 0xfff - 0x$COLOR )) )\1/g" $FILES
done

sed -i 's/__N_E_W__C_O_L_O_R__/#/g' $FILES

# Negate color defined like "rgba(238, 238, 236, 0.3)" and "rgb (104, 193, 25)"
while read i; do
	COLOR_1=$(echo $i | sed 's/rgb[a ]*([ ]*\([0-9]\+\)[, ]\+.*/\1/g')
	COLOR_2=$(echo $i | sed 's/rgb[a ]*([ ]*[0-9]\+[, ]\+\([0-9]\+\)[, ]\+.*/\1/g')
	COLOR_3=$(echo $i | sed 's/rgb[a ]*([ ]*[0-9]\+[, ]\+[0-9]\+[, ]\+\([0-9]*\)[^0-9]*.*/\1/g')
	sed -i "s/rgb\([a ]*([ ]*\)$COLOR_1\([, ]\+\)$COLOR_2\([, ]\+\)$COLOR_3\([^0-9]*.*\)/__N_E_W__R_G_B__\1$(( 255 - COLOR_1 ))\2$(( 255 - COLOR_2 ))\3$(( 255 - COLOR_3 ))\4/g" $FILES
done <<< "$(cat $FILES | grep -oE "rgb[a ]*\([ ]*[0-9]{1,3}[, ]+[0-9]{1,3}[, ]+[0-9]{1,3}" | sort | uniq)"

sed -i 's/__N_E_W__R_G_B__/rgb/g' $FILES

# Negate pictures
for i in $( find . -name "*.png"); do
	convert $i -negate $i
done
