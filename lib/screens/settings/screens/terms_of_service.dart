import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsOfServicePage extends StatefulWidget {
  @override
  _TermsOfServicePageState createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> with TickerProviderStateMixin {
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
                      'Terms of Service',
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
          
          _buildParagraph('Welcome to Hiotaku.'),
          _buildParagraph('These Terms of Service ("Terms") govern your access to and use of the Hiotaku mobile application, website, and related services (collectively, the "Service"), owned and operated by NEHU SINGH ("Hiotaku," "we," "us," or "our").'),
          _buildParagraph('By accessing or using Hiotaku, you agree to be bound by these Terms. If you do not agree with any part of these Terms, you must not use the Service.'),
          
          SizedBox(height: 30),
          _buildSection('1. Description of the Service'),
          _buildParagraph('Hiotaku is an Anime OTT Platform that allows users to browse, stream anime-related content, and interact with other users through in-app features such as chat and communication tools.'),
          _buildParagraph('The Service is provided on an "as available" basis and may change, update, or be discontinued at any time without prior notice.'),
          
          SizedBox(height: 30),
          _buildSection('2. Eligibility and Age Requirement'),
          _buildParagraph('Hiotaku is intended for a general audience. However:'),
          _buildBulletPoint('Users under the age of 18 should use the Service under parental or guardian supervision.'),
          _buildBulletPoint('Parents or legal guardians are solely responsible for monitoring and managing a minor\'s use of the Service.'),
          _buildParagraph('By using Hiotaku, you confirm that you are legally permitted to use the Service under applicable laws in your jurisdiction.'),
          
          SizedBox(height: 30),
          _buildSection('3. Account Access (Login and Guest Use)'),
          _buildParagraph('Hiotaku allows both guest access and registered user accounts.'),
          _buildBulletPoint('Certain features may be limited for guest users.'),
          _buildBulletPoint('You are responsible for maintaining the confidentiality of your account credentials.'),
          _buildBulletPoint('You agree to provide accurate and up-to-date information when creating an account.'),
          _buildBulletPoint('Hiotaku is not responsible for unauthorized access resulting from your failure to secure your account.'),
          
          SizedBox(height: 30),
          _buildSection('4. User Interaction and Communication'),
          _buildParagraph('Hiotaku provides features that allow users to interact with each other, including chat systems.'),
          _buildParagraph('You agree that:'),
          _buildBulletPoint('You will communicate respectfully and lawfully.'),
          _buildBulletPoint('Hiotaku does not actively monitor all user communications.'),
          _buildBulletPoint('Hiotaku is not responsible for user-generated interactions or messages.'),
          _buildBulletPoint('You may report inappropriate behavior using in-app support or reporting tools.'),
          
          SizedBox(height: 30),
          _buildSection('5. Acceptable Use Policy'),
          _buildParagraph('You agree not to use Hiotaku for any unlawful, harmful, or abusive purpose. Prohibited activities include, but are not limited to:'),
          _buildBulletPoint('Harassment, threats, hate speech, or abusive behavior'),
          _buildBulletPoint('Sexual, explicit, or inappropriate conduct'),
          _buildBulletPoint('Impersonation of any person or entity'),
          _buildBulletPoint('Unauthorized access, hacking, scraping, or exploitation of the Service'),
          _buildBulletPoint('Reverse engineering or attempting to damage the app or its infrastructure'),
          _buildBulletPoint('Automated bots or scripts without permission'),
          _buildBulletPoint('Any activity that violates applicable laws or regulations'),
          _buildParagraph('Violation of this policy may result in immediate action, including suspension or termination.'),
          
          SizedBox(height: 30),
          _buildSection('6. User Content Policy'),
          _buildBulletPoint('Hiotaku does not allow users to upload public content such as videos, images, or files.'),
          _buildBulletPoint('Users may interact through communication features only.'),
          _buildBulletPoint('Any misuse of interaction features is strictly prohibited.'),
          
          SizedBox(height: 30),
          _buildSection('7. Ads and Monetization'),
          _buildBulletPoint('Hiotaku may display advertisements now or in the future.'),
          _buildBulletPoint('Advertisements will not require forced viewing.'),
          _buildBulletPoint('Hiotaku reserves the right to introduce, modify, or remove monetization methods at any time.'),
          _buildBulletPoint('Third-party advertising services may be used.'),
          
          SizedBox(height: 30),
          _buildSection('8. Third-Party Services'),
          _buildParagraph('Hiotaku may integrate third-party services such as authentication, analytics, or cloud services (e.g., Firebase, Google services).'),
          _buildParagraph('Hiotaku is not responsible for the content, behavior, or policies of third-party services.'),
          _buildParagraph('Your use of such services is governed by their respective terms and privacy policies.'),
          
          SizedBox(height: 30),
          _buildSection('9. Account Suspension and Termination'),
          _buildParagraph('Hiotaku reserves the right to:'),
          _buildBulletPoint('Suspend or terminate any account'),
          _buildBulletPoint('Restrict access to the Service'),
          _buildBulletPoint('Take such action without prior notice'),
          _buildParagraph('This may occur if you violate these Terms, misuse the Service, or for security, legal, or operational reasons.'),
          _buildParagraph('All decisions made by Hiotaku regarding suspension or termination are final.'),
          
          SizedBox(height: 30),
          _buildSection('10. Intellectual Property Rights'),
          _buildParagraph('All content, branding, logos, design elements, software, and intellectual property associated with Hiotaku are owned by or licensed to Hiotaku.'),
          _buildParagraph('You may not:'),
          _buildBulletPoint('Copy, modify, distribute, sell, or exploit any part of the Service'),
          _buildBulletPoint('Use Hiotaku trademarks or branding without written permission'),
          
          SizedBox(height: 30),
          _buildSection('11. Disclaimer of Warranties'),
          _buildParagraph('Hiotaku is provided on an "as is" and "as available" basis.'),
          _buildParagraph('We make no warranties regarding:'),
          _buildBulletPoint('Service availability or uptime'),
          _buildBulletPoint('Accuracy or reliability of content'),
          _buildBulletPoint('Error-free or uninterrupted operation'),
          _buildParagraph('Use of the Service is at your own risk.'),
          
          SizedBox(height: 30),
          _buildSection('12. Limitation of Liability'),
          _buildParagraph('To the maximum extent permitted by law, Hiotaku and its owner shall not be liable for:'),
          _buildBulletPoint('Any direct or indirect loss or damage'),
          _buildBulletPoint('Data loss or service interruptions'),
          _buildBulletPoint('Financial or consequential damages'),
          
          SizedBox(height: 30),
          _buildSection('13. Privacy Policy'),
          _buildParagraph('Your use of Hiotaku is also governed by our Privacy Policy, which explains how we collect, use, and protect your information.'),
          _buildParagraph('Please review the Privacy Policy carefully.'),
          
          SizedBox(height: 30),
          _buildSection('14. Changes to These Terms'),
          _buildBulletPoint('Hiotaku reserves the right to update or modify these Terms at any time.'),
          _buildBulletPoint('Changes become effective immediately upon posting.'),
          _buildBulletPoint('Continued use of the Service constitutes acceptance of the revised Terms.'),
          
          SizedBox(height: 30),
          _buildSection('15. Governing Law and Jurisdiction'),
          _buildBulletPoint('These Terms shall be governed by and construed in accordance with the laws of India.'),
          _buildBulletPoint('Any disputes shall be subject to the exclusive jurisdiction of the courts of India.'),
          
          SizedBox(height: 30),
          _buildSection('16. Contact and Support'),
          _buildParagraph('For support, questions, or concerns:'),
          _buildBulletPoint('Use the in-app support system to contact Hiotaku Agents'),
          _buildBulletPoint('Or reach out via the official support channel provided within the app'),
          
          SizedBox(height: 30),
          _buildParagraph('By using Hiotaku, you acknowledge that you have read, understood, and agreed to these Terms of Service.', isFooter: true),
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
