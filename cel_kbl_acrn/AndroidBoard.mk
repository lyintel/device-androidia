# ----------------- BEGIN MIX-IN DEFINITIONS -----------------
# Mix-In definitions are auto-generated by mixin-update
##############################################################
# Source: device/intel/project-celadon/mixins/groups/device-specific/cel_kbl_acrn/AndroidBoard.mk
##############################################################
# Specify /dev/mmcblk0 size here
BOARD_MMC_SIZE = 15335424K

ifeq ($(PLATFORM_VERSION), OMR1)
TARGET_PREBUILT_BOOTLOADER := $(TARGET_DEVICE_DIR)/bootloader.img
PREBUILT_MULTIBOOT := $(TARGET_DEVICE_DIR)/multiboot.img
endif
##############################################################
# Source: device/intel/project-celadon/mixins/groups/variants/true/AndroidBoard.mk
##############################################################
# flashfile_add_blob <blob_name> <path> <mandatory> <var_name>
# - Replace ::variant:: from <path> by variant name
# - If the result does not exists and <mandatory> is set, error
# - If <var_name> is set, put the result in <var_name>_<variant>
# - Add the pair <result>:<blob_name> in BOARD_FLASHFILES_FIRMWARE_<variant>
define flashfile_add_blob
$(foreach VARIANT,$(FLASHFILE_VARIANTS), \
    $(eval blob := $(subst ::variant::,$(VARIANT),$(2))) \
    $(if $(wildcard $(blob)), \
        $(if $(4), $(eval $(4)_$(VARIANT) := $(blob))) \
        $(eval BOARD_FLASHFILES_FIRMWARE_$(VARIANT) += $(blob):$(1)) \
        , \
        $(if $(3), $(error $(blob) does not exist))))
endef

define add_variant_flashfiles
$(foreach VARIANT,$(FLASHFILE_VARIANTS), \
    $(eval var_flashfile := $(TARGET_DEVICE_DIR)/flashfiles/$(VARIANT)/flashfiles.ini) \
    $(if $(wildcard $(var_flashfile)), \
        $(eval $(call add_var_flashfile,$(VARIANT),$(var_flashfile),$(1)))))
endef

define add_var_flashfile
INSTALLED_RADIOIMAGE_TARGET += $(3)/flashfiles_$(1).ini
$(3)/flashfiles_$(1).ini: $(2) | $(ACP)
	$$(copy-file-to-target)
endef

# Define ROOT_VARIANTS and VARIANTS in variants.mk
include $(TARGET_DEVICE_DIR)/variants.mk

# Let the user define it's variants manually if desired
ifeq ($(FLASHFILE_VARIANTS),)
        OTA_VARIANTS := $(ROOT_VARIANTS)
        FLASHFILE_VARIANTS := $(ROOT_VARIANTS) $(VARIANTS)
        ifeq ($(GEN_ALL_OTA),true)
            OTA_VARIANTS += $(VARIANTS)
        endif
endif

ifeq ($(FLASHFILE_VARIANTS),)
        $(error variants enabled but ROOT_VARIANTS is not defined)
endif

BOARD_DEVICE_MAPPING := $(TARGET_DEVICE_DIR)/device_mapping.py
ifeq ($(wildcard $(BOARD_DEVICE_MAPPING)),)
$(error variants need device_mapping.py to generate ota packages)
endif
INSTALLED_RADIOIMAGE_TARGET += $(BOARD_DEVICE_MAPPING)
##############################################################
# Source: device/intel/project-celadon/mixins/groups/slot-ab/true/AndroidBoard.mk
##############################################################
make_ramdisk_dir:
	@mkdir -p $(PRODUCT_OUT)/root/metadata

$(PRODUCT_OUT)/ramdisk.img: make_ramdisk_dir

##############################################################
# Source: device/intel/project-celadon/mixins/groups/boot-arch/vsbl/AndroidBoard.mk
##############################################################
KERNEL_VSBL_DIFFCONFIG = $(wildcard $(KERNEL_CONFIG_PATH)/vsbl_diffconfig)
KERNEL_DIFFCONFIG += $(KERNEL_VSBL_DIFFCONFIG)

OPTIONIMAGE_BIN = $(TARGET_DEVICE_DIR)/boot_option.bin

# Partition table configuration file
BOARD_GPT_INI ?= $(TARGET_DEVICE_DIR)/gpt.ini
BOARD_GPT_BIN = $(PRODUCT_OUT)/gpt.bin
GPT_INI2BIN := ./$(INTEL_PATH_COMMON)/gpt_bin/gpt_ini2bin.py
BOARD_BOOTLOADER_PARTITION_SIZE_KILO := $$((30 * 1024))

$(BOARD_GPT_BIN): $(BOARD_GPT_INI)
	$(hide) $(GPT_INI2BIN) $< > $@
	$(hide) echo GEN $(notdir $@)

BOARD_FLASHFILES += $(BOARD_GPT_BIN):gpt.bin

# REVERT-ME create GPT IMG for ELK installer script
BOARD_GPT_IMG = $(PRODUCT_OUT)/gpt.img
BOARD_FLASHFILES += $(BOARD_GPT_IMG):gpt.img

GPT_INI2IMG := ./$(INTEL_PATH_BUILD)/create_gpt_image.py

intermediate_img := $(call intermediates-dir-for,PACKAGING,flashfiles)/gpt.img

$(BOARD_GPT_IMG): $(BOARD_GPT_INI)
	$(hide) mkdir -p $(dir $(intermediate_img))
	$(hide) $(GPT_INI2IMG) --create --table $< --size $(BOARD_MMC_SIZE) $(intermediate_img)
	$(hide) dd if=$(intermediate_img) of=$@ bs=512 count=34
	$(hide) echo GEN $(notdir $@)

# (pulled from build/core/Makefile as this gets defined much later)
# Pick a reasonable string to use to identify files.
ifneq "" "$(filter eng.%,$(BUILD_NUMBER))"
# BUILD_NUMBER has a timestamp in it, which means that
# it will change every time.  Pick a stable value.
FILE_NAME_TAG := eng.$(USER)
else
FILE_NAME_TAG := $(BUILD_NUMBER)
endif

