load(pathJoin("envvar", os.getenv("envvar_ver")))

load(pathJoin("PrgEnv-intel", os.getenv("PrgEnv_intel_ver")))
load(pathJoin("intel", os.getenv("intel_ver")))
load(pathJoin("craype", os.getenv("craype_ver")))
load(pathJoin("cray-mpich", os.getenv("cray_mpich_ver")))
load(pathJoin("cray-pals", os.getenv("cray_pals_ver")))

prepend_path("MODULEPATH", os.getenv("modulepath_compiler"))
prepend_path("MODULEPATH", os.getenv("modulepath_mpi"))

load(pathJoin("jasper", os.getenv("jasper_ver")))
load(pathJoin("zlib", os.getenv("zlib_ver")))
load(pathJoin("libpng", os.getenv("libpng_ver")))
load(pathJoin("hdf5", os.getenv("hdf5_ver")))
load(pathJoin("netcdf", os.getenv("netcdf_ver")))

load(pathJoin("bacio", os.getenv("bacio_ver")))
load(pathJoin("ip", os.getenv("ip_ver")))
load(pathJoin("sp", os.getenv("sp_ver")))
load(pathJoin("w3emc", os.getenv("w3emc_ver")))
load(pathJoin("w3nco", os.getenv("w3nco_ver")))