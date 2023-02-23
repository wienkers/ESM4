# Template for the Intel Compilers on Linux systems
#
############
# Command Macros
FC = ftn
CC = cc
CXX = CC
LD = ftn
#######################
# Build target macros
#
# Macros that modify compiler flags used in the build.  Target
# macrose are usually set on the call to make:
#
#    make BLD_TYPE=PROD NETCDF=3
#
# Most target macros are activated when their value is non-blank.
# Some have a single value that is checked.  Others will use the
# value of the macro in the compile command.

# Determines the type of build.  Values are:
# PROD - Use the production settings (default)
# REPRO - Extra options to guarentee run to run reproducibility.
# DEBUG - Compile with debug options (-O0 -g)
# TEST - Use additional compiler options defined in FFLAGS_TEST
#        and CFLAGS_TEST
BLD_TYPE = REPRO

# If non-blank, compile with openmp enabled
OPENMP = y

# INCLUDES
#A list of -I Include directories to be added to the the compile
#command.

# The Intel Instruction Set Archetecture (ISA) compile options to use.
# If blank, than use the default ISA settings for the host.
ISA = 

# Need to use at least GNU Make version 3.81
need := 3.81
ok := $(filter $(need),$(firstword $(sort $(MAKE_VERSION) $(need))))
ifneq ($(need),$(ok))
$(error Need at least make version $(need).  Load module gmake/3.81)
endif


# Macro for Fortran preprocessor
FPPFLAGS :=  -Wp,-w $(INCLUDES)
# Fortran Compiler flags for the NetCDF library
FPPFLAGS += $(shell nf-config --fflags)

# Base set of Fortran compiler flags
FFLAGS := -fno-alias -auto -stack-temps -safe-cray-ptr -ftz -assume byterecl -i4 -r8 -nowarn -g -qoverride-limits

# Flags based on perforance target (production (OPT), reproduction (REPRO), or debug (DEBUG)
FFLAGS_PROD = -debug minimal -fp-model source -O3
FFLAGS_REPRO = -debug minimal -fp-model source -O2
FFLAGS_DEBUG = -O0 -check -check noarg_temp_created -check nopointer -warn -warn noerrors -debug variable_locations -fpe0 -ftrapuv

# Flags to add additional build options
FFLAGS_OPENMP = -fopenmp
FFLAGS_VERBOSE = -v -V -what -warn all -qopt-report-phase=vec -qopt-report=2


# Macro for C preprocessor
CPPFLAGS = -D__IFC $(INCLUDES)
# C Compiler flags for the NetCDF library
CPPFLAGS += $(shell nc-config --cflags)

# Base set of C compiler flags
CFLAGS = 

# Flags based on perforance target (production (OPT), reproduction (REPRO), or debug (DEBUG)
CFLAGS_PROD = -O3
CFLAGS_REPRO = -O2
CFLAGS_DEBUG = -O0 -g -ftrapuv

# Flags to add additional build options
CFLAGS_OPENMP = -fopenmp
CFLAGS_VERBOSE = -w3 -qopt-report-phase=vec -qopt-report=2

# Linking flags
LDFLAGS :=
LDFLAGS_OPENMP := -fopenmp
LDFLAGS_VERBOSE := -Wl,-V,--verbose,-cref,-M

LIBS := $(shell pkg-config --libs yaml-0.1)
LIBS += -mkl 

CPPDEFS += -Duse_netCDF -Duse_LARGEFILE

# Additional Preprocessor Macros needed due to  Autotools and CMake
CPPDEFS += -DHAVE_SCHED_GETAFFINITY #-DHAVE_GETTID

# Get compile flags based on target macros.
ifeq ($(BLD_TYPE),REPRO)
CFLAGS += $(CFLAGS_REPRO)
FFLAGS += $(FFLAGS_REPRO)
COBALT = $(FFLAGS)
else ifeq ($(BLD_TYPE),DEBUG)
CFLAGS += $(CFLAGS_DEBUG)
FFLAGS += $(FFLAGS_DEBUG)
COBALT = -Wp,-w -fno-alias -auto -safe-cray-ptr -ftz -assume byterecl -i4 -r8 -nowarn -g -O0 -check -check noarg_temp_created -check nopointer -warn -warn noerrors -fpe0 -ftrapuv -msse2 $(FPPFLAGS)
else
CFLAGS += $(CFLAGS_PROD)
FFLAGS += $(FFLAGS_PROD)
COBALT = $(FFLAGS)
endif

