local http                        = luci.http
local nixio                       = require "nixio"

m                                 = Map("easytier")
m.description                     = translate(
    'A simple, secure, decentralized VPN networking solution implemented using Rust language and Tokio framework. Project address: <a href="https://github.com/EasyTier/EasyTier">github.com/EasyTier/EasyTier</a>&nbsp;&nbsp;<a href="http://easytier.cn">Official Documentation</a>&nbsp;&nbsp;<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=jhP2Z4UsEZ8wvfGPLrs0VwLKn_uz0Q_p&authKey=OGKSQLfg61YPCpVQuvx%2BxE7hUKBVBEVi9PljrDKbHlle6xqOXx8sOwPPTncMambK&noverify=0&group_code=949700262">QQ Group</a>&nbsp;&nbsp;<a href="https://doc.oee.icu">Beginner Tutorial</a>')

m:section(SimpleSection).template = "easytier/easytier_status"

-- easytier-core
s                                 = m:section(TypedSection, "easytier", translate("EasyTier Configuration"))
s.addremove                       = false
s.anonymous                       = true
s:tab("general", translate("General Settings"))
s:tab("privacy", translate("Advanced Settings"))
s:tab("infos", translate("Connection Info"))
s:tab("upload", translate("Upload Program"))

switch = s:taboption("general", Flag, "enabled", translate("Enable"))
switch.rmempty = false

btncq = s:taboption("general", Button, "btncq", translate("Restart"))
btncq.inputtitle = translate("Restart")
btncq.description = translate("Quickly restart once without modifying parameters")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
    luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &") -- Execute restart command
end
etcmd = s:taboption("general", ListValue, "etcmd", translate("Startup Method"),
    translate(
        "Official Web Console: <a href='https://easytier.cn/web'>easytier.cn/web</a><br>Official Config File Generator: <a href='https://easytier.cn/web/index.html#/config_generator'>easytier.cn/web/index.html#/config_generator</a><br>Note that the RPC port should be set to 15888"))
etcmd.default = "etcmd"
etcmd:value("etcmd", translate("Command Line"))
etcmd:value("config", translate("Config File"))
etcmd:value("web", translate("Web Config"))

et_config = s:taboption("general", TextValue, "et_config", translate("Config File"),
    translate(
        "The config file is located at /etc/easytier/config.toml<br>Command line startup parameters and this config file parameters will not sync.<br>Note to fill in the tun network card name and port for automatic firewall release"))
et_config.rows = 18
et_config.wrap = "off"
et_config:depends("etcmd", "config")

et_config.cfgvalue = function(self, section)
    return nixio.fs.readfile("/etc/easytier/config.toml") or ""
end
et_config.write = function(self, section, value)
    local dir = "/etc/easytier/"
    local file = dir .. "config.toml"
    -- Check if directory exists, create if it does not exist
    if not nixio.fs.access(dir) then
        nixio.fs.mkdir(dir)
    end
    nixio.fs.writefile(file, value:gsub("\r\n", "\n"))
end

web_config = s:taboption("general", Value, "web_config", translate("Web Server Address"),
    translate(
        "Web configuration server address. (-w parameter)<br>For a self-hosted Web server, input format: udp://server_address:22020/username<br>For an official Web server, input format: username <br>Official Web Console: <a href='https://easytier.cn/web'>easytier.cn/web</a>"))
web_config.placeholder = "admin"
web_config:depends("etcmd", "web")

network_name = s:taboption("general", Value, "network_name", translate("Network Name"),
    translate("Network name to identify this VPN network. (--network-name parameter)"))
network_name.password = true
network_name.placeholder = "test"
network_name:depends("etcmd", "etcmd")
network_name:depends("log", "error")
network_name:depends("log", "warn")
network_name:depends("log", "info")
network_name:depends("log", "debug")
network_name:depends("log", "trace")

network_secret = s:taboption("general", Value, "network_secret", translate("Network Secret"),
    translate("Network secret used to verify if this node belongs to the VPN network ( --network-secret parameter)"))
network_secret.password = true
network_secret.placeholder = "test"
network_secret:depends("etcmd", "etcmd")

ip_dhcp = s:taboption("general", Flag, "ip_dhcp", translate("Enable DHCP"),
    translate(
        "Automatically determine and set the IP address by Easytier, defaulting from 10.0.0.1. Warning: When using DHCP, if there is an IP conflict in the network, the IP will automatically change. (-d parameter)"))
ip_dhcp:depends("etcmd", "etcmd")

