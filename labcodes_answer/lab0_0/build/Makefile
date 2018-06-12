#=========================================================================
#  - default   : build bbl
#  - clean     : remove all generated content (except autoconf files)
#
#-------------------------------------------------------------------------
# Basic setup
#-------------------------------------------------------------------------
# Default is to build the prereqs of the all target (defined at bottom)
default : all
.PHONY : default

project_name := 
src_dir      := ..


#-------------------------------------------------------------------------
# List of subprojects
#-------------------------------------------------------------------------

sprojs         :=  bbl dummy_payload machine util
sprojs_enabled :=  bbl dummy_payload machine util

sprojs_include := -I. $(addprefix -I$(src_dir)/, $(sprojs_enabled))
VPATH := $(addprefix $(src_dir)/, $(sprojs_enabled))

#-------------------------------------------------------------------------
# Programs and flags 
#-------------------------------------------------------------------------

# C++ compiler
#  - CPPFLAGS : flags for the preprocessor (eg. -I,-D)
#  - CXXFLAGS : flags for C++ compiler (eg. -Wall,-g,-O3)

CC            := riscv32-unknown-elf-gcc
READELF       := riscv32-unknown-elf-readelf
OBJCOPY       := riscv32-unknown-elf-objcopy
OBJDUMP       := riscv32-unknown-elf-objdump
CFLAGS        := -Wall -Werror -D__NO_INLINE__ -mcmodel=medany -O2 -std=gnu99 -Wno-unused -Wno-attributes -fno-delete-null-pointer-checks $(CFLAGS) -DBBL_PAYLOAD=\"bbl_payload\" -DBBL_LOGO_FILE=\"bbl_logo_file\"
BBL_PAYLOAD   := dummy_payload
COMPILE       := $(CC) -MMD -MP $(CFLAGS) \
                 $(sprojs_include)
# Linker
#  - LDFLAGS : Flags for the linker (eg. -L)
#  - LIBS    : Library flags (eg. -l)

LD            := $(CC)
LDFLAGS       :=  -nostartfiles -nostdlib -static $(LDFLAGS)
LIBS          := -lgcc
LINK          := $(LD) $(LDFLAGS)

# Library creation

AR            := riscv32-unknown-elf-ar
RANLIB        := riscv32-unknown-elf-ranlib

# Host simulator

RUN           := @RUN@
RUNFLAGS      := @RUNFLAGS@


#-------------------------------------------------------------------------
# Include subproject makefile fragments
#-------------------------------------------------------------------------

sprojs_mk = $(addsuffix .mk, $(sprojs_enabled))

-include $(sprojs_mk)

dist_junk += $(sprojs_mk)

#-------------------------------------------------------------------------
# Reverse list helper function
#-------------------------------------------------------------------------
# This function is used by the subproject template to reverse the list
# of dependencies. It uses recursion to perform the reversal.
# 
# Arguments:
#  $(1)   : space separated input list
#  retval : input list in reverse order
#

reverse_list = $(call reverse_list_h,$(1),)
define reverse_list_h
  $(if $(strip $(1)),                        \
    $(call reverse_list_h,                   \
           $(wordlist 2,$(words $(1)),$(1)), \
           $(firstword $(1)) $(2)),          \
    $(2))
endef


define subproject_template

# In some (rare) cases, a subproject might not have any actual object
# files. It might only include header files or program sources. To keep
# things consistent we still want a library for this subproject, so in
# this spectial case we create a dummy source file and thus the build
# system will create a library for this subproject with just the
# corresponding dummy object file.

ifeq ($$(strip $$($(2)_c_srcs)),)
$(2)_c_srcs += _$(1).c
$(2)_junk += _$(1).c
endif

_$(1).c :
	echo "int _$(2)( int arg ) { return arg; }" > $$@

# Build the object files for this subproject

$(2)_c_objs := $$(patsubst %.c, %.o, $$($(2)_c_srcs))
$(2)_asm_objs := $$(patsubst %.S, %.o, $$($(2)_asm_srcs))
$(2)_c_deps := $$(patsubst %.o, %.d, $$($(2)_c_objs))
$$($(2)_c_objs) : %.o : %.c
	$(COMPILE) -c $$<
$$($(2)_asm_objs) : %.o : %.S
	$(COMPILE) -c $$<

$(2)_junk += $$($(2)_c_objs) $$($(2)_c_deps) $$($(2)_asm_objs)

# Build a library for this subproject

