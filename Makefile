export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0
export THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard Preferences
PACKAGE_VERSION = 1.4

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SiriPlus
SiriPlus_FILES = SiriPlus/Settings.swift SiriPlus/LLM.swift SiriPlus/Web.swift SiriPlus/Actions.swift SiriPlus/Conversation.swift SiriPlus/Tweak.swift SiriPlus/SiriInterceptBridge.swift SiriPlus/SiriHooks.x
SiriPlus_SWIFTFLAGS = -module-name SiriPlus
SiriPlus_FRAMEWORKS = Foundation UIKit Contacts EventKit
SiriPlus_LIBRARIES = substrate
SiriPlus_CFLAGS = -fobjc-arc
SiriPlus_LOGOS_DEFAULT_GENERATOR = MobileSubstrate

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = SiriPlusCC
SiriPlusCC_FILES = SiriPlusCC/SiriPlusCC.m
SiriPlusCC_INSTALL_PATH = /Library/ControlCenter/Bundles
SiriPlusCC_PRIVATE_FRAMEWORKS = ControlCenterUIKit
SiriPlusCC_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/bundle.mk