ipaddr = s:taboption("general", Value, "ipaddr", translate("Interface IP Address"),
    translate(
        "The IPv4 address of this VPN node. If left empty, the node will only forward packets without creating a TUN device (-i parameter)"))
ipaddr.datatype = "ip4addr"
ipaddr.placeholder = "10.0.0.1"
ipaddr:depends("etcmd", "etcmd")

peeradd = s:taboption("general", DynamicList, "peeradd", translate("Peer Node"),
    translate(
        "Initial peer nodes to connect to, same as the parameters below (-p parameter)<br>Public server status query: <a href='https://easytier.gd.nkbpal.cn/status/easytier' target='_blank'>Click here to check</a>"))
peeradd.placeholder = "tcp://public.easytier.top:11010"
peeradd:value("tcp://public.easytier.top:11010",
    translate("Official Server - Guangdong Heyuan - tcp://public.easytier.top:11010"))
peeradd:value("tcp://turn.hb.629957.xyz:11010", translate("Shiyan, Hubei Telecom V4 - tcp://turn.hb.629957.xyz:11010"))
peeradd:value("tcp://et.ie12vps.xyz:11010", translate("Nanjing V4/V6 - tcp://et.ie12vps.xyz:11010"))
peeradd:value("tcp://ah.nkbpal.cn:11010", translate("Anhui Telecom V4 - tcp://ah.nkbpal.cn:11010"))
peeradd:value("udp://ah.nkbpal.cn:11010", translate("Anhui Telecom V4 - udp://ah.nkbpal.cn:11010"))
peeradd:value("wss://ah.nkbpal.cn:11012", translate("Anhui Telecom V4 - wss://ah.nkbpal.cn:11012"))
peeradd:value("tcp://222.186.59.80:11113", translate("Zhenjiang, Jiangsu V4 - tcp://222.186.59.80:11113"))
peeradd:value("wss://222.186.59.80:11115", translate("Zhenjiang, Jiangsu V4 - wss://222.186.59.80:11115"))
peeradd:value("tcp://hw.gz.9z1.me:58443", translate("Guangzhou V4 - tcp://hw.gz.9z1.me:58443"))
peeradd:value("tcp://c.oee.icu:60006", translate("Hong Kong V4/V6 - tcp://c.oee.icu:60006"))
peeradd:value("udp://c.oee.icu:60006", translate("Hong Kong V4/V6 - udp://c.oee.icu:60006"))
peeradd:value("wss://c.oee.icu:60007", translate("Hong Kong V4/V6 - wss://c.oee.icu:60007"))
peeradd:value("tcp://etvm.oee.icu:31572", translate("Japan V4 - tcp://etvm.oee.icu:31572"))
peeradd:value("wss://etvm.oee.icu:30845", translate("Japan V4 - wss://etvm.oee.icu:30845"))
peeradd:value("tcp://et.pub.moe.gift:11010", translate("Colorado, USA V4 - tcp://et.pub.moe.gift:11010"))
peeradd:value("wss://et.pub.moe.gift:11012", translate("Colorado, USA V4 - wss://et.pub.moe.gift:11012"))
peeradd:value("tcp://et.323888.xyz:11010", translate("Shiyan, Hubei V4 - tcp://et.323888.xyz:11010"))
peeradd:value("udp://et.323888.xyz:11010", translate("Shiyan, Hubei V4 - udp://et.323888.xyz:11010"))
peeradd:value("wss://et.323888.xyz:11012", translate("Shiyan, Hubei V4 - wss://et.323888.xyz:11012"))
peeradd:depends("etcmd", "etcmd")

external_node = s:taboption("general", Value, "external_node", translate("Shared Node Address"),
    translate("Use a public shared node to discover peer nodes, similar to the above parameter (-e)"))
external_node.default = ""
external_node.placeholder = "tcp://public.easytier.top:11010"
external_node:value("tcp://public.easytier.top:11010",
    translate("Official Server - Guangdong Heyuan - tcp://public.easytier.top:11010"))
external_node:depends("etcmd", "etcmd")

proxy_network = s:taboption("general", DynamicList, "proxy_network", translate("Subnet Proxy"),
    translate("Export local network to other peers in the VPN for access to devices on the current LAN ( -n parameter )"))
proxy_network:depends("etcmd", "etcmd")

