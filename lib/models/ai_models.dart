enum AiMessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.text, required this.role, this.createdAt});

  final String text;
  final AiMessageRole role;
  final DateTime? createdAt;
}

class AiTask {
  AiTask({
    required this.name,
    required this.time,
    required this.priority,
    this.completed = false,
  });

  final String name;
  final String time;
  final String priority;
  bool completed;
}

class AiContext {
  const AiContext({
    required this.cowCount,
    required this.healthyCowCount,
    required this.volunteerCount,
    required this.presentVolunteerCount,
    required this.income,
    required this.expense,
    required this.donationCount,
    required this.checklist,
  });

  final int cowCount;
  final int healthyCowCount;
  final int volunteerCount;
  final int presentVolunteerCount;
  final int income;
  final int expense;
  final int donationCount;
  final Map<String, bool> checklist;
}

enum AiReportType {
  daily('दैनिक सेवा रिपोर्ट'),
  weekly('साप्ताहिक रिपोर्ट'),
  monthly('मासिक रिपोर्ट'),
  donations('दान summary'),
  finance('आय-व्यय summary'),
  health('गायों की health summary'),
  volunteers('श्रमदान summary');

  const AiReportType(this.label);
  final String label;
}

enum AiMessageType {
  volunteer('श्रमदान सूचना'),
  meeting('बैठक सूचना'),
  donation('दान अपील'),
  fodder('चारा सेवा अभियान'),
  medical('चिकित्सा शिविर'),
  general('सामान्य गौशाला सूचना');

  const AiMessageType(this.label);
  final String label;
}
