/// A device discovered on the local network that can receive files.
class NearbyPeer {
  const NearbyPeer({
    required this.id,
    required this.name,
    required this.host,
    required this.tcpPort,
    required this.code,
  });

  final String id;
  final String name;
  final String host;
  final int tcpPort;
  final String code;

  NearbyPeer copyWith({
    String? name,
    String? host,
    int? tcpPort,
    String? code,
  }) {
    return NearbyPeer(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      tcpPort: tcpPort ?? this.tcpPort,
      code: code ?? this.code,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NearbyPeer && other.id == id && other.host == host;

  @override
  int get hashCode => Object.hash(id, host);
}