mapped_listeners = s:taboption("privacy", DynamicList, "mapped_listeners",
    translate("Specify public address for listeners"),
    translate(
        "Manually specify this machine's public IP address. Other nodes can use this address to connect to this node (domain names are not supported).<br>Example: tcp://123.123.123.123:11223, multiple addresses can be specified. (--mapped-listeners parameter)"))
mapped_listeners:depends("listenermode", "ON")

rpc_portal = s:taboption("privacy", Value, "rpc_portal", translate("RPC Portal Address"),
    translate(
        "The RPC portal address for management. 0 means random port, 12345 means listen on localhost's port 12345, 0.0.0.0:12345 means listen on port 12345 on all interfaces.<br>Default is 0, it is recommended to choose 15888 to prevent status information from being inaccessible (-r parameter)"))
rpc_portal.placeholder = "15888"
rpc_portal.default = "15888"
rpc_portal.datatype = "range(1,65535)"
rpc_portal:depends("etcmd", "etcmd")

listenermode = s:taboption("general", ListValue, "listenermode", translate("Listener Mode"),
    translate(
        "OFF: Do not listen on any port, only connect to peer nodes (--no-listener parameter)<br>A purely client usage (not as a server) can avoid listening on ports"))
listenermode:value("ON", translate("Listen"))
listenermode:value("OFF", translate("Do Not Listen"))
listenermode.default = "OFF"
listenermode:depends("etcmd", "etcmd")

listener6 = s:taboption("general", Flag, "listener6", translate("Listen on IPv6"),
    translate(
        "By default, only listen on IPv4, peers can only connect via IPv4. Enabling this will also listen on IPv6 ports"))
listener6:depends("listenermode", "ON")
listener6:depends("etcmd", "etcmd")

tcp_port = s:taboption("general", Value, "tcp_port", translate("TCP/UDP Port"),
    translate(
        "Port number for TCP/UDP protocol: 11010. Indicates that TCP/UDP will listen on port 11010.<br>If this is a Web configuration via config file, please enter the same listening port for firewall release"))
tcp_port.datatype = "range(1,65535)"
tcp_port.default = "11010"
tcp_port:depends("listenermode", "ON")
tcp_port:depends("etcmd", "web")

ws_port = s:taboption("general", Value, "ws_port", translate("WS Port"),
    translate(
        "WS protocol port number: 11011, indicating that WS will listen on port 11011<br>If using Web configuration in the config file, please fill in the same listening port for firewall release"))
ws_port.datatype = "range(1,65535)"
ws_port.default = "11011"
ws_port:depends("listenermode", "ON")
ws_port:depends("etcmd", "web")

wss_port = s:taboption("general", Value, "wss_port", translate("WSS Port"),
    translate(
        "WSS protocol, port number: 11012, indicates that WSS will listen on port 11012 <br>If this is a Web configuration file, please fill in the same listening port for firewall release"))
wss_port.datatype = "range(1,65535)"
wss_port.default = "11012"
wss_port:depends("listenermode", "ON")
wss_port:depends("etcmd", "web")

wg_port = s:taboption("general", Value, "wg_port", translate("WG Port"),
    translate(
        "WireGuard protocol port number: 11011. This means WG will listen on port 11011.<br>If using Web configuration from a config file, please enter the same listening port for firewall rules"))
wg_port.datatype = "range(1,65535)"
wg_port.placeholder = "11011"
wg_port:depends("listenermode", "ON")
wg_port:depends("etcmd", "web")

local model = nixio.fs.readfile("/proc/device-tree/model") or ""
local hostname = nixio.fs.readfile("/proc/sys/kernel/hostname") or ""
model = model:gsub("\n", "")
hostname = hostname:gsub("\n", "")
local device_name = (model ~= "" and model) or (hostname ~= "" and hostname) or "OpenWrt"
device_name = device_name:gsub(" ", "_")
device_name = s:taboption("general", Value, "device_name", translate("Hostname"),
    translate("Used to identify this device's hostname (--hostname parameter)"))
desvice_name.placeholder = device_name
desvice_name.default = device_name
desvice_name:depends("etcmd", "etcmd")
instance_name = s:taboption("privacy", Value, "instance_name", translate("Instance Name"),
    translate(
        "Used to identify this VPN node instance on the same machine. Filling this is required for logging and should be the same in web configuration (-m parameter)"))
instance_name.placeholder = "default"
instance_name:depends("etcmd", "etcmd")
instance_name:depends("etcmd", "web")

