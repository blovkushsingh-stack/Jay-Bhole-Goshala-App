import '../app_data.dart';
import '../models/ai_models.dart';

class AiContextService {
  const AiContextService();

  AiContext read() {
    final store = LocalGoshalaStore.instance;
    return AiContext(
      cowCount: store.cows.length,
      healthyCowCount: store.healthyCows,
      volunteerCount: store.volunteers.length,
      presentVolunteerCount: store.presentVolunteers,
      income: store.income,
      expense: store.expense,
      donationCount: store.donors.length,
      checklist: Map<String, bool>.from(store.checklist),
    );
  }
}
