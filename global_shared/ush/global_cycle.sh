#!/bin/ksh
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:         global_cycle.sh
# Script description:  Makes a global spectral model surface analysis
#
# Author:        Mark Iredell       Org: NP23         Date: 2005-02-03
#
# Abstract: This script makes a global spectral model surface analysis.
#
# Script history log:
# 2005-02-03  Iredell  extracted from global_analysis.sh
# 2014-11-30  xuli  add nst_anl
#
# Usage:  global_cycle.sh SFCGES SFCANL
#
#   Input script positional parameters:
#     1             Input surface guess
#                   defaults to $SFCGES; required
#     2             Output surface analysis
#                   defaults to $SFCANL, then to ${COMOUT}/sfcanl
#
#   Imported Shell Variables:
#     SFCGES        Input surface guess
#                   overridden by $1; required
#     SFCANL        Output surface analysis
#                   overridden by $5; defaults to ${COMOUT}/sfcanl
#     FIXgsm        Directory for global fixed files
#                   defaults to $HOMEglobal/fix
#     EXECgsm       Directory for global executables
#                   defaults to $HOMEglobal/exec
#     USHgsm        Directory for global scripts
#                   defaults to $HOMEglobal/ush
#     DATA          working directory
#                   (if nonexistent will be made, used and deleted)
#                   defaults to current working directory
#     COMIN         input directory
#                   defaults to current working directory
#     COMOUT        output directory
#                   (if nonexistent will be made)
#                   defaults to current working directory
#     XC            Suffix to add to executables
#                   defaults to none
#     PREINP        Prefix to add to input observation files
#                   defaults to none
#     SUFINP        Suffix to add to input observation files
#                   defaults to none
#     NCP           Copy command
#                   defaults to cp
#     SFCHDR        Command to read surface header
#                   defaults to ${EXECgsm}/global_sfchdr$XC
#     CYCLEXEC      Surface cycle executable
#                   defaults to ${EXECgsm}/global_cycle$XC
#     FNGLAC        Input glacier climatology GRIB file
#                   defaults to ${FIXgsm}/global_glacier.2x2.grb
#     FNMXIC        Input maximum sea ice climatology GRIB file
#                   defaults to ${FIXgsm}/global_maxice.2x2.grb
#     FNTSFC        Input SST climatology GRIB file
#                   defaults to ${FIXgsm}/global_sstclim.2x2.grb
#     FNSNOC        Input snow climatology GRIB file
#                   defaults to ${FIXgsm}/global_snoclim.1.875.grb
#     FNZORC        Input roughness climatology 
#                   defaults to sib vegetation type-based lookup table
#                   FNVETC must be set to sib file: ${FIXgsm}/global_vegtype.1x1.grb
#     FNALBC        Input albedo climatology GRIB file
#                   defaults to ${FIXgsm}/global_albedo4.1x1.grb
#     FNAISC        Input sea ice climatology GRIB file
#                   defaults to ${FIXgsm}/global_iceclim.2x2.grb
#     FNTG3C        Input deep soil temperature climatology GRIB file
#                   defaults to ${FIXgsm}/global_tg3clim.2.6x1.5.grb
#     FNVEGC        Input vegetation fraction climatology GRIB file
#                   defaults to ${FIXgsm}/global_vegfrac.1x1.grb
#     FNVETC        Input vegetation type climatology GRIB file
#                   defaults to ${FIXgsm}/global_vegtype.1x1.grb
#     FNSOTC        Input soil type climatology GRIB file
#                   defaults to ${FIXgsm}/global_soiltype.1x1.grb
#     FNSMCC        Input soil moisture climatology GRIB file
#                   defaults to ${FIXgsm}/global_soilmgldas.t${JCAP}.${LONB}.${LATB}.grb
#     FNVMNC        Input min veg frac climatology GRIB file
#                   defaults to ${FIXgsm}/global_shdmin.0.144x0.144.grb
#     FNVMXC        Input max veg frac climatology GRIB file
#                   defaults to ${FIXgsm}/global_shdmax.0.144x0.144.grb
#     FNSLPC        Input slope type climatology GRIB file
#                   defaults to ${FIXgsm}/global_slope.1x1.grb
#     FNABSC        Input max snow albedo climatology GRIB file
#                   defaults to ${FIXgsm}/global_snoalb.1x1.grb
#     FNMSKH        Input high resolution land mask GRIB file
#                   defaults to ${FIXgsm}/seaice_newland.grb
#     FNOROG        Input orography GRIB file (horiz resolution dependent)
#                   defaults to ${FIXgsm}/global_orography.t$JCAP.grb
#     FNOROG_UF     Input unfiltered orography GRIB file
#                   (horiz resolution dependent)
#                   defaults to ${FIXgsm}/global_orography_uf.t$JCAP.grb
#     FNMASK        Input land mask GRIB file (horiz resolution dependent)
#                   defaults to ${FIXgsm}/global_slmask.t$JCAP.grb
#     FNTSFA        Input SST analysis GRIB file
#                   defaults to ${COMIN}/${PREINP}sstgrb${SUFINP}
#     FNACNA        Input sea ice analysis GRIB file
#                   defaults to ${COMIN}/${PREINP}engicegrb${SUFINP}
#     FNSNOA        Input snow analysis GRIB file
#                   defaults to ${COMIN}/${PREINP}snogrb${SUFINP}
#     INISCRIPT     Preprocessing script
#                   defaults to none
#     LOGSCRIPT     Log posting script
#                   defaults to none
#     ERRSCRIPT     Error processing script
#                   defaults to 'eval [[ $err = 0 ]]'
#     ENDSCRIPT     Postprocessing script
#                   defaults to none
#     KEEPFH        Flag to keep fhour the same (YES or NO)
#                   defaults to NO
#     JCAP          Spectral truncation
#                   defaults to 382
#     CDATE         Output analysis date in yyyymmddhh format
#                   defaults to the value in the input surface file header
#     FHOUR         Output forecast hour
#                   defaults to the value in the input surface file header
#     LATB          Number of latitudes in surface cycling
#                   defaults to the value in the input surface file header
#     LONB          Number of longitudes in surface cycling
#                   defaults to the value in the input surface file header
#     LSOIL         Number of soil layers
#                   defaults to 4
#     FSMCL2        Scale in days to relax to soil moisture climatology
#                   defaults to 60
#     DELTSFC       Cycling frequency in hours
#                   defaults to forecast hour of $SFCGES
#     IALB          Integer flag for Albedo - 0 for Brigleb and 1 for Modis
#                   based albedo - defaults to 0
#     CYCLVARS      Other namelist inputs to the cycle executable
#                   defaults to none set
#     NTHREADS      Number of threads
#                   defaults to 1
#     NTHSTACK      Size of stack per thread
#                   defaults to 64000000
#     FILESTYLE     File management style flag
#                   ('C' to copy to/from $DATA, 'L' for symbolic links in $DATA,
#                    'X' to use XLFUNIT or symbolic links where appropriate)
#                   defaults to 'X'
#     PGMOUT        Executable standard output
#                   defaults to $pgmout, then to '&1'
#     PGMERR        Executable standard error
#                   defaults to $pgmerr, then to '&1'
#     pgmout        Executable standard output default
#     pgmerr        Executable standard error default
#     REDOUT        standard output redirect ('1>' or '1>>')
#                   defaults to '1>', or to '1>>' to append if $PGMOUT is a file
#     REDERR        standard error redirect ('2>' or '2>>')
#                   defaults to '2>', or to '2>>' to append if $PGMERR is a file
#     VERBOSE       Verbose flag (YES or NO)
#                   defaults to NO
#
#   Exported Shell Variables:
#     PGM           Current program name
#     pgm
#     ERR           Last return code
#     err
#
#   Modules and files referenced:
#     scripts    : $INISCRIPT
#                  $LOGSCRIPT
#                  $ERRSCRIPT
#                  $ENDSCRIPT
#
#     programs   : $CYCLEXEC
#
#     fixed data : $FNGLAC
#                  $FNMXIC
#                  $FNTSFC
#                  $FNSNOC
#                  $FNZORC
#                  $FNALBC
#                  $FNAISC
#                  $FNTG3C
#                  $FNVEGC
#                  $FNVETC
#                  $FNSOTC
#                  $FNSMCC
#                  $FNVMNC
#                  $FNVMXC
#                  $FNSLPC
#                  $FNABSC
#                  $FNMSKH
#                  $FNOROG
#                  $FNOROG_UF
#                  $FNMASK
#
#     input data : $SFCGES
#                  $FNTSFA
#                  $FNACNA
#                  $FNSNOA
#
#     output data: $SFCANL
#                  $PGMOUT
#                  $PGMERR
#
# Remarks:
#
#   Condition codes
#      0 - no problem encountered
#     >0 - some problem encountered
#
#  Control variable resolution priority
#    1 Command line argument.
#    2 Environment variable.
#    3 Inline default.
#
# Attributes:
#   Language: POSIX shell
#   Machine: IBM SP
#
################################################################################