vpn_portal = s:taboption("privacy", Value, "vpn_portal", translate("VPN Portal URL"),
    translate(
        "Define the VPN portal URL to allow other VPN clients to connect.<br> Example: wg://0.0.0.0:11011/10.14.14.0/24, which means the VPN portal is a WireGuard server listening on vpn.example.com:11010 and VPN clients are in the 10.14.14.0/24 network ( --vpn-portal parameter)"))
vpn_portal.placeholder = "wg://0.0.0.0:11011/10.14.14.0/24"
vpn_portal:depends("etcmd", "etcmd")

mtu = s:taboption("privacy", Value, "mtu", translate("MTU"),
    translate("MTU of the TUN device, default is 1380 when unencrypted and 1360 when encrypted"))
mtu.datatype = "range(1,1500)"
mtu.placeholder = "1300"
mtu:depends("etcmd", "etcmd")

default_protocol = s:taboption("privacy", ListValue, "default_protocol", translate("Default Protocol"),
    translate("The default protocol used to connect to peer nodes ( --default-protocol parameter)"))
default_protocol:value("-", translate("Default"))
default_protocol:value("tcp")
default_protocol:value("udp")
default_protocol:value("ws")
default_protocol:value("wss")
default_protocol:depends("etcmd", "etcmd")

tunname = s:taboption("privacy", Value, "tunname", translate("TUN interface name"),
    translate(
        "Custom TUN interface name (--dev-name parameter)<br>If using WEB config, enter the same TUN interface name as in WEB config for firewall release"))
tunname.placeholder = "tun0"
tunname:depends("etcmd", "etcmd")
tunname:depends("etcmd", "web")

disable_encryption = s:taboption("general", Flag, "disable_encryption", translate("Disable Encryption"),
    translate(
        "Disables encryption for peer node communication. If encryption is disabled, all other nodes must also have encryption disabled (-u parameter)"))
disable_encryption:depends("etcmd", "etcmd")

multi_thread = s:taboption("general", Flag, "multi_thread", translate("Enable Multi-threading"),
    translate("Run using multi-threading, default is single-threaded (--multi-thread parameter)"))
multi_thread:depends("etcmd", "etcmd")

disable_ipv6 = s:taboption("privacy", Flag, "disable_ipv6", translate("Disable IPv6"),
    translate("Do not use IPv6 (--disable-ipv6 parameter)"))
disable_ipv6:depends("etcmd", "etcmd")

latency_first = s:taboption("general", Flag, "latency_first", translate("Enable Latency First"),
    translate(
        "Latency-first mode, will attempt to use the path with the lowest latency to forward traffic, default uses the shortest path (--latency-first parameter)"))
latency_first:depends("etcmd", "etcmd")

comp = s:taboption("general", ListValue, "comp", translate("Compression Algorithm"),
    translate("The compression algorithm used (--compression parameter)"))
comp.default = "none"
comp:value("none", translate("Default"))
comp:value("zstd", translate("zstd"))
comp:depends("etcmd", "etcmd")

exit_node = s:taboption("privacy", Flag, "exit_node", translate("Enable Exit Node"),
    translate("Allow this node to act as an exit node (--enable-exit-node parameter)"))
exit_node:depends("etcmd", "etcmd")

exit_nodes = s:taboption("privacy", DynamicList, "exit_nodes", translate("Exit Node Address"),
    translate(
        "Exit node for forwarding all traffic, virtual IPv4 address, priority determined by list order (--exit-nodes parameter)"))
exit_nodes:depends("etcmd", "etcmd")

smoltcp = s:taboption("privacy", Flag, "smoltcp", translate("Use user-space protocol stack"),
    translate("Enable smoltcp stack for subnet proxy ( --use-smoltcp parameter)"))
smoltcp:depends("etcmd", "etcmd")

no_tun = s:taboption("privacy", Flag, "no_tun", translate("No TUN mode"),
    translate("Do not create a TUN device, can use subnet proxy to access nodes ( --no-tun parameter)"))
no_tun:depends("etcmd", "etcmd")

proxy_forward = s:taboption("privacy", Flag, "proxy_forward", translate("Disable Built-in NAT"),
    translate(
        "Forward subnet proxy packets through system kernel, disable built-in NAT ( --proxy-forward-by-system parameter)"))
proxy_forward:depends("etcmd", "etcmd")

manual_routes = s:taboption("privacy", DynamicList, "manual_routes", translate("Routing CIDR"),
    translate(
        "Manually allocate routing CIDRs, which will disable subnet proxy and WireGuard routes propagated from peer nodes. (--manual-routes parameter)"))
