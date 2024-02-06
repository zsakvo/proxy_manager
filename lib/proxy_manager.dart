// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:io';

import 'proxy_manager_platform_interface.dart';
import 'package:path/path.dart' as path;

enum ProxyTypes { http, https, socks }

class ProxyManager {
  /// get platform version
  Future<String?> getPlatformVersion() {
    return ProxyManagerPlatform.instance.getPlatformVersion();
  }

  /// set system proxy
  Future<void> setAsSystemProxy(ProxyTypes types, String url, int port) async {
    switch (Platform.operatingSystem) {
      case "windows":
        await _setAsSystemProxyWindows(types, url, port);
        break;
      case "linux":
        _setAsSystemProxyLinux(types, url, port);
        break;
      case "macos":
        await _setAsSystemProxyMacos(types, url, port);
        break;
    }
  }

  Future<List<String>> _getNetworkDeviceListMacos() async {
    final resp = await Process.run("/usr/sbin/networksetup", ["-listallnetworkservices"]);
    final lines = resp.stdout.toString().split("\n");
    lines.removeWhere((element) => element.contains("*"));
    return lines;
  }

  Future<void> _setAsSystemProxyMacos(ProxyTypes type, String url, int port) async {
    final devices = await _getNetworkDeviceListMacos();
    for (final dev in devices) {
      switch (type) {
        case ProxyTypes.http:
          await Process.run("/usr/sbin/networksetup", ["-setwebproxystate", dev, "on"]);
          await Process.run("/usr/sbin/networksetup", ["-setwebproxy", dev, url, "$port"]);
          break;
        case ProxyTypes.https:
          await Process.run("/usr/sbin/networksetup", ["-setsecurewebproxystate", dev, "on"]);
          await Process.run("/usr/sbin/networksetup", ["-setsecurewebproxy", dev, url, "$port"]);
          break;
        case ProxyTypes.socks:
          await Process.run("/usr/sbin/networksetup", ["-setsocksfirewallproxystate", dev, "on"]);
          await Process.run("/usr/sbin/networksetup", ["-setsocksfirewallproxy", dev, url, "$port"]);
          break;
      }
    }
  }

  Future<void> _cleanSystemProxyMacos() async {
    final devices = await _getNetworkDeviceListMacos();
    for (final dev in devices) {
      await Future.wait([
        Process.run("/usr/sbin/networksetup", ["-setautoproxystate", dev, "off"]),
        Process.run("/usr/sbin/networksetup", ["-setwebproxystate", dev, "off"]),
        Process.run("/usr/sbin/networksetup", ["-setsecurewebproxystate", dev, "off"]),
        Process.run("/usr/sbin/networksetup", ["-setsocksfirewallproxystate", dev, "off"]),
      ]);
    }
  }

  Future<void> _setAsSystemProxyWindows(ProxyTypes types, String url, int port) async {
    ProxyManagerPlatform.instance.setSystemProxy(types, url, port);
  }

  void _setAsSystemProxyLinux(ProxyTypes types, String url, int port) {
    final homeDir = Platform.environment['HOME']!;
    final configDir = path.join(homeDir, ".config");
    final cmdList = List<List<String>>.empty(growable: true);
    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    final isKDE = desktop == "KDE";
    // gsetting
    cmdList.add(["gsettings", "set", "org.gnome.system.proxy", "mode", "manual"]);
    cmdList.add(["gsettings", "set", "org.gnome.system.proxy.${types.name}", "host", "$url"]);
    cmdList.add(["gsettings", "set", "org.gnome.system.proxy.${types.name}", "port", "$port"]);
    // kde
    if (isKDE) {
      cmdList.add(
          ["kwriteconfig5", "--file", "$configDir/kioslaverc", "--group", "Proxy Settings", "--key", "ProxyType", "1"]);
      cmdList.add([
        "kwriteconfig5",
        "--file",
        "$configDir/kioslaverc",
        "--group",
        "Proxy Settings",
        "--key",
        "${types.name}Proxy",
        "${types.name}://$url:$port"
      ]);
    }
    for (final cmd in cmdList) {
      final res = Process.runSync(cmd[0], cmd.sublist(1), runInShell: true);
      print('cmd: $cmd returns ${res.exitCode}');
    }
  }

  /// clean system proxy
  Future<void> cleanSystemProxy() async {
    switch (Platform.operatingSystem) {
      case "linux":
        _cleanSystemProxyLinux();
        break;
      case "windows":
        await _cleanSystemProxyWindows();
        break;
      case "macos":
        await _cleanSystemProxyMacos();
    }
  }

  Future<void> _cleanSystemProxyWindows() async {
    await ProxyManagerPlatform.instance.cleanSystemProxy();
  }

