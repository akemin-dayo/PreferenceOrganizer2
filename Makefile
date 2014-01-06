TWEAK_NAME = ShowCase
ShowCase_OBJCC_FILES = Tweak.xm
ShowCase_CFLAGS = -F$(SYSROOT)/System/Library/CoreServices

TARGET := iphone:7.0:3.0
ARCHS := armv6 arm64

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
