import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatefulWidget {
  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 100),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 30),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Last Updated: January 9, 2026', isHeader: true),
          SizedBox(height: 20),
          
          _buildParagraph('Hiotaku ("we," "our," or "us"), owned and operated by NEHU SINGH, respects your privacy and is committed to protecting your personal information.'),
          _buildParagraph('This Privacy Policy explains how we collect, use, store, and protect your data when you use the Hiotaku application and related services (the "Service").'),
          _buildParagraph('By using Hiotaku, you agree to the practices described in this Privacy Policy.'),
          
          SizedBox(height: 30),
          _buildSection('1. Information We Collect'),
          
          SizedBox(height: 20),
          _buildSubSection('1.1 Information You Provide'),
          _buildParagraph('We may collect the following information when you use Hiotaku:'),
          _buildBulletPoint('Account details (such as username or basic profile information)'),
          _buildBulletPoint('Messages sent through in-app support or chat systems'),
          _buildBulletPoint('Communications with Hiotaku Agents'),
          _buildParagraph('Hiotaku does not allow public content uploads such as images, videos, or files.'),
          
          SizedBox(height: 20),
          _buildSubSection('1.2 Automatically Collected Information'),
          _buildParagraph('When you use the app, we may automatically collect:'),
          _buildBulletPoint('Device information (device type, OS version)'),
          _buildBulletPoint('App usage data (features used, interactions)'),
          _buildBulletPoint('IP address (for security and analytics)'),
          _buildBulletPoint('Crash logs and performance data'),
          
          SizedBox(height: 30),
          _buildSection('2. How We Use Your Information'),
          _buildParagraph('We use collected information to:'),
          _buildBulletPoint('Provide and maintain the Service'),
          _buildBulletPoint('Enable login and authentication'),
          _buildBulletPoint('Improve app performance and user experience'),
          _buildBulletPoint('Ensure security and prevent misuse'),
          _buildBulletPoint('Respond to support requests'),
          _buildBulletPoint('Display ads (if enabled in the future)'),
          _buildParagraph('We do not sell your personal data.'),
          
          SizedBox(height: 30),
          _buildSection('3. User Interaction & Chats'),
          _buildBulletPoint('Hiotaku allows users to interact via chat systems.'),
          _buildBulletPoint('Chats are user-initiated and not publicly visible.'),
          _buildBulletPoint('Hiotaku does not actively monitor all messages.'),
          _buildBulletPoint('We reserve the right to review messages if required for security, abuse prevention, or legal compliance.'),
          _buildBulletPoint('Users are responsible for the content of their communications.'),
          
          SizedBox(height: 30),
          _buildSection('4. Ads and Analytics'),
          _buildBulletPoint('Hiotaku may display advertisements now or in the future.'),
          _buildBulletPoint('Ads will not require forced viewing.'),
          _buildBulletPoint('We may use third-party ad providers.'),
          _buildBulletPoint('Analytics tools may be used to understand app usage.'),
          _buildBulletPoint('These third parties may collect data in accordance with their own privacy policies.'),
          
          SizedBox(height: 30),
          _buildSection('5. Third-Party Services'),
          _buildParagraph('Hiotaku uses third-party services such as:'),
          _buildBulletPoint('Authentication services'),
          _buildBulletPoint('Cloud storage'),
          _buildBulletPoint('Analytics tools (e.g., Firebase, Google services)'),
          _buildParagraph('These services operate under their own privacy policies.'),
          _buildParagraph('Hiotaku is not responsible for how third-party services handle your data.'),
          
          SizedBox(height: 30),
          _buildSection('6. Data Security'),
          _buildParagraph('We take reasonable measures to protect your information, including:'),
          _buildBulletPoint('Secure authentication systems'),
          _buildBulletPoint('Encrypted connections where applicable'),
          _buildBulletPoint('Restricted access to sensitive data'),
          _buildParagraph('However, no system is 100% secure. You use the Service at your own risk.'),
          
          SizedBox(height: 30),
          _buildSection('7. Data Retention'),
          _buildBulletPoint('We retain user data only as long as necessary to provide the Service or comply with legal obligations.'),
          _buildBulletPoint('Support messages and logs may be stored for operational and security purposes.'),
          _buildBulletPoint('Accounts may be deleted or suspended as per our Terms of Service.'),
          
          SizedBox(height: 30),
          _buildSection('8. Children\'s Privacy'),
          _buildBulletPoint('Hiotaku is not specifically directed at children.'),
          _buildBulletPoint('Parents or guardians are responsible for monitoring minors\' use of the app.'),
          _buildBulletPoint('We do not knowingly collect sensitive personal data from children.'),
          _buildBulletPoint('If you believe a minor has provided personal data without consent, contact support.'),
          
          SizedBox(height: 30),
          _buildSection('9. Your Rights'),
          _buildParagraph('Depending on applicable law, you may have the right to:'),
          _buildBulletPoint('Access your personal information'),
          _buildBulletPoint('Request correction or deletion'),
          _buildBulletPoint('Contact support regarding privacy concerns'),
          _buildParagraph('Requests can be made via the in-app support system.'),
          
          SizedBox(height: 30),
          _buildSection('10. Changes to This Privacy Policy'),
          _buildBulletPoint('We may update this Privacy Policy from time to time.'),
          _buildBulletPoint('Changes take effect immediately upon posting.'),
          _buildBulletPoint('Continued use of Hiotaku constitutes acceptance of the updated policy.'),
          
          SizedBox(height: 30),
          _buildSection('11. Governing Law'),
          _buildBulletPoint('This Privacy Policy is governed by the laws of India.'),
          _buildBulletPoint('Any disputes shall fall under the jurisdiction of Indian courts.'),
          
          SizedBox(height: 30),
          _buildSection('12. Contact Us'),
          _buildParagraph('For privacy-related questions or concerns:'),
          _buildBulletPoint('Use the in-app support system to contact Hiotaku Agents'),
          
          SizedBox(height: 30),
          _buildParagraph('By using Hiotaku, you acknowledge that you have read and understood this Privacy Policy.', isFooter: true),
        ],
      ),
    );
  }

  Widget _buildSection(String title, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          color: isHeader ? Color(0xFFFF8C00) : Colors.white,
          fontSize: isHeader ? 16 : 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubSection(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, {bool isFooter = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Text(
        text,
        style: TextStyle(
          color: isFooter ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.8),
          fontSize: 14,
          height: 1.5,
          fontWeight: isFooter ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10, left: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Color(0xFFFF8C00),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
