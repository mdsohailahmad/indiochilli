#==========================================================================================================================# 
# INDIO NETWORKS PRIVATE LIMITED CONFIDENTIAL
# 
# Copyrights (C) Indio Networks Pvt. Ltd. All Rights Reserved.
# 
# NOTICE:  All information contained herein is, and remains the property of Wifi-soft Solutions Pvt. Ltd. and its suppliers,
# if any.  The intellectual and technical concepts contained herein are proprietary to Wifi-soft Solutions Pvt. Ltd.
# and its suppliers and may be covered by U.S. and international Patents, patents in process, and are protected by 
# trade secret or copyright law.Dissemination of this information or reproduction of this material is strictly forbidden 
# unless prior written permission is obtained from Wifi-soft Solutions Pvt. Ltd.
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY 
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#
# Project: Coova Chilli Based NAS For OpenWRT APs
#
#=========================================================================================================================#
# ------------------------------------------------------------------------------- #
# title         : indiochilli package makefile
# author        : Sohail Ahmad <sohail@indionetworks.com>
# ------------------------------------------------------------------------------- #

include $(TOPDIR)/rules.mk

PKG_NAME:=indiochilli
PKG_RELEASE:=1
PKG_VERSION:=0

COOVA_GIT_BRANCH:=5145be9968809b043ec6bf0bf7a17d84dfeade50

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL:=1
DISABLE_NLS:=

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/indiochilli
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Network hotspot controller (Indio Coova Chilli)
	#DEPENDS:=+libpthread +librt +mxml +libcurl +libopenssl +libjson-c +libexpat
	DEPENDS:=+libpthread +librt  +libcurl +libopenssl +libjson-c 
	URL:=http://www.indionetworks.com/
	MENU:=1
endef

define Package/indiochilli/config
	select PACKAGE_bash
	select PACKAGE_bridge
	select PACKAGE_firewall
	select PACKAGE_kmod-nf-nathelper

	select PACKAGE_iptables

	select PACKAGE_kmod-tun


	#select CLEAN_IPKG
	select USE_STRIP
	select STRIP_KERNEL_EXPORTS
	select USE_MKLIBS

	menu "IndioChilli Configuration"
		depends on PACKAGE_indiochilli
		config INDIOCHILLI_KERNEL_MODE
			default n
			bool "Enable Kernel Mode"
			select PACKAGE_ipset
			select PACKAGE_kmod-ipt-coova-wsft
			select PACKAGE_iptables-mod-ipmark
			select PACKAGE_kmod-bridge
			select PACKAGE_dnsmasq-full
			select PACKAGE_dnsmasq_full_ipset
			select PACKAGE_ebtables
			select PACKAGE_kmod-ebtables-ipv4
			select PACKAGE_iptables-mod-extra
			select PACKAGE_iptables-mod-physdev
			select PACKAGE_kmod-nft-bridge
	endmenu
endef

define KernelPackage/ipt-coova-indio
	URL:=http://www.coova.org/CoovaChilli
	SUBMENU:=Netfilter Extensions
	DEPENDS:=+kmod-ipt-core +libxtables
	TITLE:=Coova netfilter module
	FILES:=$(PKG_BUILD_DIR)/coova-chilli/src/linux/xt_*.$(LINUX_KMOD_SUFFIX)
	AUTOLOAD:=$(call AutoProbe,xt_coova)
endef

define Build/Prepare/IndioChilli
	$(eval $(call Download,coova))
	gzip -dc $(DL_DIR)/$(FILE) | tar -C $(PKG_BUILD_DIR) $(TAR_OPTIONS)
	( cd $(PKG_BUILD_DIR)/coova-chilli; \
		./bootstrap; \
		./configure; \
	)
endef

define Build/Prepare
	$(call Build/Prepare/IndioChilli)
	( if [[ "$(CONFIG_USE_MUSL)" == y ]]; then \
		cp $(PKG_BUILD_DIR)/coova-chilli/src/system.h.musl $(PKG_BUILD_DIR)/coova-chilli/src/system.h; \
	fi )
endef

TARGET_CFLAGS += $(FPIC)