#  Set environment.
export VERBOSE=${VERBOSE:-"NO"}
if [[ "$VERBOSE" = "YES" ]] ; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi
export machine=${machine:-WCOSS}
export machine=$(echo $machine|tr '[a-z]' '[A-Z]')
#if [ $machine = ZEUS ] ; then
# module load intel
# module load mpt
#fi
export APRUNCY=${APRUNCY:-""}

#  Command line arguments.
export SFCGES=${1:-${SFCGES:?}}
export SFCANL=${2:-${SFCANL}}

#  Directories.
export global_shared_ver=${global_shared_ver:-v13.0.0}
export BASEDIR=${BASEDIR:-${NWROOT:-/nwprod2}}
export HOMEglobal=${HOMEglobal:-$BASEDIR/global_shared.${global_shared_ver}}
export EXECgsm=${EXECgsm:-$HOMEglobal/exec}
export FIXSUBDA=${FIXSUBDA:-fix/fix_am}
export FIXgsm=${FIXgsm:-$HOMEglobal/$FIXSUBDA}
export USHgsm=${USHgsm:-$HOMEglobal/ush}
export DATA=${DATA:-$(pwd)}
export COMIN=${COMIN:-$(pwd)}
export COMOUT=${COMOUT:-$(pwd)}

#  Filenames.
export XC=${XC}
export PREINP=${PREINP}
export SUFINP=${SUFINP}
export KEEPFH=${KEEPFH:-NO}
export JCAP=${JCAP:-1534}
export SFCHDR=${SFCHDR:-$EXECgsm/global_sfchdr$XC}
export CYCLEXEC=${CYCLEXEC:-$EXECgsm/global_cycle$XC}
export nemsioget=${nemsioget:-$NWPROD/ngac.v1.0.0/exec/nemsio_get}
export NEMSIO_IN=${NEMSIO_IN:-.true.}
export OUTTYP=${OUTTYP:-1}
if [ ${NEMSIO_OUT:-".true."} = .true. ]; then export OUTTYP=1 ; fi
if [ ${SIGIO_OUT:-".false."} = .true. ]; then export OUTTYP=2 ; fi

