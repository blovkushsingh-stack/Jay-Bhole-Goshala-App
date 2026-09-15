import '../models/ai_models.dart';
import '../prompts/ai_prompts.dart';
import 'ai_context_service.dart';

abstract class AiService {
  Future<String> answer(String question, AiContext context);
  Future<List<AiTask>> createDailyTasks(AiContext context);
  Future<String> createMessage(AiMessageType type, AiContext context);
  Future<String> createReport(AiReportType type, AiContext context);
}

class LocalAiService implements AiService {
  const LocalAiService();

  @override
  Future<String> answer(String question, AiContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final lowerQuestion = question.toLowerCase();
    if (lowerQuestion.contains('चारा')) {
      return 'चारे की जरूरत जानने के लिए गायों की संख्या, उम्र और आज का उपलब्ध stock देखें। अभी ${context.cowCount} गायों का रिकॉर्ड है। सुबह और शाम का stock लिखकर कल की खपत से तुलना करें।';
    }
    if (lowerQuestion.contains('प्लान') || lowerQuestion.contains('काम')) {
      return 'आज का सेवा प्लान तैयार है: सुबह चारा-पानी, फिर सफाई और गायों की सामान्य जांच। शाम को पानी, गोबर सफाई और checklist की समीक्षा करें।';
    }
    if (lowerQuestion.contains('स्वास्थ्य') ||
        lowerQuestion.contains('बीमार')) {
      return 'स्वास्थ्य जांच में खाना, पानी, चलना, आंख और शरीर का तापमान जैसे संकेत नोट करें। गंभीर या असामान्य स्थिति में तुरंत पशु चिकित्सक से संपर्क करें।';
    }
    return 'मैं स्थानीय गौशाला data के आधार पर मदद कर रहा हूं। अभी ${context.cowCount} गायें, ${context.volunteerCount} सेवक और ₹${context.income - context.expense} का दर्ज शेष दिख रहा है। आप दैनिक काम, चारा, स्वास्थ्य, संदेश या रिपोर्ट के बारे में पूछ सकते हैं।';
  }

  @override
  Future<List<AiTask>> createDailyTasks(AiContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return [
      AiTask(name: 'चारा', time: 'सुबह 6:30', priority: 'जरूरी'),
      AiTask(name: 'पानी', time: 'सुबह 7:00 और शाम 5:00', priority: 'जरूरी'),
      AiTask(name: 'सफाई', time: 'सुबह 8:00', priority: 'उच्च'),
      AiTask(name: 'गायों की जांच', time: 'सुबह 9:00', priority: 'उच्च'),
      AiTask(name: 'दवा', time: 'जांच के अनुसार', priority: 'सामान्य'),
      AiTask(name: 'गोबर सफाई', time: 'दोपहर 12:00', priority: 'सामान्य'),
      AiTask(name: 'अन्य सेवा', time: 'शाम 4:00', priority: 'सामान्य'),
    ];
  }

  @override
  Future<String> createMessage(AiMessageType type, AiContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final ending = type == AiMessageType.medical
        ? '\n\nगंभीर स्थिति में पशु चिकित्सक से संपर्क करें।'
        : '';
    return 'जय भोले गौशाला समिति की ओर से सूचना।\n\n${type.label} के लिए सभी सेवकों और शुभचिंतकों से सहयोग का अनुरोध है। गौसेवा में आपका समय, श्रम और सहयोग हमारे लिए बहुत महत्वपूर्ण है। कृपया आज की सेवा में अपनी भागीदारी बताएं।\n\nधन्यवाद। जय गौमाता।$ending';
  }

  @override
  Future<String> createReport(AiReportType type, AiContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final checklist = context.checklist.entries
        .map((entry) => '${entry.key}: ${entry.value ? 'पूर्ण' : 'बाकी'}')
        .join('\n');
    return '${type.label}\n\nगौवंश: ${context.cowCount}\nस्वस्थ रिकॉर्ड: ${context.healthyCowCount}\nसेवक उपस्थित: ${context.presentVolunteerCount}/${context.volunteerCount}\nआय: ₹${context.income}\nव्यय: ₹${context.expense}\nदान रिकॉर्ड: ${context.donationCount}\n\nदैनिक checklist\n$checklist\n\nनोट: यह रिपोर्ट उपलब्ध local app data से बनी है। वास्तविक रजिस्टर से मिलान कर लें।';
  }
}

class GeminiAiService implements AiService {
  const GeminiAiService({this.endpoint});

  final String? endpoint;

  String get _message =>
      'Gemini अभी configured नहीं है। API key को Flutter app में रखने के बजाय secure backend endpoint से जोड़ें। फिलहाल Local AI mode उपलब्ध है।';

  @override
  Future<String> answer(String question, AiContext context) async => _message;

  @override
  Future<List<AiTask>> createDailyTasks(AiContext context) async => [];

  @override
  Future<String> createMessage(AiMessageType type, AiContext context) async =>
      _message;

  @override
  Future<String> createReport(AiReportType type, AiContext context) async =>
      '$_message\n\n${AiPrompts.safety}';
}

class AiServiceFactory {
  const AiServiceFactory();

  AiService createLocal() => const LocalAiService();
  AiService createGemini() => const GeminiAiService();
  AiContextService createContext() => const AiContextService();
}
