#
#--------------------------------------------------------------------------
#
#  gdas_summary.sh     
#
#  This script invokes script gdas_countstat.sh  each
#  of four cycle times (00,06,12,18) and then computes daily average counts
#  with monthly_ave.  In addition, counts for several satellite data types
#  are made.  These counts are written into web pages and forwarded to the 
#  WOK for display on the GDAS observational counts website.
#  
#  History:
#  L. Sager   09/07  Modified the script to work properly in operations.
#  V. Krishna Kumar 03/23 Modified the script to copy the final index file to
#                         the /com/arch/prod directory.
#                         For any reason, the final index file (for the month
#                         the stats are computed, for example, February 2009) 
#                         gets corrupted (could happen if this job is repeatedly run),
#                         please delete the corrupted index.shtml and copy over 
#                         from the previous month's backup (in this example, January 2009) 
#                         cp /com/arch/prod/index_backup.shtml /com/arch/prod/index.shtml 
#  D. Stokes  04/2015     Moved to vertical structure package obsproc_prep_post 
#                         and updated variables pointing to other software
#                         included in this migration.  Added variables in place
#                         of some hardwired settings to aid non-prod runs.  
#                         Added option to send html updates to developer 
#                         website for checkout runs.
#--------------------------------------------------------------------------


  set -x
# Parse arguments, if any

if [ $# -eq 3 ]; then

  date=$1
  YEAR=`echo $date | cut -c1-4 `
  MM=`echo $date | cut -c5-6`
  last_mon=$MM
  month=$2
  numdays=$3

  MON=`echo $month | tr [a-z] [A-Z]`
  MONTH=`$utilscript/month_name.sh $MM MONTH`
  Month=`$utilscript/month_name.sh $MM Month` 

else

#  CUR_DAY=`date +%d`
#  CUR_DATE=`date +%Y%m%d`
  CUR_DATE=${monsummary_dat:-`date +%Y%m%d`}
  CUR_DAY=`echo $CUR_DATE|cut -c 7-8`

  last_date=`sh $utilscript/finddate.sh ${CUR_DATE} d-${CUR_DAY}`

  numdays=`echo ${last_date} | cut -c7-8`
  YEAR=`echo ${last_date} | cut -c1-4`
  last_mon=`echo $last_date | cut -c5-6`
  MM=$last_mon                      

  date=${YEAR}${last_mon}01

  MON=`$utilscript/month_name.sh $last_mon MON`
  MONTH=`$utilscript/month_name.sh $last_mon MONTH`
  Month=`$utilscript/month_name.sh $last_mon Month`
 
fi

  month=$MON
  export MM MON MONTH Month YEAR
  echo -e "\n MON = ${MON}   MONTH = $MONTH   Month = $Month   YEAR = $YEAR \n"
  FIRSTDAY=$date
  NDAYS=$numdays

  echo -e "\n FIRSTDAT = $FIRSTDAY   NDAYS = $NDAYS \n" 

  export FIRSTDAY NDAYS

#  Summarize last month so reset file date to last month. 
#  SATCOM_monsum_base and DATCOM_monsum_base allow for alternate input source.

  SATCOM_monsum_base=${SATCOM_monsum_base:-/com/gfs/${envir}}
  if [[ "$USE_SATCOUNTS_ARCHIVE" == YES ]];then
    SATCOM=${SATCOM_monsum_base}/satcounts_archive/$YEAR/$MON   # for restoring past months
  else
    SATCOM=${SATCOM_monsum_base}/satcounts/$MON
  fi
  DATCOM_monsum_base=${DATCOM_monsum_base:-/com/arch/${envir}}
  DATCOM=${DATCOM_monsum_base}/data_counts.${YEAR}${last_mon}

#  Extract the non-sat data counts from the monthly archive

#    00Z counts

  sh $USHobsproc_prep_post/gdas_countstat.sh $date gdas $numdays 00 ${MONTH} 

#    06Z counts

  sh $USHobsproc_prep_post/gdas_countstat.sh $date gdas $numdays 06 ${MONTH}

#    12Z counts

  sh $USHobsproc_prep_post/gdas_countstat.sh $date gdas $numdays 12 ${MONTH} 
 
#    18Z counts

  sh $USHobsproc_prep_post/gdas_countstat.sh $date gdas $numdays 18 ${MONTH}


#   Execute monthly_avg

export FORT10=gdas_${MONTH}_dumpstats.t00z
export FORT11=gdas_${MONTH}_dumpstats.t06z
export FORT12=gdas_${MONTH}_dumpstats.t12z
export FORT13=gdas_${MONTH}_dumpstats.t18z
export FORT50=tmp1


#  Compute average daily non-sat counts for the month ( output is in file tmp1 )

  export pgm=gdascounts_ave
  prep_step
  $EXECobsproc_prep_post/gdascounts_ave 1>aa.out 2>aa.out
  export err=$?; err_chk


#  Build the script that creates the html table for non-sat counts

sed -e 's/= /=/g' tmp1 > tmp2
sed -e 's/= \./=0\./g' tmp2  > tmp3
sed -e 's/= */=/g' tmp3 > ${MONTH}.gdas.outfile
echo "MONTH=${MONTH}" > ${MONTH}.htmlscript
echo "YEAR=$YEAR" >> ${MONTH}.htmlscript
cat ${MONTH}.gdas.outfile >> ${MONTH}.htmlscript
echo "cat <<EOF > ${MONTH}.html" >> ${MONTH}.htmlscript
cat $FIXobsproc_prep_post/gdascounts_html  >> ${MONTH}.htmlscript


#  Run the script

  sh ${MONTH}.htmlscript
  cp ${MONTH}.html FILE_NONSAT

# Generate 3 satellite count files (received,selected,assimilated)

  $USHobsproc_prep_post/satellite_summary.sh                             

# Combine 4 files ( 1 non-sat, 3 sat ) into 1

  $USHobsproc_prep_post/gdascounts_combine.sh                           

  cp temp2 index.shtml           
  cp temp2 ${Month}_${YEAR}.shtml
#
# Copy the newly generated index.shtml file to $DATCOM1 directory
#
 cp index.shtml $DATCOM1/.
#
# Move this over to the public web server.
#
if [ "$SENDWEB" = 'YES' ]; then
  if [ "$USER" = nwprod ]; then
    scp ${Month}_${YEAR}.html nwprod@ncorzdm:/home/people/nco/nwprod/pmb/nw${envir}/gdas/
    scp index.shtml nwprod@ncorzdm:/home/people/nco/nwprod/pmb/nw${envir}/gdas/
  else # developer
    if [[ -z "$webhost" || -z "$webhostid" || -z "$webdir" ]]; then
      echo -e "\n*** WARNING:  Missing one or more variables required to send content to web! ***"
      echo -e " Check the following or set SENDWEB=NO"
      echo -e "   webhost: ${webhost:-"NOT SET!!  Should point to remote host."}"
      echo -e "   webhostid: ${webhostid:-"NOT SET!!  Should be userid for remote host."}"
      echo -e "   webdir: ${webdir:-"NOT SET!!  Should point to directory on remote host."}"
      echo -e "*** SKIPPING SCP TO REMOTE HOST ***\n"
      set -x
    else
      scp ${Month}_${YEAR}.html ${webhostid}@${webhost}:${webdir}/
      scp index.shtml ${webhostid}@${webhost}:${webdir}/
    fi
  fi
fi
