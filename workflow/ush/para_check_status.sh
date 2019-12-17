#!/bin/ksh

# Set variables based on run time input
PSLOT=$1
CDATE=$2
CDUMP=$3


# Define local variables
export ARCDIR=${ARCDIR_SAVE:-$NOSCRUB/$LOGNAME/archive/pr$PSLOT}
export COMROT=${ROTDIR:-$PTMP/$LOGNAME/pr$PSLOT}
export NDATE=${NDATE:-$NWPROD/util/exec/ndate}
export vsdbsave=${vsdbsave:-$NOSCRUB/$LOGNAME/archive/vsdb_data}
export FIT_DIR=${FIT_DIR:-$ARCDIR/fits}
export PARA_CHECK_BACKUP=${PARA_CHECK_BACKUP:-72}
export QSTAT=${QSTAT:-/u/emc.glopara/bin/qjob}
export HPSSTAR=${HPSSTAR:-/nwprod/util/ush/hpsstar}
export PARA_CHECK_HPSS_LIST=${PARA_CHECK_HPSS_LIST:-"gfs gdas gdas.enkf.obs gdas.enkf.anl gdas.enkf.fcs06"}


# Back up PARA_CHECK_BACKUP from CDATE.  
export BDATE=`$NDATE -${PARA_CHECK_BACKUP} $CDATE`
export BDATE_HPSS=`$NDATE -12 $CDATE`
export EDATE=$CDATE


# Check parallel status
echo "Check pr$PSLOT for $CDUMP $BDATE to $EDATE at `date`"

echo " "
echo "Check jobs queue"
$QSTAT | grep $PSLOT 

echo " "
echo "Check for abend jobs"
cd $COMROT
ls -ltr *dayfile*abend* | tail -10

echo " "
echo "Check for job errors"
cd $COMROT
CDATE=$BDATE
while [[ $CDATE -le $EDATE ]]; do
  for file in `ls *${CDATE}*dayfile`; do
    if (($(egrep -c "job killed" $file) > 0 || $(egrep -c "segmentation fault" $file) > 0));then
      echo " $file KILLED or SEG FAULT"
    fi
    if (($(egrep -c "msgtype=ERROR" $file) > 0));then
      echo " $file had msgtype=ERROR"
    fi
    if (($(egrep -c "quota exceeded" $file) > 0));then
      echo " $file exceeded DISK QUOTA"
    fi
  done
  ADATE=`$NDATE +06 $CDATE`
  CDATE=$ADATE
done

echo " "
echo "Check rain"
cd $ARCDIR
ls -l *rain* | tail -10

echo " "
echo "Check vsdb"
cd $vsdbsave/anom/00Z/pr$PSLOT
ls -l | tail -10

echo " "
echo "Check fits"
cd $FIT_DIR
CDATE=$BDATE
while [[ $CDATE -le $EDATE ]]; do
   echo "$CDATE `ls *${CDATE}* |wc -l`"
   ADATE=`$NDATE +06 $CDATE`
   CDATE=$ADATE
done

echo " "
echo "Check $ARCDIR"
cd $ARCDIR
rm -rf $TMPDIR/temp.disk
ls > $TMPDIR/temp.disk
CDATE=$BDATE
while [[ $CDATE -le $EDATE ]]; do
   echo "$CDATE `grep $CDATE $TMPDIR/temp.disk | wc -l`"
   ADATE=`$NDATE +06 $CDATE`
   CDATE=$ADATE
done

echo " "
echo "Check HPSS jobs"
cd $COMROT
CDATE=$BDATE_HPSS
while [ $CDATE -le $EDATE ] ; do
   for file in `ls *ARC*${CDATE}*transfer*`; do
      count=`grep "HTAR: HTAR FAIL" $file | wc -l`
      if [ $count -gt 0 ]; then
         echo `grep "HTAR: HTAR FAIL" $file` $file
      else
         count=`grep "HTAR: HTAR SUCC" $file | wc -l`
         if [ $count -gt 0 ]; then
            echo `grep "HTAR: HTAR SUCC" $file` $file
         else
            count=`grep "defined signal" $file | wc -l`
            if [ $count -gt 0 ]; then
               echo `grep "HTAR: HTAR signal FAIL" $file` $file
            else
               echo "$file RUNNING"
            fi
         fi
      fi
   done
   adate=`$NDATE +06 $CDATE`
   CDATE=$adate
done

echo " "
echo "Check $ATARDIR"
rm -rf $TMPDIR/temp.hpss
$HPSSTAR dir $ATARDIR > $TMPDIR/temp.hpss
for type in $PARA_CHECK_HPSS_LIST; do
   CDATE=$BDATE_HPSS
   while [ $CDATE -le $EDATE ] ; do
      grep "${CDATE}$type.tar" $TMPDIR/temp.hpss
      adate=`$NDATE +06 $CDATE`
      CDATE=$adate
   done
   echo " "
done

# Check NOSCRUB, STMP, and PTMP usage
echo "Check quotas"
grep "emc-global" /ptmpd1/fsets/${HOST}.filesets  | sort -n -r -k7
grep "tmp-"       /ptmpd1/fsets/${HOST}.filesets  | sort -n -r -k7
grep "emc-global" /ptmpp2/fsets/${HOST}2.filesets | sort -n -r -k7
grep "tmp-"       /ptmpp2/fsets/${HOST}2.filesets | sort -n -r -k7

exit






