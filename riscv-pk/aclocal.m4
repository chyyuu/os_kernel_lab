#=========================================================================
# Local Autoconf Macros
#=========================================================================
# This file contains the macros for the Modular C++ Build System and
# additional autoconf macros which developers can use in their
# configure.ac scripts. Please read the documentation in
# 'mcppbs-doc.txt' for more details on how the Modular C++ Build System
# works. The documenation for each macro should include information
# about the author, date, and copyright.

#-------------------------------------------------------------------------
# MCPPBS_PROG_INSTALL
#-------------------------------------------------------------------------
# This macro will add an --enable-stow command line option to the
# configure script. When enabled, this macro will first check to see if
# the stow program is available and if so it will set the $stow shell
# variable to the binary name and the $enable_stow shell variable to
# "yes". These variables can be used in a makefile to conditionally use
# stow for installation. 
#
# This macro uses two environment variables to help setup default stow
# locations. The $STOW_PREFIX is used for stowing native built packages.
# The packages are staged in $STOW_PREFIX/pkgs and then symlinks are
# created from within $STOW_PREFIX into the pkgs subdirectory. If you
# only do native builds then this is all you need to set. If you don't
# set $STOW_PREFIX then the default is just the normal default prefix
# which is almost always /usr/local.
#
# For non-native builds we probably want to install the packages in a
# different location which includes the host architecture name as part
# of the prefix. For these kind of builds, we can specify the $STOW_ROOT
# environment variable and the effective prefix will be
# $STOW_ROOT/${host_alias} where ${host_alias} is specified on the
# configure command line with "--host".
#
# Here is an example setup:
#
#  STOW_ROOT="$HOME/install"
#  STOW_ARCH="i386-macosx10.4"
#  STOW_PREFIX="${STOW_ROOT}/${STOW_ARCH}"
#

AC_DEFUN([MCPPBS_PROG_INSTALL],
[

  # Configure command line option

  AC_ARG_ENABLE(stow,
    AS_HELP_STRING(--enable-stow,[Enable stow-based install]),
      [enable_stow="yes"],[enable_stow="no"])

  AC_SUBST([enable_stow])
   
  # Environment variables

  AC_ARG_VAR([STOW_ROOT],   [Root for non-native stow-based installs])
  AC_ARG_VAR([STOW_PREFIX], [Prefix for stow-based installs])

  # Check for install script

  AC_PROG_INSTALL

  # Deterimine if native build and set prefix appropriately
  
  AS_IF([ test ${enable_stow} = "yes" ],
  [
    AC_CHECK_PROGS([stow],[stow],[no])  
    AS_IF([ test ${stow} = "no" ],
    [
      AC_MSG_ERROR([Cannot use --enable-stow since stow is not available])
    ])

    # Check if native or non-native build

    AS_IF([ test "${build}" = "${host}" ],
    [

      # build == host so this is a native build. Make sure --prefix not
      # set and $STOW_PREFIX is set, then set prefix=$STOW_PREFIX.

      AS_IF([ test "${prefix}" = "NONE" && test -n "${STOW_PREFIX}" ],
      [
        prefix="${STOW_PREFIX}"
        AC_MSG_NOTICE([Using \$STOW_PREFIX from environment])
        AC_MSG_NOTICE([prefix=${prefix}])
      ])

    ],[

      # build != host so this is a non-native build. Make sure --prefix
      # not set and $STOW_ROOT is set, then set
      # prefix=$STOW_ROOT/${host_alias}.

      AS_IF([ test "${prefix}" = "NONE" && test -n "${STOW_ROOT}" ],
      [
        prefix="${STOW_ROOT}/${host_alias}"
        AC_MSG_NOTICE([Using \$STOW_ROOT from environment])
        AC_MSG_NOTICE([prefix=${prefix}])
      ])

    ])
      
  ])

])

#-------------------------------------------------------------------------
# MCPPBS_SUBPROJECTS([ sproj1, sproj2, ... ])
#-------------------------------------------------------------------------
# The developer should call this macro with a list of the subprojects
# which make up this project. One should order the list such that any
# given subproject only depends on subprojects listed before it. The
# subproject names can also include an * suffix which indicates that
# this is an optional subproject. Optional subprojects are only included
# as part of the project build if enabled on the configure command line
# with a --enable-<subproject> flag. The user can also specify that all
# optional subprojects should be included in the build with the
# --enable-optional-subprojects flag.
#
# Subproject names can also include a ** suffix which indicates that it
# is an optional subproject, but there is a group with the same name.
# Thus the --enable-<sproj> command line option will enable not just the
# subproject sproj but all of the subprojects which are in the group.
# There is no error checking to make sure that if you use the ** suffix
# you actually define a group so be careful.
#
# Both required and optional subprojects should have a 'subproject.ac'
# file. The script's filename should be the abbreivated subproject name
# (assuming the subproject name is sproj then we would use 'sproj.ac')
# The MCPPBS_SUBPROJECTS macro includes the 'subproject.ac' files for
# enabled subprojects. Whitespace and newlines are allowed within the
# list.
#
# Author : Christopher Batten
# Date   : September 10, 2008

