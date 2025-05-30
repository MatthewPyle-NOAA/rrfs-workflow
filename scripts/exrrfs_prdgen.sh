#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHrrfs/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that runs the post-processor (UPP) on
the output files corresponding to a specified forecast hour.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Set environment
#
#-----------------------------------------------------------------------
#
ulimit -a

case $MACHINE in

  "WCOSS2")
    export OMP_NUM_THREADS=1
    ncores=$(( NNODES_PRDGEN*PPN_PRDGEN))
    APRUN="mpiexec -n ${ncores} -ppn ${PPN_PRDGEN}"
    ;;

  "HERA")
    APRUN="srun --export=ALL"
    ;;

  "ORION")
    export OMP_NUM_THREADS=1
    export OMP_STACKSIZE=1024M
    APRUN="srun"
    ;;

  "HERCULES")
    export OMP_NUM_THREADS=1
    export OMP_STACKSIZE=1024M
    APRUN="srun"
    ;;

  "JET")
    APRUN="srun"
    ;;

  *)
    err_exit "\
Run command has not been specified for this machine:
  MACHINE = \"$MACHINE\"
  APRUN = \"$APRUN\""
    ;;

esac
#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respectively)
# from CDATE.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${CDATE:0:8}
hh=${CDATE:8:2}
cyc=$hh
#
#-----------------------------------------------------------------------
#
# A separate ${post_fhr} forecast hour variable is required for the post
# files, since they may or may not be three digits long, depending on the
# length of the forecast.
#
#-----------------------------------------------------------------------
#
len_fhr=${#fhr}
if [ ${len_fhr} -eq 9 ]; then
  post_min=${fhr:4:2}
  if [ ${post_min} -lt 15 ]; then
    post_min=00
  fi
else
  post_min=00
fi

subh_fhr=${fhr}
if [ ${len_fhr} -eq 2 ]; then
  post_fhr=${fhr}00
elif [ ${len_fhr} -eq 3 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    post_fhr="${fhr:1}00"
  else
    post_fhr=${fhr}00
  fi
elif [ ${len_fhr} -eq 9 ]; then
  if [ "${fhr:0:1}" = "0" ]; then
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:1:2}00"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:1:2}${fhr:4:2}"
    fi
  else
    if [ ${post_min} -eq 00 ]; then
      post_fhr="${fhr:0:3}00"
      subh_fhr="${fhr:0:3}"
    else
      post_fhr="${fhr:0:3}${fhr:4:2}"
    fi
  fi
else
  err_exit "\
The \${fhr} variable contains too few or too many characters:
  fhr = \"$fhr\""
fi

# replace fhr with subh_fhr
echo "fhr=${fhr} and subh_fhr=${subh_fhr}"
fhr=${subh_fhr}
#
gridname=""
gridspacing=""
if [ "${PREDEF_GRID_NAME}" = "RRFS_FIREWX_1.5km" ]; then
  gridname="firewx"
  gridspacing="1p5km"
elif [ "${PREDEF_GRID_NAME}" = "RRFS_CONUS_25km" ]; then
  gridname="conus"
  gridspacing="25km"
elif [ "${PREDEF_GRID_NAME}" = "RRFS_CONUS_13km" ]; then
  gridname="conus"
  gridspacing="13km"
elif [ "${PREDEF_GRID_NAME}" = "RRFS_CONUS_3km" ]; then
  gridname="conus"
  gridspacing="3km"
elif [ "${PREDEF_GRID_NAME}" = "RRFS_NA_3km" ]; then
  gridname="na"
  gridspacing="3km"
fi
#
net4=$(echo ${NET:0:4} | tr '[:upper:]' '[:lower:]')
#
# Include member number with ensemble forecast output
if [ ${DO_ENSFCST} = "TRUE" ]; then
  prslev=${net4}.t${cyc}z.${mem_num}.prslev.${gridspacing}.f${fhr}.${gridname}.grib2
  natlev=${net4}.t${cyc}z.${mem_num}.natlev.${gridspacing}.f${fhr}.${gridname}.grib2
  testbed=${net4}.t${cyc}z.${mem_num}.testbed.${gridspacing}.f${fhr}.${gridname}.grib2
else
  prslev=${net4}.t${cyc}z.prslev.${gridspacing}.f${fhr}.${gridname}.grib2
  natlev=${net4}.t${cyc}z.natlev.${gridspacing}.f${fhr}.${gridname}.grib2
  testbed=${net4}.t${cyc}z.testbed.${gridspacing}.f${fhr}.${gridname}.grib2
  prslev_subh=${net4}.t${cyc}z.prslev.${gridspacing}.subh.f${fhr}.${gridname}.grib2
fi

# extract the output fields for the testbed
if [[ ! -z ${TESTBED_FIELDS_FN} ]]; then
  if [[ -f ${FIX_UPP}/${TESTBED_FIELDS_FN} ]]; then
    wgrib2 ${COMOUT}/${prslev} | grep -F -f ${FIX_UPP}/${TESTBED_FIELDS_FN} | wgrib2 -i -grib ${DATA}/${testbed} ${COMOUT}/${prslev}
    export err=$?; err_chk
  else
    echo "${FIX_UPP}/${TESTBED_FIELDS_FN} not found"
  fi
fi
if [[ ! -z ${TESTBED_FIELDS_FN2} ]]; then
  if [[ -f ${FIX_UPP}/${TESTBED_FIELDS_FN2} ]]; then
    if [[ -f ${COMOUT}/${natlev} ]]; then
      wgrib2 ${COMOUT}/${natlev} | grep -F -f ${FIX_UPP}/${TESTBED_FIELDS_FN2} | wgrib2 -i -append -grib ${DATA}/${testbed} ${COMOUT}/${natlev}
      export err=$?; err_chk
    fi
  else
    echo "${FIX_UPP}/${TESTBED_FIELDS_FN2} not found"
  fi
fi

#Link output for transfer to Jet
# Should the following be done only if on jet??

# Seems like start_date is the same as "$yyyymmdd $hh", where yyyymmdd
# and hh are calculated above, i.e. start_date is just CDATE but with a
# space inserted between the dd and hh.  If so, just use "$yyyymmdd $hh"
# instead of calling sed.

basetime=$( date +%y%j%H%M -d "${yyyymmdd} ${hh}" )

if [ "${PREDEF_GRID_NAME}" != "RRFS_FIREWX_1.5km" ]; then
  if [ -f  ${DATA}/${testbed} ]; then
    cp ${DATA}/${testbed}  ${COMOUT}/${testbed}
  fi
fi

if [ -s ${COMOUT}/${prslev} ]; then
  wgrib2 ${COMOUT}/${prslev} -s > ${COMOUT}/${prslev}.idx
fi
if [ -s ${COMOUT}/${natlev} ]; then
  wgrib2 ${COMOUT}/${natlev} -s > ${COMOUT}/${natlev}.idx
fi

if [ "${PREDEF_GRID_NAME}" != "RRFS_FIREWX_1.5km" ]; then
  if [ -s ${COMOUT}/${testbed} ]; then
    wgrib2 ${COMOUT}/${testbed} -s > ${COMOUT}/${testbed}.idx
  fi
fi

if [ "${DO_ENSFCST}" != "TRUE" ] && [ ${fhr} != '000' ] && [ -e $COMOUT/${prslev_subh} ]; then
  wgrib2 ${COMOUT}/${prslev_subh} -s > ${COMOUT}/${prslev_subh}.idx
fi

# Remap to additional output grids if requested

if [ "${DO_PARALLEL_PRDGEN}" = "TRUE" ]; then
  #  parallel run wgrib2 for product generation
  if [ "${PREDEF_GRID_NAME}" = "RRFS_NA_3km" ]; then
    DATAprdgen=$DATA/prdgen_${fhr}
    mkdir $DATAprdgen

    wgrib2 ${COMOUT}/${prslev} >& $DATAprdgen/prslevf${fhr}.txt

    # Create parm files for subsetting on the fly - do it for each forecast hour
    # 4 subpieces for CONUS and Alaska grids
    sed -n -e '1,251p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_1.txt
    sed -n -e '252,500p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_2.txt
    sed -n -e '501,750p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_3.txt
    sed -n -e '751,$p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/conus_ak_4.txt

    # 2 subpieces for Hawaii and Puerto Rico grids
    sed -n -e '1,500p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/hi_pr_1.txt
    sed -n -e '501,$p' $DATAprdgen/prslevf${fhr}.txt >& $DATAprdgen/hi_pr_2.txt

    # Create script to execute production generation tasks in parallel using CFP
    tasks=(4 4 2 2)
    domains=(conus ak hi pr)
    count=0
    for domain in ${domains[@]}
    do
      for task in $(seq ${tasks[count]})
      do
        mkdir -p $DATAprdgen/prdgen_${domain}_${task}
        echo "$USHrrfs/prdgen/rrfs_prdgen_subpiece.sh $fhr $cyc $task $domain $prslev ${DATAprdgen} ${COMOUT}" >> $DATAprdgen/poescript_${fhr}
      done
      count=$count+1
    done

    chmod 775 $DATAprdgen/poescript_${fhr}

    # Execute the script
    export CMDFILE=$DATAprdgen/poescript_${fhr} 
    mpiexec -np 12 --cpu-bind core cfp $CMDFILE >>$pgmout 2>errfile
    export err=$?; err_chk

    # reassemble the output grids
    tasks=(4 4 2 2)
    domains=(conus ak hi pr)
    count=0
    for domain in ${domains[@]}
    do

      outspacing=${gridspacing}
      if [[ $domain = "hi" || $domain = "pr" ]]
       then
        outspacing="2p5km"
      fi

      if [ ${DO_ENSFCST} = "TRUE" ]; then
        for task in $(seq ${tasks[count]})
        do
          cat $DATAprdgen/prdgen_${domain}_${task}/${domain}_${task}.grib2 >> ${COMOUT}/rrfs.t${cyc}z.${mem_num}.prslev.${outspacing}.f${fhr}.${domain}.grib2
        done
        wgrib2 ${COMOUT}/rrfs.t${cyc}z.${mem_num}.prslev.${outspacing}.f${fhr}.${domain}.grib2 -s > ${COMOUT}/rrfs.t${cyc}z.${mem_num}.prslev.${outspacing}.f${fhr}.${domain}.grib2.idx
      else
        for task in $(seq ${tasks[count]})
        do
          cat $DATAprdgen/prdgen_${domain}_${task}/${domain}_${task}.grib2 >> ${COMOUT}/rrfs.t${cyc}z.prslev.${outspacing}.f${fhr}.${domain}.grib2
        done
        wgrib2 ${COMOUT}/rrfs.t${cyc}z.prslev.${outspacing}.f${fhr}.${domain}.grib2 -s > ${COMOUT}/rrfs.t${cyc}z.prslev.${outspacing}.f${fhr}.${domain}.grib2.idx
      fi
      count=$count+1
    done

    # create subhourly files for CONUS, Alaska, Hawaii, Puerto Rico grids
    if [ "${DO_ENSFCST}" != "TRUE" ] && [ ${fhr} != '000' ] && [ -e $COMOUT/${prslev_subh} ]; then
      for domain in ${domains[@]}
      do

      outspacing=${gridspacing}
      if [[ $domain = "hi" || $domain = "pr" ]]
       then
        outspacing="2p5km"
      fi
        prslev_subh_dom=${net4}.t${cyc}z.prslev.${outspacing}.subh.f${fhr}.${domain}.grib2
        if [ $domain == "conus" ]; then
          # 3-km Lambert Conformal CONUS domain
          gridspecs="lambert:262.5:38.5:38.5 237.280472:1799:3000 21.138123:1059:3000"
        elif [ $domain == "ak" ]; then
          # 3-km NPS Alaska domain
          gridspecs="nps:210.0:60.0 181.429:1649:2976.0 40.530:1105:2976.0"
        elif [ $domain == "hi" ]; then
          # 2.5 km Mercator Hawaii domain
          gridspecs="mercator:20.00 198.474999:321:2500.0:206.13099 18.072699:225:2500.0:23.087799"
        elif [ $domain == "pr" ]; then
          # 2.5 km Mercator Puerto Rico domain
          gridspecs="mercator:20 284.5:544:2500:297.491 15.0:310:2500:22.005"
        fi
        
        wgrib2 ${COMOUT}/${prslev_subh} -new_grid_vectors "UGRD:VGRD:USTM:VSTM" -submsg_uv inputs.grib${domain}.uv
        #### export err=$?; err_chk #### need to test
        wgrib2 inputs.grib${domain}.uv -set_bitmap 1 -set_grib_type c3 \
          -new_grid_winds grid -new_grid_vectors "UGRD:VGRD:USTM:VSTM" \
          -new_grid_interpolation neighbor \
          -if ":(WEASD|APCP|NCPCP|ACPCP|SNOD):" -new_grid_interpolation budget -fi \
          -new_grid ${gridspecs} ${COMOUT}/${prslev_subh_dom}
        #### export err=$?; err_chk
        wgrib2 ${COMOUT}/${prslev_subh_dom} -s > ${COMOUT}/${prslev_subh_dom}.idx
      done
    fi

    # create testbed files on 3-km CONUS grid
    if [ ${DO_ENSFCST} = "TRUE" ]; then
      prslev_conus=${net4}.t${cyc}z.${mem_num}.prslev.${gridspacing}.f${fhr}.conus.grib2
      testbed_conus=${net4}.t${cyc}z.${mem_num}.testbed.${gridspacing}.f${fhr}.conus.grib2
    else
      prslev_conus=${net4}.t${cyc}z.prslev.${gridspacing}.f${fhr}.conus.grib2
      testbed_conus=${net4}.t${cyc}z.testbed.${gridspacing}.f${fhr}.conus.grib2
    fi
    if [[ ! -z ${TESTBED_FIELDS_FN} ]]; then
      if [[ -f ${FIX_UPP}/${TESTBED_FIELDS_FN} ]]; then
        wgrib2 ${COMOUT}/${prslev_conus} | grep -F -f ${FIX_UPP}/${TESTBED_FIELDS_FN} | wgrib2 -i -grib ${COMOUT}/${testbed_conus} ${COMOUT}/${prslev_conus}
      else
        echo "WARNING: ${FIX_UPP}/${TESTBED_FIELDS_FN} not found"
      fi
    fi

    #-- Upscale & subset FAA requested information
    #-- FAA grib2 output is not generated for ensemble forecasts
 
     # echo "$USHrrfs/prdgen/rrfs_prdgen_faa_subpiece.sh $fhr $cyc $prslev $natlev $ififip $aviati ${COMOUT} &" >> $DATAprdgen/poescript_faa_${fhr}

#    if [ ${DO_ENSFCST} = "FALSE" ]; then
#      ${USHrrfs}/prdgen/rrfs_prdgen_faa_subpiece.sh $fhr $cyc $prslev $natlev $ififip $aviati ${COMOUT} ${USHrrfs}/prdgen
#    fi

  else
    echo "WARNING: this grid is not ready for parallel prdgen: ${PREDEF_GRID_NAME}"
  fi

elif [ ${PREDEF_GRID_NAME} = "RRFS_FIREWX_1.5km" ]; then
  #
  # Processing for the RRFS fire weather grid
  #
#  DATA=${postprd_dir}/${fhr}
#  cd $DATA

  # set GTYPE=2 for GRIB2
  GTYPE=2

  cat > itagfw <<EOF
CONUS
$GTYPE
EOF

  # Read in corner lat lons from UPP text file
  export FORT11=${COMOUT}/latlons_corners.txt.f${fhr}
  export FORT45=itagfw

  # Calculate the wgrib2 gridspecs for the fire weather grid
  $APRUN $EXECrrfs/firewx_gridspecs.exe >> $pgmout 2>errfile
  export err=$?; err_chk

  grid_specs_firewx=`head $DATA/copygb_gridnavfw.txt`
  eval infile=${COMOUT}/${net4}.t${cyc}z.prslev.${gridspacing}.f${fhr}.firewx.grib2

  wgrib2 ${infile} -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid \
   -new_grid_vectors "UGRD:VGRD:USTM:VSTM:VUCSH:VVCSH" \
   -new_grid_interpolation neighbor \
   -if ":(WEASD|APCP|NCPCP|ACPCP|SNOD):" -new_grid_interpolation budget -fi \
   -new_grid ${grid_specs_firewx} ${COMOUT}/rrfs.t${cyc}z.prslev.${gridspacing}.f${fhr}.firewx_lcc.grib2
  #### export err=$?; err_chk
  wgrib2 ${COMOUT}/rrfs.t${cyc}z.prslev.${gridspacing}.f${fhr}.firewx_lcc.grib2 -s > ${COMOUT}/rrfs.t${cyc}z.prslev.${gridspacing}.f${fhr}.firewx_lcc.grib2.idx

else
  #
  # use single core to process all addition grids.
  #
  if [ ${#ADDNL_OUTPUT_GRIDS[@]} -gt 0 ]; then
    cd ${COMOUT}

    grid_specs_130="lambert:265:25.000000 233.862000:451:13545.000000 16.281000:337:13545.000000"
    grid_specs_200="lambert:253:50.000000 285.720000:108:16232.000000 16.201000:94:16232.000000"
    grid_specs_221="lambert:253:50.000000 214.500000:349:32463.000000 1.000000:277:32463.000000"
    grid_specs_242="nps:225:60.000000 187.000000:553:11250.000000 30.000000:425:11250.000000"
    grid_specs_243="latlon 190.0:126:0.400 10.000:101:0.400"
    grid_specs_clue="lambert:262.5:38.5 239.891:1620:3000.0 20.971:1120:3000.0"
    grid_specs_hrrr="lambert:-97.5:38.5 -122.719528:1799:3000.0 21.138123:1059:3000.0"
    grid_specs_hrrre="lambert:-97.5:38.5 -122.719528:1800:3000.0 21.138123:1060:3000.0"
    grid_specs_rrfsak="lambert:-161.5:63.0 172.102615:1379:3000.0 45.84576:1003:3000.0"
    grid_specs_hrrrak="nps:225:60.000000 185.117126:1299:3000.0 41.612949:919:3000.0"

    for grid in ${ADDNL_OUTPUT_GRIDS[@]}
    do
      for leveltype in prslev natlev ififip testbed
      do
      
        eval grid_specs=\$grid_specs_${grid}
        subdir=${DATA}/${grid}_grid
        mkdir -p ${subdir}/${fhr}
        bg_remap=${subdir}/${net4}.t${cyc}z.${leveltype}.${gridspacing}.f${fhr}.${grid}.grib2

        # Interpolate fields to new grid
        eval infile=${COMOUT}/${net4}.t${cyc}z.${leveltype}.${gridspacing}.f${fhr}.${gridname}.grib2
	if [ -f ${infile} ]; then
          if [ "${PREDEF_GRID_NAME}" = "RRFS_NA_13km" ]; then
            wgrib2 ${infile} -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid \
             -new_grid_vectors "UGRD:VGRD:USTM:VSTM:VUCSH:VVCSH" \
             -new_grid_interpolation bilinear \
             -if ":(WEASD|APCP|NCPCP|ACPCP|SNOD):" -new_grid_interpolation budget -fi \
             -if ":(NCONCD|NCCICE|SPNCR|CLWMR|CICE|RWMR|SNMR|GRLE|PMTF|PMTC|REFC|CSNOW|CICEP|CFRZR|CRAIN|LAND|ICEC|TMP:surface|VEG|CCOND|SFEXC|MSLMA|PRES:tropopause|LAI|HPBL|HGT:planetary boundary layer):|ICPRB|SIPD|ICESEV" -new_grid_interpolation neighbor -fi \
             -new_grid ${grid_specs} ${subdir}/${fhr}/tmp_${grid}.grib2
            #### export err=$?; err_chk
          else
            wgrib2 ${infile} -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid \
             -new_grid_vectors "UGRD:VGRD:USTM:VSTM:VUCSH:VVCSH" \
             -new_grid_interpolation neighbor \
             -new_grid ${grid_specs} ${subdir}/${fhr}/tmp_${grid}.grib2
            #### export err=$?; err_chk
          fi

        # Merge vector field records
          wgrib2 ${subdir}/${fhr}/tmp_${grid}.grib2 -new_grid_vectors "UGRD:VGRD:USTM:VSTM:VUCSH:VVCSH" -submsg_uv ${bg_remap}
          export err=$?; err_chk
        # Remove temporary files
          rm -f ${subdir}/${fhr}/tmp_${grid}.grib2

        # Save to com directory 
          mkdir -p ${COMOUT}/${grid}_grid
          cp ${bg_remap} ${COMOUT}/${net4}.t${cyc}z.${leveltype}.${gridspacing}.f${fhr}.${grid}.grib2
          wgrib2 ${COMOUT}/${net4}.t${cyc}z.${leveltype}.${gridspacing}.f${fhr}.${grid}.grib2 -s > ${COMOUT}/${net4}.t${cyc}z.${leveltype}.${gridspacing}.f${fhr}.${grid}.grib2.idx
        fi
      done
    done
  fi
fi  # block for parallel or series wgrib2 runs.

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Post-processing for forecast hour $fhr completed successfully.

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

