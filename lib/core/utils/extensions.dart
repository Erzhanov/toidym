import 'package:flutter/material.dart';
import 'package:toidym/core/l10n/app_localizations.dart';
import 'package:toidym/domain/rules/business_rules.dart';
import 'package:toidym/shared/models/enums.dart';

/// Удобные расширения для работы с темой и локализацией из контекста.
extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

extension AstanaDistrictL10n on AstanaDistrict {
  String label(AppLocalizations l10n) {
    return switch (this) {
      AstanaDistrict.esil => l10n.districtEsil,
      AstanaDistrict.almaty => l10n.districtAlmaty,
      AstanaDistrict.saryarka => l10n.districtSaryarka,
      AstanaDistrict.baiqonyr => l10n.districtBaiqonyr,
    };
  }
}

extension BoxFilterChipL10n on BoxFilterChip {
  String label(AppLocalizations l10n) {
    return switch (this) {
      BoxFilterChip.all => l10n.categoryAll,
      BoxFilterChip.bakery => l10n.categoryBakery,
      BoxFilterChip.hotFood => l10n.categoryHotFood,
      BoxFilterChip.halal => l10n.categoryHalal,
      BoxFilterChip.coffee => l10n.categoryCoffee,
    };
  }
}

extension BoxCategoryL10n on BoxCategory {
  String label(AppLocalizations l10n) {
    return switch (this) {
      BoxCategory.bakery => l10n.categoryBakery,
      BoxCategory.hotFood => l10n.categoryHotFood,
      BoxCategory.coffee => l10n.categoryCoffee,
    };
  }
}

extension VenueCategoryL10n on VenueCategory {
  String label(AppLocalizations l10n) {
    return switch (this) {
      VenueCategory.bakery => l10n.categoryBakery,
      VenueCategory.hotFood => l10n.categoryHotFood,
      VenueCategory.coffee => l10n.categoryCoffee,
      VenueCategory.grocery => l10n.categoryGrocery,
    };
  }
}

extension VenueStatusL10n on VenueStatus {
  String label(AppLocalizations l10n) {
    return switch (this) {
      VenueStatus.pending => l10n.venueStatusPending,
      VenueStatus.approved => l10n.venueStatusApproved,
      VenueStatus.rejected => l10n.venueStatusRejected,
      VenueStatus.banned => l10n.venueStatusBanned,
    };
  }
}

extension OrderStatusL10n on OrderStatus {
  String label(AppLocalizations l10n) {
    return switch (this) {
      OrderStatus.reserved => l10n.orderStatusReserved,
      OrderStatus.completed => l10n.orderStatusCompleted,
      OrderStatus.cancelledByUser => l10n.orderStatusCancelledByUser,
      OrderStatus.cancelledByVenue => l10n.orderStatusCancelledByVenue,
      OrderStatus.noShow => l10n.orderStatusNoShow,
    };
  }
}

extension QyzylKitapAnimalL10n on QyzylKitapAnimal {
  String label(AppLocalizations l10n) {
    return switch (this) {
      QyzylKitapAnimal.qumbek => l10n.animalQumbek,
      QyzylKitapAnimal.irbis => l10n.animalIrbis,
      QyzylKitapAnimal.saigak => l10n.animalSaigak,
      QyzylKitapAnimal.seal => l10n.animalSeal,
    };
  }
}

extension PaymentMethodL10n on PaymentMethod {
  String label(AppLocalizations l10n) {
    return switch (this) {
      PaymentMethod.onSite => l10n.paymentOnSite,
    };
  }
}

extension DietaryPreferenceL10n on DietaryPreference {
  String label(AppLocalizations l10n) {
    return switch (this) {
      DietaryPreference.halalOnly => l10n.dietHalalOnly,
      DietaryPreference.vegetarian => l10n.dietVegetarian,
      DietaryPreference.nutFree => l10n.dietNutFree,
    };
  }
}

extension BoxSortOptionL10n on BoxSortOption {
  String label(AppLocalizations l10n) {
    return switch (this) {
      BoxSortOption.nearest => l10n.sortNearest,
      BoxSortOption.endingSoon => l10n.sortEndingSoon,
      BoxSortOption.maxDiscount => l10n.sortMaxDiscount,
    };
  }
}

extension HalalCertStatusL10n on HalalCertStatus {
  String label(AppLocalizations l10n) {
    return switch (this) {
      HalalCertStatus.verified => l10n.adminHalalStatusVerified,
      HalalCertStatus.pending => l10n.adminHalalStatusPending,
      HalalCertStatus.rejected => l10n.adminHalalStatusRejected,
      HalalCertStatus.none => l10n.adminHalalStatusNone,
    };
  }
}

extension ComplaintStatusL10n on ComplaintStatus {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ComplaintStatus.none => '',
      ComplaintStatus.open => l10n.adminComplaintStatusOpen,
      ComplaintStatus.inReview => l10n.adminComplaintStatusInReview,
      ComplaintStatus.resolved => l10n.adminComplaintStatusResolved,
    };
  }
}

extension BoxStatusL10n on BoxStatus {
  String label(AppLocalizations l10n) {
    return switch (this) {
      BoxStatus.active => l10n.adminBoxStatusActive,
      BoxStatus.soldOut => l10n.adminBoxStatusSoldOut,
      BoxStatus.disabled => l10n.adminBoxStatusDisabled,
      BoxStatus.expired => l10n.adminBoxStatusExpired,
    };
  }
}

extension BusinessRuleViolationL10n on BusinessRuleViolation {
  String label(AppLocalizations l10n) {
    return switch (this) {
      BusinessRuleViolation.invalidPrice => l10n.ruleInvalidPrice,
      BusinessRuleViolation.invalidQuantity => l10n.ruleInvalidQuantity,
      BusinessRuleViolation.discountBelowMinimum => l10n.ruleDiscountTooLow,
      BusinessRuleViolation.pickupWindowTooShort => l10n.ruleWindowTooShort,
      BusinessRuleViolation.pickupWindowOutsideWorkHours =>
        l10n.ruleWindowOutsideHours,
      BusinessRuleViolation.publishTooLate => l10n.rulePublishTooLate,
      BusinessRuleViolation.halalCertNotVerified => l10n.ruleHalalCertRequired,
      BusinessRuleViolation.prohibitedContent => l10n.ruleProhibitedItems,
    };
  }
}