  void _cleanSystemProxyLinux() {
    final homeDir = Platform.environment['HOME']!;
    final configDir = path.join(homeDir, ".config/");
    final cmdList = List<List<String>>.empty(growable: true);
    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    final isKDE = desktop == "KDE";
    // gsetting
    cmdList.add(["gsettings", "set", "org.gnome.system.proxy", "mode", "none"]);
    if (isKDE) {
      cmdList.add(
          ["kwriteconfig5", "--file", "$configDir/kioslaverc", "--group", "Proxy Settings", "--key", "ProxyType", "0"]);
    }
    for (final cmd in cmdList) {
      final res = Process.runSync(cmd[0], cmd.sublist(1));
      print('cmd: $cmd returns ${res.exitCode}');
    }
  }

  Future<Map<String, dynamic>?> getSystemProxy() async {
    switch (Platform.operatingSystem) {
      case "linux":
        return _getSystemProxyLinux();
      case "windows":
        return _getSystemProxyWindows();
      case "macos":
        return _getSystemProxyMacos();
      default:
        return null;
    }
  }

  Future<Map<String, dynamic>?> _getSystemProxyLinux() async {
    return await ProxyManagerPlatform.instance.getSystemProxy();
  }

  Future<Map<String, dynamic>?> _getSystemProxyWindows() async {
    return await ProxyManagerPlatform.instance.getSystemProxy();
  }

  Future<Map<String, dynamic>> _getSystemProxyMacos() async {
    final res = await Process.run("scutil", ["--proxy"]);
    final lines = res.stdout.toString().split("\n");
    final map = <String, dynamic>{};

    for (var line in lines) {
      if (line.contains('HTTPEnable')) {
        map['HTTPEnable'] = line.split(':')[1].trim() == "1";
      } else if (line.contains('HTTPProxy')) {
        map['HTTPProxy'] = line.split(':')[1].trim();
      } else if (line.contains('HTTPPort')) {
        map['HTTPPort'] = int.parse(line.split(':')[1].trim());
      } else if (line.contains('HTTPSEnable')) {
        map['HTTPSEnable'] = line.split(':')[1].trim() == "1";
      } else if (line.contains('HTTPSProxy')) {
        map['HTTPSProxy'] = line.split(':')[1].trim();
      } else if (line.contains('HTTPSPort')) {
        map['HTTPSPort'] = int.parse(line.split(':')[1].trim());
      } else if (line.contains('SOCKSEnable')) {
        map['SOCKSEnable'] = line.split(':')[1].trim() == "1";
      } else if (line.contains('SOCKSProxy')) {
        map['SOCKSProxy'] = line.split(':')[1].trim();
      } else if (line.contains('SOCKSPort')) {
        map['SOCKSPort'] = int.parse(line.split(':')[1].trim());
      }
    }
    return {
      "http": map['HTTPEnable'] ? "${map['HTTPProxy']}:${map['HTTPPort']}" : null,
      "https": map['HTTPSEnable'] ? "${map['HTTPSProxy']}:${map['HTTPSPort']}" : null,
      "socks": map['SOCKSEnable'] ? "${map['SOCKSProxy']}:${map['SOCKSPort']}" : null,
    };
  }

  Future<Map<String, dynamic>?> getSystemDns() async {
    switch (Platform.operatingSystem) {
      case "linux":
        return _getSystemDnsLinux();
      case "windows":
        return _getSystemDnsWindows();
      case "macos":
        return _getSystemDnsMacos();
      default:
        return null;
    }
  }

  Future<Map<String, dynamic>?> _getSystemDnsLinux() async {
    return await ProxyManagerPlatform.instance.getSystemDns();
  }

  Future<Map<String, dynamic>?> _getSystemDnsWindows() async {
    return await ProxyManagerPlatform.instance.getSystemDns();
  }

  Future<Map<String, dynamic>?> _getSystemDnsMacos() async {
    final devices = await _getNetworkDeviceListMacos();
    Map<String, List<String>> dnsMap = {};
    for (final dev in devices) {
      if (dev.isEmpty) continue;
      final res = await Process.run("/usr/sbin/networksetup", ["-getdnsservers", dev]);
      String str = res.stdout.toString().trim();
      final lines = str.contains("There aren't any DNS Servers") ? <String>[] : str.split("\n");
      dnsMap[dev] = lines;
    }
    return dnsMap;
  }

  /// clean system proxy
  Future<void> setSystemDns(List<String> dns) async {
    switch (Platform.operatingSystem) {
      case "linux":
        await _setSystemDnsLinux(dns);
        break;
      case "windows":
        await _setSystemDnsWindows(dns);
        break;
      case "macos":
        await _setSystemDnsMacos(dns);
    }
  }

  Future<void> _setSystemDnsLinux(List<String> dns) async {
    return await ProxyManagerPlatform.instance.setSystemDns(dns);
  }

  Future<void> _setSystemDnsWindows(List<String> dns) async {
    return await ProxyManagerPlatform.instance.setSystemDns(dns);
  }

  Future<void> _setSystemDnsMacos(List<String> dns) async {
    final devices = await _getNetworkDeviceListMacos();
    // 获取当前使用的设备
    for (final dev in devices) {
      if (dev.isEmpty) continue;
      await Process.run("/usr/sbin/networksetup", ["-setdnsservers", dev, dns.join(" ")]);
    }
  }
}
