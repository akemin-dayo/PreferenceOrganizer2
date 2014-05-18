THEOS_PACKAGE_DIR_NAME = debs
TARGET =: clang
ARCHS = armv7 armv7s arm64
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PreferenceOrganizer2
PreferenceOrganizer2_FILES = PreferenceOrganizer2.xm
PreferenceOrganizer2_FRAMEWORKS = UIKit Foundation
PreferenceOrganizer2_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += POPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk