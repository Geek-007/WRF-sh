#!/bin/bash

################################################################
### THIS SCRIPT INSTALL LIBRARIES NEEDED FOR                 ###
### WRF MODEL                                                ###
###                                                          ###
### AUTHOR: pavel.oropeza@me.com                             ###
################################################################


# EXECUTION OF THIS SCRIPT:
# YOU SHOULD RUN THIS SCRIPT LIKE THE FOLLLOWING
# Ex: ./libraries_wrf_install.sh 3.9 /home/user/WRF

# DIRECTORY NAME where WRF and libraries will be installed
# WHICH IS GIVEN BY USER AS THIS: 3.8 or 3.9 


DIR_WRF=$1

WRF="$2/$DIR_WRF"

if [ "$DIR_WRF" == 3.9 ] 
then

	URL_WRF="http://www2.mmm.ucar.edu/wrf/src/WRFV3.9.TAR.gz"
	URL_WPS="http://www2.mmm.ucar.edu/wrf/src/WPSV3.9.TAR.gz"

else

	URL_WRF="http://www2.mmm.ucar.edu/wrf/src/WRFV3.8.TAR.gz"
	URL_WPS="http://www2.mmm.ucar.edu/wrf/src/WPSV3.8.TAR.gz"

fi

#WRF="$HOME/pavel/WRF/$DIR_WRF"

function loadIntel {
    ml Compiler/intel
}

function creaDirs {

    mkdir -p $WRF/apps
    mkdir -p $WRF/lib
    mkdir -p $WRF/src

    echo 'STATUS:'
    echo $?
}

SRC="$WRF/src"

function downLibs {

    cd $SRC

    URL_JASPER="http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz"
    URL_NETCDF_FORTRAN="ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-4.4.4.tar.gz"
    URL_NETCDF="ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.1.1.tar.gz"
    URL_HDF5="https://support.hdfgroup.org/ftp/HDF5/current18/src/hdf5-1.8.18.tar.gz"

    wget -c $URL_HDF5 && wget -c $URL_NETCDF && wget -c $URL_NETCDF_FORTRAN && wget -c $URL_JASPER && wget -c $URL_WRF && wget -c $URL_WPS

    echo 'STATUS:'
    echo $?

}

### INSTALL HDF5 LIBRARY

LIB="$WRF/lib"

function installHdf5 {
    HDF5_LIB_DIR="$LIB/hdf5-1.8.18"

    cd $SRC
    tar -xvzf hdf5-1.8.18.tar.gz

    cd hdf5-1.8.18/ 

    if [ -d build ]
    then
       rm -rf build
       make distclean
    else
       mkdir build && cd build
    fi
    
    logsave CONFIG-hdf5-$(date +%s) ../configure --enable-fortran2003 --enable-fortran \
    CC=icc FC=ifort --prefix=$HDF5_LIB_DIR

    make && logsave MAKE-CHECK-LOG-$(date +%s) make check && logsave MAKE-INSTALL-LOG-$(date +%s) make install
##
    echo 'STATUS:'
    echo $?
}

export LD_LIBRARY_PATH=$LIB/hdf5-1.8.18/lib:$LD_LIBRARY_PATH

function installNetcdf {

   HDF5_LIB_DIR="$LIB/hdf5-1.8.18"
   NETCDF_LIB_DIR="$LIB/netcdf-4.4.1.1"

   cd $SRC
   tar -xvzf netcdf-4.4.1.1.tar.gz
   cd netcdf-4.4.1.1/ 

   if [ -d build ]
   then
      rm -rf build
      #make distclean
      exit
   else
      mkdir build && cd build
   fi

   logsave CONFIG-netcdf-$(date +%s) ../configure CC=icc FC=ifort CXX=icpc --prefix=$NETCDF_LIB_DIR LDFLAGS="-L$HDF5_LIB_DIR/lib/" \
   CPPFLAGS="-I$HDF5_LIB_DIR/include/"
   
   make && logsave MAKE-CHECK-LOG-$(date +%s) make check && logsave MAKE-INSTALL-LOG-$(date +%s) make install

   echo 'STATUS:'
   echo $?
}

export LD_LIBRARY_PATH=$LIB/netcdf-4.4.1.1/lib:$LD_LIBRARY_PATH

function installNetcdf_fortran {


   HDF5_LIB_DIR="$LIB/hdf5-1.8.18"
   NETCDF_LIB_DIR="$LIB/netcdf-4.4.1.1"

   cd $SRC
   tar -xvzf netcdf-fortran-4.4.4.tar.gz
   cd netcdf-fortran-4.4.4

   if [ -d build ]
   then
      rm -rf build
      #make distclean
      #exit
   else
      mkdir build && cd build
   fi

   logsave CONFIG-netcdf-fortran-$(date +%s) ../configure CC=icc FC=ifort CXX=icpc --prefix=$NETCDF_LIB_DIR LDFLAGS="-L$HDF5_LIB_DIR/lib/ -L$NETCDF_LIB_DIR/lib/" CPPFLAGS="-I$HDF5_LIB_DIR/include/ -I$NETCDF_LIB_DIR/include/"
   
   make && logsave MAKE-CHECK-LOG-$(date +%s) make check && logsave MAKE-INSTALL-LOG-$(date +%s) make install

   echo 'STATUS:'
   echo $?
}