if [[ $KEEPFH = YES ]];then
  if [[ $NEMSIO_IN = .true. ]] ; then
    export CDATE=$($nemsioget $SFCGES idate | grep -i "idate" |awk -F= '{print $2}')
    export FHOUR=$($nemsioget $SFCGES nfhour |awk -F"= " '{print $2}' |awk -F" " '{print $1}')
  else
    export CDATE=$($SFCHDR $SFCGES IDATE||echo 0)
    export FHOUR=$($SFCHDR $SFCGES FHOUR||echo 0)
  fi
else
  export CDATE=${CDATE}
  export FHOUR=${FHOUR:-00}
fi
if [[ $NEMSIO_IN = .true. ]] ; then
  export LATB=${LATB:-$($nemsioget $SFCGES LATR |awk -F"= " '{print $2}' |awk -F" " '{print $1}')}
  export LONB=${LONB:-$($nemsioget $SFCGES LONR |awk -F"= " '{print $2}' |awk -F" " '{print $1}')}
  export DELTSFC=${DELTSFC:-$($nemsioget $SFCGES nfhour |awk -F"= " '{print $2}' |awk -F" " '{print $1}')}
else
  export LATB=${LATB:-$($SFCHDR $SFCGES LATB||echo 0)}
  export LONB=${LONB:-$($SFCHDR $SFCGES LONB||echo 0)}
  export DELTSFC=${DELTSFC:-$($SFCHDR $SFCGES FHOUR||echo 0)}
