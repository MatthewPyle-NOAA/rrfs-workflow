MACHINE="wcoss2"
ACCOUNT="RRFS-DEV"
HPSS_ACCOUNT="RRFS-DEV"
EXPT_SUBDIR="test_nonDA_grib2"

envir="test"
NET="rrfs"
TAG="c0v00"
MODEL="rrfs"
RUN="rrfs"

STMP="/lfs/h2/emc/stmp/${USER}/test_nonDA_grib2"
PTMP="/lfs/h2/emc/ptmp/${USER}/test_nonDA_grib2"
GESROOT="/lfs/h2/emc/ptmp/${USER}/test_nonDA_grib2"

VERBOSE="TRUE"
PRINT_ESMF="TRUE"

USE_CRON_TO_RELAUNCH="TRUE"
CRON_RELAUNCH_INTVL_MNTS="03"

PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
QUILTING="TRUE"

CCPP_PHYS_SUITE="FV3_HRRR"
FCST_LEN_HRS="6"
LBC_SPEC_INTVL_HRS="6"

DATE_FIRST_CYCL="20190615"
DATE_LAST_CYCL="20190615"
CYCL_HRS=( "00" )

RUN_TASK_MAKE_GRID="TRUE"
RUN_TASK_MAKE_OROG="TRUE"
RUN_TASK_MAKE_SFC_CLIMO="TRUE"
RUN_TASK_PRDGEN="FALSE"

EXTRN_MDL_NAME_ICS="GFS"
EXTRN_MDL_NAME_LBCS="GFS"

GFS_FILE_FMT_ICS="grib2"
GFS_FILE_FMT_LBCS="grib2"

WTIME_FORECAST="00:30:00"
PPN_FORECAST="12"

DO_NON_DA_RUN="TRUE"
DO_RETRO="TRUE"
VCOORD_FILE="global_hyblev_fcst_rrfsL65.txt"
WFLOW_XML_TMPL_FN="FV3LAM_wflow_nonDA.xml"
FV3_NML_YAML_CONFIG_FN="FV3.input.nonDA.yml"

USE_USER_STAGED_EXTRN_FILES="TRUE"
EXTRN_MDL_SOURCE_BASEDIR_ICS="/lfs/h2/emc/lam/noscrub/RRFS_input/input_model_data/FV3GFS/grib2/2019061500"
EXTRN_MDL_SOURCE_BASEDIR_LBCS="/lfs/h2/emc/lam/noscrub/RRFS_input/input_model_data/FV3GFS/grib2/2019061500"