manual_routes.placeholder = "192.168.0.0/16"
manual_routes:depends("etcmd", "etcmd")

relay_network = s:taboption("privacy", Flag, "relay_network", translate("Forward traffic of whitelisted networks"),
    translate("Only forward traffic from whitelisted networks, default allows all networks"))
relay_network:depends("etcmd", "etcmd")

whitelist = s:taboption("privacy", DynamicList, "whitelist", translate("Whitelist Networks"),
    translate(
        "Only forward traffic from whitelisted networks. Input is a wildcard string, e.g., '*' (all networks), 'def*' (networks starting with def).<br>Multiple networks can be specified. If the parameter is empty, forwarding is disabled. (--relay-network-whitelist parameter)"))
whitelist:depends("relay_network", "1")

socks_port = s:taboption("privacy", Value, "socks_port", translate("Socks5 Port"),
    translate(
        "Enable socks5 server, allowing socks5 clients to access the virtual network. Leave blank to disable (--socks5 parameter)"))
socks_port.datatype = "range(1,65535)"
socks_port.placeholder = "1080"
socks_port:depends("etcmd", "etcmd")

disable_p2p = s:taboption("privacy", Flag, "disable_p2p", translate("Disable P2P"),
    translate(
        "Disable P2P communication and only forward packets through the nodes specified with -p ( --disable-p2p parameter)"))
disable_p2p:depends("etcmd", "etcmd")

disable_udp = s:taboption("privacy", Flag, "disable_udp", translate("Disable UDP"),
    translate("Disable UDP hole punching feature ( --disable-udp-hole-punching parameter)"))
disable_udp:depends("etcmd", "etcmd")

relay_all = s:taboption("privacy", Flag, "relay_all", translate("Allow Relaying"),
    translate(
        "Relay all peer node RPC packets, even if the peer nodes are not in the relay network whitelist.<br>This can help peers outside the whitelist establish P2P connections. (-relay-all-peer-rpc parameter)"))
relay_all:depends("etcmd", "etcmd")

bind_device = s:taboption("privacy", Flag, "bind_device", translate("Use Physical Interface Only"),
    translate(
        "Bind connector socket to physical device to avoid routing issues.<br>For example, if subnet proxy network segment conflicts with a node's network segment, binding to the physical device allows normal communication with that node. (--bind-device parameter)"))
bind_device.default = "0"
bind_device:depends("etcmd", "etcmd")

kcp_proxy = s:taboption("privacy", Flag, "kcp_proxy", translate("Enable KCP Proxy"),
    translate(
        "Convert TCP traffic to KCP traffic to reduce latency and improve speed.<br>KCP proxy function requires all nodes in the virtual network to have EasyTier version v2.2.0 or above. ( --enable-kcp-proxy parameter)"))
kcp_proxy:depends("etcmd", "etcmd")

kcp_input = s:taboption("privacy", Flag, "kcp_input", translate("Disable KCP Input"),
    translate(
        "Do not allow other nodes to use KCP proxy for TCP streams to this node.<br>Nodes with KCP proxy enabled will still use the original connection when accessing this node. ( --disable-kcp-input parameter)"))
kcp_input:depends("etcmd", "etcmd")

log = s:taboption("general", ListValue, "log", translate("Program Log"),
    translate(
        "Runtime log is located at /tmp/easytier.log, viewable in logs above.<br>If startup fails, check specific failure logs under Status - System Logs<br>Verbosity levels: Warning < Info < Debug < Trace"))
log.default = "off"
log:value("off", translate("Off"))
log:value("error", translate("Error"))
log:value("warn", translate("Warning"))
log:value("info", translate("Info"))
log:value("debug", translate("Debug"))
log:value("trace", translate("Trace"))

et_forward = s:taboption("privacy", luci.cbi.MultiValue, "et_forward", translate("Access Control"),
    translate("Set traffic allow rules between different network regions"))
et_forward:value("etfwlan", translate("Allow traffic from EasyTier virtual network to lan local network"))
et_forward:value("etfwwan", translate("Allow traffic from EasyTier virtual network to wan wide area network"))
et_forward:value("lanfwet", translate("Allow traffic from lan local network to EasyTier virtual network"))
et_forward:value("wanfwet", translate("Allow traffic from wan wide area network to EasyTier virtual network"))
et_forward.default = "etfwlan etfwwan lanfwet"
et_forward.rmempty = true

check = s:taboption("privacy", Flag, "check", translate("Connectivity Check"),
    translate(
        "Enable connectivity check to specify the IP of peer devices. If all specified IPs are unreachable, the easytier program will restart"))