ifdef OPENMP
CFLAGS += $(CFLAGS_OPENMP)
FFLAGS += $(FFLAGS_OPENMP)
LDFLAGS += $(LDFLAGS_OPENMP)
endif

ifdef ISA
CFLAGS += $(ISA)
FFLAGS += $(ISA)
endif

ifdef VERBOSE
CFLAGS += $(CFLAGS_VERBOSE)
FFLAGS += $(FFLAGS_VERBOSE)
LDFLAGS += $(LDFLAGS_VERBOSE)
endif


LDFLAGS += $(LIBS)

#---------------------------------------------------------------------------
# you should never need to change any lines below.

# see the MIPSPro F90 manual for more details on some of the file extensions
# discussed here.
# this makefile template recognizes fortran sourcefiles with extensions
# .f, .f90, .F, .F90. Given a sourcefile <file>.<ext>, where <ext> is one of
# the above, this provides a number of default actions:

# make <file>.opt	create an optimization report
# make <file>.o		create an object file
# make <file>.s		create an assembly listing
# make <file>.x		create an executable file, assuming standalone
#			source
# make <file>.i		create a preprocessed file (for .F)
# make <file>.i90	create a preprocessed file (for .F90)

# The macro TMPFILES is provided to slate files like the above for removal.

RM = rm -f
TMPFILES = .*.m *.B *.L *.i *.i90 *.l *.s *.mod *.opt

.SUFFIXES: .F .F90 .H .L .T .f .f90 .h .i .i90 .l .o .s .opt .x

.f.L:
	$(FC) $(FFLAGS) -c -listing $*.f
.f.opt:
	$(FC) $(FFLAGS) -c -opt_report_level max -opt_report_phase all -opt_report_file $*.opt $*.f
.f.l:
	$(FC) $(FFLAGS) -c $(LIST) $*.f
.f.T:
	$(FC) $(FFLAGS) -c -cif $*.f
.f.o:
	$(FC) $(FFLAGS) -c $*.f
.f.s:
	$(FC) $(FFLAGS) -S $*.f
.f.x:
	$(FC) $(FFLAGS) -o $*.x $*.f *.o $(LDFLAGS)
.f90.L:
	$(FC) $(FFLAGS) -c -listing $*.f90
.f90.opt:
	$(FC) $(FFLAGS) -c -opt_report_level max -opt_report_phase all -opt_report_file $*.opt $*.f90
.f90.l:
	$(FC) $(FFLAGS) -c $(LIST) $*.f90
.f90.T:
	$(FC) $(FFLAGS) -c -cif $*.f90
.f90.o:
	$(FC) $(FFLAGS) -c $*.f90
.f90.s:
	$(FC) $(FFLAGS) -c -S $*.f90
.f90.x:
	$(FC) $(FFLAGS) -o $*.x $*.f90 *.o $(LDFLAGS)
.F.L:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -listing $*.F
.F.opt:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -opt_report_level max -opt_report_phase all -opt_report_file $*.opt $*.F
.F.l:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $(LIST) $*.F
.F.T:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -cif $*.F
.F.f:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -EP $*.F > $*.f
.F.i:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -P $*.F
.F.o:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F
.F.s:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -S $*.F
.F.x:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -o $*.x $*.F *.o $(LDFLAGS)
.F90.L:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -listing $*.F90
.F90.opt:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -opt_report_level max -opt_report_phase all -opt_report_file $*.opt $*.F90
.F90.l:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $(LIST) $*.F90
.F90.T:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -cif $*.F90
.F90.f90:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -EP $*.F90 > $*.f90
.F90.i90:
	$(FC) $(CPPDEFS) $(FPPFLAGS) -P $*.F90
.F90.o:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c $*.F90
.F90.s:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -c -S $*.F90
.F90.x:
	$(FC) $(CPPDEFS) $(FPPFLAGS) $(FFLAGS) -o $*.x $*.F90 *.o $(LDFLAGS)
