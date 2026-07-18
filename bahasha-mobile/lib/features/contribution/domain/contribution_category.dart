import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A contribution category as shown on the giving screen.
///
/// In production these are fetched from the backend (`/churches/:id/categories`)
/// so the list changes without an app release, and cached locally for offline
/// use. [seed] mirrors the server's launch set so a first, never-synced launch
/// still shows the correct twelve categories.
@immutable
class ContributionCategory {
  const ContributionCategory({
    required this.code,
    required this.name,
    required this.description,
    this.fixedAmount,
    this.percentageHint,
  });

  final String code;
  final String name;
  final String description;

  /// Categories with a mandated amount (e.g. Station Fund, KSh 200) are shown
  /// with the amount preset and not freely editable.
  final double? fixedAmount;

  /// Categories expressed as a share of income (e.g. God's Tithe, 10%). Used
  /// only to prefill a suggestion; the giver always confirms.
  final double? percentageHint;

  /// The row colour is a function of position, cycling the Figma palette.
  static Color colorForIndex(int index) =>
      AppColors.categoryCycle[index % AppColors.categoryCycle.length];

  /// The launch categories, identical in code and order to the backend seed
  /// (`0008_seed_reference_data.sql`).
  static const List<ContributionCategory> seed = <ContributionCategory>[
    ContributionCategory(
      code: 'tithe',
      name: "God's Tithe",
      description:
          'Your contributions support your local conference pastors and church conference workers',
      percentageHint: 10,
    ),
    ContributionCategory(
      code: 'combined_offering',
      name: 'Combined Offering',
      description: 'Shared offering distributed across local, conference and union funds',
    ),
    ContributionCategory(
      code: 'local_church_budget',
      name: 'Local Church Budget (LCB) / AEMR',
      description: 'Runs the day-to-day operations of your local church',
    ),
    ContributionCategory(
      code: 'church_building',
      name: 'Church Building / Development',
      description: 'Construction and development of your local church',
    ),
    ContributionCategory(
      code: 'church_evangelism',
      name: 'Church Evangelism',
      description: 'Supports evangelism run by your local church',
    ),
    ContributionCategory(
      code: 'conference_evangelism',
      name: 'Conference Evangelism',
      description: 'Supports evangelism coordinated at conference level',
    ),
    ContributionCategory(
      code: 'camp_meeting_offering',
      name: 'Camp Meeting Offering',
      description: 'Offering collected toward camp meeting',
    ),
    ContributionCategory(
      code: 'camp_meeting_expenses',
      name: 'Camp Meeting Expenses',
      description: 'Covers the running costs of camp meeting',
    ),
    ContributionCategory(
      code: 'thanksgiving',
      name: 'Thanksgiving',
      description: 'A thanksgiving offering',
    ),
    ContributionCategory(
      code: 'welfare',
      name: 'Welfare',
      description: 'Supports members of the church family in need',
    ),
    ContributionCategory(
      code: 'station_fund',
      name: 'Station Fund',
      description: 'Fixed station contribution of KSh 200',
      fixedAmount: 200,
    ),
    ContributionCategory(
      code: 'others',
      name: 'Others',
      description: 'Any other contribution not covered above',
    ),
  ];
}