checkip = s:taboption("privacy", DynamicList, "checkip", translate("Check IP"),
    translate(
        "Ensure that the IP addresses of peer devices entered here are correct and accessible. Incorrect entries can lead to unreachability and repeated program restarts"))
checkip.rmempty = true
checkip.datatype = "ip4addr"
checkip:depends("check", "1")
checktime = s:taboption("privacy", ListValue, "checktime", translate("Interval Time (minutes)"),
    translate("The interval time for checking the connectivity of specified IPs"))
for s = 1, 60 do
    checktime:value(s)
end
checktime:depends("check", "1")

local process_status = luci.sys.exec("ps | grep easytier-core| grep -v grep")

btn0 = s:taboption("infos", Button, "btn0")
btn0.inputtitle = translate("Node Info")
btn0.description = translate("Click the button to refresh and view local node information")
btn0.inputstyle = "apply"
btn0.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli node >/tmp/easytier-cli_node 2>&1")
    else
        luci.sys.call(
            "echo 'Error: Program is not running! Please start the program and try refreshing again.' >/tmp/easytier-cli_node")
    end
end

btn0info = s:taboption("infos", DummyValue, "btn0info")
btn0info.rawhtml = true
btn0info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_node") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn1 = s:taboption("infos", Button, "btn1")
btn1.inputtitle = translate("Peer Information")
btn1.description = translate("Click the button to refresh and view peer information")
btn1.inputstyle = "apply"
btn1.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli peer >/tmp/easytier-cli_peer 2>&1")
    else
        luci.sys.call(
            "echo 'Error: Program not running! Please start the program and refresh again.' >/tmp/easytier-cli_peer")
    end
end

btn1info = s:taboption("infos", DummyValue, "btn1info")
btn1info.rawhtml = true
btn1info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_peer") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn2 = s:taboption("infos", Button, "btn2")
btn2.inputtitle = translate("Connector Information")
btn2.description = translate("Click the button to refresh and view connector information")
btn2.inputstyle = "apply"
btn2.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli connector >/tmp/easytier-cli_connector 2>&1")
    else
        luci.sys.call(
            "echo 'Error: Program not running! Please start the program and refresh again' >/tmp/easytier-cli_connector")
    end
end

btn2info = s:taboption("infos", DummyValue, "btn2info")
btn2info.rawhtml = true
btn2info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_connector") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn3 = s:taboption("infos", Button, "btn3")
btn3.inputtitle = translate("STUN Information")
btn3.description = translate("Click button to refresh and view STUN information")
btn3.inputstyle = "apply"
btn3.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli stun >/tmp/easytier-cli_stun 2>&1")
    else
        luci.sys.call(
            "echo 'Error: Program is not running! Please start the program and refresh again.' >/tmp/easytier-cli_stun")
    end
end

btn3info = s:taboption("infos", DummyValue, "btn3info")
btn3info.rawhtml = true
btn3info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_stun") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end


btn4 = s:taboption("infos", Button, "btn4")
btn4.inputtitle = translate("Route Information")
btn4.description = translate("Click the button to refresh and view route information")
btn4.inputstyle = "apply"
btn4.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli route >/tmp/easytier-cli_route 2>&1")
    else
        luci.sys.call(
            "echo 'Error: Program not running! Please start the program and try refreshing again.' >/tmp/easytier-cli_route")
    end
end

btn4info = s:taboption("infos", DummyValue, "btn4info")
btn4info.rawhtml = true
btn4info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_route") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn6 = s:taboption("infos", Button, "btn6")
btn6.inputtitle = translate("peer-center information")
btn6.description = translate("Click button to refresh and view peer-center information")
btn6.inputstyle = "apply"
btn6.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli peer-center >/tmp/easytier-cli_peer-center 2>&1")
    else
        luci.sys.call(
            "echo 'Error: The program is not running! Please start the program and refresh again.' >/tmp/easytier-cli_peer-center")
    end
end

btn6info = s:taboption("infos", DummyValue, "btn6info")
btn6info.rawhtml = true
btn6info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_peer-center") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn7 = s:taboption("infos", Button, "btn7")
btn7.inputtitle = translate("VPN Portal Info")
btn7.description = translate("Click button to refresh and view VPN portal information")
btn7.inputstyle = "apply"
btn7.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli vpn-portal >/tmp/easytier-cli_vpn-portal 2>&1")
    else
        luci.sys.call(
            "echo 'Error: The program is not running! Please start the program and then click refresh again.' >/tmp/easytier-cli_vpn-portal")
    end
