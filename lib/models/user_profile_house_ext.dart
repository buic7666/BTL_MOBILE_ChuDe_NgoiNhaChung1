import 'user_profile.dart';

// Utility to track if a user is in a house (using cache only)
extension UserProfileHouseExt on UserProfile {
  static bool _userInHouseCache = false;
  
  bool get isInHouse {
    return _userInHouseCache;
  }
  
  static Future<void> initializeFromStorage() async {
    // No storage needed, just reset cache on app start
    _userInHouseCache = false;
  }
  
  static Future<void> setUserInHouse(bool value) async {
    _userInHouseCache = value;
    print('User in house status set to: $value');
  }
}
