THEOS_PACKAGE_DIR_NAME = debs
TARGET =: clang
ARCHS = armv7 armv7s arm64
DEBUG = 0
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PreferenceOrganizer2
PreferenceOrganizer2_FILES = PreferenceOrganizer2.xm
PreferenceOrganizer2_FRAMEWORKS = UIKit Foundation
PreferenceOrganizer2_PRIVATE_FRAMEWORKS = Preferences
PreferenceOrganizer2_CFLAGS += -DVERBOSE

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += POPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/KarenLocalize$(ECHO_END)
	$(ECHO_NOTHING)cp -r KarenLocalize/PreferenceOrganizer2.bundle $(THEOS_STAGING_DIR)/Library/KarenLocalize/$(ECHO_END)