bootloader_bin := $(PRODUCT_OUT)/bootloader
BOARD_BOOTLOADER_DEFAULT_IMG := $(PRODUCT_OUT)/bootloader.img
BOARD_BOOTLOADER_DIR := $(PRODUCT_OUT)/abl
BOARD_BOOTLOADER_IASIMAGE := $(BOARD_BOOTLOADER_DIR)/kf4abl.abl
BOARD_BOOTLOADER_VAR_IMG := $(BOARD_BOOTLOADER_DIR)/bootloader.img
INSTALLED_RADIOIMAGE_TARGET += $(BOARD_BOOTLOADER_DEFAULT_IMG)

define add_board_flashfiles_variant
$(eval BOARD_FLASHFILES_FIRMWARE_$(1) += $(BOARD_BOOTLOADER_DEFAULT_IMG):bootloader) \
$(eval BOARD_FLASHFILES_FIRMWARE_$(1) += $(TARGET_DEVICE_DIR)/extra_files/boot-arch/fftf_build.opt:fftf_build.opt) \
$(eval BOARD_FLASHFILES_FIRMWARE_$(1) += $(BOARD_BOOTLOADER_IASIMAGE):fastboot)
endef

SBL_AVAILABLE_CONFIG := $(ROOT_VARIANTS)
$(foreach config,$(SBL_AVAILABLE_CONFIG),$(call add_board_flashfiles_variant,$(config)))

$(call flashfile_add_blob,capsule.fv,$(INTEL_PATH_HARDWARE)/fw_capsules/gordon_peak_acrn/::variant::/$(IFWI_VARIANT)/capsule.fv,,BOARD_SFU_UPDATE)
$(call flashfile_add_blob,ifwi.bin,$(INTEL_PATH_HARDWARE)/fw_capsules/gordon_peak_acrn/::variant::/$(IFWI_VARIANT)/ifwi.bin,,EFI_IFWI_BIN)

ifneq ($(EFI_IFWI_BIN),)
$(call dist-for-goals,droidcore,$(EFI_IFWI_BIN):$(TARGET_PRODUCT)-ifwi-$(FILE_NAME_TAG).bin)
endif

ifneq ($(BOARD_SFU_UPDATE),)
$(call dist-for-goals,droidcore,$(BOARD_SFU_UPDATE):$(TARGET_PRODUCT)-sfu-$(FILE_NAME_TAG).fv)
endif

