#!/bin/ksh
################################################################################
# This script runs the archive and cleanup.
# Usage: arch.sh
# Imported variables:
#   CONFIG
#   CDATE
#   CDUMP
#   CSTEP
# Configuration variables:
#   DATATMP
#   COMROT
#   COMDAY
#   HRKTMP
#   HRKROT
#   HRKSIG
#   HRKFLX
#   HRKSIGG
#   HRKPGBM
#   HRKVFY
#   HRKDAY
#   HRKOCN_NC
#   HRKOCN_ANL
#   HRKOCN_GRB
#   ALIST
#   PBEG
#   PERR
#   PEND
################################################################################
set -ux

################################################################################
# Go configure

export CKSH=$(echo $CSTEP|cut -c-4)
export CKND=$(echo $CSTEP|cut -c5-)
set -a;. $CONFIG;set +a
eval export DATA=$DATATMP
export COMROTTMP=${COMROTTMP:-$COMROT}
eval export COMROT=$COMROTTMP
eval export COMDAY=${COMDAY:-$COMROT}
export RESDIR=${RESDIR:-$COMROT/RESTART}
export ARCH_TO_HPSS=${ARCH_TO_HPSS:-YES}
cd;rm -rf $DATA||exit 1;mkdir -p $DATA||exit 1;cd $DATA||exit 1
#chgrp ${group_name:-rstprod} $DATA
chmod ${permission:-755} $DATA
#
export BASEDIR=${BASEDIR:-..}
export SHDIR=${SHDIR:-$BASEDIR/bin}
export USHDIR=${USHDIR:-$BASEDIR/ush}
export NWPROD=${NWPROD:-$BASEDIR}
#
PBEG=${PBEG:-$SHDIR/pbeg}
PEND=${PEND:-$SHDIR/pend}
PERR=${PERR:-$SHDIR/perr}
ARCHCFSRRSH=${ARCHCFSRRSH:-$BASEDIR/ush/cfsrr/hpss.cfsrr.daily.qsub}
CFSRR_ARCH=${CFSRR_ARCH:-YES}
HRKTMP=${HRKTMP:-24}
HRKRES=${HRKRES:-24}
HRKSIG=${HRKSIG:-120}
HRKFLX=${HRKFLX:-192}
HRKSIGG=${HRKSIGG:-120}
HRKPGBM=${HRKPGBM:-48}
HRKROT=${HRKROT:-120}
HRKDAY=${HRKDAY:-${HRKROT:-120}}
HRKVFY=${HRKVFY:-${HRKROT:-120}}
HRKOCN_NC=${HRKOCN_NC:-$HRKSIG}
HRKOCN_ANL=${HRKOCN_ANL:-$HRKROT}
HRKOCN_GRB=${HRKOCN_GRB:-$HRKROT}
HRKTMPGDAS=${HRKTMPGDAS:-$HRKTMP}
HRKTMPGFS=${HRKTMPGFS:-$HRKTMP}
HRKGEMPAK=${HRKGEMPAK:-$HRKTMP}
HRKBUFRSND=${HRKBUFRSND:-$HRKTMP}
HRKCOM=${HRKCOM:-$HRKTMP}

ARCH_GLOBSTAT=${ARCH_GLOBSTAT:-NO}
ARCHCOPY=${ARCHCOPY:-NO}
ARCHSCP=${ARCHSCP:-NO}
ARCHDAY=${ARCHDAY:-2}       # impacts delay for online archive only
BACKDATE=$((ARCHDAY*24))    # impacts delay for online archive only
BACKDATEVSDB=$((BACKDATE+24))
BACKDATEPRCP=$((BACKDATEVSDB+VBACKUP_PRCP))

DO_PRODNAMES=${DO_PRODNAMES:-NO}
PRODNAMES_DIR=${PRODNAMES_DIR:-$COMROT/prod}
SETUPPRODNAMESH=${SETUPPRODNAMESH:-$USHDIR/setup_prodnames.sh}

