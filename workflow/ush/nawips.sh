#!/bin/ksh

########################################
# Runs GFS Postprocessing up to 24 hours
########################################

set -ux

set -a; . $CONFIG; set +a

export RUN_ENVIR=para
export envir=para
export job=gfs_gempak
export pid=$$
export DATAROOT=$STMP/$LOGNAME
export PDY=`echo $CDATE | cut -c1-8`
export cyc=`echo $CDATE | cut -c9-10`

export SENDCOM=YES
export SENDDBN=NO
export SENDECF=NO

export gfs_ver=v12.0.8
export util_ver=v1.0.0
export HOMEgempak=/nwprod/gfs.${gfs_ver}/gempak
export HOMEgfs=/nwprod/gfs.${gfs_ver}
export HOMEutil=/nwprod/util.${util_ver}

export COM_IN=$PRODNAMES_DIR/com/gfs/para
export COM_OUT=$COMROT/nawips
export jlogfile=$COM_OUT/jlogfile.${job}.${pid}

# #### 08/25/1999 ###################
# SET SHELL PROCESSING VARIABLES
# ###################################
export PS4='$SECONDS + ' 
date
# 
# obtain unique process id (pid) and make temp directories
#

export RUN_ENVIR=${RUN_ENVIR:-prod}

export NET=${NET:-gfs}
export RUN=${RUN:-gfs}

###############################################################
# This block can be modified for different Production test
# environment. This is used for operational testings
###############################################################
if [ $RUN_ENVIR = "prod" -a $envir != "prod" ]
then
   export DBNROOT=/nwprod/spa_util/fakedbn
   export jlogfile=${jlogfile:-/com/logs/${envir}/jlogfile}
fi

export pid=$$
export DATA=$DATAROOT/${job}.${pid}
mkdir $DATA
cd $DATA 

####################################
# File To Log Msgs
####################################
export jlogfile=${jlogfile:-/com/logs/jlogfiles/jlogfile.${job}.${pid}}

####################################
# Determine Job Output Name on System
####################################
export outid="LL$job"
export jobid="${outid}.o${pid}"
export pgmout="OUTPUT.${pid}"

export cycle=t${cyc}z 

export SENDCOM=${SENDCOM:-YES}
export SENDDBN=${SENDDBN:-YES}
export SENDECF=${SENDECF:-YES}

# For half-degree P Grib files 
export DO_HD_PGRB=${DO_HD_PGRB:-YES}

#
# Set up model and cycle specific variables
#
export finc=${finc:-3}
export fstart=${fstart:-0}
export model=${model:-gfs}
export GRIB=${GRIB:-pgrb2f}
export EXT=""
export DBN_ALERT_TYPE=${DBN_ALERT_TYPE:-GFS_GEMPAK}

export HOMEgempak=${HOMEgempak:-/nw${envir}/gfs.${gfs_ver}/gempak}
export FIXgempak=${FIXgempak:-$HOMEgempak/fix}
export USHgempak=${USHgempak:-$HOMEgempak/ush/gfs}

export HOMEgfs=${HOMEgfs:-/nw${envir}/gfs.${gfs_ver}}
export SRCgfs=${SRCgfs:-$HOMEgfs/scripts}
export GFSNAWIPSSH=${GFSNAWIPSSH:-$SRCgfs/exgfs_nawips.sh.ecf}

#
# Now set up GEMPAK/NTRANS environment
#
. /nwprod/gempak/.gempak

###################################
# Set up the UTILITIES
###################################
export HOMEutil=${HOMEutil:-/nw${envir}/util.${util_ver}}
export utilscript=${utilscript:-$HOMEutil/ush}
export utilities=${utilities:-$HOMEutil/ush}
export utilexec=${utilexec:-$HOMEutil/exec}

# Run setup to initialize working directory and utility scripts
$utilscript/setup.sh

# Run setpdy and initialize PDY variables
##$utilscript/setpdy.sh
##. PDY

export COM_IN=${COM_IN:-/com/${NET}/${envir}}
export COM_OUT=${COM_OUT:-/com/nawips/${envir}}
export COMIN=${COMIN:-${COM_IN}/${RUN}.${PDY}}
export COMOUT=${COMOUT:-${COM_OUT}/${RUN}.${PDY}}

if [ ! -f $COMOUT ] ; then
  mkdir -p -m 775 $COMOUT
fi

env

#################################################################
# Execute the script for the 384 hour 1 degree grib

echo "$GFSNAWIPSSH gfs 384 GFS_GEMPAK" >>poescript
##################################################################

#################################################################
# Execute the script for the half-degree grib

echo "$GFSNAWIPSSH gfs_0p50 384 GFS_GEMPAK" >>poescript

#################################################################
# Execute the script for the quater-degree grib

echo "$GFSNAWIPSSH gfs_0p25 384 GFS_GEMPAK" >>poescript

####################################################################
# Execute the script to create the 35km Pacific grids for OPC

echo "$GFSNAWIPSSH gfs35_pac 180 GFS_GEMPAK_WWB" >>poescript
#####################################################################

####################################################################
# Execute the script to create the 35km Atlantic grids for OPC

echo "$GFSNAWIPSSH gfs35_atl 180 GFS_GEMPAK_WWB" >>poescript
#####################################################################

#####################################################################
# Execute the script to create the 40km grids for HPC

echo "$GFSNAWIPSSH gfs40 180 GFS_GEMPAK_WWB" >>poescript
######################################################################

cat poescript

chmod 775 $DATA/poescript
export MP_PGMMODEL=mpmd
export MP_CMDFILE=$DATA/poescript

# Execute the script.

mpirun.lsf

cat $pgmout

# If requested, submit gempak meta job
##if [ $CDUMP = gfs -a $GENGEMPAK_META = YES ];then
##  export mem=16384
##  export jn=${PSLOT}${CDATE}${CDUMP}gempak_meta
##  export out=$COMROT/${jn}.dayfile
##  $SUB -e 'CDATE=$CDATE CDUMP=$CDUMP CSTEP=$CSTEP CONFIG=$CONFIG' -q $CUE2RUN -a $ACCOUNT -g $GROUP -p 25/25/N -r $mem/1/8 -t 06:00 -j $jn -o $out $NAWIPSMETASH
##fi

##date
##cd $DATA
##cd ../
##rm -rf $DATA
##date

