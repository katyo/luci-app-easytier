#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_VERSION:=2.2.4
PKG_RELEASE:=4

LUCI_TITLE:=LuCI support for EasyTier
LUCI_DEPENDS:=+kmod-tun
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-easytier

define Package/$(PKG_NAME)/conffiles
/etc/easytier/
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh

if [ -f /etc/config/easytier ]; then
    echo "Backing up easytier configuration file /etc/config/easytier to /tmp/easytier_backup"
    echo "Configuration will not be lost if luci-app-easytier is reinstalled without rebooting, no need to reconfigure"
    mv -f /etc/config/easytier /tmp/easytier_backup
fi

if [ -f /etc/easytier/config.toml ]; then
    echo "Backing up easytier configuration file /etc/easytier/config.toml to /tmp/et_config_backup.toml"
    echo "Configuration will not be lost if luci-app-easytier is reinstalled without rebooting, no need to reconfigure"
    mv -f /etc/easytier/config.toml /tmp/et_config_backup.toml
fi

DB_PATH=$(uci -q get easytier.@easytierweb[0].db_path)
if [ -n "$DB_PATH" ] && [ -f "$DB_PATH" ]; then
    echo "Database $DB_PATH has been backed up to /tmp/et_backup.db"
    mv -f "$DB_PATH" /tmp/et_backup.db
else
    echo "Database file not found, skipping backup!"
fi

if [ -f /etc/easytier/et_machine_id ]; then
    echo "Backing up easytier UUID /etc/easytier/et_machine_id to /tmp/et_machine_id_backup"
    echo "UUID will not be lost if luci-app-easytier is reinstalled without rebooting, no need to reconfigure"
    mv -f /etc/easytier/et_machine_id /tmp/et_machine_id_backup
fi
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

chmod +x /etc/init.d/easytier
if [ -f /tmp/easytier_backup ] ; then
    echo "Found easytier backup configuration file /tmp/easytier_backup, starting restore to /etc/config/easytier"
    mv -f /tmp/easytier_backup /etc/config/easytier
    echo "Please go to VPN - EasyTier interface to restart the plugin"
fi

if [ -f /tmp/et_config_backup.toml ] ; then
    echo "Found easytier backup configuration file /tmp/et_config_backup.toml, starting restore to /etc/easytier/config.toml"
    mv -f /tmp/et_config_backup.toml /etc/easytier/config.toml
    echo "Please go to VPN - EasyTier interface to restart the plugin"
fi

if [ -f /tmp/et_backup.db ] ; then
    echo "Found easytier backup database /tmp/et_backup.db, starting restore to /etc/easytier/et.db"
    echo "Warning: If you modified the easytier database path before uninstallation, please manually copy /etc/easytier/et.db to the modified database file path location. If you do not want to modify it, please restore the database path to /etc/easytier/et.db"
    mv -f /tmp/et_backup.db /etc/easytier/et.db
    echo "Please go to VPN - EasyTier interface to restart the plugin"
fi

if [ -f /tmp/et_machine_id_backup ] ; then
    echo "Found easytier backup UUID /tmp/et_machine_id_backup, starting restore to /etc/easytier/et_machine_id"
    mv -f /tmp/et_machine_id_backup /etc/easytier/et_machine_id
    echo "Please go to VPN - EasyTier interface to restart the plugin"
fi
endef

$(eval $(call Build/Template,Package/$(PKG_NAME)/prerm))
$(eval $(call Build/Template,Package/$(PKG_NAME)/postinst))

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
