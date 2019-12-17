#!/bin/ksh
set -x

mac=$(hostname | cut -c1-1)

#---------------------------------------------
if [ $mac = t -o $mac = g ] ; then  #For WCOSS
#---------------------------------------------

export NWPRODLIB=/nwprod2/lib
export FCMP=ifort

export W3NCO_VER=v2.0.6
export W3NCO_DIR=$NWPRODLIB/w3nco/$W3NCO_VER
export W3NCO_LIBd=w3nco_${W3NCO_VER}_d

export W3EMC_VER=v2.2.0
export W3EMC_DIR=$NWPRODLIB/w3emc/$W3EMC_VER
export W3EMC_LIBd=w3emc_${W3EMC_VER}_d
export W3EMC_INCd=$W3EMC_DIR/include/$W3EMC_LIBd             

export SP_VER=v2.0.2
export SP_DIR=$NWPRODLIB/sp/$SP_VER
export SP_LIBd=sp_${SP_VER}_d

export SFCIO_VER=v1.0.0
export SFCIO_DIR=$NWPRODLIB/sfcio/$SFCIO_VER
export SFCIO_LIB4=sfcio_${SFCIO_VER}_4
export SFCIO_INC4=$SFCIO_DIR/include/$SFCIO_LIB4

export BACIO_VER=v2.0.2
export BACIO_DIR=$NWPRODLIB/bacio/$BACIO_VER
export BACIO_LIB4=bacio_${BACIO_VER}_4

export NEMSIO_VER=v2.2.1
export NEMSIO_DIR=$NWPRODLIB/nemsio/$NEMSIO_VER
export NEMSIO_LIB=nemsio_${NEMSIO_VER}
export NEMSIO_INC=${NEMSIO_DIR}/include/$NEMSIO_LIB            

export NEMSIOGFS_VER=v1.0.0
export NEMSIOGFS_DIR=$NWPRODLIB/nemsiogfs/$NEMSIOGFS_VER
export NEMSIOGFS_LIB=nemsiogfs_$NEMSIOGFS_VER
export NEMSIOGFS_INC=${NEMSIOGFS_DIR}/include/$NEMSIOGFS_LIB                 


#---------------------------------------------
elif [ $mac = f ]; then #For Zeus
#---------------------------------------------

export NWPRODLIB=/contrib/nceplibs/nwprod/lib
export FCMP=ifort


export W3NCO_VER=v2.0.6
export W3NCO_DIR=$NWPRODLIB/w3nco/$W3NCO_VER
export W3NCO_LIBd=w3nco_${W3NCO_VER}_d

export W3EMC_VER=v2.2.0
export W3EMC_DIR=$NWPRODLIB/w3emc/$W3EMC_VER
export W3EMC_LIBd=w3emc_${W3EMC_VER}_d
export W3EMC_INCd=$W3EMC_DIR/include/$W3EMC_LIBd             

export SP_VER=v2.0.2
export SP_DIR=$NWPRODLIB/sp/$SP_VER
export SP_LIBd=sp_${SP_VER}_d

export SFCIO_VER=v1.0.0
export SFCIO_DIR=$NWPRODLIB/sfcio/$SFCIO_VER
export SFCIO_LIB4=sfcio_${SFCIO_VER}_4
export SFCIO_INC4=$SFCIO_DIR/include/$SFCIO_LIB4

export BACIO_VER=v2.0.2
export BACIO_DIR=$NWPRODLIB/bacio/$BACIO_VER
export BACIO_LIB4=bacio_${BACIO_VER}_4

export NEMSIO_VER=v2.2.1
export NEMSIO_DIR=$NWPRODLIB/nemsio/$NEMSIO_VER
export NEMSIO_LIB=nemsio_${NEMSIO_VER}
export NEMSIO_INC=${NEMSIO_DIR}/include/$NEMSIO_LIB            

export NEMSIOGFS_VER=v1.0.0
export NEMSIOGFS_DIR=$NWPRODLIB/nemsiogfs/$NEMSIOGFS_VER
export NEMSIOGFS_LIB=nemsiogfs_$NEMSIOGFS_VER
export NEMSIOGFS_INC=${NEMSIOGFS_DIR}/include/$NEMSIOGFS_LIB                 

#---------------------------------------------
else
 echo "Machine Option Not Found, exit"
 exit
fi
#---------------------------------------------


##export DEBUG='-ftrapuv -check all -check nooutput_conversion -fp-stack-check -fstack-protector -traceback -g'
export INCS="-I$SFCIO_INC4 -I$W3EMC_INCd -I$NEMSIO_INC -I$NEMSIOGFS_INC"                    
export FFLAGS="$INCS -O3 -r8 -convert big_endian -traceback -g"
export OMPFLAG=-openmp
export LDFLG=-openmp
export LIBSM="-L${NEMSIOGFS_DIR} -l${NEMSIOGFS_LIB} \
              -L${NEMSIO_DIR} -l${NEMSIO_LIB} \
              -L${W3EMC_DIR} -l${W3EMC_LIBd} \
              -L${SFCIO_DIR} -l${SFCIO_LIB4} \
              -L${W3NCO_DIR} -l${W3NCO_LIBd} \
              -L${BACIO_DIR} -l${BACIO_LIB4} \
              -L${SP_DIR} -l${SP_LIBd} "

make -f Makefile clean
make -f Makefile
make -f Makefile install
make -f Makefile clean
