
##############################################################
#
# This file can be used to compile the executables using any
# standard Fortran 90 compiler (e.g. the Linux INTEL Fortran 95)
# This makefile was written by Remco van den Bosch, using the
# Leiden, 2009
#
##############################################################
#FAST=TRUE
#PROFILE=TRUE
#ABEL_NO_INTERPOL=true
compiler=gfortran

#PROFILEDIR=~/t/profile/orblib


#PROPRIETARY=proprietary
ifndef PROPRIETARY
	PROPRIETARY=sub
endif

ifeq ($(compiler),ifort) 
ifdef FAST
  flags = -fast #-assume buffered_stdout 
  flags += -O3 -IPO  -opt-matmul #-mkl=cluster
  #flags += -fno-fnalias 
#  flags += -heap-arrays 7 -scalar-rep -funroll-loops -unroll-aggressive -opt-multi-version-aggressive -opt-matmul -opt-prefetch -inline-level=2 -no-inline-max-total-size -no-inline-max-size -fomit-frame-pointer -finline-functions -static -xHost -O3 -IPO -mkl=cluster  
else
  flags += -nostack_temps -C -g -inline-debug-info		
endif



ifdef PROFILEDIR
ifdef PROFILE
flags  += -prof-dir $(PROFILEDIR)
flags  +=  -prof-gen -profile-loops:all -profile-loops-report:2 -profile-functions
else
  ifdef FAST
    flags  += -prof-dir $(PROFILEDIR)
    flags  += -prof-use	-prof-func-order #-prof-data-order
  endif
endif

endif


fortran90 = $(compiler) $(flags)     -c
fortran77 = $(compiler) $(flags) -W0 -c
link      = $(compiler) $(flags)     -o
endif 

ifeq ($(compiler),F)
  fortran90 = F -ieee=stop -C -O4   -c 
  fortran77 = g77.old -O2   -c
  link = F -ieee=stop -C -O4   -o
endif

ifeq ($(compiler),g95)
  fortran90 = ~/local/bin/g95 -c -O3 -m64  -c
  fortran77 = ~/local/bin/g95 -c -O3 -m64  -c
  link = ~/local/bin/g95 -o -O3 -m64 -o
endif

ifeq ($(compiler),gfortran) 
  ifdef FAST
   flags =   -ffast-math -O3 -march=native -fomit-frame-pointer -m64
   flags +=    -funroll-loops -ftree-loop-linear 
   flags +=  -fwhole-file -fwhole-program  -flto 
  else
  # flags =  -m64 -g  -ggdb -fbounds-check -fcheck-array-temporaries   	
  endif
  
  ifdef PROFILEDIR
  ifdef PROFILE
    flags  += -fprofile-generate=$(PROFILEDIR)
  else
    ifdef FAST
        flags  += -fprofile-use=$(PROFILEDIR)
    endif
  endif
  endif

   # on MAC OS X we can use the built-in BLAS/LAPACK
  flags += -fexternal-blas -framework Accelerate              
  # On MAC OS X te build static binaries
  flags += -static-libgfortran -static-libgcc     

  fortran90 = gfortran $(flags) -c
  fortran77 = gfortran $(flags) -c
  link = gfortran $(flags) -o
endif
 
# define local Galahad directory
#GALAHADDIR = ../galahad-2.3.0000
#GALAHADDIR = ../galahad-2.4
        
# Define galahad compiled libary choice (platform dependant)

# MAC, gfortran
#GALAHADTYPE= mac.osx.gfo/double/  

# linux, ifort
#GALAHADTYPE= pc.lnx.ifr/double
#GALAHADTYPE= pc.lnx.gfo/double
##########################################################

all : orbitstart orblib triaxmass triaxmassbin triaxnnls modelgen partgen

#########################################################
#
# Store a copy of all compiled version in RCS as backup
#
#########################################################

RCS : Makefile run_model.sh iniparam_f.f90      orblib_f.f90           triaxpotent.f90 interpolpotent.f90  orblibprogram.f90    triaxmassbin.f90 modelgen.f90           triaxmass.f90 orbitstart.f90       triaxnnls.f90  dmpotent.f90 partgen.f90  
	ci -q -l -mcompile Makefile run_model.sh iniparam_f.f90      orblib_f.f90             triaxpotent.f90 interpolpotent.f90  orblibprogram.f90    triaxmassbin.f90 modelgen.f90 triaxmass.f90 orbitstart.f90   triaxnnls.f90 dmpotent.f90 partgen.f90

##########################################################
#
# Choice between two integrators
#
# DOP853 is the more accurate and is less prone to fail 
# integrating the orbit trajectory, but it is slower too.
# 
##########################################################

#DOPCDE = sub/dopri5.f
#DOPOBJ = dopri5.o

DOPCDE = sub/dop853.f
DOPOBJ = dop853.o


######################################################
#
# MGE Code.
#
######################################################

MGECDE = sub/numeric_kinds_f.f90 sub/dqxgs.f $(PROPRIETARY)/ellipint.f90 iniparam_f.f90 triaxpotent.f90 dmpotent.f90 interpolpotent.f90
MGEOBJ = numeric_kinds_f.o dqxgs.o iniparam_f.o triaxpotent.o dmpotent.o interpolpotent.o ellipint.o

iniparam_f.o: iniparam_f.f90 numeric_kinds_f.o  
	$(fortran90) iniparam_f.f90

triaxpotent.o : triaxpotent.f90 ellipint.o numeric_kinds_f.o iniparam_f.o  
	$(fortran90) triaxpotent.f90