function installJasper {

   JASPER_LIB_DIR="$LIB/jasper" 

   cd $SRC
   tar -xvzf jasper-1.900.1.tar.gz
   cd jasper-1.900.1

   if [ -d build ]
   then
      rm -rf build
      #make distclean
      exit
   else
      mkdir build && cd build
   fi

   logsave CONFIG-jasper-$(date +%s) ../configure CC=icc CXX=icpc F77=ifort --prefix=$JASPER_LIB_DIR    
   make && logsave MAKE-CHECK-LOG-$(date +%s) make check && logsave MAKE-INSTALL-LOG-$(date +%s) make install

   echo 'STATUS:'
   echo $?
   
   export JASPERINC=$JASPER_LIB_DIR/include/
   export JASPERLIB=$JASPER_LIB_DIR/lib/
}

JASPER_LIB_DIR="$LIB/jasper" 

function prepareWRFWPS {
   
   APPS="$WRF/apps"
   
   cd $SRC
	
   URL_H="${URL_WRF:7}"
   URL_WRF=${URL_H##**/}

   URL_H="${URL_WPS:7}"
   URL_WPS=${URL_H##**/}
	
   tar -xvzf $URL_WRF -C $APPS && tar -xvzf $URL_WPS -C $APPS

   export JASPERINC=$JASPER_LIB_DIR/include/
   export JASPERLIB=$JASPER_LIB_DIR/lib/

   HDF5_LIB_DIR="$LIB/hdf5-1.8.18"
   NETCDF_LIB_DIR="$LIB/netcdf-4.4.1.1"
   
   export NETCDF=$NETCDF_LIB_DIR
   export HDF5=$HDF5_LIB_DIR/

   WRFV3="$APPS/WRFV3"
#
#   if [ -d $WRFV3 ]
#   then
#     cd $WRFV3
#     clear
#     ./clean -aa
#     wait
#   else
#        #mkdir "$WRFV3"	
#	   echo 'STATUS:'
#	   echo $?
#   fi
#
   cd $WRFV3
#
ENVWRF="../envarWRF.sh"
#
exec 6>&1
exec > $ENVWRF
#
cat <<- _EOF_
   export LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
   export NETCDF="$NETCDF"
   export HDF5="$HDF5"
   export JASPERLIB="$JASPERLIB"
   export JASPERINC="$JASPERINC"
_EOF_

 exec 1>&6 6>&-

#
   MESSAGE="ARE YOU READY TO COMPILE WRF"
   echo $MESSAGE
   head --lines=1 README
#
   echo "[Y]es"
   echo "[N]o"
   read ANS
   case "$ANS" in
      "Y" | "y" )
      echo
      echo "Choose the best option according to INTEL compilers"
      ./configure
      wait
      echo "WE START. TIME TO EDIT configure.wrf. Don't forget to source envarWRF.sh"
      ;;
      "N" | "n" )
      echo
      echo "BYE!"
      exit
      ;;
   esac

}

allofThem ()
{
	### CALL PREVIOUS FUNCTIONS
	loadIntel #0
	if [ $? -eq 0 ]; then
	   creaDirs #1
	else
	   echo "Not found Intel environment"
	   exit
	fi

	if [ $? -eq 0 ]; then
	   downLibs #2
	else 
	   echo "Can not download files. Check links and internet connection"
	   exit
	fi

	if [ $? -eq 0 ]; then
	   installHdf5 #3
	else 
	   echo "Couldn't install hdf5"
	   exit
	fi
	#&&
	if [ $? -eq 0 ]; then
	   installNetcdf #4
	else 
	   echo "Couldn't install netcdf"
	   exit
	fi
	#&&
	if [ $? -eq 0 ]; then
	   installNetcdf_fortran #5 
	else 
	   echo "Couldn't install netcdf-fortran"
	   exit
	fi
	#&&
	if [ $? -eq 0 ]; then
	   installJasper #6
	else 
	   echo "Couldn't install jasper"
	   exit
	fi
	#&&
	prepareWRFWPS #7
}

displayMenu ()
{
    clear

cat <<-MENU
THIS SCRIPT INSTALL LIBRARIES AND
PREPARES ENVIRONMENT TO INSTALL 
WRF/WPS CODE UNDER INTEL COMPILERS
CHOOSE WHAT TO INSTALL
--------------------------------------
0. Load Intel compilers and libraries
1. Create directories
2. Download libraries and WRF/WPS code
3. Install HDF5
4. Install NetCDF
5. Install NetCDF-Fortran
6. Install Jasper
7. Prepare source file for WRF 
8. All the previous
9. Quit
--------------------------------------
MENU
    read -p "Make a choice: " choice
    echo "Your choice: $choice"

}

readsMenu ()
{
    case $choice in
        0)
        loadIntel ;;
        1)
        creaDirs ;;
        2)
        downLibs ;;
        3)
        installHdf5 ;;
        4)
        installNetcdf ;;
        5)
        installNetcdf_fortran ;;
        6)
        installJasper ;;
        7)
        prepareWRFWPS ;;
        8)
        allofThem ;;
        9)
        exit ;;
    esac

}

################

displayMenu
readsMenu

################