fi
export LSOIL=${LSOIL:-4}
export FSMCL2=${FSMCL2:-60}
export IALB=${IALB:-0}
export CYCLVARS=${CYCLVARS}
export NTHREADS=${NTHREADS:-4}
export NTHSTACK=${NTHSTACK:-4096000000}
export use_ufo=${use_ufo:-.true.}
export nst_anl=${nst_anl:-.false.}
export nst_anl=${nst_anl:-.false.}
export nst_anl=${nst_anl:-.false.}

export FNGLAC=${FNGLAC:-${FIXgsm}/global_glacier.2x2.grb}
export FNMXIC=${FNMXIC:-${FIXgsm}/global_maxice.2x2.grb}
export FNTSFC=${FNTSFC:-${FIXgsm}/cfs_oi2sst1x1monclim19822001.grb}
export FNSNOC=${FNSNOC:-${FIXgsm}/global_snoclim.1.875.grb}
export FNZORC=${FNZORC:-sib}
export FNALBC=${FNALBC:-${FIXgsm}/global_albedo4.1x1.grb}
export FNAISC=${FNAISC:-${FIXgsm}/cfs_ice1x1monclim19822001.grb}
export FNTG3C=${FNTG3C:-${FIXgsm}/global_tg3clim.2.6x1.5.grb}
export FNVEGC=${FNVEGC:-${FIXgsm}/global_vegfrac.0.144.decpercent.grb}
export FNVETC=${FNVETC:-${FIXgsm}/global_vegtype.1x1.grb}
export FNSOTC=${FNSOTC:-${FIXgsm}/global_soiltype.1x1.grb}
export FNSMCC=${FNSMCC:-${FIXgsm}/global_soilmgldas.t${JCAP}.${LONB}.${LATB}.grb}
export FNVMNC=${FNVMNC:-${FIXgsm}/global_shdmin.0.144x0.144.grb}
export FNVMXC=${FNVMXC:-${FIXgsm}/global_shdmax.0.144x0.144.grb}
export FNSLPC=${FNSLPC:-${FIXgsm}/global_slope.1x1.grb}
export FNABSC=${FNABSC:-${FIXgsm}/global_snoalb.1x1.grb}
export FNMSKH=${FNMSKH:-${FIXgsm}/seaice_newland.grb}
export FNOROG=${FNOROG:-${FIXgsm}/global_orography.t$JCAP.$LONB.$LATB.grb}
export FNOROG_UF=${FNOROG_UF:-${FIXgsm}/global_orography_uf.t$JCAP.$LONB.$LATB.grb}
export FNMASK=${FNMASK:-${FIXgsm}/global_slmask.t$JCAP.$LONB.$LATB.grb}
export FNTSFA=${FNTSFA:-${COMIN}/${PREINP}sstgrb${SUFINP}}
export FNACNA=${FNACNA:-${COMIN}/${PREINP}engicegrb${SUFINP}}
export FNSNOA=${FNSNOA:-${COMIN}/${PREINP}snogrb${SUFINP}}
export SFCANL=${SFCANL:-${COMIN}/${PREINP}sfcanl}
export INISCRIPT=${INISCRIPT}
export ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}
export LOGSCRIPT=${LOGSCRIPT}
export ENDSCRIPT=${ENDSCRIPT}
#  Other variables.
export FILESTYLE=${FILESTYLE:-'X'}
export PGMOUT=${PGMOUT:-${pgmout:-'&1'}}
export PGMERR=${PGMERR:-${pgmerr:-'&2'}}
export REDOUT=${REDOUT:-'1>'}
export REDERR=${REDERR:-'2>'}
# Set defaults
################################################################################
#  Preprocessing
$INISCRIPT
pwd=$(pwd)
if [[ -d $DATA ]]
then
   mkdata=NO
