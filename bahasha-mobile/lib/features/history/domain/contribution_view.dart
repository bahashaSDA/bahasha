import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/local_database.dart';
import '../../../core/theme/app_colors.dart';

/// A presentation view over a stored [Contribution]: parses the allocation JSON,
/// maps the raw status to a label/colour, and builds the shareable receipt text.
class ContributionView {
  ContributionView(this.row)
      : allocations = _parse(row.allocationsJson);

  final Contribution row;
  final List<({String code, String name, int amount})> allocations;

  int get total => row.totalAmount;
  DateTime get date => row.createdAt;

  static final _money = NumberFormat.currency(locale: 'en_KE', symbol: 'KSh ', decimalDigits: 0);
  static final _dateFmt = DateFormat('d MMM yyyy, h:mm a');

  String get amountLabel => _money.format(total);
  String get dateLabel => _dateFmt.format(date);

  ({String label, Color color, Color bg}) get statusChip {
    switch (row.status) {
      case 'completed':
        return (label: 'Completed', color: const Color(0xFF2F7D3A), bg: AppColors.categoryGreen);
      case 'processing':
      case 'sent':
      case 'transmitting':
        return (label: 'Processing', color: const Color(0xFF1C7FA0), bg: AppColors.categoryCyan);
      case 'queued':
        return (label: 'Queued', color: AppColors.ink, bg: AppColors.panelGreen);
      case 'failed':
        return (label: 'Failed', color: Colors.white, bg: const Color(0xFFE03131));
      case 'cancelled':
        return (label: 'Cancelled', color: AppColors.ink, bg: const Color(0xFFE8E8EE));
      default:
        return (label: row.status, color: AppColors.ink, bg: AppColors.panelGreen);
    }
  }

  /// Human-friendly category name from its code (fallback to a title-cased code).
  static String niceName(String code) {
    const names = {
      'tithe': "God's Tithe",
      'combined_offering': 'Combined Offering',
      'local_church_budget': 'Local Church Budget (LCB) / AEMR',
      'church_building': 'Church Building / Development',
      'church_evangelism': 'Church Evangelism',
      'conference_evangelism': 'Conference Evangelism',
      'camp_meeting_offering': 'Camp Meeting Offering',
      'camp_meeting_expenses': 'Camp Meeting Expenses',
      'thanksgiving': 'Thanksgiving',
      'welfare': 'Welfare',
      'station_fund': 'Station Fund',
      'others': 'Others',
    };
    return names[code] ??
        code.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  /// The text shared via the Android share sheet.
  String get shareText {
    final buffer = StringBuffer()
      ..writeln('Bahasha contribution')
      ..writeln('Date: $dateLabel')
      ..writeln('Status: ${statusChip.label}')
      ..writeln('');
    for (final a in allocations) {
      buffer.writeln('• ${a.name}: ${_money.format(a.amount)}');
    }
    buffer
      ..writeln('')
      ..writeln('Total: $amountLabel')
      ..writeln('Ref: ${row.id.substring(0, 8).toUpperCase()}');
    return buffer.toString();
  }

  static List<({String code, String name, int amount})> _parse(String json) {
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return list
          .map((m) => (
                code: m['categoryCode'] as String,
                name: niceName(m['categoryCode'] as String),
                amount: (m['amount'] as num).toInt(),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
