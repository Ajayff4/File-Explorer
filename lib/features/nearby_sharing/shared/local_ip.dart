import 'dart:async';
import 'dart:io';

/// Resolve this device's LAN IPv4 address for display in the Share UI.
///
/// Prefers a `wlan` interface; falls back to the first non-loopback IPv4
/// address. Returns 'Unknown' if none can be determined.
Future<String> getLanIpAddress() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      if (iface.name.toLowerCase().contains('wlan') &&
          iface.addresses.isNotEmpty) {
        return iface.addresses.first.address;
      }
    }
    for (final iface in interfaces) {
      if (iface.addresses.isNotEmpty) return iface.addresses.first.address;
    }
  } catch (_) {}
  return 'Unknown';
}
