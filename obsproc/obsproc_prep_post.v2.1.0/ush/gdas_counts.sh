#!/bin/sh
#    gdas_counts.sh
#
#    This scripts copies the files containing 
#      observational data counts to an archive  
#      for compiling at the end of month
#
# History
#      Larry Sager 06/2007   -  Implementation of
#                               Ralph Jones' script
#      Krishna Kumar 10/2012    Modified from the generic name of the 
#                               type gps to the specific type gps_bnd
#                               
#
  cd $DATA 

#  Loop through each cycle and create reformated files

   for d_cyc in t00z t06z t12z t18z
     do
       INFILE="${COMIN}/gdas1.${d_cyc}.status.tm00.bufr_d"
      if [ ! -f $INFILE ]; then
            echo -e "\n\n  INFILE:  $INFILE  does not exist \n\n"
            break
      fi
      grep "in data group" ${INFILE}  > tmp
      grep "total for all" ${INFILE}  >> tmp
      grep "COMBINED TOTAL" ${INFILE} >> tmp
      grep "(SUPEROBED) TRMM" ${INFILE} | cut -c1-80 >> tmp
      grep "REPROCESSED QUIKSCAT" ${INFILE}   >> tmp
      cp tmp ${DATCOM}/gdas1.${d_cyc}.status.tm00.bufr_d.$PDY   
      echo COUNTS  created ${DATCOM}/gdas1.${d_cyc}.status.tm00.bufr_d.$PDY
    done


#
# Loop through the 4 gsistats files and collect the assimilated counts 
#
    for d_cyc in t00z t06z t12z t18z
    do
      INFILE=${COMIN}/gdas1.${d_cyc}.gsistat        
      if [ ! -f $INFILE ]; then
            echo -e "\n\n  INFILE:  $INFILE  does not exist \n\n"
            break
      fi
      grep "o-g 03 rad" $INFILE  > tmp
      grep "o-g 03 pcp" $INFILE  >> tmp
      grep "o-g 03 oz" $INFILE  >> tmp
#      grep "type   gps jiter   3" $INFILE >> tmp
      grep "type gps_bnd jiter   3" $INFILE >> tmp
      grep -v "0          0          0   " tmp > tmpa
      cp tmpa ${SATCOM}/gdas_gsistat.${PDY}.${d_cyc}
      echo COUNTS  created ${SATCOM}/gdas_gsistat.${PDY}.${d_cyc}
    done 

exit
