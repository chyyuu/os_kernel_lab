#=========================================================================
# Toplevel configure.ac for the Modular C++ Build System
#=========================================================================
# Please read the documenation in 'mcppbs-doc.txt' for more details on
# how the Modular C++ Build System works. For most new projects, a
# developer will only need to make the following changes:
#
#  - change the project metadata listed right below
#  - update the list of subprojects via the 'MCPPBS_SUBPROJECTS' macro
#  - possibly add subproject groups if needed to ease configuration
#  - add more configure checks for platform specific configuration
#

#-------------------------------------------------------------------------
# Project metadata
#-------------------------------------------------------------------------

m4_define( proj_name,         [RISC-V Proxy Kernel])
m4_define( proj_maintainer,   [Andrew Waterman])
m4_define( proj_abbreviation, [riscv-pk])

#-------------------------------------------------------------------------
# Project version information
#-------------------------------------------------------------------------
# Version information is meant to be managed through a version control
# system's tags and revision numbers. In a working copy the version will
# not be defined here (you should just use the version control system's
# mechanisms). When we make a distribution then we can set the version
# here as formed by the scripts/vcs-version.sh script so that the
# distribution knows what version it came from. If you are not using
# version control then it is fine to set this directly.

m4_define( proj_version, [?])

#-------------------------------------------------------------------------
# Setup
#-------------------------------------------------------------------------

AC_INIT(proj_name,proj_version,proj_maintainer,proj_abbreviation)
AC_CONFIG_SRCDIR([pk/pk.h])
AC_CONFIG_AUX_DIR([scripts])
AC_CANONICAL_BUILD
AC_CANONICAL_HOST

#-------------------------------------------------------------------------
# Checks for programs
#-------------------------------------------------------------------------

AC_PROG_CC
AC_PROG_CXX
AC_CHECK_TOOL([AR],[ar])
AC_CHECK_TOOL([RANLIB],[ranlib])
AC_CHECK_TOOL([READELF],[readelf])
AC_CHECK_TOOL([OBJCOPY],[objcopy])

#-------------------------------------------------------------------------
# MCPPBS specific program checks
#-------------------------------------------------------------------------
# These macros check to see if we can do a stow-based install and also
# check for an isa simulator suitable for running the unit test programs
# via the makefile.

MCPPBS_PROG_INSTALL

#-------------------------------------------------------------------------
# Checks for header files
#-------------------------------------------------------------------------

AC_HEADER_STDC

#-------------------------------------------------------------------------
# Register RISCV environment variable
#-------------------------------------------------------------------------

AC_ARG_VAR(RISCV, [top-level RISC-V install directory])

#-------------------------------------------------------------------------
# Set compiler flags
#-------------------------------------------------------------------------

default_CFLAGS="-Wall -Werror -D__NO_INLINE__ -mcmodel=medany -O2 -std=gnu99 -Wno-unused -Wno-attributes -fno-delete-null-pointer-checks"

AC_ARG_ENABLE([32bit],
	AS_HELP_STRING([--enable-32bit], [Build a 32-bit pk]),
	BUILD_32BIT=$enableval,
	BUILD_32BIT=no)

case "${BUILD_32BIT}" in
  yes|default)
	echo "Building 32-bit pk"
	CFLAGS="$default_CFLAGS -m32"
	LDFLAGS="-m32"
	install_subdir="riscv32-unknown-elf"
	;;
  *)
	CFLAGS="$default_CFLAGS"
	LDFLAGS=
	install_subdir="riscv64-unknown-elf"
	;;
esac

AC_ARG_ENABLE([print-device-tree], AS_HELP_STRING([--enable-print-device-tree], [Print DTS when booting]))
AS_IF([test "x$enable_print_device_tree" == "xyes"], [
  AC_DEFINE([PK_PRINT_DEVICE_TREE],,[Define if the DTS is to be displayed])
])

AC_SUBST(CFLAGS)
AC_SUBST(LDFLAGS)
AC_SUBST([LIBS], ["-lgcc"])
AC_SUBST(install_subdir)

#-------------------------------------------------------------------------
# MCPPBS subproject list
#-------------------------------------------------------------------------
# Order list so that subprojects only depend on those listed earlier.
# The '*' suffix indicates an optional subproject. The '**' suffix
# indicates an optional subproject which is also the name of a group.

MCPPBS_SUBPROJECTS([ pk, bbl, softfloat, dummy_payload, machine, util ])

#-------------------------------------------------------------------------
# MCPPBS subproject groups
#-------------------------------------------------------------------------
# If a group has the same name as a subproject then you must add the
# '**' suffix in the subproject list above. The list of subprojects in a
# group should be ordered so that subprojets only depend on those listed
# earlier. Here is an example:
#
#  MCPPBS_GROUP( [group-name], [sproja,sprojb,...] )
#

#-------------------------------------------------------------------------
# Output
#-------------------------------------------------------------------------

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