dmpotent.o : dmpotent.f90 triaxpotent.o numeric_kinds_f.o iniparam_f.o  
	$(fortran90) dmpotent.f90

interpolpotent.o : interpolpotent.f90 triaxpotent.o numeric_kinds_f.o iniparam_f.o  
	$(fortran90) interpolpotent.f90

#####################################################
#
# AUX routines
#
###################################################

numeric_kinds_f.o : ./sub/numeric_kinds_f.f90 
	$(fortran90) ./sub/numeric_kinds_f.f90

ellipint.o : ./$(PROPRIETARY)/ellipint.f90 
	$(fortran90) ./$(PROPRIETARY)/ellipint.f90

numrep.o: ./sub/numrep.f90 numeric_kinds_f.o 
	$(fortran77) ./sub/numrep.f90

nag.o : $(PROPRIETARY)/nag.f
	$(fortran77) $(PROPRIETARY)/nag.f

numrec_arloc.o : $(PROPRIETARY)/numrec_arloc.f
	$(fortran77) $(PROPRIETARY)/numrec_arloc.f

dop853.o: ./sub/dop853.f
	$(fortran77) ./sub/dop853.f

dopri5.o: ./sub/dopri5.f
	$(fortran77) ./sub/dopri5.f

nnls95.o : ./sub/nnls95.f
	$(fortran77) ./sub/nnls95.f

gausherm.o : ./sub/gausherm.f
	$(fortran77) ./sub/gausherm.f

dqxgs.o : ./sub/dqxgs.f
	$(fortran77)  ./sub/dqxgs.f

####################################################
#
# triaxmass
#
###################################################

triaxmass: $(MGEOBJ) nag.o  triaxmass.f90 
	$(link) triaxmass $(MGEOBJ) nag.o triaxmass.f90

####################################################
#
# triaxmassbin
#
###################################################

triaxmassbin: $(MGEOBJ) triaxmassbin.f90 
	$(link) triaxmassbin $(MGEOBJ) triaxmassbin.f90


######################################################
#
# orblib_f, The orbit library program.
#
#######################################################

ORBLIBCDE= $(MGECDE) $(PROPRIETARY)/numrec_arloc.f $(DOPCDE) orblib_f.f90 
ORBLIBOBJ= $(MGEOBJ) numrec_arloc.o $(DOPOBJ) orblib_f.o 
ORBLIBABELCDE= $(ABELCDE) $(PROPRIETARY)/numrec_arloc.f $(DOPCDE) orblib_f.f90 
ORBLIBABELOBJ= $(ABELOBJ) numrec_arloc.o $(DOPOBJ) orblib_f.o 

ifeq ($(FAST),TRUE)
  ORBLIBOBJ=$(ORBLIBCDE)
  ORBLIBABELOBJ=$(ORBLIBABELCDE)	
endif

orblib_f.o : orblib_f.f90 $(MGEOBJ) numrec_arloc.o $(DOPOBJ)
	$(fortran90) orblib_f.f90

orblib : $(ORBLIBOBJ) orblibprogram.f90
	$(link) orblib  $(ORBLIBOBJ) orblibprogram.f90

modelgen : $(ORBLIBOBJ) modelgen.f90
	$(link) modelgen  $(ORBLIBOBJ) modelgen.f90

partgen : $(ORBLIBOBJ) partgen.f90
	$(link) partgen  $(ORBLIBOBJ) partgen.f90

orbitstart : $(ORBLIBOBJ) orbitstart.f90
	$(link) orbitstart  $(ORBLIBOBJ) orbitstart.f90

orblibabel : $(ORBLIBABELOBJ) orblibprogram.f90
	$(link) orblibabel  $(ORBLIBABELOBJ) orblibprogram.f90

orbsolabel : $(ORBLIBABELOBJ) modelgen.f90
	$(link) orbsolabel  $(ORBLIBABELOBJ) modelgen.f90

orbitstartabel : $(ORBLIBABELOBJ) orbitstart.f90
	$(link) orbitstartabel  $(ORBLIBABELOBJ) orbitstart.f90


##############################################################
#
# triaxnnls
#
##############################################################

OBJECTS5 = nnls95.o iniparam_f.o numeric_kinds_f.o gausherm.o triaxnnls.o


triaxnnls : $(OBJECTS5)  
	$(link) triaxnnls $(OBJECTS5)  # -I$(GALAHADDIR)/modules/$(GALAHADTYPE)  -L$(GALAHADDIR)/objects/$(GALAHADTYPE)  -lgalahad  -lgalahad_hsl -lgalahad_metis -lgalahad_lapack -lgalahad_blas

triaxnnls.o : triaxnnls.f90 numeric_kinds_f.o iniparam_f.o 
	$(fortran90) triaxnnls.f90 # -I$(GALAHADDIR)/modules/$(GALAHADTYPE)  -L$(GALAHADDIR)/objects/$(GALAHADTYPE)

##########################################
#
#  Utilities
#
##########################################

distclean:
	rm  *.o *.il *.mod *.dyn work.* *.d *.exe ifc* *.dpi *.spi gmon.out orbitstart orblib triaxmass triaxmassbin triaxnnls orbsol  orblibabel orbitstartabel orbsolabel partgen modelgen
	rm -r *.dSYM

clean:
	rm  *.o *.il *.mod work.* *.d ifc* 
	rm -r *.dSYM

profclean:
	rm -f *.o