PARA_CHECK_STATUS=${PARA_CHECK_STATUS:-NO}
PARA_CHECK_CDUMP=${PARA_CHECK_CDUMP:-"gfs gdas"}
PARA_CHECK_CYCLE=${PARA_CHECK_CYCLE:-"00 06 12 18"}
PARA_CHECK_RUNSH=${PARA_CHECK_RUNSH:-$USHDIR/para_check_run.sh}
PARA_CHECKSH=${PARA_CHECKSH:-$USHDIR/para_check_status.sh}
PARA_CHECK_MAIL=${PARA_CHECK_MAIL:-$LOGNAME}

GENGEMPAK=${GENGEMPAK:-NO}
GENGEMPAK_META=${GENGEMPAK_META:-NO}
NAWIPSSH=${NAWIPSSH:-$USHDIR/nawips.sh}
NAWIPSMETASH=${NAWIPSMETASH:-$USHDIR/nawips_meta.sh}

GENBUFRSND=${GENBUFRSND:-NO}
POSTSNDSH=${POSTSNDSH:-$USHDIR/postsnd.sh}


RSTPRODSH=${RSTPRODSH-$NWPROD/runhistory.v2.1.26/ush/rhist_restrict.sh}
TSM_FLAG=${TSM_FLAG:-NO}

myhost=$(hostname)
case $myhost in
  g*) export HOST=gyre;;
  t*) export HOST=tide;;
  *) echo unexpected hostname $myhost;HOST="";;
esac

if [[ $ARCHSCP = YES ]];then
  if [[ $HOST = gyre ]]; then
     SCPTO=tide
  elif [[ $HOST = tide ]]; then
     SCPTO=gyre
  else
     SCPTO=undefined
     ARCHSCP=NO
     echo "ARCHSCP turned off.  No valid remote host."
  fi
  ARCHSCPTO=${ARCHSCPTO:-$SCPTO}
fi

$PBEG

################################################################################
# Set other variables

export PCOP=${PCOP:-$SHDIR/pcop}
export NCP=${NCP:-cp}
export SCP=${SCP:-/usr/bin/scp}
export NDATE=${NDATE:-${NWPROD}/util/exec/ndate}
export COPYGB=${COPYGB:-${NWPROD}/util/exec/copygb}
export NCEPPOST=${NCEPPOST:-NO}
export CYINC=${CYINC:-06}
export CDFNL=${CDFNL:-gdas}
export GDATE=$($NDATE -$CYINC $CDATE)
export HPSSTAR=${HPSSTAR:-$BASEDIR/ush/hpsstar}
export SUB=${SUB:-$BASEDIR/bin/sub}
export HTAR=${HTAR:-/apps/hpss/htar}
export HSI=${HSI:-/apps/hpss/hsi}

export fhmax_1=${fmax1:-192}
export fhmax_2=${fmax2:-384}
export io_save=${io_save:-144}
export jo_save=${jo_save:-73}
export pgbf_gfs=${pgbf_gfs:-3}     #resolution of gfs pgbf files saved in HPSS archive, 3-1x1,4-0.5x0.5
export pgbf_gdas=${pgbf_gdas:-4}   #resolution of gdas pgbf files saved in HPSS archive
export pgbf_grid=$(eval echo \$pgbf_$CDUMP)
if [ $pgbf_grid -eq 4 ] ; then
 export flag_pgb=h
elif [ $pgbf_grid -eq 3 ] ; then
 export flag_pgb=f
elif [ $pgbf_grid -eq 2 ] ; then
 export flag_pgb=l
fi
export flag_pgb=${flag_pgb:-f}


SDATE=$CDATE
BDATE=$($NDATE -$BACKDATE $CDATE)    # online archive date only


################################################################################# Copy files to online archive
if [[ $ARCHCOPY = YES ]];then
 if [[ ! -s $ARCDIR ]]; then
    mkdir -p $ARCDIR
 fi

 SPECIALARCHSH=${SPECIALARCHSH:-""}
 if [ ! -z $SPECIALARCHSH ]; then
   if [ -s $SPECIALARCHSH ] ; then
     $SPECIALARCHSH
   fi
   rc=$?
   if [[ $rc -ne 0 ]];then $PERR;exit 1;fi
   $PEND
 fi

 export CDATE=$BDATE

# be sure we are in working directory $DATA
 cd $DATA
# rm *

# return code gets checked for any required files (ARCR)
 $PCOP $CDATE/$CDUMP/arch/ARCR $COMROT   $DATA <$RLIST
 rc=$?

