#!/bin/ksh
set -x

mac=$(hostname | cut -c1-1)

#---------------------------------------------
if [ $mac = t -o $mac = g ] ; then  #For WCOSS
#---------------------------------------------

export NWPRODLIB=/nwprod/lib
export NWPRODLIB2=/nwprod2/lib
export FCMP=ifort
export FCMP95=$FCMP

export W3NCO_VER=v2.0.6
export W3NCO_DIR=$NWPRODLIB/w3nco/$W3NCO_VER
export W3NCO_LIBd=w3nco_${W3NCO_VER}_d

export W3EMC_VER=v2.0.5
export W3EMC_DIR=$NWPRODLIB/w3emc/$W3EMC_VER
export W3EMC_LIBd=w3emc_${W3EMC_VER}_d

export SP_VER=v2.0.2
export SP_DIR=$NWPRODLIB/sp/$SP_VER
export SP_LIBd=sp_${SP_VER}_d

export IP_VER=v2.0.0
export IP_DIR=$NWPRODLIB/ip/$IP_VER
export IP_LIBd=ip_${IP_VER}_d

export SFCIO_VER=v1.0.0
export SFCIO_DIR=$NWPRODLIB/sfcio/$SFCIO_VER
export SFCIO_LIB4=sfcio_${SFCIO_VER}_4
export SFCIO_INC4=${SFCIO_DIR}/incmod/$SFCIO_LIB4

export SIGIO_VER=v2.0.1
export SIGIO_DIR=$NWPRODLIB/sigio/$SIGIO_VER
export SIGIO_LIB4=sigio_${SIGIO_VER}_4
export SIGIO_INC4=${SIGIO_DIR}/incmod/$SIGIO_LIB4

export GFSIO_VER=v1.1.0
export GFSIO_DIR=$NWPRODLIB/gfsio/$GFSIO_VER
export GFSIO_LIB4=gfsio_${GFSIO_VER}_4
export GFSIO_INC4=${GFSIO_DIR}/incmod/$GFSIO_LIB4

export NEMSIO_VER=v2.2.1
export NEMSIO_DIR=$NWPRODLIB/nemsio/$NEMSIO_VER
export NEMSIO_LIB=nemsio_${NEMSIO_VER}
export NEMSIO_INC=${NEMSIO_DIR}/incmod/$NEMSIO_LIB

export NEMSIOGFS_VER=v1.0.0
export NEMSIOGFS_DIR=$NWPRODLIB/nemsiogfs/$NEMSIOGFS_VER
export NEMSIOGFS_LIB=nemsiogfs_${NEMSIOGFS_VER}
export NEMSIOGFS_INC=${NEMSIOGFS_DIR}/incmod/$NEMSIOGFS_LIB

export LANDSFCUTIL_VER=v2.0.0
export LANDSFCUTIL_DIR=$NWPRODLIB/landsfcutil/$LANDSFCUTIL_VER
export LANDSFCUTIL_LIBd=landsfcutil_${LANDSFCUTIL_VER}_d
export LANDSFCUTIL_INCd=${LANDSFCUTIL_DIR}/incmod/$LANDSFCUTIL_LIBd

export BACIO_VER=v2.0.2
export BACIO_DIR=$NWPRODLIB2/bacio/$BACIO_VER
export BACIO_LIB4=bacio_${BACIO_VER}_4

#---------------------------------------------
elif [ $mac = f ]; then #For Zeus
#---------------------------------------------

export NWPRODLIB=/contrib/nceplibs/nwprod/lib
export FCMP=ifort
export FCMP95=$FCMP


export W3NCO_VER=v2.0.6
export W3NCO_DIR=$NWPRODLIB
export W3NCO_LIBd=w3nco_${W3NCO_VER}_d

export W3EMC_VER=v2.0.5
export W3EMC_DIR=$NWPRODLIB
export W3EMC_LIBd=w3emc_${W3EMC_VER}_d

export SP_VER=v2.0.1
export SP_DIR=$NWPRODLIB
export SP_LIBd=sp_${SP_VER}_d

export IP_VER=v2.0.0
export IP_DIR=$NWPRODLIB
export IP_LIBd=ip_${IP_VER}_d

export SFCIO_VER=
export SFCIO_DIR=$NWPRODLIB
export SFCIO_LIB4=sfcio_4
export SFCIO_INC4=${SFCIO_DIR}/incmod/$SFCIO_LIB4

export SIGIO_VER=v2.0.1_beta
export SIGIO_DIR=/contrib/nceplibs/dev/lib
export SIGIO_LIB4=sigio_${SIGIO_VER} 
export SIGIO_INC4=${SIGIO_DIR}/incmod/$SIGIO_LIB4

export GFSIO_VER=v1.1.0
export GFSIO_DIR=$NWPRODLIB
export GFSIO_LIB4=gfsio_${GFSIO_VER}_4
export GFSIO_INC4=${GFSIO_DIR}/incmod/$GFSIO_LIB4

export NEMSIO_VER=v2.2.1
export NEMSIO_DIR=$NWPRODLIB
export NEMSIO_LIB=nemsio_${NEMSIO_VER}
export NEMSIO_INC=${NEMSIO_DIR}/incmod/$NEMSIO_LIB

export LANDSFCUTIL_VER=
export LANDSFCUTIL_DIR=$NWPRODLIB
export LANDSFCUTIL_LIBd=landsfcutil_d
export LANDSFCUTIL_INCd=${LANDSFCUTIL_DIR}/incmod/$LANDSFCUTIL_LIBd

export BACIO_VER=v2.0.1
export BACIO_DIR=$NWPRODLIB
export BACIO_LIB4=bacio_${BACIO_VER}_4

#---------------------------------------------
else
 echo "Machine Option Not Found, exit"
 exit
fi
#---------------------------------------------

 export FFLAGSM="-i4 -O3 -r8  -convert big_endian -fp-model precise"
 export FFLAGS2M="-i4 -O3 -r8 -convert big_endian -fp-model precise -FR"
#export RECURS="-recursive"
 export RECURS=
 export LDFLAGSM="-openmp -auto"
 export OMPFLAGM="-openmp -auto"

export INCS="-I${SIGIO_INC4} -I${SFCIO_INC4} -I${LANDSFCUTIL_INCd} \
             -I${NEMSIO_INC} -I${NEMSIOGFS_INC} -I${GFSIO_INC4} "
export LIBSM="-L${GFSIO_DIR} -l${GFSIO_LIB4} \
              -L${NEMSIOGFS_DIR} -l${NEMSIOGFS_LIB} \
              -L${NEMSIO_DIR} -l${NEMSIO_LIB} \
              -L${SIGIO_DIR} -l${SIGIO_LIB4} \
              -L${SFCIO_DIR} -l${SFCIO_LIB4} \
              -L${LANDSFCUTIL_DIR} -l${LANDSFCUTIL_LIBd} \
              -L${IP_DIR} -l${IP_LIBd} \
              -L${SP_DIR} -l${SP_LIBd} \
              -L${W3EMC_DIR} -l${W3EMC_LIBd} \
              -L${W3NCO_DIR} -l${W3NCO_LIBd}  \
              -L${BACIO_DIR} -l${BACIO_LIB4} "

make -f Makefile clean
make -f Makefile
make -f Makefile install
make -f Makefile clean
