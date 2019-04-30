TARGET =: clang
ARCHS = armv7 armv7s arm64e
DEBUG = 0
GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = POPreferences
POPreferences_FILES = POPreferences.mm 
POPreferences_INSTALL_PATH = /Library/PreferenceBundles
POPreferences_LIBRARIES = karenprefs karenlocalizer
POPreferences_FRAMEWORKS = UIKit
POPreferences_CFLAGS = -fobjc-arc
POPreferences_PRIVATE_FRAMEWORKS = Preferences
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PreferenceOrganizer2.plist$(ECHO_END)