end

btn7info = s:taboption("infos", DummyValue, "btn7info")
btn7info.rawhtml = true
btn7info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_vpn-portal") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn8 = s:taboption("infos", Button, "btn8")
btn8.inputtitle = translate("TCP/KCP Proxy Information")
btn8.description = translate("Click button to refresh and view TCP/KCP proxy information")
btn8.inputstyle = "apply"
btn8.write = function()
    if process_status ~= "" then
        luci.sys.call(
            "$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli proxy >/tmp/easytier-cli_proxy 2>&1")
    else
        luci.sys.call(
            "echo 'Error: Program not running! Please start the program and refresh again.' >/tmp/easytier-cli_proxy")
    end
end

btn8info = s:taboption("infos", DummyValue, "btn8info")
btn8info.rawhtml = true
btn8info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_proxy") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn5 = s:taboption("infos", Button, "btn5")
btn5.inputtitle = translate("Local startup parameters")
btn5.description = translate("Click the button to refresh and view the full local startup parameters")
btn5.inputstyle = "apply"
btn5.write = function()
    if process_status ~= "" then
        luci.sys.call("echo $(cat /proc/$(pidof easytier-core)/cmdline | awk '{print $1}') >/tmp/easytier_cmd")
    else
        luci.sys.call(
            "echo 'Error: The program is not running! Please start the program and refresh again' >/tmp/easytier_cmd")
    end
end

btn5cmd = s:taboption("infos", DummyValue, "btn5cmd")
btn5cmd.rawhtml = true
btn5cmd.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier_cmd") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btnrm = s:taboption("infos", Button, "btnrm")
btnrm.inputtitle = translate("Check for Updates")
btnrm.description = translate(
    "Click this button to check for updates and refresh the version display in the status bar above")
btnrm.inputstyle = "apply"
btnrm.write = function()
    os.execute("rm -rf /tmp/easytier*.tag /tmp/easytier*.newtag /tmp/easytier-core_*")
end


easytierbin = s:taboption("upload", Value, "easytierbin", translate("Path to easytier-core program"),
    translate(
        "Customize the storage path for easytier-core. Ensure the full path and name are provided. If the specified path runs out of space, it will automatically be moved to /tmp/easytier-core"))
easytierbin.placeholder = "/usr/bin/easytier-core"
easytierbin.default = "/usr/bin/easytier-core"

webbin = s:taboption("upload", Value, "webbin", translate("easytier-web program path"),
    translate(
        "Customize the storage path for easytier-web, ensure to enter the full path and name, then upload the installation program"))
webbin.placeholder = "/usr/bin/easytier-web"
webbin.default = "/usr/bin/easytier-web"

local upload = s:taboption("upload", FileUpload, "upload_file")
upload.optional = true
upload.default = ""
upload.template = "easytier/other_upload"
upload.description = translate(
    "You can directly upload binary programs easytier-core and easytier-cli or .zip files. Uploading a new version will automatically overwrite the old version. Download address: <a href='https://github.com/EasyTier/EasyTier/releases' target='_blank'>github.com/EasyTier/EasyTier</a><br>The uploaded file will be saved in the /tmp folder. If a custom program path is specified, the program will be automatically moved to that path when started.<br>")
local um = s:taboption("upload", DummyValue, "", nil)
um.template = "easytier/other_dvalue"

