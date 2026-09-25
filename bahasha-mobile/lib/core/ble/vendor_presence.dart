import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_protocol.dart';

/// Whether a church's CVendor collector (the BLE hub) is in range — the right
/// avatar of the Send screen: found (Vendor Card, 692:440) or missing
/// (Missing Vendor, 700:504).
enum VendorStatus { searching, found, missing }

class VendorPresence {
  const VendorPresence(this.status, {this.name});
  final VendorStatus status;

  /// The hub's advertised Bluetooth name (CVendor advertises "Bahasha Hub").
  final String? name;
}

/// Scans for the Bahasha GATT service the hub advertises. Read-only: it never
/// connects — delivery is still the transport's job (ble_transport.dart). A
/// denied permission or a switched-off radio simply reads as "missing", and
/// giving still works: the signed offering waits safely in the outbox.
class VendorPresenceController extends Notifier<VendorPresence> {
  StreamSubscription<DiscoveredDevice>? _scan;
  Timer? _timeout;
  FlutterReactiveBle? _ble;

  @override
  VendorPresence build() {
    ref.onDispose(_stop);
    return const VendorPresence(VendorStatus.searching);
  }

  Future<void> scan({Duration timeout = const Duration(seconds: 12)}) async {
    _stop();
    state = const VendorPresence(VendorStatus.searching);

    final granted = await _permissions();
    if (!granted) {
      state = const VendorPresence(VendorStatus.missing);
      return;
    }
    try {
      _ble ??= FlutterReactiveBle();
      _timeout = Timer(timeout, () {
        _stop();
        if (state.status == VendorStatus.searching) state = const VendorPresence(VendorStatus.missing);
      });
      _scan = _ble!.scanForDevices(withServices: [BleProtocol.serviceUuid]).listen(
        (d) {
          _stop();
          state = VendorPresence(VendorStatus.found, name: d.name.trim().isEmpty ? null : d.name.trim());
        },
        onError: (_) {
          _stop();
          state = const VendorPresence(VendorStatus.missing);
        },
      );
    } catch (_) {
      _stop();
      state = const VendorPresence(VendorStatus.missing);
    }
  }

  Future<bool> _permissions() async {
    try {
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse, // required for BLE scans on Android ≤ 11
      ].request();
      final scanOk = results[Permission.bluetoothScan]?.isGranted ?? false;
      final locOk = results[Permission.locationWhenInUse]?.isGranted ?? false;
      // Android 12+ needs BLUETOOTH_SCAN; older versions need location instead.
      return scanOk || locOk;
    } catch (_) {
      return false;
    }
  }

  void _stop() {
    _timeout?.cancel();
    _timeout = null;
    _scan?.cancel();
    _scan = null;
  }
}

final vendorPresenceProvider =
    NotifierProvider<VendorPresenceController, VendorPresence>(VendorPresenceController.new);