AC_DEFUN([MCPPBS_SUBPROJECTS],
[

  # Add command line argument to enable all optional subprojects 

  AC_ARG_ENABLE(optional-subprojects,
    AS_HELP_STRING([--enable-optional-subprojects],
      [Enable all optional subprojects]))

  # Loop through the subprojects given in the macro argument

  m4_foreach([MCPPBS_SPROJ],[$1],
  [
  
    # Determine if this is a required or an optional subproject

    m4_define([MCPPBS_IS_REQ],
      m4_bmatch(MCPPBS_SPROJ,[\*+],[false],[true]))

    # Determine if there is a group with the same name

    m4_define([MCPPBS_IS_GROUP],
      m4_bmatch(MCPPBS_SPROJ,[\*\*],[true],[false]))

    # Create variations of the subproject name suitable for use as a CPP
    # enabled define, a shell enabled variable, and a shell function

    m4_define([MCPPBS_SPROJ_NORM],
      m4_normalize(m4_bpatsubsts(MCPPBS_SPROJ,[*],[])))

    m4_define([MCPPBS_SPROJ_DEFINE],
      m4_toupper(m4_bpatsubst(MCPPBS_SPROJ_NORM[]_ENABLED,[-],[_])))

    m4_define([MCPPBS_SPROJ_FUNC],
      m4_bpatsubst(_mpbp_[]MCPPBS_SPROJ_NORM[]_configure,[-],[_]))

    m4_define([MCPPBS_SPROJ_UNDERSCORES],
      m4_bpatsubsts(MCPPBS_SPROJ,[-],[_]))

    m4_define([MCPPBS_SPROJ_SHVAR],
      m4_bpatsubst(enable_[]MCPPBS_SPROJ_NORM[]_sproj,[-],[_]))
    
    # Add subproject to our running list

    subprojects="$subprojects MCPPBS_SPROJ_NORM"

    # Process the subproject appropriately. If enabled add it to the
    # $enabled_subprojects running shell variable, set a
    # SUBPROJECT_ENABLED C define, and include the appropriate
    # 'subproject.ac'.

    m4_if(MCPPBS_IS_REQ,[true],
    [
      AC_MSG_NOTICE([configuring default subproject : MCPPBS_SPROJ_NORM])
      AC_CONFIG_FILES(MCPPBS_SPROJ_NORM[].mk:MCPPBS_SPROJ_NORM[]/MCPPBS_SPROJ_NORM[].mk.in)
      MCPPBS_SPROJ_SHVAR="yes"
      subprojects_enabled="$subprojects_enabled MCPPBS_SPROJ_NORM"
      AC_DEFINE(MCPPBS_SPROJ_DEFINE,,
        [Define if subproject MCPPBS_SPROJ_NORM is enabled])
      m4_include(MCPPBS_SPROJ_NORM[]/MCPPBS_SPROJ_NORM[].ac) 
    ],[

      # For optional subprojects we capture the 'subproject.ac' as a
      # shell function so that in the MCPPBS_GROUP macro we can just
      # call this shell function instead of reading in 'subproject.ac'
      # again.

      MCPPBS_SPROJ_FUNC ()
      { 
        AC_MSG_NOTICE([configuring optional subproject : MCPPBS_SPROJ_NORM])
        AC_CONFIG_FILES(MCPPBS_SPROJ_NORM[].mk:MCPPBS_SPROJ_NORM[]/MCPPBS_SPROJ_NORM[].mk.in)
        MCPPBS_SPROJ_SHVAR="yes"
        subprojects_enabled="$subprojects_enabled MCPPBS_SPROJ_NORM"
        AC_DEFINE(MCPPBS_SPROJ_DEFINE,,
          [Define if subproject MCPPBS_SPROJ_NORM is enabled])
        m4_include(MCPPBS_SPROJ_NORM[]/MCPPBS_SPROJ_NORM[].ac) 
      };

      # Optional subprojects add --enable-subproject command line
      # options, _if_ the subproject name is not also a group name.

      m4_if(MCPPBS_IS_GROUP,[false],
      [
        AC_ARG_ENABLE(MCPPBS_SPROJ_NORM,
          AS_HELP_STRING(--enable-MCPPBS_SPROJ_NORM,
            [Subproject MCPPBS_SPROJ_NORM]),
          [MCPPBS_SPROJ_SHVAR="yes"],[MCPPBS_SPROJ_SHVAR="no"])

        AS_IF([test "$MCPPBS_SPROJ_SHVAR" = "yes"],
        [
          eval "MCPPBS_SPROJ_FUNC"
        ],[ 
          AC_MSG_NOTICE([processing optional subproject : MCPPBS_SPROJ_NORM])
        ])

     ],[

       # If the subproject name is also a group name then we need to
       # make sure that we set the shell variable for that subproject to
       # no so that the group code knows we haven't run it yet.

       AC_MSG_NOTICE([processing optional subproject : MCPPBS_SPROJ_NORM])
       MCPPBS_SPROJ_SHVAR="no"

     ])

     # Always execute the subproject configure code if we are enabling
     # all subprojects.

     AS_IF([    test "$enable_optional_subprojects" = "yes" \
             && test "$MCPPBS_SPROJ_SHVAR" = "no"  ],
     [
       eval "MCPPBS_SPROJ_FUNC"
     ])

    ])

  ])

  # Output make variables  

  AC_SUBST([subprojects])
  AC_SUBST([subprojects_enabled])

])

