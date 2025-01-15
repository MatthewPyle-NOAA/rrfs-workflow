#!/bin/ksh

##################################################################################
#  UTILITY SCRIPT NAME :  exrrfs_awips.sh.
#
#  Abstract:  This utility script produces AWIPS products for RRFS
#
#  History: April 8, 2008 - Original script from Boi Vuong at NCO
#           Feb 27, 2014 - Update for HiresW v6 domain changes by Matthew Pyle
#           March 27, 2015 - Update for HiresW v6.1 filename changes by Matthew Pyle
#           Jan 15, 2025 - Converted for use by RRFS system
#
##################################################################################

set -x

cd $DATA

msg="RRFS post-processing for AWIPS has begun on `hostname` at `date`"
postmsg  "$msg"
startmsg

for fhr in 000 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 \
       016 017 018 019 020 021 022 023 024 025 026 027 028 029 030 031 032 033 \
       034 035 036 037 038 039 040 041 042 043 044 045 046 047 048 \
       049 050 051 052 053 054 055 056 057 058 059 060 ;
do
    export FORTREPORTS="unit_vars=yes"     # Allow overriding default names.

  icnt=1
  maxtries=100
  while [ $icnt -lt $maxtries ]
  do

	  # believe need to add grid spacing to file name.
    if [ -f $COMIN/${NET}.t${cyc}z.prslev.f${fhr}.grib2.idx ]; then
      break
    else
      let "icnt=icnt+1"
      sleep 30
    fi
  done
  if [ $icnt -ge $maxtries ]; then
     msg="FATAL ERROR - ABORTING after 50 minutes of waiting for ${NET}.t${cyc}z.prslev.f${fhr}.grib2.idx to become available."
     err_exit $msg
  fi
	  # believe need to add grid spacing to file name.
    export FORT11=$COMIN/${NET}.t${cyc}z.prslev.f${fhr}.grib2
    export FORT31=""
    export FORT51=grib2.t${cyc}z.rrfs_f${fhr}
    $TOCGRIB2 < $PARMutil/grib2.awips.rrfs.${fhr}

    if [ $SENDCOM = "YES" ] ; then
       cp  $FORT51  $COMOUTwmo/
    fi

    if [ $SENDDBN_NTC = "YES" ] ; then
       $SIPHONROOT/bin/dbn_alert NTC_LOW ${DBN_ALERT_TYPE} $job $COMOUTwmo/grib2.t${cyc}z.rrfs_f${fhr}
    else
       msg="File $output_grb.$job not posted to db_net."
       postmsg  "$msg"
    fi

done

#####################################################################
# GOOD RUN
set +x
echo "**************JOB $job COMPLETED NORMALLY on `hostname` at `date`"
echo "**************JOB $job COMPLETED NORMALLY on `hostname` at `date`"
echo "**************JOB $job COMPLETED NORMALLY on `hostname` at `date`"
set -x
#####################################################################
