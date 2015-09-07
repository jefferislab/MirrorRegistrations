#!/bin/bash

# User config
REFLOC="ReferenceBrains"	# Relative location of reference brain image
MUNGER="munger"         	# Command or path to munger program
CMTK="/opt/local/bin/"  	# Path to bin directory containing cmtk commands (for calling reformatx from munger)

if [ -z "$*" ]; then echo "Usage: autoflip.sh <TEMPLATE_NAME>"; exit 0; fi

NAME=$1
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
cp $REFLOC/$NAME.nrrd $NAME/refbrain/

# Flip brain and save to correct location, via Fiji
echo 'open("'$ROOTDIR/$NAME'/refbrain/'$NAME'.nrrd"); run("Flip Horizontally", "stack"); setKeyDown("alt"); run("Nrrd ... ", "nrrd='$ROOTDIR/$NAME'/images/'$NAME'flip_01.nrrd");' > fijitmp.ijm
rm fijitmp.ijm

fiji -batch $ROOTDIR'/fijitmp.ijm' 
cd $NAME

# Create munger command
CMD="$MUNGER -v -b $CMTK -awr 01 -l af -T 7 -X 13 -C 5 -G 40 -R 3 -A '--accuracy 0.4 --omit-original-data' -W ' --omit-original-data --accuracy .4' -s 'refbrain/$NAME.nrrd' 'images'"

# Save munger command to commands directory
CMDFILE="commands/warp_${NAME}_${NAME}_flip.command"
echo "#!/bin/bash" >> ${CMDFILE}
echo "#" $(date) >> ${CMDFILE}
echo "" >> ${CMDFILE}
echo $CMD >> ${CMDFILE}

# Run munger
eval $CMD
