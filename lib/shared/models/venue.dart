import 'package:flutter/foundation.dart';
import 'package:toidym/shared/models/enums.dart';

/// Рабочие часы заведения в пределах суток (минуты от 00:00).
@immutable
class WorkHours {
  const WorkHours({
    required this.openMinuteOfDay,
    required this.closeMinuteOfDay,
  });

  final int openMinuteOfDay;
  final int closeMinuteOfDay;

  String get formatted {
    return '${_formatMinutes(openMinuteOfDay)}–${_formatMinutes(closeMinuteOfDay)}';
  }

  /// Проверяет, укладывается ли интервал [start]..[end] в рабочие часы заведения.
  bool containsWindow(DateTime start, DateTime end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (end.isBefore(start)) {
      return false;
    }
    return startMinutes >= openMinuteOfDay && endMinutes <= closeMinuteOfDay;
  }

  static String _formatMinutes(int totalMinutes) {
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Map<String, dynamic> toJson() => {
        'openMinuteOfDay': openMinuteOfDay,
        'closeMinuteOfDay': closeMinuteOfDay,
      };

  factory WorkHours.fromJson(Map<String, dynamic> json) {
    return WorkHours(
      openMinuteOfDay: (json['openMinuteOfDay'] as num?)?.toInt() ?? 8 * 60,
      closeMinuteOfDay: (json['closeMinuteOfDay'] as num?)?.toInt() ?? 22 * 60,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkHours &&
        other.openMinuteOfDay == openMinuteOfDay &&
        other.closeMinuteOfDay == closeMinuteOfDay;
  }

  @override
  int get hashCode => Object.hash(openMinuteOfDay, closeMinuteOfDay);
}

/// Модель заведения (партнёр toıdym в Астане).
@immutable
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.category,
    required this.district,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewsCount,
    required this.isHalal,
    required this.halalCertStatus,
    required this.workHours,
    required this.phone,
    required this.photo,
    required this.status,
    this.halalCertNumber,
    this.halalCertPhoto,
    this.rejectionFields = const [],
    this.rejectionComment,
    this.ownerId,
  });

  final String id;
  final String name;
  final VenueCategory category;
  final AstanaDistrict district;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final int reviewsCount;
  final bool isHalal;
  final HalalCertStatus halalCertStatus;
  final WorkHours workHours;
  final String phone;
  final String photo;
  final VenueStatus status;
  final String? halalCertNumber;
  final String? halalCertPhoto;
  final List<String> rejectionFields;
  final String? rejectionComment;
  final String? ownerId;

  bool get hasVerifiedHalalBadge =>
      isHalal && halalCertStatus == HalalCertStatus.verified;

  /// Возвращает URL/Data URL загруженного фото сертификата Халал.
  String? get resolvedHalalCertPhoto {
    final photoUrl = halalCertPhoto?.trim();
    if (photoUrl != null && photoUrl.isNotEmpty) return photoUrl;
    final legacy = halalCertNumber?.trim();
    if (legacy != null &&
        (legacy.startsWith('data:image/') ||
            legacy.startsWith('http://') ||
            legacy.startsWith('https://'))) {
      return legacy;
    }
    return null;
  }

  Venue copyWith({
    String? id,
    String? name,
    VenueCategory? category,
    AstanaDistrict? district,
    String? address,
    double? lat,
    double? lng,
    double? rating,
    int? reviewsCount,
    bool? isHalal,
    HalalCertStatus? halalCertStatus,
    WorkHours? workHours,
    String? phone,
    String? photo,
    VenueStatus? status,
    String? halalCertNumber,
    String? halalCertPhoto,
    List<String>? rejectionFields,
    String? rejectionComment,
    String? ownerId,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      district: district ?? this.district,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isHalal: isHalal ?? this.isHalal,
      halalCertStatus: halalCertStatus ?? this.halalCertStatus,
      workHours: workHours ?? this.workHours,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      status: status ?? this.status,
      halalCertNumber: halalCertNumber ?? this.halalCertNumber,
      halalCertPhoto: halalCertPhoto ?? this.halalCertPhoto,
      rejectionFields: rejectionFields ?? this.rejectionFields,
      rejectionComment: rejectionComment ?? this.rejectionComment,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.apiValue,
        'district': district.code,
        'address': address,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'isHalal': isHalal,
        'halalCertStatus': halalCertStatus.apiValue,
        'workHours': workHours.toJson(),
        'phone': phone,
        'photo': photo,
        'status': status.apiValue,
        'halalCertNumber': halalCertNumber,
        'halalCertPhoto': halalCertPhoto,
        'rejectionFields': rejectionFields,
        'rejectionComment': rejectionComment,
        'ownerId': ownerId,
      };

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: VenueCategory.fromApi(json['category'] as String?),
      district: AstanaDistrict.fromCode(json['district'] as String?),
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 51.1282,
      lng: (json['lng'] as num?)?.toDouble() ?? 71.4304,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      isHalal: json['isHalal'] as bool? ?? false,
      halalCertStatus: HalalCertStatus.fromApi(
        json['halalCertStatus'] as String?,
      ),
      workHours: json['workHours'] is Map<String, dynamic>
          ? WorkHours.fromJson(json['workHours'] as Map<String, dynamic>)
          : const WorkHours(openMinuteOfDay: 8 * 60, closeMinuteOfDay: 22 * 60),
      phone: json['phone'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      status: VenueStatus.fromApi(json['status'] as String?),
      halalCertNumber: json['halalCertNumber'] as String?,
      halalCertPhoto: json['halalCertPhoto'] as String?,
      rejectionFields: (json['rejectionFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      rejectionComment: json['rejectionComment'] as String?,
      ownerId: json['ownerId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Venue &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.district == district &&
        other.address == address &&
        other.lat == lat &&
        other.lng == lng &&
        other.rating == rating &&
        other.reviewsCount == reviewsCount &&
        other.isHalal == isHalal &&
        other.halalCertStatus == halalCertStatus &&
        other.workHours == workHours &&
        other.phone == phone &&
        other.photo == photo &&
        other.status == status &&
        other.halalCertNumber == halalCertNumber &&
        other.halalCertPhoto == halalCertPhoto &&
        listEquals(other.rejectionFields, rejectionFields) &&
        other.rejectionComment == rejectionComment &&
        other.ownerId == ownerId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        district,
        address,
        lat,
        lng,
        rating,
        reviewsCount,
        isHalal,
        halalCertStatus,
        workHours,
        phone,
        photo,
        status,
        halalCertNumber,
        halalCertPhoto,
        Object.hashAll(rejectionFields),
        rejectionComment,
        ownerId,
      );
}