local dir, fd, chunk
dir = "/tmp/"
nixio.fs.mkdir(dir)
http.setfilehandler(
    function(meta, chunk, eof)
        if not fd then
            if not meta then return end

            if meta and chunk then fd = nixio.open(dir .. meta.file, "w") end

            if not fd then
                um.value = "Error: Upload failed!"
                return
            end
        end
        if chunk and fd then
            fd:write(chunk)
        end
        if eof and fd then
            fd:close()
            fd = nil
            um.value = "File uploaded to" .. ' "/tmp/' .. meta.file .. '"'

            if string.sub(meta.file, -4) == ".zip" then
                local file_path = dir .. meta.file
                os.execute("unzip -q " .. file_path .. " -d " .. dir)
                local extracted_dir = "/tmp/easytier-linux-*/"
                os.execute("mv " .. extracted_dir .. "easytier-cli /tmp/easytier-cli")
                os.execute("mv " .. extracted_dir .. "easytier-core /tmp/easytier-core")
                os.execute("mv " .. extracted_dir .. "easytier-web-embed /tmp/easytier-web-embed")
                if nixio.fs.access("/tmp/easytier-cli") then
                    um.value = um.value ..
                        "\n" ..
                        translate(
                            "-Program /tmp/easytier-cli uploaded successfully, a plugin restart is required to take effect")
                end
                if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value ..
                        "\n" ..
                        translate(
                            "- Program /tmp/easytier-core uploaded successfully, restart the plugin once for it to take effect")
                end
                if nixio.fs.access("/tmp/easytier-web-embed") then
                    um.value = um.value ..
                        "\n" .. translate("-Program /tmp/easytier-web uploaded successfully, plugin restart required")
                end
            end
            if string.sub(meta.file, -7) == ".tar.gz" then
                local file_path = dir .. meta.file
                os.execute("tar -xzf " .. file_path .. " -C " .. dir)
                local extracted_dir = "/tmp/easytier-linux-*/"
                os.execute("mv " .. extracted_dir .. "easytier-cli /tmp/easytier-cli")
                os.execute("mv " .. extracted_dir .. "easytier-core /tmp/easytier-core")
                os.execute("mv " .. extracted_dir .. "easytier-web-embed /tmp/easytier-web-embed")
                if nixio.fs.access("/tmp/easytier-cli") then
                    um.value = um.value ..
                        "\n" .. translate("- /tmp/easytier-cli upload successful, plugin needs to be restarted")
                end
                if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value ..
                        "\n" ..
                        translate(
                            "-The /tmp/easytier-core program uploaded successfully, restart the plugin once for it to take effect")
                end
                if nixio.fs.access("/tmp/easytier-web-embed") then
                    um.value = um.value ..
                        "\n" ..
                        translate(
                            "-Program /tmp/easytier-web uploaded successfully, restart the plugin once to take effect")
                end
            end
            os.execute("chmod +x /tmp/easytier-core")
            os.execute("chmod +x /tmp/easytier-cli")
            os.execute("chmod +x /tmp/easytier-web-embed")
        end
    end
)
if luci.http.formvalue("upload") then
    local f = luci.http.formvalue("ulfile")
end

-- easytier-web
s = m:section(TypedSection, "easytierweb", translate("Self-hosted Web Server"))
s.addremove = false
s.anonymous = true

switch = s:option(Flag, "enabled", translate("Enable"))
switch.rmempty = false

btncq = s:option(Button, "btncq", translate("Restart"))
btncq.inputtitle = translate("Restart")
btncq.description = translate("Quickly restart without modifying parameters")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
    luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &") -- Execute restart command
end

db_path = s:option(Value, "db_path", translate("Database file path"),
    translate("sqlite3 database file path, used to store all data. (-d parameter)"))
db_path.default = "/etc/easytier/et.db"

web_protocol = s:option(ListValue, "web_protocol", translate("Listening Protocol"),
    translate("Configure the server listening protocol used by easytier-core to connect. (-p parameter)"))
web_protocol.default = "udp"
web_protocol:value("udp", translate("UDP"))
web_protocol:value("tcp", translate("TCP"))

web_port = s:option(Value, "web_port", translate("Service Port"),
    translate("Configure the server's listening port for connection by easytier-core. ( -c parameter)"))
web_port.datatype = "range(1,65535)"
web_port.placeholder = "22020"
web_port.default = "22020"

api_port = s:option(Value, "api_port", translate("API Port"),
    translate("RESTful server listening port, used as ApiHost and by web frontend. (-a parameter)"))
api_port.datatype = "range(1,65535)"
api_port.placeholder = "11211"
api_port.default = "11211"

html_port = s:option(Value, "html_port", translate("Web Interface Port"),
    translate("Frontend listening port for the web dashboard server. Leave blank to disable. (-l parameter)"))
html_port.datatype = "range(1,65535)"
html_port.placeholder = "11210"

weblog = s:option(ListValue, "weblog", translate("Program Log"),
    translate(
        "Log file is located at /tmp/easytierweb.log. You can view it above in the log section.<br>If startup fails, please check the specific failure logs in Status - System Logs.<br>Verbosity levels: Warning < Info < Debug < Trace"))
weblog.default = "off"
weblog:value("off", translate("Off"))
weblog:value("error", translate("Error"))
weblog:value("warn", translate("Warning"))
weblog:value("info", translate("Info"))
weblog:value("debug", translate("Debug"))
weblog:value("trace", translate("Trace"))

return m