ifeq ($(wildcard $(EFI_IFWI_BIN)),)
$(warning ##### EFI_IFWI_BIN not found, IFWI binary will not be provided in out/dist/)
endif

BOARD_FLASHFILES += $(BOARD_BOOTLOADER_DEFAULT_IMG):bootloader

$(BOARD_BOOTLOADER_DIR):
	$(hide) rm -rf $(BOARD_BOOTLOADER_DIR)
	$(hide) mkdir -p $(BOARD_BOOTLOADER_DIR)

ifneq ($(BOARD_BOOTLOADER_PARTITION_SIZE),0)
define generate_bootloader_var
rm -f $(BOARD_BOOTLOADER_VAR_IMG)
$(hide) if [ -e "$(BOARD_SFU_UPDATE)" ]; then \
    dd of=$(BOARD_BOOTLOADER_VAR_IMG) if=$(BOARD_SFU_UPDATE) bs=1024; \
else \
    dd of=$(BOARD_BOOTLOADER_VAR_IMG) if=/dev/zero bs=1024 count=16384; \
fi
$(hide) dd of=$(BOARD_BOOTLOADER_VAR_IMG) if=$(BOARD_BOOTLOADER_IASIMAGE) bs=1024 seek=16384
cp $(BOARD_BOOTLOADER_VAR_IMG) $(BOARD_BOOTLOADER_DEFAULT_IMG)
cp $(BOARD_BOOTLOADER_VAR_IMG) $(bootloader_bin)
echo "Bootloader image successfully generated $(BOARD_BOOTLOADER_VAR_IMG)"
endef

fastboot_image: fb4abl-$(TARGET_BUILD_VARIANT)
bootloader: $(BOARD_BOOTLOADER_DIR) mkext2img kf4abl-$(TARGET_BUILD_VARIANT)
	$(call generate_bootloader_var,$(config))
else
bootloader: $(BOARD_BOOTLOADER_DIR)
	$(ACP) -f $(ABL_PREBUILT_PATH)/bldr_utils.img $(BOARD_BOOTLOADER_DEFAULT_IMG)
	$(foreach config,$(ABL_AVAILABLE_CONFIG),cp -v $(BOARD_BOOTLOADER_DEFAULT_IMG) $(BOARD_BOOTLOADER_DIR)/$(config)/)
endif

$(BOARD_BOOTLOADER_DIR)/%/bootloader.img: bootloader
	@echo "Generate bootloader: $@ finished."

$(BOARD_BOOTLOADER_DEFAULT_IMG): bootloader
	@echo "Generate default bootloader: $@ finished."
droidcore: bootloader

$(bootloader_bin): bootloader

.PHONY: bootloader
##############################################################
# Source: device/intel/project-celadon/mixins/groups/wlan/mwifiex/AndroidBoard.mk
##############################################################
KERNEL_MARVELL_DIFFCONFIG += $(wildcard $(LOCAL_KERNEL_SRC)/arch/x86/configs/cfg80211_diffconfig)
KERNEL_DIFFCONFIG += $(KERNEL_MARVELL_DIFFCONFIG)

LOAD_MODULES_IN += $(TARGET_DEVICE_DIR)/extra_files/wlan/load_mwifiex.in
##############################################################
# Source: device/intel/project-celadon/mixins/groups/kernel/gmin64/AndroidBoard.mk
##############################################################
ifeq ($(TARGET_PREBUILT_KERNEL),)

LOCAL_KERNEL_PATH := $(abspath $(PRODUCT_OUT)/obj/kernel)
KERNEL_INSTALL_MOD_PATH := .
LOCAL_KERNEL := $(LOCAL_KERNEL_PATH)/arch/x86/boot/bzImage
LOCAL_KERNEL_MODULE_TREE_PATH := $(LOCAL_KERNEL_PATH)/lib/modules
KERNELRELEASE := $(shell cat $(LOCAL_KERNEL_PATH)/include/config/kernel.release)

KERNEL_CCACHE := $(realpath $(CC_WRAPPER))

#remove time_macros from ccache options, it breaks signing process
KERNEL_CCSLOP := $(filter-out time_macros,$(subst $(comma), ,$(CCACHE_SLOPPINESS)))
KERNEL_CCSLOP := $(subst $(space),$(comma),$(KERNEL_CCSLOP))


ifeq ($(DEV_BKC_KERNEL), true)
  LOCAL_KERNEL_SRC := 
  KERNEL_CONFIG_PATH := 
  EXT_MODULES := 
  DEBUG_MODULES := 

else ifeq ($(LTS2018_KERNEL), true)
  LOCAL_KERNEL_SRC := 
  KERNEL_CONFIG_PATH := 
  EXT_MODULES := 
  DEBUG_MODULES := 

else
  LOCAL_KERNEL_SRC := kernel/4.14
  EXT_MODULES := marvell/wifi
  DEBUG_MODULES := 
  KERNEL_CONFIG_PATH := kernel/config-lts/v4.14/bxt/android
endif

EXTMOD_SRC := ../modules
EXTERNAL_MODULES := $(EXT_MODULES)

KERNEL_DEFCONFIG := $(KERNEL_CONFIG_PATH)/$(TARGET_KERNEL_ARCH)_defconfig
ifneq ($(TARGET_BUILD_VARIANT), user)
  KERNEL_DEBUG_DIFFCONFIG += $(wildcard $(KERNEL_CONFIG_PATH)/debug_diffconfig)
  ifneq ($(KERNEL_DEBUG_DIFFCONFIG),)
    KERNEL_DIFFCONFIG += $(KERNEL_DEBUG_DIFFCONFIG)
  else
    KERNEL_DEFCONFIG := $(LOCAL_KERNEL_SRC)/arch/x86/configs/$(TARGET_KERNEL_ARCH)_debug_defconfig
  endif
  EXTERNAL_MODULES := $(EXT_MODULES) $(DEBUG_MODULES)
endif # variant not eq user

KERNEL_CONFIG := $(LOCAL_KERNEL_PATH)/.config

ifeq ($(TARGET_BUILD_VARIANT), eng)
  KERNEL_ENG_DIFFCONFIG := $(wildcard $(KERNEL_CONFIG_PATH)/eng_diffconfig)
  ifneq ($(KERNEL_ENG_DIFFCONFIG),)
    KERNEL_DIFFCONFIG += $(KERNEL_ENG_DIFFCONFIG)
  endif
endif

KERNEL_MAKE_OPTIONS = \
    SHELL=/bin/bash \
    -C $(LOCAL_KERNEL_SRC) \
    O=$(LOCAL_KERNEL_PATH) \
    ARCH=$(TARGET_KERNEL_ARCH) \
    INSTALL_MOD_PATH=$(KERNEL_INSTALL_MOD_PATH) \
    CROSS_COMPILE="$(KERNEL_CCACHE) $(YOCTO_CROSSCOMPILE)" \
    CCACHE_SLOPPINESS=$(KERNEL_CCSLOP)

KERNEL_MAKE_OPTIONS += \
    EXTRA_FW="$(_EXTRA_FW_)" \
    EXTRA_FW_DIR="$(abspath $(PRODUCT_OUT)/vendor/firmware)"

KERNEL_CONFIG_DEPS = $(strip $(KERNEL_DEFCONFIG) $(KERNEL_DIFFCONFIG))
KERNEL_CONFIG_MK := $(LOCAL_KERNEL_PATH)/config.mk
-include $(KERNEL_CONFIG_MK)

ifneq ($(KERNEL_CONFIG_DEPS),$(KERNEL_CONFIG_PREV_DEPS))
.PHONY: $(KERNEL_CONFIG)
endif

CHECK_CONFIG_SCRIPT := $(LOCAL_KERNEL_SRC)/scripts/diffconfig
CHECK_CONFIG_LOG :=  $(LOCAL_KERNEL_PATH)/.config.check

KERNEL_DEPS := $(shell find $(LOCAL_KERNEL_SRC) \( -name *.git -prune \) -o -print )

# Before building final defconfig with debug diffconfigs
# Check that base defconfig is correct. Check is performed
# by comparing generated .config with .config.old
# If differences are observed, display a help message
# and stop kernel build.
# If a .config is already present, save it before processing
# the check and restore it at the end
$(CHECK_CONFIG_LOG): $(KERNEL_DEFCONFIG) $(KERNEL_DEPS) | yoctotoolchain
	$(hide) mkdir -p $(@D)
	-$(hide) [[ -e $(KERNEL_CONFIG) ]] && mv -f $(KERNEL_CONFIG) $(KERNEL_CONFIG).save
	$(hide) cat $< > $(KERNEL_CONFIG)
	$(hide) $(MAKE) $(KERNEL_MAKE_OPTIONS) olddefconfig
	$(hide) $(CHECK_CONFIG_SCRIPT) $(KERNEL_CONFIG).old $(KERNEL_CONFIG) > $@
	-$(hide) [[ -e $(KERNEL_CONFIG).save ]] && mv -f $(KERNEL_CONFIG).save $(KERNEL_CONFIG)
	$(hide) if [[ -s $@ ]] ; then \
	  echo "CHECK KERNEL DEFCONFIG FATAL ERROR :" ; \
	  echo "Kernel config copied from $(KERNEL_DEFCONFIG) has some config issue." ; \
	  echo "Final '.config' and '.config.old' differ. This should never happen." ; \
	  echo "Observed diffs are :" ; \
	  cat $@ ; \
	  echo "Root cause is probably that a dependancy declared in Kconfig is not respected" ; \
	  echo "or config was added in Kconfig but value not explicitly added to defconfig." ; \
	  echo "Recommanded method to generate defconfig is menuconfig tool instead of manual edit." ; \
	  exit 1;  fi;

menuconfig xconfig gconfig: $(CHECK_CONFIG_LOG)
	$(hide) xterm -e $(MAKE) $(KERNEL_MAKE_OPTIONS) $@
	$(hide) cp -f $(KERNEL_CONFIG) $(KERNEL_DEFCONFIG)
	@echo ===========
	@echo $(KERNEL_DEFCONFIG) has been modified !
	@echo ===========

$(KERNEL_CONFIG): $(KERNEL_CONFIG_DEPS) | yoctotoolchain $(CHECK_CONFIG_LOG)
	$(hide) echo "KERNEL_CONFIG_PREV_DEPS := $(KERNEL_CONFIG_DEPS)" > $(KERNEL_CONFIG_MK)
	$(hide) cat $(KERNEL_CONFIG_DEPS) > $@
	@echo "Generating Kernel configuration, using $(KERNEL_CONFIG_DEPS)"
	$(hide) $(MAKE) $(KERNEL_MAKE_OPTIONS) olddefconfig </dev/null

$(PRODUCT_OUT)/kernel: $(LOCAL_KERNEL) $(LOCAL_KERNEL_PATH)/copy_modules
	$(hide) cp $(LOCAL_KERNEL) $@

# kernel modules must be copied before vendorimage is generated
$(PRODUCT_OUT)/vendor.img: $(LOCAL_KERNEL_PATH)/copy_modules

# Copy modules in directory pointed by $(KERNEL_MODULES_ROOT)
# First copy modules keeping directory hierarchy lib/modules/`uname-r`for libkmod
# Second, create flat hierarchy for insmod linking to previous hierarchy
$(LOCAL_KERNEL_PATH)/copy_modules: $(LOCAL_KERNEL)
	@echo Copy modules from $(LOCAL_KERNEL_PATH)/lib/modules/$(KERNELRELEASE) into $(PRODUCT_OUT)/$(KERNEL_MODULES_ROOT)
	$(hide) rm -rf $(PRODUCT_OUT)/$(KERNEL_MODULES_ROOT)
	$(hide) rm -rf $(TARGET_RECOVERY_ROOT_OUT)/$(KERNEL_MODULES_ROOT)
	$(hide) mkdir -p $(PRODUCT_OUT)/$(KERNEL_MODULES_ROOT)
	$(hide) cd $(LOCAL_KERNEL_PATH)/lib/modules/$(KERNELRELEASE) && for f in `find . -name '*.ko' -or -name 'modules.*'`; do \
		cp $$f $(PWD)/$(PRODUCT_OUT)/$(KERNEL_MODULES_ROOT)/$$(basename $$f) || exit 1; \
		mkdir -p $(PWD)/$(PRODUCT_OUT)/$(KERNEL_MODULES_ROOT)/$(KERNELRELEASE)/$$(dirname $$f) ; \
		ln -s /$(KERNEL_MODULES_ROOT_PATH)/$$(basename $$f) $(PWD)/$(PRODUCT_OUT)/$(KERNEL_MODULES_ROOT)/$(KERNELRELEASE)/$$f || exit 1; \
		done
	$(hide) touch $@
#usb-init for recovery
	$(hide) mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/$(KERNEL_MODULES_ROOT)
	$(hide) for f in dwc3.ko dwc3-pci.ko xhci-hcd.ko xhci-pci.ko; do \
		find $(LOCAL_KERNEL_PATH)/lib/modules/ -name $$f -exec cp {} $(TARGET_RECOVERY_ROOT_OUT)/$(KERNEL_MODULES_ROOT)/ \; ;\
		done
#mei for recovery
	$(hide) for f in mei.ko mei-me.ko; do \
		find $(LOCAL_KERNEL_PATH)/lib/modules/ -name $$f -exec cp {} $(TARGET_RECOVERY_ROOT_OUT)/$(KERNEL_MODULES_ROOT)/ \; ;\
		done

ifeq ($(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_SUPPORTS_VERITY), true)
DM_VERITY_CERT := $(LOCAL_KERNEL_PATH)/verity.x509
$(DM_VERITY_CERT): $(PRODUCTS.$(INTERNAL_PRODUCT).PRODUCT_VERITY_SIGNING_KEY).x509.pem $(OPENSSL)
	$(transform-pem-cert-to-der-cert)
$(LOCAL_KERNEL): $(DM_VERITY_CERT)
endif

$(LOCAL_KERNEL): $(MINIGZIP) $(KERNEL_CONFIG) $(BOARD_DTB) $(KERNEL_DEPS) | yoctotoolchain
	$(MAKE) $(KERNEL_MAKE_OPTIONS)
	$(MAKE) $(KERNEL_MAKE_OPTIONS) modules
	$(MAKE) $(KERNEL_MAKE_OPTIONS) INSTALL_MOD_STRIP=1 modules_install


# disable the modules built in parallel due to some modules symbols has dependency,
# and module install depmod need they be installed one at a time.

PREVIOUS_KERNEL_MODULE := $(LOCAL_KERNEL)

define bld_external_module

$(eval MODULE_DEPS_$(2) := $(shell find kernel/modules/$(1) \( -name *.git -prune \) -o -print ))

$(LOCAL_KERNEL_PATH)/build_$(2): $(LOCAL_KERNEL) $(MODULE_DEPS_$(2)) $(PREVIOUS_KERNEL_MODULE)
	@echo BUILDING $(1)
	@mkdir -p $(LOCAL_KERNEL_PATH)/../modules/$(1)
	$(hide) $(MAKE) $$(KERNEL_MAKE_OPTIONS) M=$(EXTMOD_SRC)/$(1) V=1 $(ADDITIONAL_ARGS_$(subst /,_,$(1))) modules
	@touch $$(@)

$(LOCAL_KERNEL_PATH)/install_$(2): $(LOCAL_KERNEL_PATH)/build_$(2) $(PREVIOUS_KERNEL_MODULE)
	@echo INSTALLING $(1)
	$(hide) $(MAKE) $$(KERNEL_MAKE_OPTIONS) M=$(EXTMOD_SRC)/$(1) INSTALL_MOD_STRIP=1 modules_install
	@touch $$(@)

$(LOCAL_KERNEL_PATH)/copy_modules: $(LOCAL_KERNEL_PATH)/install_$(2)

$(eval PREVIOUS_KERNEL_MODULE := $(LOCAL_KERNEL_PATH)/install_$(2))
endef


# Check external module path
$(foreach m,$(EXTERNAL_MODULES),$(if $(findstring .., $(m)), $(error $(m): All external kernel modules should be put under kernel/modules folder)))

$(foreach m,$(EXTERNAL_MODULES),$(eval $(call bld_external_module,$(m),$(subst /,_,$(m)))))



# Add a kernel target, so "make kernel" will build the kernel
.PHONY: kernel
kernel: $(LOCAL_KERNEL_PATH)/copy_modules $(PRODUCT_OUT)/kernel


endif
##############################################################
# Source: device/intel/project-celadon/mixins/groups/sepolicy/permissive/AndroidBoard.mk
##############################################################
include $(CLEAR_VARS)
LOCAL_MODULE := sepolicy-areq-checker
LOCAL_REQUIRED_MODULES := sepolicy

#
# On user builds, enforce that open tickets are considered violations.
#
ifeq ($(TARGET_BUILD_VARIANT),user)
LOCAL_USER_OPTIONS := -i
endif

LOCAL_POST_INSTALL_CMD := $(INTEL_PATH_SEPOLICY)/tools/capchecker $(LOCAL_USER_OPTIONS) -p $(INTEL_PATH_SEPOLICY)/tools/caps.conf $(TARGET_ROOT_OUT)/sepolicy

include $(BUILD_PHONY_PACKAGE)
##############################################################
# Source: device/intel/project-celadon/mixins/groups/trusty/true/AndroidBoard.mk
##############################################################
.PHONY: lk evmm tosimage multiboot

LOCAL_MAKE := make

lk:
	@echo "making lk.elf.."
	$(hide) (cd $(TOPDIR)trusty && $(TRUSTY_ENV_VAR) $(LOCAL_MAKE) sand-x86-64)

evmm: yoctotoolchain
	@echo "making evmm.."
	$(hide) (cd $(TOPDIR)$(INTEL_PATH_VENDOR)/fw/evmm && $(TRUSTY_ENV_VAR) $(LOCAL_MAKE))

# include sub-makefile according to boot_arch
include $(TARGET_DEVICE_DIR)/extra_files/trusty/trusty_vsbl.mk

LOAD_MODULES_H_IN += $(TARGET_DEVICE_DIR)/extra_files/trusty/load_trusty_modules.in
##############################################################
# Source: device/intel/project-celadon/mixins/groups/vendor-partition/true/AndroidBoard.mk
##############################################################
include $(CLEAR_VARS)
LOCAL_MODULE := vendor-partition
LOCAL_REQUIRED_MODULES := toybox_static
include $(BUILD_PHONY_PACKAGE)

RECOVERY_VENDOR_LINK_PAIRS := \
	$(PRODUCT_OUT)/recovery/root/vendor/bin/getprop:toolbox_static \

RECOVERY_VENDOR_LINKS := \
	$(foreach item, $(RECOVERY_VENDOR_LINK_PAIRS), $(call word-colon, 1, $(item)))

$(RECOVERY_VENDOR_LINKS):
	$(hide) echo "Creating symbolic link on $(notdir $@)"
	$(eval PRV_TARGET := $(call word-colon, 2, $(filter $@:%, $(RECOVERY_VENDOR_LINK_PAIRS))))
	$(hide) mkdir -p $(dir $@)
	$(hide) mkdir -p $(dir $(dir $@)$(PRV_TARGET))
	$(hide) touch $(dir $@)$(PRV_TARGET)
	$(hide) ln -sf $(PRV_TARGET) $@

ALL_DEFAULT_INSTALLED_MODULES += $(RECOVERY_VENDOR_LINKS)
##############################################################
# Source: device/intel/project-celadon/mixins/groups/config-partition/true/AndroidBoard.mk
##############################################################
INSTALLED_CONFIGIMAGE_TARGET := $(PRODUCT_OUT)/config.img

selinux_fc := $(TARGET_ROOT_OUT)/file_contexts.bin

make_oem_config_dir:
	@mkdir -p $(PRODUCT_OUT)/root/mnt/vendor
	@mkdir -p $(PRODUCT_OUT)/root/mnt/vendor/oem_config
	@mkdir -p $(PRODUCT_OUT)/recovery/root/mnt/vendor
	@mkdir -p $(PRODUCT_OUT)/recovery/root/mnt/vendor/oem_config

$(INSTALLED_CONFIGIMAGE_TARGET) : PRIVATE_SELINUX_FC := $(selinux_fc)
$(INSTALLED_CONFIGIMAGE_TARGET) : $(MKEXTUSERIMG) $(MAKE_EXT4FS) $(E2FSCK) $(selinux_fc) bootimage make_oem_config_dir
	$(call pretty,"Target config fs image: $(INSTALLED_CONFIGIMAGE_TARGET)")
	@mkdir -p $(PRODUCT_OUT)/config
	$(hide)	PATH=$(HOST_OUT_EXECUTABLES):$$PATH \
		$(MKEXTUSERIMG) -s \
		$(PRODUCT_OUT)/config \
		$(PRODUCT_OUT)/config.img \
		ext4 \
		oem_config \
		$(BOARD_CONFIGIMAGE_PARTITION_SIZE) \
		$(PRIVATE_SELINUX_FC)

INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_CONFIGIMAGE_TARGET)

