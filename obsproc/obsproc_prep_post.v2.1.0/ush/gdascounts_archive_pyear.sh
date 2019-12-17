#
set -x
#--------------------------------------------------------------------------
#
#  gdascounts_archive_pyear.sh
#
#  This script copies, on the 2nd day of February 18Z run (for computing
#  the January statistics of the current year's data), all the data for 
#  the previous year (all calendar months JAN, FEB, MAR, ....., OCT, NOV, DEC) 
#  from the directory /com/gfs/prod/satcounts to another new directory 
#  /com/gfs/prod/satcounts_archive/YYYY(previous year)  (eg., for the 
#  current year 2009, a directory /com/gfs/prod/satcounts_archive/2008 
#  containing all the calendar months JAN, FEB, MAR, ....., OCT, NOV, DEC
#  will be created).
#
#  History:
#  V. Krishna Kumar  2009/01/12 New script for operations 
#--------------------------------------------------------------------------

  satcom=$ARCHCOM/satcounts
  satcom_archive=$ARCHCOM/satcounts_archive
  CUR_DATE=`date +%Y%m%d`
  CUR_YEAR=`echo ${CUR_DATE} | cut -c1-4`
  LYEAR=`expr $CUR_YEAR - 1`
  cal_months='JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC'
#
# Create the archival directories for the previous year for all
# calendar months
#
  for cmon in $cal_months
  do
     mkdir -p $satcom_archive/${LYEAR}/$cmon
     # Create these directories on the backup CCS as well
     ssh devwcoss "mkdir -p $satcom_archive/${LYEAR}/$cmon"
  done
#
# Copy all the previous year's calendar months data to the newly
# created archival directory 
#
  for cmon in $cal_months
  do 
    mv $satcom/$cmon/*${LYEAR}* $satcom_archive/${LYEAR}/$cmon/
    # Move these files on the backup CCS as well to avoid problems
    # when switching CCS with the transfers copying old data back into
    # the active satcounts directories
    ssh devwcoss "mv $satcom/$cmon/*${LYEAR}* $satcom_archive/${LYEAR}/$cmon/"
  done
exit
