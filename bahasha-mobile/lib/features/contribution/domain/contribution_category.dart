import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A contribution category as shown on the giving screen.
///
/// The offertory redesign represents each category with a fruit image: choosing
/// a fruit adds that giving type to the basket. [asset] is the fruit photo,
/// [giveLabel] fills the "How much ... are you giving?" prompt.
///
/// Codes are identical to the backend reference rows (contribution_categories);
/// the ingest RPC rejects any unknown code, so this list and the seed migration
/// (0017) must stay in lock-step.
@immutable
class ContributionCategory {
  const ContributionCategory({
    required this.code,
    required this.name,
    required this.asset,
    required this.giveLabel,
    this.description = '',
    this.fixedAmount,
    this.percentageHint,
  });

  final String code;
  final String name;

  /// Fruit image for this category, under assets/fruits/.
  final String asset;

  /// Lowercase phrase used in the basket prompt, e.g. "tithe" → "How much tithe
  /// are you giving?".
  final String giveLabel;

  final String description;
  final double? fixedAmount;
  final double? percentageHint;

  /// The row colour is a function of position, cycling the Figma palette.
  /// Retained for the legacy Customize screen.
  static Color colorForIndex(int index) =>
      AppColors.categoryCycle[index % AppColors.categoryCycle.length];

  /// The ten giving types of the offertory design, in Figma grid order
  /// (row-major, two columns). Codes match seed migration 0017.
  static const List<ContributionCategory> seed = <ContributionCategory>[
    ContributionCategory(code: 'tithe', name: 'Tithe', asset: 'assets/fruits/tithe.png', giveLabel: 'tithe', percentageHint: 10),
    ContributionCategory(code: 'offering', name: 'Offering', asset: 'assets/fruits/offering.png', giveLabel: 'offering'),
    ContributionCategory(code: 'church_budget', name: 'Church budget', asset: 'assets/fruits/church_budget.png', giveLabel: 'church budget'),
    ContributionCategory(code: 'camp_offering', name: 'Camp offering', asset: 'assets/fruits/camp_offering.png', giveLabel: 'camp offering'),
    ContributionCategory(code: 'camp_budget', name: 'Camp budget', asset: 'assets/fruits/camp_budget.png', giveLabel: 'camp budget'),
    ContributionCategory(code: 'mission', name: 'Mission', asset: 'assets/fruits/mission.png', giveLabel: 'mission'),
    ContributionCategory(code: 'development', name: 'Development', asset: 'assets/fruits/development.png', giveLabel: 'development'),
    ContributionCategory(code: 'children_ministry', name: 'Children ministry', asset: 'assets/fruits/children_ministry.png', giveLabel: 'children ministry'),
    ContributionCategory(code: 'women_ministry', name: 'Women ministry', asset: 'assets/fruits/women_ministry.png', giveLabel: 'women ministry'),
    ContributionCategory(code: 'adventist_men', name: 'Adventist men', asset: 'assets/fruits/adventist_men.png', giveLabel: 'adventist men'),
  ];
}
