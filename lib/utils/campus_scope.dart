/// UiTM Perlis campus scope for UMart (FYP).
/// New sign-ups are tagged in Firestore; the register screen states Perlis-only use.
/// Login is not blocked on [campus] — existing accounts without the tag still work.
const String kCampusId = 'perlis';
const String kCampusDisplayName = 'UiTM Perlis';

Map<String, String> perlisCampusFirestoreFields() => {
      'campus': kCampusId,
      'campusName': kCampusDisplayName,
    };

bool isUmartAdminEmail(String? email) =>
    email?.trim().toLowerCase() == 'admin@umart.com';

bool userHasPerlisCampus(Map<String, dynamic>? data) {
  if (data == null) return false;
  final campus = (data['campus'] ?? '').toString().trim().toLowerCase();
  return campus == kCampusId;
}

String campusLabelFromData(
  Map<String, dynamic>? data, {
  String fallback = kCampusDisplayName,
}) {
  final name = (data?['campusName'] ?? '').toString().trim();
  if (name.isNotEmpty) return name;
  if (userHasPerlisCampus(data)) return kCampusDisplayName;
  return fallback;
}
