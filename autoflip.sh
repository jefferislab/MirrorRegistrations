#!/bin/bash
if [ -z "$*" ]; then echo "Usage: autoflip.sh <TEMPLATE_NAME> <path/to/inputimage.nrrd>"; exit 0; fi

# Find path to bin directory containing cmtk commands (for calling reformatx from munger)
CMTK=`which cmtk`
grepres=`file -L $CMTK | grep script`
if [ -z "$grepres" ]; then echo "cannot find cmtk shell script!"; exit 0; fi
CMTK_BINARY_DIR=`grep CMTK_BINARY_DIR "$CMTK" | head -n 1 | grep -Eo '/[^}]+'`
if [ -z "$CMTK_BINARY_DIR" ]; then echo "cannot find cmtk binary directory from shell script!"; exit 0; fi

# User config
REFLOC="ReferenceBrains"	# Relative location of reference brain image
MUNGER= `which munger 2> /dev/null`         	# Command or path to munger program
if [ -z "$MUNGER" ]; then MUNGER=`which munger.pl`; fi
if [ -z "$MUNGER" ]; then echo "Cannot find CMTK contributed munger[.pl] script"; exit 0; fi

NAME=$1
INPUTIMG=$2
ROOTDIR=$(pwd)

# Set up directory structure
mkdir -p $NAME/commands;           	# Log directory for munger command
mkdir -p $NAME/images;             	# Mirror image location (automatically produced and saved here)
mkdir -p $NAME/refbrain;           	# Reference brain location (the reference brain is automatically copied from the $REFLOC directory)
mkdir -p $NAME/reformatted;        	# Output directory for transformed images
mkdir -p $NAME/Registration;       	# Contains transformation descriptions saved by CMTK
mkdir -p $NAME/Registration/affine;	# Affine transformation is saved here by CMTK
mkdir -p $NAME/Registration/warp;  	# Warp transformation is saved here by CMTK

# Copy reference brain into proper location
INPUTNAME=`basename $INPUTIMG`
REFPATH="$NAME/refbrain/$NAME.nrrd"
cp $INPUTIMG $REFPATH

# Flip brain and save to correct location, via Fiji
echo 'open("'$ROOTDIR/$REFPATH'"); run("Flip Horizontally", "stack"); setKeyDown("alt"); run("Nrrd ... ", "nrrd='$ROOTDIR/$NAME'/images/'$NAME'flip_01.nrrd");' > fijitmp.ijm

fiji -batch $ROOTDIR'/fijitmp.ijm' 
rm fijitmp.ijm
cd $NAME

# Create munger command
CMD="$MUNGER -v -b $CMTK_BINARY_DIR -awr 01 -l af -T 7 -X 13 -C 4 -G 20 -R 2 -A '--accuracy 0.4 --omit-original-data' -W '--accuracy .4' -s 'refbrain/$NAME.nrrd' 'images'"

# Save munger command to commands directory
CMDFILE="commands/warp_${NAME}_${NAME}_flip.command"
echo "#!/bin/bash" >> ${CMDFILE}
echo "#" $(date) >> ${CMDFILE}
echo "" >> ${CMDFILE}
echo $CMD >> ${CMDFILE}

# Run munger
eval $CMD
