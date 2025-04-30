# luci-app-easytier

Dependency `kmod-tun` needs to be installed in the system packages first
### Quick Start
```bash
Fork and clone this project from the top right corner, then manually trigger the automatic compilation process in Actions. You can obtain the latest ipk package `luci-app-easytier.zip` in 2 minutes, unzip it, upload it to your OpenWrt router, and install it.

```
![Actions interface](https://github.com/user-attachments/assets/7e5e843b-eb01-48f1-81ab-226a1418ca0f)
### Installation Method
```bash
# First upload to the /tmp/tmp directory on OpenWrt for installation
opkg install /tmp/tmp/luci-app-easytier_all.ipk

# Uninstall
opkg remove luci-app-easytier

# To update the version, first uninstall and then install the new ipk. Go to the management interface to disable the plugin, modify the parameters, then click apply and save.
# After installation, EasyTier does not appear in the OpenWrt management interface. Please log out or close and reopen the window.
```

```bash
# If it's a new version of OpenWrt using the apk package manager and you encounter issues installing the apk, you can try ignoring certificate verification
apk add --allow-untrusted /tmp/tmp/luci-app-easytier.apk
```

This luci-app-easytier does not include a binary program. You need to upload the binary program manually through the easytier plugin interface in the OpenWrt management interface.

### Compilation Method
```bash
# Download OpenWrt compilation SDK to opt directory (architecture-independent)
wget -qO /opt/sdk.tar.xz https://downloads.openwrt.org/releases/22.03.5/targets/rockchip/armv8/openwrt-sdk-22.03.5-rockchip-armv8_gcc-11.2.0_musl.Linux-x86_64.tar.xz
tar -xJf /opt/sdk.tar.xz -C /opt

cd /opt/openwrt-sdk*/package
# Clone luci-app-easytier into the sdk's package directory
git clone https://github.com/EasyTier/luci-app-easytier.git /opt/luci-app-easytier
cp -R /opt/luci-app-easytier/luci-app-easytier .

cd /opt/openwrt-sdk*
# Create upgrade script template
./scripts/feeds update -a
make defconfig

# Start compiling
make package/luci-app-easytier/compile V=s -j1

# After compilation in the /opt/openwrt-sdk*/bin/packages/aarch64_generic/base directory
cd /opt/openwrt-sdk*/bin/packages/aarch64_generic/base
# Move to /opt directory
mv *.ipk /opt/luci-app-easytier_all.ipk
```

> If the following log content appears in Status-System Log, you can use the following command to resolve it

```
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
Fri Feb  7 11:13:30 2025 daemon.err uhttpd[3381]: luci.util.pcdata() has been replaced by luci.xml.pcdata() - Please update your code.
```

```
sed -i 's/util/xml/g' /usr/lib/lua/luci/model/cbi/easytier.lua
```