#-------------------------------------------------------------------------
# MCPPBS_GROUP( [group-name], [ sproj1, sproj2, ... ] )
#-------------------------------------------------------------------------
# This macro creates a subproject group with the given group-name. When
# a user specifies --enable-<group-name> the listed subprojects will be
# enabled. Groups can have the same name as a subproject and in that
# case whenever a user specifies --enable-<subproject> the subprojects
# listed in the corresponding group will also be enabled. Groups are
# useful for specifying related subprojects which are usually enabled
# together, as well as for specifying that a specific optional
# subproject has dependencies on other optional subprojects.
#
# Author : Christopher Batten
# Date   : September 10, 2008

AC_DEFUN([MCPPBS_GROUP],
[

  m4_define([MCPPBS_GROUP_NORM],
    m4_normalize([$1]))

  m4_define([MCPPBS_GROUP_SHVAR],
    m4_bpatsubst(enable_[]MCPPBS_GROUP_NORM[]_group,[-],[_]))
                
  AC_ARG_ENABLE(MCPPBS_GROUP_NORM,
    AS_HELP_STRING(--enable-MCPPBS_GROUP_NORM,
      [Group MCPPBS_GROUP_NORM: $2]),
    [MCPPBS_GROUP_SHVAR="yes"],[MCPPBS_GROUP_SHVAR="no"])

  AS_IF([test "$MCPPBS_GROUP_SHVAR" = "yes" ],
  [ 
    AC_MSG_NOTICE([configuring optional group : MCPPBS_GROUP_NORM])
  ])

  m4_foreach([MCPPBS_SPROJ],[$2],
  [    

    m4_define([MCPPBS_SPROJ_NORM],
      m4_normalize(MCPPBS_SPROJ))

    m4_define([MCPPBS_SPROJ_SHVAR],
      m4_bpatsubst(enable_[]MCPPBS_SPROJ_NORM[]_sproj,[-],[_]))

    m4_define([MCPPBS_SPROJ_FUNC],
      m4_bpatsubst(_mpbp_[]MCPPBS_SPROJ_NORM[]_configure,[-],[_]))

    AS_IF([    test "$MCPPBS_GROUP_SHVAR" = "yes" \
            && test "$MCPPBS_SPROJ_SHVAR" = "no" ],
    [
      eval "MCPPBS_SPROJ_FUNC"
    ])

  ])

])

#-------------------------------------------------------------------------
# AX_DEFAULT_CONFIGURE_ARG
#-------------------------------------------------------------------------
# Simple little macro which adds a configure commane line option to an
# internal autoconf shell variable. Not sure how safe this is, but it
# seems to work fine.
#
# Author : Christopher Batten
# Date   : August 20, 2009

AC_DEFUN([AX_DEFAULT_CONFIGURE_ARG],
[
  AC_MSG_NOTICE([adding default configure arg: $1])
  ac_configure_args="$1 ${ac_configure_args}"
])
