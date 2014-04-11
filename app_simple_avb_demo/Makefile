# The TARGET variable determines what target system the application is 
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling.

TARGET = XR-AVB-LC-BRD

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to 
# the project name

APP_NAME =

VERBOSE=0


# This variable controls where the include files for the app are found.
# In this application the extra include files may be found in a target
# specific directory for XMOS development boards

INCLUDE_DIRS = src xmos_board_info/$(TARGET)

# This header file is marked as optional since it is only included for
# a known XMOS development board
OPTIONAL_HEADERS = avb_app_board_config.h

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
#
#    XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
#
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to 
# xcc for the final link (mapping) stage.

XCC_FLAGS = -O2 -save-temps -g -report -Xmapper --map -Xmapper MAPFILE

###########################################################################
# Settings derived from configuration names
###########################################################################

# if config name contains TDM, use the TDM multi interface
ifneq (,$(findstring TDM,$(CONFIG))) 
AUDIO_INTERFACE = tdm_multi
# one of i2s, tdm, tdm_multi
endif


###########################################################################
# Default settings
###########################################################################

ifndef AUDIO_INTERFACE
AUDIO_INTERFACE = i2s
endif

#hack
XCC_FLAGS += -DAVB_AUDIO_IF_$(AUDIO_INTERFACE)=1 -DI2S_SYNTH_FROM=1

###########################################################################
#############################  Configurations #############################
###########################################################################
# Configuration naming convention:
# example: 1t1s16ch_2l2s32ch_TDM
# $X[tl]$Ys$Zch[_$if]
# $Xt: 	number of talkers
# $Xl: 	number of listeners
# $Ys: 	number of streams
# $Zch: number of channels
# $if:	optional: audio interface other than i2s

XCC_FLAGS_1t8s16ch_1l8s16ch_TDM = $(XCC_FLAGS) -DAVB_NUM_SINKS=8 -DAVB_NUM_SOURCES=8 -DAVB_DEMO_NUM_CHANNELS=16

XCC_FLAGS_1t4s16ch_1l4s16ch_TDM = $(XCC_FLAGS) -DAVB_NUM_SINKS=4 -DAVB_NUM_SOURCES=4 -DAVB_DEMO_NUM_CHANNELS=16

XCC_FLAGS_1t2s16ch_1l2s16ch_TDM = $(XCC_FLAGS) -DAVB_NUM_SINKS=2 -DAVB_NUM_SOURCES=2 -DAVB_DEMO_NUM_CHANNELS=16

XCC_FLAGS_1t1s16ch_1l1s16ch_TDM = $(XCC_FLAGS) -DAVB_NUM_SINKS=1 -DAVB_NUM_SOURCES=1 -DAVB_DEMO_NUM_CHANNELS=16

XCC_FLAGS_1t1s16ch_TDM = $(XCC_FLAGS) -DAVB_DEMO_ENABLE_LISTENER=0 -DAVB_NUM_SOURCES=1 -DAVB_DEMO_NUM_CHANNELS=16

XCC_FLAGS_1t1s8ch_TDM = $(XCC_FLAGS) -DAVB_DEMO_ENABLE_TALKER=0 -DAVB_NUM_SINKS=1 -DAVB_DEMO_NUM_CHANNELS=8

XCC_FLAGS_1t1s8ch_1l1s8ch_TDM = $(XCC_FLAGS) -DAVB_NUM_SINKS=1 -DAVB_NUM_SOURCES=1 -DAVB_DEMO_NUM_CHANNELS=8

XCC_FLAGS_1t2s8ch_1l2s8ch_TDM = $(XCC_FLAGS) -DAVB_NUM_SINKS=2 -DAVB_NUM_SOURCES=2 -DAVB_DEMO_NUM_CHANNELS=8

# Doesn't enumerate on MAC
XCC_FLAGS_1l8s8ch_TDM = $(XCC_FLAGS) -DAVB_DEMO_ENABLE_TALKER=0 -DAVB_NUM_SINKS=8 -DAVB_DEMO_NUM_CHANNELS=8

XCC_FLAGS_1t8s8ch_TDM = $(XCC_FLAGS) -DAVB_DEMO_ENABLE_LISTENER=0 -DAVB_NUM_SOURCES=1 -DAVB_DEMO_NUM_CHANNELS=8

XCC_FLAGS_1t8s8ch_1l8s8ch_TDM = $(XCC_FLAGS) -DAVB_NUM_SINKS=8 -DAVB_NUM_SOURCES=8 -DAVB_DEMO_NUM_CHANNELS=8


# This is for the Testbench Endpoint. I2S I/O of actual audio. The remaining channels are computed
XCC_FLAGS_1t8s16ch_1l8s16ch_I2S = $(XCC_FLAGS) -DAVB_NUM_SINKS=8 -DAVB_NUM_SOURCES=8 -DAVB_DEMO_NUM_CHANNELS=16 
#force to fit in the I/O budget
XCC_FLAGS_1t8s16ch_1l8s16ch_I2S += -DAVB_NUM_AUDIO_SDATA_IN=4 -DAVB_NUM_AUDIO_SDATA_OUT=4  

# This is for the Testbench Endpoint. I2S I/O of actual audio. The remaining channels are computed
XCC_FLAGS_1t4s8ch_1l4s8ch_I2S = $(XCC_FLAGS) -DAVB_NUM_SINKS=4 -DAVB_NUM_SOURCES=4 -DAVB_DEMO_NUM_CHANNELS=8


XCC_FLAGS_main.xc = $(XCC_FLAGS) -falways-inline


# The USED_MODULES variable lists other module used by the application. 

USED_MODULES = module_avb_1722 module_avb_1722_maap module_avb_srp module_avb_media_clock module_avb_audio module_random
USED_MODULES += module_avb module_avb_util module_gptp module_ethernet module_ethernet_board_support module_avb_1722_1

#Add audio interfaces from module_avb_audio
USED_AUDIO_INTERFACES = $(AUDIO_INTERFACE)

ifeq ($(TARGET),$(filter $(TARGET),XR-AVB-LC-BRD D4U-AVB-DG SLICEKIT-L2))
    USED_MODULES += module_i2c_simple
endif

ifeq ($(TARGET),$(filter $(TARGET),XR-AVB-LC-BRD SLICEKIT-L2))
    XCC_FLAGS += -fxscope
endif

ifeq ($(TARGET),SLICEKIT-L2)
    USED_MODULES += module_slicekit_support
endif

#=============================================================================
#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
ifneq ($(wildcard $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common),)
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
else
include ../module_xcommon/build/Makefile.common
endif


