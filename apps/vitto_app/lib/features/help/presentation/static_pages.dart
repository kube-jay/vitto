import 'package:flutter/material.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/common.dart';

/// How Vitto works + safety guidance (DEC-10: no chatbot).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = [
      (Icons.search, l10n.helpStep1Title, l10n.helpStep1Body),
      (Icons.chat_bubble_outline, l10n.helpStep2Title, l10n.helpStep2Body),
      (Icons.handshake_outlined, l10n.helpStep3Title, l10n.helpStep3Body),
      (Icons.verified_user_outlined, l10n.helpStep4Title, l10n.helpStep4Body),
      (Icons.star_outline, l10n.helpStep5Title, l10n.helpStep5Body),
    ];
    return PageBody(
      children: [
        Text(l10n.helpTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final (icon, title, body) in steps)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: VittoColors.navySoft,
              child: Icon(icon, color: VittoColors.navy),
            ),
            title: Text(title, style: theme.textTheme.titleMedium),
            subtitle: Text(body),
          ),
        SectionTitle(l10n.safetyTitle),
        Text(l10n.safetyBody),
        SectionTitle(l10n.prohibitedTitle),
        Text(l10n.prohibitedBody),
        SectionTitle(l10n.supportTitle),
        Text(l10n.supportBody),
      ],
    );
  }
}

/// Placeholder legal text. Must be replaced after legal review for
/// Nigeria and Benin before launch (Part II §44.3).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.terms});

  final bool terms;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageBody(
      children: [
        Text(
          terms ? l10n.screenTerms : l10n.screenPrivacy,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          color: VittoColors.navySoft,
          child: Text(l10n.legalDraftNotice),
        ),
        const SizedBox(height: 16),
        Text(terms ? l10n.termsBody : l10n.privacyBody),
      ],
    );
  }
}
