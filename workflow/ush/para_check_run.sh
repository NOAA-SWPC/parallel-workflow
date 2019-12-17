#!/bin/ksh
set -x

export TMPDIR=$DATA/check_status
rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

export PARA_CHECKSH=${PARA_CHECKSH:-$USHDIR/para_check_status.sh}
export PARA_CHECK_MAIL=${PARA_CHECK_MAIL:-$LOGNAME}


$PARA_CHECKSH $PSLOT $CDATE $CDUMP > temp.msg

mail -s "$PSLOT $CDATE $CDUMP status" $PARA_CHECK_MAIL < temp.msg

exit