#  Comment out next two  pcops so RLIST isn't reprocessed for FIT_DIR and HORZ_DIR
#   - reduces unnecessary errors
#   - at this time at least, no fit or horiz files are listed as ARCR anyway
#     because archiving of these done in global_savefits.sh (called by vrfy.sh)
#  Uncomment if deemed necessary (old setups?  future use?)
# $PCOP $CDATE/$CDUMP/arch/ARCR $FIT_DIR  $DATA <$RLIST
# ((rc+=$?))
# $PCOP $CDATE/$CDUMP/arch/ARCR $HORZ_DIR $DATA <$RLIST
# ((rc+=$?))

# dayfiles may not be stored in COMROT...
#    need to work on this to avoid unnecessary errors
 [ $COMDAY != $COMROT ] && $PCOP $CDATE/$CDUMP/arch/ARCR $COMDAY   $DATA <$RLIST

 ((rc+=$?))

# optional files
 $PCOP $CDATE/$CDUMP/arch/ARCO $COMROT $DATA <$RLIST
 [ $COMDAY != $COMROT ] && $PCOP $CDATE/$CDUMP/arch/ARCO $COMDAY   $DATA <$RLIST

 # Check to see if we only need to save the low resolution pgrb file online
 #   This is done for gfs and gdas pgb files archived via ARCR or ARCO

 if [ $io_save -lt $io_1 -a $jo_save -lt $jo_1 ] ; then
   if [ $NCEPPOST = YES ] ; then
     eval fhmax_cvt=\${fhmax_$fseg}
   elif [ $io_save -lt $io_2 -a $jo_save -lt $jo_2 ] ; then
     fhmax_cvt=$fhmax_2
   else
     fhmax_cvt=$fhmax_1
   fi

   if [ $io_save = 144 -a $jo_save = 73 ] ; then
#    copygbvars="-g2 -i1,1"
     copygbvars="-g2 -i0"
   elif [ $io_save = 360 -a $jo_save = 181 ] ; then
#    copygbvars="-g3 -i2"
     copygbvars="-g3 -i0"
   else
     copygbvars=" "
   fi

