#---------------------------------------------------------------------------
#
#  gdas_countstat.sh                         
#
#
#  This script collects gdas observational data counts from Dennis Keysers
#  status count files.
#
#  Usage: gdas_countstat.sh<start_date> <network> <num days> <hour> <month>
#
#  History
#  L. Sager  09/07  Modified script to work properly in operations.
#  C. Magee  12/08  Modified script to remove REPROCESSED references.
#  D. Stokes 04/2015  Moved to vertical structure package obsproc_prep_post 
#                     and updated variables pointing to other software
#                     included in this migration.  Made additional minor 
#                     changes to reduce unnecessary warnings.
#
#---------------------------------------------------------------------------

set -x 

start=$1
net=$2
numdays=$3
hour=$4
CYCLE=t${hour}z
month=$5


num=`expr $numdays - 1 `
string=`$utilscript/finddate.sh $start s+$num`
echo "num=$num"
echo "string=$string"
last=`$utilscript/finddate.sh $start d+$num`

file=$DATCOM/gdas1.$CYCLE.status.tm00.bufr_d.$day

daystring="$start ""$string"
echo $daystring 
echo "&DATA" > ${net}_${month}_dumpstats.$CYCLE
  type0="000.001 000.007"
  type1="001.001 001.002 001.003 001.004 001.005 001.006"
  type2="002.001 002.002 002.003 002.004 002.005 002.007 002.009 002.008"
  type3="003.001 003.104"
  type4="004.001 004.002 004.003 004.004 004.005"
  type5="005.010 005.012 005.013 005.041 005.042 005.043 005.064" 
  type8="008.010"
  type12="012.001 012.002 012.013 TMI 012.103 012.137 REPROCESSED"
  type21="021.021 021.022 021.023 021.024 021.025 021.041"
  type99="COMBINED"
  types="$type0 $type1 $type2 $type3 $type4 $type5 $type8 $type12 $type21 $type99"

  for type in $types
  do
      rm -f $type
  done

  for day in $daystring
  do
      echo -e "\n     DAY = $day"
      file=$DATCOM/gdas1.$CYCLE.status.tm00.bufr_d.$day
      eval TF=$file
      echo file is $file
      for type in $types
        do
          if test -f $TF
          then
            if test $type = '012.137'
            then
              num=`grep $type $TF | grep -vi Global | grep qkscat | cut -c65-71`
              echo num=$num
            elif test $type = 'REPROCESSED'
            then
              num=`grep 'REPROCESSED QUIKSCAT' $TF | awk '{ print $11 }'`
            elif test $type = 'COMBINED'
            then
              num=`grep 'COMBINED TOTAL' $TF | awk '{ print $9 }'`
            elif test $type = 'TMI'
            then
              num=`grep $type $TF | awk '{ print $12 } '`
            else
              num=`grep $type $TF | grep -vi Global | cut -c65-71`
            fi
            if test -n "$num";then
              if test $num -ge 0
              then
                echo $num >> $type
              fi
            fi
          fi
        done

      echo "Processing complete for $day"
  done

  for type in $types
  do
        mnemonic=`grep $type $FIXobsproc_prep_post/gdascounts_types | awk '{print $2}'`
        if test -s $type
        then 
          echo "get stats for $type"
          awk -f $FIXobsproc_prep_post/gdascounts_avg.awk $type var=$mnemonic >> ${net}_${month}_dumpstats.$CYCLE
        else
          echo $type is not dumped for $net
        fi
  done

mkdir $DATA/${MON}
sed -e 's/ = /=/g' ${net}_${month}_dumpstats.$CYCLE > tmps                                             
echo "/" >>tmps

cp  tmps  $DATA/${net}_${month}_dumpstats.$CYCLE

exit