selinux_fc :=
##############################################################
# Source: device/intel/project-celadon/mixins/groups/graphics/mesa/AndroidBoard.mk
##############################################################
ifneq ($(TARGET_BOARD_PLATFORM),kabylake)
I915_FW_PATH := ./$(INTEL_PATH_VENDOR)/ufo/gen9_dev/x86_64_media/vendor/firmware/i915
else
I915_FW_PATH := ./$(INTEL_PATH_VENDOR)/ufo/gen9_dev/x86_64_media_kbl/vendor/firmware/i915
endif
#list of i915/huc_xxx.bin i915/dmc_xxx.bin i915/guc_xxx.bin
$(foreach t, $(patsubst $(I915_FW_PATH)/%,%,$(wildcard $(I915_FW_PATH)/*)) ,$(eval I915_FW += i915/$(t)))

_EXTRA_FW_ += $(I915_FW)

#kernel will find i915 firmware in out/target/.../vendor/firmware/
#so build ufo_prebuilts before kernel.
$(LOCAL_KERNEL) : ufo_prebuilts
##############################################################
# Source: device/intel/project-celadon/mixins/groups/ethernet/dhcp/AndroidBoard.mk
##############################################################
LOAD_MODULES_IN += $(TARGET_DEVICE_DIR)/extra_files/ethernet/load_eth_modules.in
##############################################################
# Source: device/intel/project-celadon/mixins/groups/usb-init/true/AndroidBoard.mk
##############################################################
LOAD_MODULES_IN += $(TARGET_DEVICE_DIR)/extra_files/usb-init/load_usb_modules.in
##############################################################
# Source: device/intel/project-celadon/mixins/groups/device-type/car/AndroidBoard.mk
##############################################################
# Car device required kernel diff config
KERNEL_CAR_DIFFCONFIG = $(wildcard $(KERNEL_CONFIG_PATH)/car_diffconfig)
KERNEL_DIFFCONFIG += $(KERNEL_CAR_DIFFCONFIG)
##############################################################
# Source: device/intel/project-celadon/mixins/groups/security/cse/AndroidBoard.mk
##############################################################
LOAD_MODULES_IN += $(TARGET_DEVICE_DIR)/extra_files/security/load_mei_modules.in
##############################################################
# Source: device/intel/project-celadon/mixins/groups/mediaserver-radio/true/AndroidBoard.mk
##############################################################
include $(CLEAR_VARS)
LOCAL_MODULE := mediaserver-radio
LOCAL_REQUIRED_MODULES := audioserver
LOCAL_POST_INSTALL_CMD := $(hide) sed -i 's/group audio [radio ]*/group audio radio /g' $(TARGET_OUT_ETC)/init/audioserver.rc
include $(BUILD_PHONY_PACKAGE)
##############################################################
# Source: device/intel/project-celadon/mixins/groups/audio/gordon_peak_acrn/AndroidBoard.mk
##############################################################
USE_CUSTOM_PARAMETER_FRAMEWORK=true
##############################################################
# Source: device/intel/project-celadon/mixins/groups/acrn-guest/true/AndroidBoard.mk.1
##############################################################
######################################################################
# ACRN GPT Image Generation
######################################################################

gptimage_size ?= 9840M

ACRN_DATA_DIR = $(PRODUCT_OUT)/data_partition
ACRN_AND_DIR = $(ACRN_DATA_DIR)/android
ACRN_GUEST_DIR = $(PRODUCT_OUT)/acrn_guest
ACRN_GUEST_IMAGES_DIR = $(PRODUCT_OUT)/acrn_guest/IMAGES
ACRN_GPT_BIN = $(ACRN_AND_DIR)/android.img
ACRN_DATA_SIZE ?= 10320M
MAKE_EXT4FS_ACRN = $(TARGET_DEVICE_DIR)/make_ext4fs

raw_config := none
raw_factory := none
tos_bin := none
raw_product := none
raw_odm := none
raw_acpi := none
raw_acpio := none

.PHONY: none
none: ;

.PHONY: $(INSTALLED_CONFIGIMAGE_TARGET).raw
$(INSTALLED_CONFIGIMAGE_TARGET).raw: $(INSTALLED_CONFIGIMAGE_TARGET) $(SIMG2IMG)
	$(SIMG2IMG) $< $@

.PHONY: $(INSTALLED_FACTORYIMAGE_TARGET).raw
$(INSTALLED_FACTORYIMAGE_TARGET).raw: $(INSTALLED_FACTORYIMAGE_TARGET) $(SIMG2IMG)
	$(SIMG2IMG) $< $@

ifdef INSTALLED_CONFIGIMAGE_TARGET
raw_config := $(INSTALLED_CONFIGIMAGE_TARGET).raw
endif

ifdef INSTALLED_FACTORYIMAGE_TARGET
raw_factory := $(INSTALLED_FACTORYIMAGE_TARGET).raw
endif

ifdef INSTALLED_PRODUCTIMAGE_TARGET
raw_product := $(INSTALLED_PRODUCTIMAGE_TARGET).raw
endif

.PHONY: $(ACRN_GPTIMAGE_BIN)
ifeq ($(strip $(TARGET_USE_TRUSTY)),true)
tos_bin = $(ACRN_GUEST_IMAGES_DIR)/tos.img
endif




$(ACRN_GPTIMAGE_BIN): \
	target-files-package \
	$(SIMG2IMG) \
	$(raw_config) \
	$(raw_factory)

	rm -rf $(ACRN_GUEST_DIR)
	mkdir $(ACRN_GUEST_DIR)
	unzip $(BUILT_TARGET_FILES_PACKAGE) IMAGES/* -d $(ACRN_GUEST_DIR)
	$(hide) rm -f $(ACRN_GUEST_IMAGES_DIR)/system.img.raw
	$(hide) rm -f $(INSTALLED_USERDATAIMAGE_TARGET).raw

	$(SIMG2IMG) $(ACRN_GUEST_IMAGES_DIR)/system.img $(ACRN_GUEST_IMAGES_DIR)/system.img.raw
	$(SIMG2IMG) $(ACRN_GUEST_IMAGES_DIR)/vendor.img $(ACRN_GUEST_IMAGES_DIR)/vendor.img.raw

	$(INTEL_PATH_BUILD)/create_gpt_image.py \
		--create $@ \
		--block $(BOARD_FLASH_BLOCK_SIZE) \
		--table $(BOARD_GPT_INI) \
		--size $(gptimage_size) \
		--bootloader $(bootloader_bin) \
		--bootloader2 $(bootloader_bin) \
		--tos $(tos_bin) \
		--boot $(ACRN_GUEST_IMAGES_DIR)/boot.img \
		--vbmeta $(ACRN_GUEST_IMAGES_DIR)/vbmeta.img \
		--system $(ACRN_GUEST_IMAGES_DIR)/system.img.raw \
		--vendor $(ACRN_GUEST_IMAGES_DIR)/vendor.img.raw \
		--config $(raw_config) \
		--factory $(raw_factory)
##############################################################
# Source: device/intel/project-celadon/mixins/groups/acrn-guest/true/AndroidBoard.mk
##############################################################
######################################################################
# Define Specific Kernel Config for ACRN
######################################################################

KERNEL_ACRN_GUEST_DIFFCONFIG = $(wildcard $(KERNEL_CONFIG_PATH)/acrn_guest_diffconfig)
KERNEL_DIFFCONFIG += $(KERNEL_ACRN_GUEST_DIFFCONFIG)

######################################################################
# Acrn Flashfiles Contains Below Image Files
######################################################################
ACRN_IFWI_FW := ifwi.bin
ACRN_IFWI_DNX := ifwi_dnx.bin
ACRN_IFWI_DNXP := dnxp_0x1.bin
ACRN_IFWI_FV := capsule.fv
ACRN_FW_VERSION := fwversion.txt
ACRN_IOC_FW_D := ioc_firmware_gp_mrb_fab_d.ias_ioc
ACRN_IOC_FW_E := ioc_firmware_gp_mrb_fab_e.ias_ioc
ACRN_SOS_BOOT_IMAGE := sos_boot.img
ACRN_SOS_ROOTFS_IMAGE := sos_rootfs.img
ACRN_PARTITION_DESC_BIN := partition_desc.bin
ACRN_MD5SUM_MD5 = md5sum.txt

######################################################################
# Define The Script Path and ACRN Related Files
######################################################################
ACRN_TMP_DIR := $(PRODUCT_OUT)/acrn_fls
ACRN_GETLINK_SCRIPT := $(TARGET_DEVICE_DIR)/extra_files/acrn-guest/getlink.py
ACRN_VERSION_CONFIG := $(TARGET_DEVICE_DIR)/extra_files/acrn-guest/acrnversion.cfg
LOCAL_SOS_PATH = $(TARGET_DEVICE_DIR)/acrn_sos
ACRN_EXT4_BIN = $(PRODUCT_OUT)/$(TARGET_PRODUCT)_AaaG.img
ACRN_EXT4_BIN_ZIP = $(PRODUCT_OUT)/$(TARGET_PRODUCT)_AaaG.zip
PUBLISH_DEST := $(TOP)/pub/$(TARGET_PRODUCT)/$(TARGET_BUILD_VARIANT)
GUEST_FLASHFILES = $(PRODUCT_OUT)/$(TARGET_PRODUCT)-guest-flashfiles*.zip
ifneq ($(findstring eng,$(BUILD_NUMBER)),)
ACRN_FLASHFILES = $(PRODUCT_OUT)/$(TARGET_PRODUCT)-flashfiles-$(FILE_NAME_TAG).zip
else
ACRN_FLASHFILES = $(PRODUCT_OUT)/$(TARGET_PRODUCT)-flashfiles-$(BUILD_NUMBER).zip
endif

######################################################################
# Get SOS Link and Version By getlink.py
######################################################################
SOS_LINK_CFG := $(shell sed -n '{/^#/!p}' $(ACRN_VERSION_CONFIG) | grep 'SOS_LINK' | sed 's/^.*=//g' | sed 's/ //g')
SOS_VERSION_CFG := $(shell sed -n '{/^#/!p}' $(ACRN_VERSION_CONFIG) | grep 'SOS_VERSION' | sed 's/^.*=//g' | sed 's/ //g')

ifeq ($(strip $(SOS_VERSION)),)
    SOS_VERSION = ""
    ifeq ($(strip $(SOS_VERSION_CFG)), 'latest')
        ACRN_LINK := $(word 2,$(strip $(shell python $(ACRN_GETLINK_SCRIPT) $(ACRN_VERSION_CONFIG) $(SOS_VERSION))))
    else
        ACRN_LINK := $(SOS_LINK_CFG)/$(SOS_VERSION_CFG)/gordonpeak/virtualization
    endif
else
    SOS_VERSION_CFG := $(SOS_VERSION)
    ACRN_LINK := $(word 2,$(strip $(shell python $(ACRN_GETLINK_SCRIPT) $(ACRN_VERSION_CONFIG) $(SOS_VERSION))))
endif

######################################################################
# Download files from the link to point dir, $2 was the link, $1 was
# the download file, $3 was the dir
######################################################################
ARIA2C := aria2c

define load-image
	retry=1; while [ $$retry -le 5 ]; \
	do \
	echo "Begin $$retry time download $2/$1"; \
	retry=`expr $$retry + 1`; \
	$(ARIA2C) -c -s 10 -x 10 -t 600 $2/$1 -d $3 || continue; \
	echo "Download $1 successful" && exit 0; \
	done; \
	echo "Download $1 FAILED, please check your network!"; \
	$(if $(findstring $1, $(ACRN_MD5SUM_MD5)), echo "Warning: Check SoS Release!", \
	echo "Error: Mandatory Images failed!" && exit 1)
endef

define load-fw
	echo "Begin to load firmware...";
endef

######################################################################
# Generate ACRN AaaG Extra4 Image
######################################################################
.PHONY: acrn_ext4_bin
acrn_ext4_bin: $(ACRN_GPTIMAGE_BIN) $(IMG2SIMG) mkuserimg_mke2fs.sh
	$(hide) mkdir -p $(ACRN_DATA_DIR)
	$(hide) mkdir -p $(ACRN_AND_DIR)
	$(hide) rm -f $(ACRN_GPT_BIN)
	$(hide) cp $(ACRN_GPTIMAGE_BIN) $(ACRN_GPT_BIN)
	$(hide) echo "Try making $@"
	mkuserimg_mke2fs.sh -s $(ACRN_DATA_DIR) $(ACRN_EXT4_BIN) ext4 dummy $(ACRN_DATA_SIZE)
	echo ">>> $@ is generated successfully"

######################################################################
# Download Extra ACRN Images
######################################################################
.PHONY: img_download
ifeq ($(strip $(SOS_VERSION)),local)
img_download:
	$(hide) rm -rf $(ACRN_TMP_DIR)
	$(hide) mkdir -p $(ACRN_TMP_DIR)
	$(call load-fw)
	echo -e "**********************************" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e "* SoS_Version: Local Images" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e "**********************************" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e ">>> Path: $(LOCAL_SOS_PATH)" >> $(ACRN_TMP_DIR)/acrnversion.txt
	@$(ACP) $(LOCAL_SOS_PATH)/* $(ACRN_TMP_DIR)
	$(hide) cp $(ACRN_TMP_DIR)/acrnversion.txt $(PRODUCT_OUT)/
	echo ">>> $@ is successful !!!"
else
img_download:
	$(hide) rm -rf $(ACRN_TMP_DIR)
	$(hide) mkdir -p $(ACRN_TMP_DIR)
	$(call load-fw)
	echo "Start to download SoS files from: $(ACRN_LINK) ..."
	$(call load-image,$(ACRN_MD5SUM_MD5),$(ACRN_LINK),$(ACRN_TMP_DIR))
	$(call load-image,$(ACRN_PARTITION_DESC_BIN),$(ACRN_LINK),$(ACRN_TMP_DIR))
	$(call load-image,$(ACRN_SOS_BOOT_IMAGE),$(ACRN_LINK),$(ACRN_TMP_DIR))
	$(call load-image,$(ACRN_SOS_ROOTFS_IMAGE),$(ACRN_LINK),$(ACRN_TMP_DIR))
	echo -e "**********************************" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e "* SoS_Version: $(SOS_VERSION_CFG) " >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e "**********************************" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e ">>> Download SOS files:" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e "    - $(ACRN_SOS_BOOT_IMAGE)" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e "    - $(ACRN_SOS_ROOTFS_IMAGE)" >> $(ACRN_TMP_DIR)/acrnversion.txt
	echo -e "    - $(ACRN_PARTITION_DESC_BIN)" >> $(ACRN_TMP_DIR)/acrnversion.txt
	$(hide) cp $(ACRN_TMP_DIR)/acrnversion.txt $(PRODUCT_OUT)/
	echo ">>> $@ is successfull !!!"
endif

######################################################################
# Generate ACRN AaaG *.zip
######################################################################
.PHONY: acrn_image
acrn_image: acrn_ext4_bin
	$(hide) mkdir -p $(PUBLISH_DEST)
	$(hide) zip -qjX $(ACRN_EXT4_BIN_ZIP) $(ACRN_EXT4_BIN)
	@$(ACP) $(ACRN_EXT4_BIN_ZIP) $(PUBLISH_DEST)
	echo ">>> $@ is generated successfully!"

######################################################################
# Generate ACRN E2E flashfiles *.zip
######################################################################
.PHONY: acrn_flashfiles
acrn_flashfiles: acrn_ext4_bin flashfiles img_download publish_otapackage publish_ota_targetfiles
	$(hide) cp $(ACRN_EXT4_BIN) $(ACRN_TMP_DIR)
	$(hide) cp $(TARGET_DEVICE_DIR)/flash_AaaG.json $(ACRN_TMP_DIR)
	$(hide) mkdir -p $(PUBLISH_DEST)
	$(TARGET_DEVICE_DIR)/extra_files/acrn-guest/md5_check.sh $(ACRN_TMP_DIR)
	$(hide) zip -qrjX $(ACRN_FLASHFILES) $(ACRN_TMP_DIR)
	@$(ACP) $(ACRN_FLASHFILES) $(PUBLISH_DEST)
	$(hide) rm -rf $(ACRN_TMP_DIR)
	echo ">>> $@ is generated successfully"
##############################################################
# Source: device/intel/project-celadon/mixins/groups/load_modules/true/AndroidBoard.mk
##############################################################
include $(CLEAR_VARS)
LOCAL_MODULE := load_modules.sh
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_OWNER := intel
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SRC := $(LOAD_MODULES_H_IN) $(LOAD_MODULES_IN)
include $(BUILD_SYSTEM)/base_rules.mk
$(LOCAL_BUILT_MODULE): $(LOCAL_SRC)
	$(hide) mkdir -p "$(dir $@)"
	echo "#!/system/bin/sh" > $@
	echo "modules=\`getprop ro.vendor.boot.moduleslocation\`" >> $@
	cat $(LOAD_MODULES_H_IN) >> $@
	echo wait >> $@
	cat $(LOAD_MODULES_IN) >> $@
##############################################################
# Source: device/intel/project-celadon/mixins/groups/mixin-check/true/AndroidBoard.mk
##############################################################
mixin_update := $(wildcard device/intel/mixins/mixin-update)

ifeq ($(mixin_update),)
mixin_update := $(wildcard $(TARGET_DEVICE_DIR)/mixins/mixin-update)
endif

ifneq ($(mixin_update),)

.PHONY: check-mixins
check-mixins:
	$(mixin_update) --dry-run -s $(TARGET_DEVICE_DIR)/mixins.spec

droidcore: check-mixins
flashfiles: check-mixins

endif

##############################################################
# Source: device/intel/project-celadon/mixins/groups/vndk/default/AndroidBoard.mk
##############################################################
define define-vndk-sp-lib
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,,)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := first
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk-sp
include $$(BUILD_PREBUILT)

ifneq ($$(TARGET_2ND_ARCH),)
ifneq ($$(TARGET_TRANSLATE_2ND_ARCH),true)
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,$$(TARGET_2ND_ARCH_VAR_PREFIX),)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := 32
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk-sp
include $$(BUILD_PREBUILT)
endif # TARGET_TRANSLATE_2ND_ARCH is not true
endif # TARGET_2ND_ARCH is not empty
endef

define define-vndk-lib
ifeq ($$(filter libstagefright_soft_%,$1),)
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,,)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := first
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk
include $$(BUILD_PREBUILT)
endif

ifneq ($$(TARGET_2ND_ARCH),)
ifneq ($$(TARGET_TRANSLATE_2ND_ARCH),true)
include $$(CLEAR_VARS)
LOCAL_MODULE := $1.vendor
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_PREBUILT_MODULE_FILE := $$(call intermediates-dir-for,SHARED_LIBRARIES,$1,,,$$(TARGET_2ND_ARCH_VAR_PREFIX),)/$1.so
LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := 32
LOCAL_MODULE_TAGS := optional
LOCAL_INSTALLED_MODULE_STEM := $1.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := vndk
include $$(BUILD_PREBUILT)
endif # TARGET_TRANSLATE_2ND_ARCH is not true
endif # TARGET_2ND_ARCH is not empty
endef

$(foreach lib,$(VNDK_SAMEPROCESS_LIBRARIES),\
    $(eval $(call define-vndk-sp-lib,$(lib))))

$(foreach lib,$(VNDK_CORE_LIBRARIES),\
    $(eval $(call define-vndk-lib,$(lib))))

# ------------------ END MIX-IN DEFINITIONS ------------------