## for file in `ls pgbf*.$CDUMP.$CDATE  2>/dev/null` ; do
   for file in `ls pgb${flag_pgb}*.$CDUMP.$CDATE  2>/dev/null` ; do
     fhr=`echo $file |awk -F"." '{print $1}' |cut -c5-`
     if [ $fhr -le $fhmax_cvt ] ; then
       fname=pgbf${fhr}.$CDUMP.$CDATE
       if [ $file != $fname ]; then
          mv $file $fname
       fi
       $COPYGB $copygbvars -x $fname ${fname}.lowres
       sleep 2
       mv ${fname}.lowres $fname
     fi
   done
   if [ -s pgb${flag_pgb}nl.$CDUMP.$CDATE ]; then
     file=pgb${flag_pgb}nl.$CDUMP.$CDATE
     $COPYGB $copygbvars -x $file ${file}.lowres
     sleep 2
     mv ${file}.lowres $file
   fi
   if [ -s pgbanl.$CDUMP.$CDATE ]; then
     file=pgbanl.$CDUMP.$CDATE
     $COPYGB $copygbvars -x $file ${file}.lowres
     sleep 2
     mv ${file}.lowres $file
   fi
 fi

  $NCP *${CDATE}* $ARCDIR/
  CDATE00=$(echo $CDATE|cut -c1-8)
  $NCP $COMROT/*SCORES*${CDATE00}* $ARCDIR/

# CONUS pcp score (rain) file directly copied to $ARCDIR 
# via vsdbjob.sh in vrfy.sh.   Thus, no rain file in $COMROT
##CDATE00=$(echo $($NDATE -${BACKDATEPRCP:-00} $CDATE) |cut -c1-8 )
##$NCP $COMROT/*rain*${CDATE00}* $ARCDIR/

  if [[ $LOGNAME = glopara && $ARCHSCP = YES ]]; then
     $SCP *${CDATE}* $LOGNAME@$ARCHSCPTO:$ARCDIR/
##   list="SCORES rain"
     list="SCORES"
     for file in $list; do
        CDATE00=$(echo $CDATE|cut -c1-8)
        $SCP $COMROT/*${file}*${CDATE00}* $LOGNAME@$ARCHSCPTO:$ARCDIR/
     done
  fi


fi

export CDATE=$SDATE

################################################################################
# Zhu archive.
if [[ $ARCH_GLOBSTAT = YES ]];then
  if [[ $LOGNAME = glopara  ]];then
    if [[ $CDUMP = $CDFNL ]];then
     RUN=GDAS ; if [ $NOANAL = YES ] ; then RUN=GFS ; fi
     RUN=GDAS EXP=$PSLOT CDIR=$COMROT EDIR=$EXPDIR $SUB -a $ACCOUNT \
     -g class1onprod -e 'CDATE,RUN,EXP,CDIR,EDIR' -j garch.FNL$PSLOT.$CDATE \
     -o /global/shared/stat/$EXPDIR/FNL$PSLOT.$CDATE -u globstat@$HOST \
     /global/save/wx20rt/globstat/arch/garch.lls
    else
     RUN=MRF EXP=$PSLOT CDIR=$COMROT EDIR=$EXPDIR $SUB -a $ACCOUNT \
     -g class1onprod-e 'CDATE,RUN,EXP,CDIR,EDIR' -j garch.GFS$PSLOT.$CDATE \
     -o /global/shared/stat/$EXPDIR/GFS$PSLOT.$CDATE -u globstat@$HOST \
     /global/save/wx20rt/globstat/arch/garch.lls
    fi
  fi
fi

###############################################################################

################################################################################
# Archive to tape.

# export CDATE=$BDATE    # commented out because short hrksigg is sometimes required
export CDATE=$SDATE      # so, instead, archive to tape asap
rc=0

SGDATE=$GDATE
if [ $ARCH_TO_HPSS = YES ] ; then
 cycle=$(echo $CDATE|cut -c9-10)
 cdump=$(echo $CDUMP|tr '[a-z]' '[A-Z]')

# GDATE and GDATE00 for SCORES and rain files
 export GDATE=$($NDATE -6 $CDATE)
 export CDATE00=$(echo $CDATE|cut -c1-8)
 export GDATE00=$(echo $GDATE|cut -c1-8)
# cd $DATA

 for a in ARCA ARCB ARCC ARCD ARCE ARCF ARCG ;do
   NDATA=$DATA/$a
   mkdir -p $NDATA||exit 1;cd $NDATA||exit 1
   rm *
   eval eval afile=\${$a$cycle$cdump:-null}
   if [[ $afile != null ]];then
# make hpss directory if it doesn't exist
     if [ $machine = IBMP6 ] ; then
       $HPSSTAR dir `dirname $afile` > /dev/null 2>&1   #dcs
       [ $? -ne 0 ] && $HPSSTAR mkd `dirname $afile`
     elif [ $machine = THEIA -o $machine = WCOSS ] ; then
       $HSI mkdir -p ${ATARDIR}
     fi
     $PCOP $CDATE/$CDUMP/arch/$a $COMROT $NDATA <$RLIST
     [ $COMDAY != $COMROT ] && $PCOP $CDATE/$CDUMP/arch/$a $COMDAY $NDATA <$RLIST
     sleep 30
     if [ $machine = IBMP6 ] ; then
       $HPSSTAR put $afile *
       ((rc+=$?))
     elif [ $machine = THEIA -o $machine = WCOSS ] ; then
     np='1/1/S'
     mem='1024/1'
     tl=${TIMELIMARCH:-'3:00:00'}
     qq=${CUE2RUNA:-transfer}
     jn=hpsstrans$a$cycle$cdump
     out=$COMROT/${a}${CDATE}${CDUMP}${CSTEP}.transfer
     trans_local=$COMROT/transfer_${a}_${CDATE}${CDUMP}${CSTEP}
     > $trans_local
     echo "#!/bin/ksh"          >> $trans_local
     echo "set -ax"             >> $trans_local
     echo "export NDATA=$NDATA" >> $trans_local
     echo "export HTAR=$HTAR"   >> $trans_local
     echo "export afile=$afile" >> $trans_local
     echo ""                    >> $trans_local
     echo "cd $NDATA"           >> $trans_local
     echo "$HTAR -cvf $afile *" >> $trans_local
     echo "rc=\$?"               >> $trans_local
     echo "export TSM_FLAG=$TSM_FLAG" >> $trans_local
     echo "$RSTPRODSH $afile"   >> $trans_local
     echo "if [[ \$rc -eq 0 ]]; then rm -rf *${CDATE}* ; fi"   >> $trans_local
     chmod 755 $trans_local
     en=CONFIG="$trans_local"
     $SUB -e $en -q $qq -a $ACCOUNT -g $GROUP -p $np -r $mem -t $tl -j $jn -o $out $trans_local
     ((rc+=$?))
     fi

   fi
 done
fi

if [[ $CFSRR_ARCH = YES && $CDATE = ????????00 ]];then
 xdate=$($NDATE -24 $CDATE)
 $ARCHCFSRRSH pr$PSLOT $xdate $CDUMP $COMROT
fi

export CDATE=$SDATE
export GDATE=$SGDATE

################################################################################
# Clean up.

# rm old work directories
HRKTMPDIR=$HRKTMP
if [[ $CDUMP = gdas ]] ; then
  HRKTMPDIR=$HRKTMPGDAS
elif [[ $CDUMP = gfs ]] ; then
  HRKTMPDIR=$HRKTMPGFS
fi
rdate=$($NDATE -$HRKTMPDIR $CDATE)
rm -rf $(CDATE=$rdate CDUMP=$CDUMP CSTEP='*' eval ls -d $DATATMP) 2>/dev/null

# Save ARCDIR
export ARCDIR_SAVE=$ARCDIR

# define function to check that verifications files are archived online before clean up.
chkarc ()
{
  set -x
    ARCDIR=$1
    for verif_file in `ls $rmfiles 2>/dev/null`
    do
      if [ ! -s $ARCDIR/$verif_file ]; then
        set +x
        echo "****  VERIFICATION FILE $verif_file MISSING FROM $ARCDIR"
        echo "****  WILL ATTEMPT TO MOVE $verif_file TO $ARCDIR NOW"
        echo "****  TAPE ARCHIVE SHOULD BE CHECKED"
        set -x
        mv $verif_file $ARCDIR
      fi
    done
}

## for dayfiles, cd to COMDAY to avoid hitting unix line length limit ("Arg list too long.")
cd $COMDAY
rdate=$($NDATE -$HRKDAY $CDATE)
rm $PSLOT$rdate*dayfile 2>/dev/null

## for other files, cd to COMROT to avoid hitting unix line length limit ("Arg list too long.")

cd $COMROT

# sigma/gfnf and surface files of age HRKSIG
rdate=$($NDATE -$HRKSIG $CDATE)
rm ${SIGOSUF}f*.$CDUMP.$rdate* 2>/dev/null
rm ${SFCOSUF}f*.$CDUMP.$rdate* 2>/dev/null
# use touch to prevent system scrubber from removing
# aged sig and sfc files (3 days) that are used for fit2obs
if [ $CDUMP = gfs ]; then
 cycle=$(echo $CDATE|cut -c9-10)
 keepday=$($NDATE -72 $(date +%Y%m%d)$cycle )
 sdate=$($NDATE +12 $rdate)
 while [ $sdate -le $CDATE ]; do
  if [ -s ${SIGOSUF}f24.$CDUMP.$sdate ]; then
   sigctime=$(stat -c '%y' ${SIGOSUF}f24.$CDUMP.$sdate | cut -c 1-10 | sed 's/-//g')$cycle
   if [ $keepday -gt $sigctime ]; then
    touch ${SIGOSUF}f*.$CDUMP.$sdate
    touch ${SFCOSUF}f*.$CDUMP.$sdate
   fi
  fi
  sdate=$($NDATE +12 $sdate)
 done
fi

# flx files of age HRKFLX  
rdate=$($NDATE -$HRKFLX $CDATE)
rm ${FLXOSUF}f*.$CDUMP.$rdate* 2>/dev/null
# use touch to prevent system scrubber from removing 
# aged flx files (3 days) that are used for QPF computation 
if [ $CDUMP = gfs ]; then
 cycle=$(echo $CDATE|cut -c9-10)
 keepday=$($NDATE -72 $(date +%Y%m%d)$cycle )
 sdate=$($NDATE +12 $rdate)
 while [ $sdate -le $CDATE ]; do
  if [ -s ${FLXOSUF}f24.$CDUMP.$sdate ]; then
   flxctime=$(stat -c '%y' ${FLXOSUF}f24.$CDUMP.$sdate | cut -c 1-10 | sed 's/-//g')$cycle
   if [ $keepday -gt $flxctime ]; then touch ${FLXOSUF}f*.$CDUMP.$sdate ; fi
  fi
  sdate=$($NDATE +12 $sdate)
 done
fi

# sigma/gfnf guess files of age HRKSIGG
rdate=$($NDATE -$HRKSIGG $CDATE)
rm sigg*.$CDUMP.$rdate* 2>/dev/null

# gaussin and/or high-resolution pgb files of age HRKPGBM
rdate=$($NDATE -$HRKPGBM $CDATE)
rm pgbm*.$CDUMP.$rdate* 2>/dev/null
rm pgbh*.$CDUMP.$rdate* 2>/dev/null
rm pgbq*.$CDUMP.$rdate* 2>/dev/null
# use touch to prevent system scrubber from removing 
# aged pgbq files (3 days) that are used for QPF computation for NEMS GFS 
if [ $CDUMP = gfs ]; then
 cycle=$(echo $CDATE|cut -c9-10)
 keepday=$($NDATE -72 $(date +%Y%m%d)$cycle )
 sdate=$($NDATE +12 $rdate)
 while [ $sdate -le $CDATE ]; do
  if [ -s pgbq24.$CDUMP.$sdate ]; then
   flxctime=$(stat -c '%y' pgbq24.$CDUMP.$sdate | cut -c 1-10 | sed 's/-//g')$cycle
   if [ $keepday -gt $flxctime ]; then touch pgbq*.$CDUMP.$sdate ; fi
  fi
  sdate=$($NDATE +12 $sdate)
 done
fi

# remove ocean files
if [ $COUP_FCST = YES ] ; then

# remove netcdf ocean files (ocn and ice)
 rdate=$($NDATE -$HRKOCN_NC $CDATE)
 rm ocn_*.$CDUMP.$rdate* 2>/dev/null
 rm ice_*.$CDUMP.$rdate* 2>/dev/null

# remove  ocean analysis files
 rdate=$($NDATE -$HRKOCN_ANL $CDATE)
 rm ${OCNISUF}.$CDUMP.$rdate* 2>/dev/null

# remove  ocean forecast grib  files
 rdate=$($NDATE -$HRKOCN_GRB $CDATE)
 rm ocnh*.$CDUMP.$rdate* 2>/dev/null
 rm ocnf*.$CDUMP.$rdate* 2>/dev/null
fi

# remaining CDUMP files except flxf of age HRKROT
rdate=$($NDATE -$HRKROT $CDATE)
#rm *.$CDUMP.$rdate* 2>/dev/null
rm $(ls *.$CDUMP.$rdate* |grep -v ${FLXOSUF}f ) 2>/dev/null

# verification files of age HRKVFY
rdate=$($NDATE -$HRKVFY $CDATE)
rdate00=$(echo $rdate|cut -c1-8)
rmfiles="SCORES${PSLOT}.$rdate pr${PSLOT}_rain_$rdate00"
# check that they have been archived online.  no check for tape archive.
[[ $ARCHCOPY = YES ]] && chkarc $ARCDIR
rm $rmfiles 2>/dev/null

# check fits safely archived before removal
rmfiles="f*.acar.$rdate f*.acft.$rdate f*.raob.$rdate f*.sfc.$rdate"
FIT_DIR=${FIT_DIR:-$ARCDIR}
chkarc $FIT_DIR
rm $rmfiles 2>/dev/null

rmfiles="*.anl.$rdate"
HORZ_DIR=${HORZ_DIR:-$ARCDIR}
#chkarc ${HORZ_DIR}/anl   # need to pass in modified filename for this to work (do later)
rm $rmfiles 2>/dev/null

rmfiles="*.fcs.$rdate"
#chkarc ${HORZ_DIR}/fcs   # need to pass in modified filename for this to work (do later)
rm $rmfiles 2>/dev/null

#
# Clean the restart files in the RESTART directory
#
cd $RESDIR
rdate=$($NDATE -$HRKRES $CDATE)
rm sig1r*.$CDUMP.$rdate*       2>/dev/null
rm sig2r*.$CDUMP.$rdate*       2>/dev/null
rm sfcr*.$CDUMP.$rdate*       2>/dev/null
if [ $COUP_FCST = YES ] ; then
 rm omrest*.$CDUMP.$rdate.*.tar 2>/dev/null
 rm *.2restart*.$CDUMP.$rdate   2>/dev/null
 rm fluxes_for*.$CDUMP.$rdate.* 2>/dev/null
#rm noah.rst*.$rdate     2>/dev/null
fi

#
# If requested, make symbolic links to create ops-like /com/gfs files
if [ $DO_PRODNAMES = YES ] ; then
  rc=0
  if [ ! -s $PRODNAMES_DIR ] ; then
    mkdir -p $PRODNAMES_DIR
    rc=$?
  fi
  if [[ $rc -eq 0 ]]; then
     $SETUPPRODNAMESH $COMROT $PRODNAMES_DIR $CDATE $CDUMP $HRKCOM
     rc_prod=$?
  else
     echo "ARCH:  ***WARNING*** CANNOT mkdir $PRODNAMES_DIR.  Will NOT run $SETUPPRODNAMESH"
     rc_prod=9
  fi
fi


# If requested, save special sigf and sfcf files for HWRF group      
if [ $CDUMP = gfs -a $ARCH_TO_HPSS = YES -a ${HWRF_ARCH:-NO}  = YES ] ; then
set -x
  export INHERIT_ENV=YES
  export PSLOT=$PSLOT               
  export CDATE=$CDATE               
  export FHMAX_HWRF=${FHMAX_HWRF:-126}
  export FHOUT_HWRF=${FHOUT_HWRF:-6}
  export ATARDIR_HWRF=${ATARDIR_HWRF:-/2year/NCEPDEV/emc-hwrf/GFS-PR4DEV}
  np='1/1/S'
  mem='1024/1'
  tl=${TIMELIMARCH:-'3:00:00'}
  qq=${CUE2RUNA:-transfer}
  jn=hpsstranshwrf$CDATE
  out=$COMROT/hpsstranshwrf$CDATE                      
  job=${HWRFARCHSH:-$USHDIR/global_save4hwrf.sh}
  en="PSLOT,CDATE,COMROT,FHMAX_HWRF,FHOUT_HWRF,HPSSTAR,ATARDIR_HWRF"
  $SUB -e $en -q $qq -a $ACCOUNT -g $GROUP -p $np -r $mem -t $tl -j $jn -o $out $job
  export INHERIT_ENV=NO
fi


cd $DATA

# If requsted, generate status message
if [ $PARA_CHECK_STATUS = YES ] ; then
   for PARA_CDUMP in $PARA_CHECK_CDUMP; do
      if [ $CDUMP = $PARA_CDUMP ] ; then
         CYCLE=$(echo $CDATE|cut -c9-10)
         for PARA_CYCLE in $PARA_CHECK_CYCLE; do
            if [ $CYCLE = $PARA_CYCLE ] ; then
               $PARA_CHECK_RUNSH
            fi
         done
      fi
   done
fi

################################################################################
# If requested, make gempak.
if [ $CDUMP = gfs -a $DO_PRODNAMES = YES -a $GENGEMPAK = YES ];then
  export mem=16384
  export jn=${PSLOT}${CDATE}${CDUMP}gempak
  export out=$COMROT/${jn}.dayfile
  $SUB -e 'CDATE=$CDATE CDUMP=$CDUMP CSTEP=$CSTEP CONFIG=$CONFIG' -q $CUE2RUN -a $ACCOUNT -g $GROUP -p 6/6/N -r $mem/1/2 -t 06:00 -j $jn -o $out $NAWIPSSH

  if [ $GENGEMPAK_META = YES ];then
    export mem=16384
    export jn=${PSLOT}${CDATE}${CDUMP}gempak_meta
    export out=$COMROT/${jn}.dayfile
    $SUB -e 'CDATE=$CDATE CDUMP=$CDUMP CSTEP=$CSTEP CONFIG=$CONFIG' -q $CUE2RUN -a $ACCOUNT -g $GROUP -p 25/25/N -r $mem/1/8 -t 06:00 -j $jn -o $out $NAWIPSMETASH
  fi

  rdate=$($NDATE -$HRKGEMPAK $CDATE)   
  pdyr=`echo $rdate | cut -c1-8`
  cycr=`echo $rdate | cut -c9-10`
  cd $COMROT/nawips
  rm gfs.$pdyr/gfs*_${rdate}* 2>/dev/null
  rm gfs.$pdyr/gfs.t${cycr}z*idx 2>/dev/null
fi

################################################################################
# If requested, make GFS station profiles in bufr format
if [ $CDUMP = gfs -a $DO_PRODNAMES = YES -a $GENBUFRSND = YES ];then
   PDY=`echo $CDATE | cut -c1-8`
   export COMIN=$PRODNAMES_DIR/com/gfs/para/$CDUMP.$PDY
   export COMOUT=$COMROT/nawips/$CDUMP.$PDY
   mkdir -p $COMOUT
   export pid=$$
   export JCAP=${JCAP:-574}
   export LEVS=${LEVS:-64}
   export LATB=${LATB:-880}
   export LONB=${LONB:-1760}
   export STARTHOUR=${STARTHOUR:-00}
   export ENDHOUR=${ENDHOUR:-180}
   export jn=${PSLOT}${CDATE}${CDUMP}bufrsnd
   export out=$COMROT/${jn}.dayfile
   mac=`hostname |cut -c1`
   if [ $mac = g -o $mac = t ]; then
      export launcher=mpirun.lsf
      $SUB -a $ACCOUNT -e 'GFLUX=$GFLUX,GBUFR=$GBUFR,TOCSBUFR=$TOCSBUFR,launcher=$launcher,HOMEbufr=$HOMEbufr,PARMbufr=$PARMbufr,CDATE=$CDATE,COMIN=$COMIN,COMOUT=$COMOUT,DATA=$DATA,BASEDIR=$BASEDIR,JCAP=$JCAP,LEVS=$LEVS,LATB=$LATB,LONB=$LONB,STARTHOUR=$STARTHOUR,ENDHOUR=$ENDHOUR,FIXGLOBAL=$FIXGLOBAL' -q $CUE2RUN -p 5/5/N  -r 16000/16/1 -t 3:00:00 -j $jn -o $out $POSTSNDSH
   elif [ $mac = f ]; then
      export launcher=mpiexec_mpt
      CUE2RUN=bigmem
      export KMP_STACKSIZE=2048m
      $SUB -a $ACCOUNT -e machine=$machine,GFLUX=$GFLUX,GBUFR=$GBUFR,TOCSBUFR=$TOCSBUFR,KMP_STACKSIZE=$KMP_STACKSIZE,launcher=$launcher,PARMbufr=$PARMbufr,CDATE=$CDATE,COMROT=$COMROT,COMIN=$COMIN,COMOUT=$COMOUT,DATA=$DATA,BASEDIR=$BASEDIR,JCAP=$JCAP,LEVS=$LEVS,LATB=$LATB,LONB=$LONB,STARTHOUR=$STARTHOUR,ENDHOUR=$ENDHOUR,FIXGLOBAL=$FIXGLOBAL -q $CUE2RUN -p 3/2/g2  -r 36000/3/1 -t 3:00:00 -j $jn -o $out $POSTSNDSH
   fi

   rdate=$($NDATE -$HRKBUFRSND $CDATE)
   pdyr=`echo $rdate | cut -c1-8`
   cycr=`echo $rdate | cut -c9-10`
   cd $COMROT/nawips/gfs.$pdyr
   rm -rf bufr.t${cycr}z 2>/dev/null
   rm gfs.t${cycr}z.bufrsnd.tar.gz 2>/dev/null
   rm nawips/gfs_${pdyr}${cycr}* 2>/dev/null
   rmdir nawips
fi

################################################################################
# Exit gracefully

if [[ $rc -ne 0 ]];then $PERR;exit 1;fi
$PEND