else
   mkdir -p $DATA
   mkdata=YES
fi
cd $DATA||exit 99
[[ -d $COMOUT ]]||mkdir -p $COMOUT

################################################################################
#  Make surface analysis
export XLSMPOPTS="parthds=$NTHREADS:stack=$NTHSTACK"
export PGM=$CYCLEXEC
export pgm=$PGM
$LOGSCRIPT

rm $SFCANL
iy=$(echo $CDATE|cut -c1-4)
im=$(echo $CDATE|cut -c5-6)
id=$(echo $CDATE|cut -c7-8)
ih=$(echo $CDATE|cut -c9-10)

export OMP_NUM_THREADS=${OMP_NUM_THREADS_CY:-${CYCLETHREAD:-1}}

cat << EOF > fort.35
&NAMSFC
  FNGLAC="$FNGLAC",
  FNMXIC="$FNMXIC",
  FNTSFC="$FNTSFC",
  FNSNOC="$FNSNOC",
  FNZORC="$FNZORC",
  FNALBC="$FNALBC",
  FNAISC="$FNAISC",
  FNTG3C="$FNTG3C",
  FNVEGC="$FNVEGC",
  FNVETC="$FNVETC",
  FNSOTC="$FNSOTC",
  FNSMCC="$FNSMCC",
  FNVMNC="$FNVMNC",
  FNVMXC="$FNVMXC",
  FNSLPC="$FNSLPC",
  FNABSC="$FNABSC",
  FNMSKH="$FNMSKH",
  FNTSFA="$FNTSFA",
  FNACNA="$FNACNA",
  FNSNOA="$FNSNOA",
  LDEBUG=.false.,
  FSMCL(2)=$FSMCL2,
  FSMCL(3)=$FSMCL2,
  FSMCL(4)=$FSMCL2,
  $CYCLVARS
 /
EOF

eval $APRUNCY $CYCLEXEC <<EOF $REDOUT$PGMOUT $REDERR$PGMERR
 &NAMCYC 
  idim=$LONB, jdim=$LATB, lsoil=$LSOIL,
  iy=$iy, im=$im, id=$id, ih=$ih, fh=$FHOUR,
  DELTSFC=$DELTSFC,ialb=$IALB,use_ufo=$use_ufo,nst_anl=$nst_anl,
  OUTTYP=$OUTTYP
 /
 &NAMSFCD
  FNBGSI="$SFCGES",
  FNBGSO="$SFCANL",
  FNOROG="$FNOROG",
  FNOROG_UF="$FNOROG_UF",
  FNMASK="$FNMASK",
  LDEBUG=.false.,
 /
EOF

export ERR=$?
export err=$ERR
$ERRSCRIPT||exit 2

################################################################################
#  Postprocessing
cd $pwd
[[ $mkdata = YES ]]&&rmdir $DATA
$ENDSCRIPT
set +x
if [[ "$VERBOSE" = "YES" ]]
then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
