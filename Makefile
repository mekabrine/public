ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard Preferences
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SiriPlus
SiriPlus_FILES = SiriPlus/Settings.swift SiriPlus/LLM.swift SiriPlus/Web.swift SiriPlus/Actions.swift SiriPlus/Conversation.swift SiriPlus/Tweak.swift SiriPlus/SiriInterceptBridge.swift SiriPlus/SiriHooks.x
SiriPlus_SWIFTFLAGS = -module-name SiriPlus
SiriPlus_FRAMEWORKS = Foundation UIKit
SiriPlus_LIBRARIES = substrate
SiriPlus_CFLAGS = -fobjc-arc

BUNDLE_NAME = SiriPlusCC
SiriPlusCC_FILES = SiriPlusCC/SiriPlusCC.m
SiriPlusCC_INSTALL_PATH = /Library/ControlCenter/Bundles
SiriPlusCC_PRIVATE_FRAMEWORKS = ControlCenterUIKit
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
