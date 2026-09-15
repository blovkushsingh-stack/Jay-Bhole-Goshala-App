abstract class VoiceInputService {
  Future<String?> listen();
}

class LocalVoiceInputService implements VoiceInputService {
  @override
  Future<String?> listen() async => null;
}
