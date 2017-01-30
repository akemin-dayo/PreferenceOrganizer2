TARGET =: clang
ARCHS = armv7 armv7s arm64
DEBUG = 0
GO_EASY_ON_ME = 1

THEOS_PACKAGE_DIR_NAME = debs
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PreferenceOrganizer2
PreferenceOrganizer2_FILES = PreferenceOrganizer2.xm PO2Log.mm
PreferenceOrganizer2_LIBRARIES = karenlocalizer
PreferenceOrganizer2_FRAMEWORKS = UIKit Foundation
PreferenceOrganizer2_PRIVATE_FRAMEWORKS = Preferences
PreferenceOrganizer2_CFLAGS += -DVERBOSE

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += POPreferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall Preferences; exit 0"

sync: stage
	rsync -e "ssh -p 2222" -avz .theos/_/Library/MobileSubstrate/DynamicLibraries/* root@127.0.0.1:/Library/MobileSubstrate/DynamicLibraries/
	ssh root@127.0.0.1 -p 2222 killall Preferences
