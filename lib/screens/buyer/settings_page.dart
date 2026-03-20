import 'package:flutter/material.dart';
import 'edit_profile_page.dart'; // To link Manage Profile
import '../auth/login_page.dart'; // To link Logout

// --- Color Constants ---
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION: ACCOUNT ---
            _buildSectionTitle('Account'),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Manage Profile',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Password & Security',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // --- SECTION: PREFERENCES ---
            _buildSectionTitle('Preferences'),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  trailingText: 'English', // Shows current language
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  trailingText: 'Light', // Shows current theme
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'My Schedule', // Adjusted for student context (was Appointments)
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- SECTION: SUPPORT ---
            _buildSectionTitle('Support'),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.headset_mic_outlined,
                  title: 'Contact Us',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About UMART',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON (Clean iOS Style) ---
            _buildSettingsCard(
              children: [
                ListTile(
                  onTap: () {
                    // Navigate back to Login Page and clear history
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  ),
                  title: const Text(
                    'Log Out', 
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // HELPER WIDGET: Section Title (e.g., Account, Preferences)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
      ),
    );
  }

  // HELPER WIDGET: White Card Container for grouping tiles
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // HELPER WIDGET: Individual Setting Row
  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    String? trailingText, 
    required VoidCallback onTap
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 14),
        ],
      ),
    );
  }

  // HELPER WIDGET: Subtle divider between tiles inside the card
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 60, // Indent so it doesn't go under the icon
      endIndent: 20,
    );
  }
}