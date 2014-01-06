TWEAK_NAME = PreferenceOrganizer
PreferenceOrganizer_FILES = Tweak.xm
PreferenceOrganizer_PRIVATE_FRAMEWORKS = UIKit Preferences

TARGET := iphone:7.0:5.0
ARCHS := armv7 arm64

# NOTE: The following is needed until logos is updated to not generate
#       unnecessary 'ungrouped' objects.
export GO_EASY_ON_ME = 1

include theos/makefiles/common.mk
include theos/makefiles/tweak.mk

sync: stage
	rsync -z _/Library/MobileSubstrate/DynamicLibraries/* root@iphone:/Library/MobileSubstrate/DynamicLibraries/
	ssh root@iphone killall SpringBoard

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(APP_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*
