MACHINE="hera"
EXPT_SUBDIR="proto_aws"
ACCOUNT="fv3-cam"
HPSS_ACCOUNT="fv3-cam"

envir="test"
NET="rrfs"
TAG="c0v00"
MODEL="rrfs"
RUN="rrfs"

STMP="/scratch2/NCEPDEV/stmp3/${USER}/proto_aws"
PTMP="/scratch2/NCEPDEV/fv3-cam/${USER}/proto_aws"

VERBOSE="TRUE"
PRINT_ESMF="TRUE"

PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_NA_3km"
. set_rrfs_config_general.sh

QUILTING="TRUE"

# default

FCST_LEN_HRS="18"

OUTPUT_FH="1 -1"
# #set UPP/prodgen for 15 min output
NFHMAX_HF="18"
NFHOUT="1"
NSOUT_MIN="15"

for i in {0..23}; do FCST_LEN_HRS_CYCLES[$i]=18; done
for i in {0..23..6}; do FCST_LEN_HRS_CYCLES[$i]=60; done

POSTPROC_LONG_LEN_HRS="60"
POSTPROC_LEN_HRS="60"
LBC_SPEC_INTVL_HRS="1"

DATE_FIRST_CYCL="20230701"
DATE_LAST_CYCL="20230715"
CYCL_HRS=( "00" "06" "12" "18" )

RUN_TASK_MAKE_GRID="FALSE"
RUN_TASK_MAKE_OROG="FALSE"
RUN_TASK_MAKE_SFC_CLIMO="FALSE"

WTIME_RUN_FCST="04:30:00"
WTIME_RUN_BUFRSND="04:30:00"

DO_PARALLEL_PRDGEN="TRUE"
DO_SMOKE_DUST="TRUE"
USE_CLM="TRUE"

DO_NON_DA_RUN="FALSE"
DO_RETRO="FALSE"
DO_BUFRSND="TRUE"
CCPP_PHYS_SUITE="FV3_HRRR_gf"
VCOORD_FILE="global_hyblev_fcst_rrfsL65.txt"
WFLOW_XML_TMPL_FN="FV3LAM_wflow_awsretro.xml"
FV3_NML_YAML_CONFIG_FN="FV3.input.yml"