CONFIGURE_VARS += \
       ARCH="$(LINUX_KARCH)" \
       KERNEL_DIR="$(LINUX_DIR)"

MAKE_FLAGS += \
       ARCH="$(LINUX_KARCH)" \
       KERNEL_DIR="$(LINUX_DIR)"

MAKE_INSTALL_FLAGS += \
       ARCH="$(LINUX_KARCH)" \
       KERNEL_DIR="$(LINUX_DIR)" \
       INSTALL_MOD_PATH="$(PKG_INSTALL_DIR)"

MAKE_PATH:=coova-chilli
CONFIGURE_PATH:=coova-chilli
CURL_FLAGS:=$(shell $(STAGING_DIR)/host/bin/curl-config --libs --cflags)

define Build/Configure
	$(call Build/Configure/Default, --enable-chilliredir --with-nfcoova --with-openssl --disable-tap --disable-radproxy --enable-binstatusfile --enable-layer3 --enable-json)
endef

define Build/Compile
	$(call Build/Compile/Default)
endef

define Build/Install
	$(call Build/Install/Default)
	rm -rf $(PKG_INSTALL_DIR)/etc/chilli/www
endef

define Download/coova
	VERSION:=$(COOVA_GIT_BRANCH)
	SUBDIR:=coova-chilli
	FILE:=coova-chilli-$$(VERSION).tar.gz
	#URL:=ssh://git@projects.wifi-soft.com/diffusion/4/coova-chilli.git
	#URL:=ssh://git@projects.wifi-soft.com/source/coova-chilli.git
	URL:=https://github.com/mdsohailahmad/coova-chilli-owf.git
	PROTO:=git
endef

define Package/indiochilli/conffiles
/etc/chilli/defaults
endef

define Package/indiochilli/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) files/chilli/init $(1)/etc/init.d/chilli
	$(CP) files/chilli/firewall $(1)/etc/chilli_firewall.sh
	$(INSTALL_CONF) $(PKG_INSTALL_DIR)/etc/chilli.conf $(1)/etc/

	$(INSTALL_DIR) $(1)/etc/chilli
	$(CP) $(PKG_INSTALL_DIR)/etc/chilli/* $(1)/etc/chilli/

	ln -sf /var/run/chilli/config $(1)/etc/chilli/config
	ln -sf /var/run/chilli/main.conf $(1)/etc/chilli/main.conf
	ln -sf /var/run/chilli/hs.conf $(1)/etc/chilli/hs.conf
	ln -sf /var/run/chilli/local.conf $(1)/etc/chilli/local.conf

	$(INSTALL_DATA) files/chilli/ca.crt $(1)/etc/chilli/
	$(INSTALL_DATA) files/chilli/indiochilli.crt $(1)/etc/chilli/
	$(INSTALL_DATA) files/chilli/ssl.key $(1)/etc/chilli/

	$(INSTALL_DIR) $(1)/etc/chilli/www
	$(INSTALL_DATA) files/chilli/login.chi $(1)/etc/chilli/www/
	$(INSTALL_DATA) files/chilli/templogin.chi $(1)/etc/chilli/www/
	$(INSTALL_DATA) files/chilli/ajax-loading.gif $(1)/etc/chilli/www/
	$(INSTALL_DATA) files/chilli/jquery-1.10.1.min.js $(1)/etc/chilli/www/
	$(INSTALL_BIN) files/chilli/conup $(1)/etc/chilli/conup.sh
	$(INSTALL_BIN) files/chilli/condown $(1)/etc/chilli/condown.sh

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) files/chilli/hotplug $(1)/etc/hotplug.d/iface/16-chilli
	$(INSTALL_BIN) files/chilli/tc.hotplug $(1)/etc/hotplug.d/iface/15-tc

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) files/chilli/indiochilli.config $(1)/etc/config/indiochilli

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/chilli* $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/lib*.so.* $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/iptables
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/iptables/lib*.so $(1)/usr/lib/iptables/
endef

$(eval $(call BuildPackage,indiochilli))
$(eval $(call KernelPackage,ipt-coova-indio))