lib$(1).a : $$($(2)_c_objs) $$($(2)_asm_objs)
	$(AR) rcv $$@ $$^
	$(RANLIB) $$@

$(2)_junk += lib$(1).a

# Reverse the dependency list so that a given subproject only depends on
# subprojects listed to its right. This is the correct order for linking
# the list of subproject libraries.

$(2)_reverse_deps   := $$(call reverse_list,$$($(2)_subproject_deps))

# Build programs

$(2)_prog_objs      := $$(patsubst %.c, %.o, $$($(2)_prog_srcs))
$(2)_prog_deps      := $$(patsubst %.o, %.d, $$($(2)_prog_objs))
$(2)_prog_exes      := $$(patsubst %.c, %, $$($(2)_prog_srcs))
$(2)_prog_libs      := $(1) $$($(2)_reverse_deps)
$(2)_prog_libnames  := $$(patsubst %, lib%.a, $$($(2)_prog_libs))
$(2)_prog_libarg    := -L. $$(patsubst %, -l%, $$($(2)_prog_libs))

$$($(2)_prog_objs) : %.o : %.c
	$(COMPILE) -c $$<

$$($(2)_prog_exes) : % : %.o $$($(2)_prog_libnames)
	$(LINK) -o $$@ $$< $$($(2)_prog_libarg) $(LIBS)

$(2)_c_deps += $$($(2)_prog_deps)
$(2)_junk += $$($(2)_prog_objs) $$($(2)_prog_deps) $$($(2)_prog_exes)

# Build programs which will be installed

$(2)_install_prog_objs := $$(patsubst %.c, %.o, $$($(2)_install_prog_srcs))
$(2)_install_prog_deps := $$(patsubst %.o, %.d, $$($(2)_install_prog_objs))
$(2)_install_prog_exes := $$(patsubst %.c, %, $$($(2)_install_prog_srcs))

$$($(2)_install_prog_objs) : %.o : %.c
	$(COMPILE) -c $$<

$$($(2)_install_prog_exes) : % : %.o $$($(2)_prog_libnames)
	$(LINK) -o $$@ $$< $$($(2)_prog_libarg) $(LIBS) -T $(src_dir)/$(2)/$(2).lds

$(install_bin): bbl
	$(OBJCOPY) -O binary bbl bbl.bin
	$(OBJDUMP) -S bbl >bbl.s

run: $(install_bin)
	riscvemu32 -b 32 -ctrlc root-riscv32.cfg  2>&1|tee exe.log

$(2)_c_deps += $$($(2)_install_prog_deps)
$(2)_junk += \
  $$($(2)_install_prog_objs) $$($(2)_install_prog_deps) \
  $$($(2)_install_prog_exes)

# Subproject specific targets

all-$(1) : lib$(1).a $$($(2)_install_prog_exes)

check-$(1) : $$($(2)_test_outs)
	echo; grep -h -e'Unit Tests' -e'FAILED' -e'Segementation' $$^; echo

clean-$(1) :
	rm -rf $$($(2)_junk)

.PHONY : all-$(1) check-$(1) clean-$(1)

# Update running variables

libs += lib$(1).a
objs += $$($(2)_c_objs)
srcs += $$(addprefix $(src_dir)/$(1)/, $$($(2)_c_srcs)) 
hdrs += $$(addprefix $(src_dir)/$(1)/, $$($(2)_hdrs))
junk += $$($(2)_junk)
deps += $$($(2)_c_deps)

install_hdrs += $$(addprefix $(src_dir)/$(1)/, $$($(2)_hdrs))
install_libs += lib$(1).a
install_exes += $$($(2)_install_prog_exes)
install_bin = bbl.bin

endef

# Iterate over the subprojects and call the template for each one

$(foreach sproj,$(sprojs_enabled), \
  $(eval $(call subproject_template,$(sproj),$(subst -,_,$(sproj)))))

#-------------------------------------------------------------------------
# Autodependency files
#-------------------------------------------------------------------------

-include $(deps)

deps : $(deps)
.PHONY : deps


#-------------------------------------------------------------------------
# Default
#-------------------------------------------------------------------------

all : $(install_hdrs) $(install_libs) $(install_exes) $(install_bin)
.PHONY : all

#-------------------------------------------------------------------------
# Clean up junk
#-------------------------------------------------------------------------

clean :
	rm -rf *~ $(junk) *.d bbl.bin bbl.s

.PHONY : clean distclean
