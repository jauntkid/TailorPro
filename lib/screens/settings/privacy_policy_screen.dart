import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontSize: 14,
      height: 1.6,
      color: cs.onSurface.withValues(alpha: 0.75),
    );
    final headingStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy & Terms')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Text(
            'Godukaan Privacy Policy',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: June 2025',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),

          _PolicySection(
            heading: '1. Information We Collect',
            headingStyle: headingStyle,
            content:
                'Godukaan collects and stores the following information to provide tailor shop management services:\n\n'
                '• Account information: Your name, email address, and profile picture (via Google Sign-In).\n'
                '• Customer data: Names, phone numbers, email addresses, and physical addresses of your clients that you enter.\n'
                '• Order data: Order details, garment measurements, due dates, pricing, payment records, and notes.\n'
                '• Reference images: Photos you upload for order references.\n'
                '• Device contacts: Only when you explicitly choose to import a contact. We access individual contacts, not your entire address book.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '2. How We Use Your Information',
            headingStyle: headingStyle,
            content:
                'Your data is used solely to provide and improve the Godukaan app experience:\n\n'
                '• Store and manage your customer and order records.\n'
                '• Generate invoices and bills.\n'
                '• Send order notifications via WhatsApp (initiated by you).\n'
                '• Display analytics and reports about your business.\n'
                '• Sync data across your devices in real time.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '3. Data Storage & Security',
            headingStyle: headingStyle,
            content:
                'Your data is stored securely using Google Firebase services:\n\n'
                '• Cloud Firestore: Customer, order, and settings data is stored in Google Cloud Firestore with encryption at rest and in transit.\n'
                '• Firebase Storage: Reference images are uploaded to Firebase Cloud Storage.\n'
                '• Firebase Authentication: Your sign-in credentials are managed by Firebase Auth with industry-standard security.\n'
                '• All data is scoped to your store account — other users cannot access your data.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '4. Third-Party Services',
            headingStyle: headingStyle,
            content: 'Godukaan uses the following third-party services:\n\n'
                '• Google Firebase (Authentication, Firestore, Storage) — for secure cloud data storage and authentication.\n'
                '• Google Sign-In — for account authentication.\n'
                '• WhatsApp — for sending order notifications (messages are composed locally and sent via the WhatsApp app on your device).\n\n'
                'These services have their own privacy policies. We recommend reviewing them:\n'
                '• Google Privacy Policy: https://policies.google.com/privacy\n'
                '• WhatsApp Privacy Policy: https://www.whatsapp.com/legal/privacy-policy',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '5. Device Permissions',
            headingStyle: headingStyle,
            content:
                'Godukaan may request the following device permissions:\n\n'
                '• Camera & Photos: To capture or select reference images for orders.\n'
                '• Contacts: To import customer details from your device contacts (only when you choose to).\n'
                '• Internet: To sync data with Firebase cloud services.\n\n'
                'All permissions are optional and requested only when the related feature is used.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '6. Data Sharing',
            headingStyle: headingStyle,
            content:
                'We do not sell, trade, or share your personal data or your customers\' data with any third parties for marketing or advertising purposes.\n\n'
                'Data may be shared only:\n'
                '• With Firebase/Google for the purpose of cloud storage and authentication (as described above).\n'
                '• If required by law or to protect our rights.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '7. Data Retention & Deletion',
            headingStyle: headingStyle,
            content:
                '• Your data is retained as long as your account is active.\n'
                '• You can delete individual customers, orders, and measurement records at any time from within the app.\n'
                '• To request complete account and data deletion, contact us at the email below.\n'
                '• Upon account deletion, all associated data will be permanently removed from our servers within 30 days.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '8. Children\'s Privacy',
            headingStyle: headingStyle,
            content:
                'Godukaan is not intended for use by children under 13. We do not knowingly collect personal information from children.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '9. Changes to This Policy',
            headingStyle: headingStyle,
            content:
                'We may update this privacy policy from time to time. Changes will be reflected in the app with an updated "Last updated" date. Continued use of the app after changes constitutes acceptance of the revised policy.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '10. Terms of Service',
            headingStyle: headingStyle,
            content: 'By using Godukaan, you agree to the following terms:\n\n'
                '• You are responsible for the accuracy of customer and order data you enter.\n'
                '• You will not use the app for any unlawful purpose.\n'
                '• The app is provided "as is" without warranties of any kind.\n'
                '• We are not liable for any data loss due to device failure, network issues, or other circumstances beyond our control.\n'
                '• We reserve the right to modify or discontinue the service at any time.',
            textStyle: textStyle,
          ),

          _PolicySection(
            heading: '11. Contact Us',
            headingStyle: headingStyle,
            content:
                'If you have any questions about this privacy policy, your data, or wish to request data deletion, please contact us:\n\n'
                '• Email: support@godukaan.app\n'
                '• In-app: Settings → About',
            textStyle: textStyle,
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2025 Godukaan. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String heading;
  final TextStyle headingStyle;
  final String content;
  final TextStyle textStyle;

  const _PolicySection({
    required this.heading,
    required this.headingStyle,
    required this.content,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: headingStyle),
          const SizedBox(height: 8),
          Text(content, style: textStyle),
        ],
      ),
    );
  }
}
