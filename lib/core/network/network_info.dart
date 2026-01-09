import 'dart:io';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl({
    this.lookupAddress = 'example.com',
    this.timeout = const Duration(seconds: 5),
  });

  final String lookupAddress;
  final Duration timeout;

  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup(lookupAddress).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
