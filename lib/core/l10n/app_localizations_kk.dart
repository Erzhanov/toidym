// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'toıdym';

  @override
  String get brandPhrase => 'Ас болсын!';

  @override
  String get brandSlogan => 'Дәмді тағамды −70%-ға дейін құтқар';

  @override
  String get qyzylKitapTitle => 'Қызыл кітап';

  @override
  String get qumbekName => 'Құмбек';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageTitle => 'Қосымша тілі';

  @override
  String get navBoxes => 'Бокстар';

  @override
  String get navMap => 'Карта';

  @override
  String get navOrders => 'Тапсырыстар';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navVenueBoxes => 'Бокстар';

  @override
  String get navVenuePickup => 'Беру';

  @override
  String get navVenueStats => 'Қорытынды';

  @override
  String get districtEsil => 'Есіл';

  @override
  String get districtAlmaty => 'Алматы';

  @override
  String get districtSaryarka => 'Сарыарқа';

  @override
  String get districtBaiqonyr => 'Байқоңыр';

  @override
  String get districtAllAstana => 'Бүкіл Астана';

  @override
  String get cityAstana => 'Астана';

  @override
  String get categoryAll => 'Барлығы';

  @override
  String get categoryBakery => 'Нан-тоқаш';

  @override
  String get categoryHotFood => 'Ыстық тағам';

  @override
  String get categoryHalal => 'Халал';

  @override
  String get categoryCoffee => 'Кофе';

  @override
  String get categoryGrocery => 'Дүкен';

  @override
  String get badgeHalal => 'Халал';

  @override
  String get badgeEndingSoon => 'Таусылуға жақын';

  @override
  String badgeLeftCount(int count) {
    return 'Қалғаны: $count';
  }

  @override
  String get badgeSoldOut => 'Таусылды';

  @override
  String pickupToday(String window) {
    return 'Бүгін алу: $window';
  }

  @override
  String distanceKm(String value) {
    return '$value км';
  }

  @override
  String distanceMeters(int value) {
    return '$value м';
  }

  @override
  String reviewsCountShort(int count) {
    return '($count)';
  }

  @override
  String boxesWaitingCount(int count) {
    return 'Жаныңызда $count бокс күтуде';
  }

  @override
  String get actionStart => 'Бастау';

  @override
  String get actionRepresentVenue => 'Мен мекеме өкілімін';

  @override
  String get actionRetry => 'Қайталау';

  @override
  String actionReserveFor(String price) {
    return '$price бағасына брондау';
  }

  @override
  String actionPayAmount(String price) {
    return '$price төлеу';
  }

  @override
  String get actionLogin => 'Кіру';

  @override
  String get actionLogout => 'Шығу';

  @override
  String get actionDone => 'Дайын';

  @override
  String get actionCancel => 'Болдырмау';

  @override
  String get actionSave => 'Сақтау';

  @override
  String get actionNext => 'Келесі';

  @override
  String get actionBack => 'Артқа';

  @override
  String get actionShare => 'Бөлісу';

  @override
  String get actionDetails => 'Толығырақ';

  @override
  String get actionRoute => 'Бағыт';

  @override
  String get actionCall => 'Қоңырау шалу';

  @override
  String get actionResetFilters => 'Сүзгіні тазалау';

  @override
  String get actionAddToFavorites => 'Таңдаулыларға қосу';

  @override
  String get actionRemoveFromFavorites => 'Таңдаулылардан өшіру';

  @override
  String get actionSwitchToVenue => 'Мекеме режимі';

  @override
  String get actionSwitchToBuyer => 'Сатып алушы';

  @override
  String get actionBecomePartner => 'Серіктес болу';

  @override
  String get stateErrorTitle => 'Жүктеу мүмкін болмады';

  @override
  String get stateErrorSubtitle => 'Байланысты тексеріп, қайта көріңіз';

  @override
  String get stateEmptyBoxesTitle => 'Жақын маңда бокстар әзірге жоқ';

  @override
  String get stateEmptyBoxesSubtitle =>
      'Құмбек жаңа ұсыныстар іздеп жатыр — сәл кейінірек кіріңіз немесе сүзгіні ауыстырыңыз';

  @override
  String get onboardingLocationTitle => 'Бокстарды қайдан құтқарамыз?';

  @override
  String get onboardingLocationSubtitle =>
      'Геолокацияға рұқсат беріңіз немесе Астана ауданын таңдаңыз — аккаунт әзірше қажет емес';

  @override
  String get onboardingDetectLocation => 'Геолокацияны анықтау';

  @override
  String onboardingLocationDetected(String district) {
    return 'Анықталды: Астана, $district';
  }

  @override
  String get onboardingOrChooseDistrict => 'Немесе ауданды қолмен таңдаңыз';

  @override
  String get homeGreeting => 'Сәлем! Бүгін не құтқарамыз?';

  @override
  String homeGreetingNamed(String name) {
    return 'Сәлем, $name! Бокс таңдаңыз';
  }

  @override
  String get homeSearchHint => 'Бокс немесе мекеме іздеу';

  @override
  String get homeViewList => 'Тізім';

  @override
  String get homeViewMap => 'Картада';

  @override
  String get homeNotificationsTitle => 'Хабарламалар';

  @override
  String get homeMarkAllRead => 'Барлығын оқу';

  @override
  String get homeEndingSoonSection => 'Таусылуға жақын';

  @override
  String get homeAllBoxesSection => 'Барлық ұсыныстар';

  @override
  String get homeSimulateError => 'Қате экранын тексеру';

  @override
  String get mapYouAreHere => 'Сіз осындасыз';

  @override
  String get mapCenterOnMe => 'Орталықтау';

  @override
  String get mapOpenInList => 'Тізіммен';

  @override
  String get boxDetailSurpriseTitle => 'Ішінде әдетте не болады';

  @override
  String get boxDetailSurpriseDisclaimer =>
      'Құрамы күн соңында қалған тағамға байланысты. Сипаттамаға сәйкес келмесе — алар кезде бас тартуға болады.';

  @override
  String get boxDetailAllergensTitle => 'Аллергендер';

  @override
  String get boxDetailAllergensEmpty => 'Негізгі аллергендер көрсетілмеген';

  @override
  String get boxDetailAllergensNote =>
      'Аллергия болса, алмас бұрын құрамын сол жерде нақтылаңыз.';

  @override
  String get boxDetailPickupOnlyBadge => 'Тек өзіңіз алып кетесіз';

  @override
  String get boxDetailReviewsTitle => 'Қонақтардың пікірлері';

  @override
  String boxDetailShareMessage(String title, String venue, String price) {
    return 'toıdym арқылы $venue мекемесінен «$title» боксын $price бағасына құтқарып жатырмын!';
  }

  @override
  String boxDetailRouteOpening(String address, String lat, String lng) {
    return '$address (Астана) мекенжайына бағыт: $lat, $lng';
  }

  @override
  String get authPhoneTitle => 'Боксты құтқару үшін кіріңіз';

  @override
  String get authPhoneSubtitle =>
      'Тапсырысты растау үшін SMS арқылы қысқа код жібереміз';

  @override
  String get authPhoneLabel => 'Телефон нөмірі';

  @override
  String get authPhoneHint => '+7 (777) 123-45-67';

  @override
  String get authSendCode => 'Код алу';

  @override
  String get authSmsTitle => 'SMS кодын енгізіңіз';

  @override
  String authSmsSubtitle(String phone) {
    return '$phone нөміріне 4 таңбалы код жібердік';
  }

  @override
  String get authSmsHint => '4 таңбалы кодты енгізіңіз (демо: 1234)';

  @override
  String get authConfirmCode => 'Растау';

  @override
  String get authChangePhone => 'Нөмірді өзгерту';

  @override
  String get authInvalidCode => 'Код қате. Демо үшін 1234 қолданыңыз';

  @override
  String get guestBenefitsTitle => 'Аккаунтқа кіріңіз';

  @override
  String get guestBenefitsSubtitle =>
      'Сүйікті орындарды сақтап, бокстар жинаңыз және «Қызыл кітап» тұрғындарын ашыңыз';

  @override
  String get guestBenefitOrders =>
      'Барлық тапсырыстар тарихы және QR-ға жылдам қол жеткізу';

  @override
  String get guestBenefitStats =>
      'Құтқарылған тағам килограмын және үнемді есептеу';

  @override
  String get guestBenefitKitap =>
      'Сирек кездесетін жануарлар жинағы — «Қызыл кітап»';

  @override
  String get paymentQuantityLabel => 'Бокс саны';

  @override
  String get paymentMethodTitle => 'Төлем тәсілі';

  @override
  String get paymentKaspi => 'Kaspi.kz';

  @override
  String get paymentKaspiHint => 'Шот Kaspi қосымшасына келеді';

  @override
  String get paymentCard => 'Банк картасы';

  @override
  String get paymentCardNumberLabel => 'Карта нөмірі';

  @override
  String get paymentCardExpiryLabel => 'Мерзімі (АА/ЖЖ)';

  @override
  String get paymentCardCvvLabel => 'CVV';

  @override
  String get paymentCardInvalid => 'Карта деректерін тексеріңіз';

  @override
  String get paymentRegularPrice => 'Әдеттегі баға';

  @override
  String get paymentYouSave => 'Сіздің үнеміңіз';

  @override
  String get paymentTotal => 'Барлығы';

  @override
  String get paymentRuleRefund =>
      'Егер мекеме боксты болдырмаса, бронь айыппұлсыз жойылады (Strike берілмейді).';

  @override
  String get paymentRuleCharity =>
      '1 сағат бұрын болдырмай келмесеңіз — Strike беріледі (3 Strike = 30 күнге бұғаттау).';

  @override
  String get paymentSimulateError => 'Демо: брондау қатесін көрсету';

  @override
  String get paymentProcessing => 'Брондау рәсімделуде...';

  @override
  String orderTitle(String number) {
    return 'Тапсырыс $number';
  }

  @override
  String get orderShowQrHint => 'Кассада QR көрсетіңіз немесе кодты айтыңыз';

  @override
  String get orderPinLabel => 'Алу коды';

  @override
  String orderCountdownBefore(String time) {
    return 'Беруге дейін $time';
  }

  @override
  String orderCountdownDuring(String time) {
    return 'Беру уақыты ашық · қалғаны $time';
  }

  @override
  String get orderCountdownEnded => 'Беру уақыты аяқталды';

  @override
  String get orderCancelButton => 'Тапсырысты болдырмау';

  @override
  String get orderCancelBlockedHint =>
      'Болдырмау беру басталуына кемінде 1 сағат қалғанда ғана мүмкін';

  @override
  String get orderCancelConfirmTitle => 'Тапсырысты болдырмау?';

  @override
  String get orderCancelConfirmBody =>
      'Бокс басқа сатып алушыларға қолжетімді болады, Strike берілмейді.';

  @override
  String get orderProblemButton => 'Тапсырыспен мәселе бар';

  @override
  String get orderDemoCompletePickup => 'Демо: мекеме тапсырысты берді';

  @override
  String get orderCallDialogTitle => 'Мекемеге қоңырау шалу';

  @override
  String orderCallDialogBody(String phone) {
    return 'Байланыс нөмірі: $phone';
  }

  @override
  String get complaintTitle => 'Тапсырыспен мәселе';

  @override
  String get complaintSubtitle =>
      'Не дұрыс болмағанын жазыңыз. Шағым алғаннан кейін 24 сағат ішінде қабылданады, жауап — 3 жұмыс күніне дейін.';

  @override
  String get complaintNoteHint =>
      'Мысалы: құрамы сипаттамадан қатты өзгеше болды немесе өнім жарамсыз';

  @override
  String get complaintAddPhoto => 'Фото тіркеу';

  @override
  String get complaintPhotoAdded => 'Фото тіркелді';

  @override
  String get complaintSubmit => 'Шағым жіберу';

  @override
  String get complaintSubmittedToast =>
      'Шағым қабылданды. 3 жұмыс күні ішінде жауап береміз';

  @override
  String get complaintAlreadySent => 'Бұл тапсырыс бойынша шағым жіберілген';

  @override
  String successSavedSubtitle(String amount) {
    return 'Сіз бокс құтқарып, $amount үнемдедіңіз';
  }

  @override
  String get successRateTitle => 'Бокс қалай болды?';

  @override
  String get successTagTasty => 'Дәмді';

  @override
  String get successTagPlenty => 'Тағам көп';

  @override
  String get successTagFresh => 'Жаңа піскен';

  @override
  String get successTagPolite => 'Сыпайы';

  @override
  String get successCommentHint => 'Мекемеге бір-екі ауыз сөз (міндетті емес)';

  @override
  String get successShareStories => 'Стористе бөлісу';

  @override
  String get successStoriesTitle => 'Сториске арналған ашық хат';

  @override
  String get successStoriesSaved => 'Ашық хат сториске көшірілді!';

  @override
  String get ordersTabActive => 'Белсенді';

  @override
  String get ordersTabPast => 'Өткен';

  @override
  String get ordersEmptyActiveTitle => 'Белсенді тапсырыстар жоқ';

  @override
  String get ordersEmptyActiveSubtitle =>
      'Кешке дәмді бокс таңдап, кезексіз алып кетіңіз';

  @override
  String get ordersEmptyPastTitle => 'Өткен тапсырыстар әзірше жоқ';

  @override
  String get ordersEmptyPastSubtitle =>
      'Мұнда құтқарылған бокстарыңыздың тарихы сақталады';

  @override
  String get ordersOpenQr => 'QR ашу';

  @override
  String get orderStatusPaid => 'Төленді';

  @override
  String get orderStatusReady => 'Беруге дайын';

  @override
  String get orderStatusPickedUp => 'Алынды';

  @override
  String get orderStatusCancelled => 'Болдырылмады';

  @override
  String get orderStatusExpired => 'Уақыты өтті';

  @override
  String get profileBoxesSaved => 'Құтқарылған бокс';

  @override
  String get profileKgSaved => 'Қалдыққа кетпеді';

  @override
  String get profileMoneySaved => 'Үнемделді';

  @override
  String get profileFavoritesTitle => 'Таңдаулылар';

  @override
  String get profileFavoritesEmpty =>
      'Сүйікті мекемені жоғалтпау үшін жүрекшені басыңыз';

  @override
  String get profileFavoriteAlerts => 'Сүйікті орындардағы бокстар';

  @override
  String get profileFavoriteAlertsSubtitle =>
      'Сүйікті орындар бокс шығарғанда еске салу';

  @override
  String get profileCharityTitle => 'Қорға арналған бокс';

  @override
  String get profileCharitySubtitle =>
      'Боксты төлеңіз — біз оны Астанадағы қайырымдылық қорына жеткіземіз';

  @override
  String get profileCharityConfirm => 'Қорға бокс сыйлау';

  @override
  String get profileCharitySuccess =>
      'Рахмет! Сіз қорға арналған боксты төледіңіз';

  @override
  String get profileRoleDemoTitle => 'Жүйе рөлдері мен панельдер';

  @override
  String get profileRoleBuyer => 'Сатып алушы';

  @override
  String get profileRoleOwner => 'Дүкен иесі';

  @override
  String get profileRoleCashier => 'Кассир';

  @override
  String get profileRoleAdmin => 'Әкімші';

  @override
  String get actionSwitchToAdmin => 'Админ-панель';

  @override
  String get actionOpenAdminDemo => 'Админ-панель';

  @override
  String get navAdminOverview => 'Шолу';

  @override
  String get navAdminVenues => 'Дүкендер';

  @override
  String get navAdminBoxes => 'Бокстар';

  @override
  String get navAdminComplaints => 'Шағымдар';

  @override
  String get screenAdminOverviewTitle => 'Админ-панель · Шолу';

  @override
  String get screenAdminVenuesTitle => 'Дүкендер және Халал';

  @override
  String get screenAdminBoxesTitle => 'Бокстар каталогы';

  @override
  String get screenAdminComplaintsTitle => 'Шағымдар мен тапсырыстар';

  @override
  String get adminGmvLabel => 'Айналым (GMV)';

  @override
  String get adminCommissionLabel => 'Комиссия 15%';

  @override
  String get adminVenuesCountLabel => 'Дүкендер';

  @override
  String get adminOpenComplaintsLabel => 'Ашық шағымдар';

  @override
  String get adminPendingQueueTitle => 'Тексеруді күтуде';

  @override
  String get adminRecentOrdersTitle => 'Соңғы тапсырыстар';

  @override
  String get adminFilterAll => 'Барлығы';

  @override
  String get adminFilterPending => 'Тексеруде';

  @override
  String get adminFilterApproved => 'Мақұлданған';

  @override
  String get adminFilterRejected => 'Қайтарылған';

  @override
  String get adminApproveVenue => 'Дүкенді мақұлдау';

  @override
  String get adminRejectVenue => 'Түзетуге жіберу';

  @override
  String get adminVerifyHalal => 'Халалды растау';

  @override
  String get adminRejectHalal => 'Халалды қабылдамау';

  @override
  String get adminHalalStatusVerified => 'Халал расталды';

  @override
  String get adminHalalStatusPending => 'Халал тексерілуде';

  @override
  String get adminHalalStatusRejected => 'Халал қабылданбады';

  @override
  String get adminHalalStatusNone => 'Халал жоқ';

  @override
  String get adminRejectReasonHint => 'Дүкенге ескерту жазыңыз';

  @override
  String get adminHideBox => 'Жариялаудан алу';

  @override
  String get adminRestoreBox => 'Сатылымға қайтару';

  @override
  String get adminBoxStatusActive => 'Белсенді';

  @override
  String get adminBoxStatusSoldOut => 'Таусылды';

  @override
  String get adminBoxStatusDisabled => 'Жасырулы';

  @override
  String get adminComplaintsTab => 'Шағымдар';

  @override
  String get adminAllOrdersTab => 'Барлық тапсырыстар';

  @override
  String get adminComplaintTakeInReview => 'Қарауға алу';

  @override
  String get adminComplaintRefund => 'Қайтарыммен шешу';

  @override
  String get adminComplaintResolve => 'Жауаппен жабу';

  @override
  String get adminComplaintResolutionHint =>
      'Сатып алушыға жауап (3 жұмыс күніне дейін)';

  @override
  String get adminComplaintStatusOpen => 'Ашық';

  @override
  String get adminComplaintStatusInReview => 'Қаралуда';

  @override
  String get adminComplaintStatusResolved => 'Шешілді';

  @override
  String get adminComplaintStatusRefunded => 'Қайтарым жасалды';

  @override
  String get adminNoComplaintsTitle => 'Ашық шағымдар жоқ';

  @override
  String get adminNoComplaintsSubtitle =>
      'Сатып алушылардың барлық өтініші қаралды';

  @override
  String get venueModerationPendingBanner =>
      'Дүкен тексерілуде: бокстар әкімші мақұлдаған соң сатып алушыларға көрінеді.';

  @override
  String get venueModerationRejectedBanner => 'Өтінім түзетуді қажет етеді';

  @override
  String get venueSettingsHalalNumber => 'Халал сертификат нөмірі';

  @override
  String get venueSettingsSubmitHalal => 'Халал тексеруге жіберу';

  @override
  String get animalQumbek => 'Құмбек';

  @override
  String get animalIrbis => 'Барыс';

  @override
  String get animalSaigak => 'Ақбөкен';

  @override
  String get animalSeal => 'Итбалық';

  @override
  String qyzylKitapProgress(int saved, int target, int left, String animal) {
    return '$target бокстың $saved-і — тағы $left, сонда $animal ашылады';
  }

  @override
  String get qyzylKitapAllUnlocked =>
      '«Қызыл кітаптың» барлық тұрғыны ашылды! Сіз күн сайын тағамды құтқарасыз.';

  @override
  String get qyzylKitapUnlocked => 'Ашылды';

  @override
  String qyzylKitapLockedLeft(int count) {
    return 'тағы $count бокс';
  }

  @override
  String get qyzylKitapNoMoneyNote =>
      'Жинақ тағамды құтқаруға қосқан үлесіңізді көрсетеді — бонустар ақшаға айырбасталмайды.';

  @override
  String get venueOnboardingStep1 => 'Мекеме';

  @override
  String get venueOnboardingStep2 => 'Мекенжай мен уақыт';

  @override
  String get venueOnboardingStep3 => 'Деректемелер';

  @override
  String get venueOnboardingStep4 => 'Шарт';

  @override
  String get venueNameLabel => 'Мекеме атауы';

  @override
  String get venueAddressLabel => 'Астанадағы мекенжайы';

  @override
  String get venuePhoneLabel => 'Байланыс телефоны';

  @override
  String get venueBinLabel => 'БСН / ЖСН';

  @override
  String get venueIbanLabel => 'ЖСК (IBAN)';

  @override
  String get venueBikLabel => 'БСК';

  @override
  String get venueContractText =>
      'toıdym серіктестік оферта шарты: сатылған бокстардан 15% комиссия, дүйсенбі сайын апталық төлем. Қолма-қол есеп айырысуға және тыйым салынған тауарларды сатуға болмайды.';

  @override
  String get venueContractAgree => 'Оферта шартының талаптарымен келісемін';

  @override
  String get venueSubmitApplication => 'Өтінім жіберу';

  @override
  String get venueStatusPending => 'Тексеруде';

  @override
  String get venueStatusApproved => 'Мақұлданды';

  @override
  String get venueStatusRejected => 'Түзету қажет';

  @override
  String get venueDemoStatusSwitch => 'Өтінімнің демо-мәртебесі';

  @override
  String get venueOpenDashboard => 'Кабинетке өту';

  @override
  String get venueTodaySold => 'Сатылды';

  @override
  String get venueTodayWaiting => 'Алуды күтуде';

  @override
  String get venueTodayRevenue => 'Түсім';

  @override
  String get venueQumbekTip =>
      'Бокстарды 16:00-ге дейін жариялаңыз — сатып алушылар кешке дейін көріп үлгереді';

  @override
  String get venueInSale => 'Сатылымда';

  @override
  String get venueStockLabel => 'Қалдығы';

  @override
  String get venueNewBoxButton => 'Жаңа бокс';

  @override
  String get venueNewBoxTitleField => 'Бокс атауы';

  @override
  String get venueNewBoxType => 'Бокс түрі';

  @override
  String get venueNewBoxSurprise => 'Сюрприз-бокс';

  @override
  String get venueNewBoxSet => 'Нақты жиынтық';

  @override
  String get venueNewBoxInside => 'Ішінде не болуы мүмкін';

  @override
  String get venueNewBoxOriginalPrice => 'Әдеттегі бағасы (₸)';

  @override
  String get venueNewBoxDiscountPrice => 'toıdym бағасы (₸)';

  @override
  String venueNewBoxAutoDiscount(int percent) {
    return 'Жеңілдік: $percent%';
  }

  @override
  String get venueNewBoxLowDiscountWarn =>
      'Жеңілдік 50%-дан аз — жариялауға болмайды';

  @override
  String venueNewBoxYouReceive(String amount) {
    return 'Бокстан алатыныңыз: $amount';
  }

  @override
  String get venueNewBoxQuantity => 'Бокс саны';

  @override
  String get venueNewBoxWindowStart => 'Беру басталуы';

  @override
  String get venueNewBoxWindowEnd => 'Беру аяқталуы';

  @override
  String get venueNewBoxRepeatDays => 'Апта күндері бойынша қайталау';

  @override
  String get venueNewBoxAllergens => 'Аллергендер';

  @override
  String get venueNewBoxPreviewButton => 'Алдын ала көру';

  @override
  String get venueNewBoxPublishButton => 'Жариялау';

  @override
  String get venueNewBoxHalalNoCertHint =>
      'Баптауларда халал-сертификатты жүктеп растаңыз';

  @override
  String get venuePickupScannerHint =>
      'Камераны сатып алушының QR-ына бағыттаңыз';

  @override
  String get venuePickupSimulateQr =>
      'Демо: бірінші тапсырыстың QR-ын сканерлеу';

  @override
  String get venuePickupPinHint => '4 таңбалы код';

  @override
  String get venuePickupGiveButton => 'Тапсырысты беру';

  @override
  String get venuePickupWaitingTitle => 'Алуды күтуде';

  @override
  String get venuePickupEmptyWaiting => 'Беруді күтіп тұрған тапсырыстар жоқ';

  @override
  String venuePickupSuccess(String number) {
    return '$number тапсырысы берілді!';
  }

  @override
  String get venuePickupCancelTitle => 'Тапсырысты болдырмау';

  @override
  String get venuePickupCancelReasonHint =>
      'Себебі (ақша сатып алушыға автоматты түрде қайтарылады)';

  @override
  String get venueStatsDay => 'Күн';

  @override
  String get venueStatsWeek => 'Апта';

  @override
  String get venueStatsMonth => 'Ай';

  @override
  String get venueStatsFoodSaved => 'Құтқарылған тағам';

  @override
  String get venueStatsCommission => 'Комиссия';

  @override
  String get venueStatsNextPayout => 'Келесі төлем';

  @override
  String get venueStatsPayoutHistory => 'Төлемдер тарихы';

  @override
  String get venueStatsReviews => 'Рейтинг және пікірлер';

  @override
  String get venueSettingsWorkHours => 'Жұмыс уақыты';

  @override
  String get venueSettingsStaff => 'Қызметкерлер';

  @override
  String get venueSettingsAddCashier => 'Кассир қосу';

  @override
  String get venueSettingsCashierName => 'Кассир есімі';

  @override
  String get venueSettingsSupport => 'Серіктестерді қолдау';

  @override
  String get venueSettingsSupportText =>
      'Telegram @toidym_partner · +7 (7172) 55-00-11';

  @override
  String get ruleDiscountTooLow => 'Жеңілдік кемінде 50% болуы керек';

  @override
  String get ruleWindowTooShort => 'Беру уақыты кемінде 30 минут болуы тиіс';

  @override
  String get ruleWindowOutsideHours =>
      'Беру уақыты мекеменің жұмыс уақытында болуы керек';

  @override
  String get rulePublishTooLate =>
      'Боксты беру басталуынан кемінде 2 сағат бұрын жариялау қажет';

  @override
  String get ruleHalalCertRequired =>
      '«Халал» белгісі тек тексерілген сертификатпен қойылады';

  @override
  String get ruleProhibitedItems =>
      'Алкоголь, темекі және мерзімі өткен өнімдерді сатуға тыйым салынады';

  @override
  String get ruleInvalidPrice =>
      'Әдеттегі баға мен toıdym бағасын дұрыс көрсетіңіз';

  @override
  String get ruleInvalidQuantity => 'Бокс саны нөлден көп болуы керек';

  @override
  String timerMinutesShort(int minutes) {
    return '$minutes мин';
  }

  @override
  String timerHoursMinutes(int hours, int minutes) {
    return '$hours сағ $minutes мин';
  }

  @override
  String weightKg(String value) {
    return '$value кг';
  }

  @override
  String get screenOnboardingTitle => 'toıdym-ға қош келдіңіз';

  @override
  String get screenHomeTitle => 'Жақын бокстар';

  @override
  String get screenMapTitle => 'Бокстар картасы';

  @override
  String get screenBoxDetailTitle => 'Бокс туралы';

  @override
  String get screenPaymentTitle => 'Тапсырысты төлеу';

  @override
  String get screenOrderTitle => 'Белсенді тапсырыс';

  @override
  String get screenSuccessTitle => 'Ас болсын!';

  @override
  String get screenOrdersHistoryTitle => 'Менің тапсырыстарым';

  @override
  String get screenProfileTitle => 'Профиль';

  @override
  String get screenQyzylKitapTitle => 'Қызыл кітап';

  @override
  String get screenVenueOnboardingTitle => 'Мекемені қосу';

  @override
  String get screenVenueBoxesTodayTitle => 'Бүгінгі бокстар';

  @override
  String get screenVenueNewBoxTitle => 'Жаңа бокс';

  @override
  String get screenVenuePickupTitle => 'Тапсырыс беру';

  @override
  String get screenVenueStatsTitle => 'Қорытынды және төлемдер';

  @override
  String get screenVenueSettingsTitle => 'Мекеме баптаулары';

  @override
  String get phaseFoundationStubNote => 'Экран қаңқасы';

  @override
  String get dietHalalOnly => 'Тек Халал';

  @override
  String get dietVegetarian => 'Вегетариандық';

  @override
  String get dietNutFree => 'Жаңғақсыз';

  @override
  String get sortNearest => 'Жақын маңда';

  @override
  String get sortEndingSoon => 'Таусылуға жақын';

  @override
  String get sortMaxDiscount => 'Макс. жеңілдік';

  @override
  String get venueStatusBanned => 'Бұғатталған';

  @override
  String get orderStatusReserved => 'Брондалды';

  @override
  String get orderStatusCompleted => 'Берілді';

  @override
  String get orderStatusCancelledByUser => 'Сіз бас тарттыңыз';

  @override
  String get orderStatusCancelledByVenue => 'Мекеме бас тартты';

  @override
  String get orderStatusNoShow => 'Келмеді (Strike)';

  @override
  String get paymentOnSite => 'Алу кезінде төлеу';

  @override
  String get adminBoxStatusExpired => 'Мұрағатта';

  @override
  String get authLoginTitle => 'toıdym-ға кіру';

  @override
  String get authRegisterTitle => 'Тіркелу';

  @override
  String get authTabLogin => 'Кіру';

  @override
  String get authTabRegister => 'Тіркелу';

  @override
  String get authNameLabel => 'Есіміңіз';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailOrPhoneLabel => 'Email немесе телефон';

  @override
  String get authPasswordLabel => 'Құпиясөз';

  @override
  String get authPasswordHint => 'Кемінде 8 таңба, 1 сан және 1 бас әріп';

  @override
  String get authConfirmPasswordLabel => 'Құпиясөзді қайталаңыз';

  @override
  String get authForgotPassword => 'Құпиясөзді ұмыттыңыз ба?';

  @override
  String authForgotPasswordSent(String email) {
    return 'Құпиясөзді қалпына келтіру сілтемесі $email поштасына жіберілді';
  }

  @override
  String get authVerifyEmailTitle => 'Email-ды растаңыз';

  @override
  String authVerifyEmailBody(String email) {
    return 'Растау сілтемесі $email поштасына жіберілді. Демо үшін төмендегі батырманы басыңыз.';
  }

  @override
  String get authVerifyEmailDemoButton => 'Демо: Email растау';

  @override
  String get authVerifiedSuccess => 'Email расталды! Енді кіруге болады.';

  @override
  String get authErrInvalidPhone =>
      '+7 (7XX) XXX-XX-XX форматында дұрыс нөмір енгізіңіз';

  @override
  String get authErrInvalidEmail => 'Дұрыс Email енгізіңіз';

  @override
  String get authErrWeakPassword =>
      'Құпиясөзде кемінде 8 таңба, 1 сан және 1 бас әріп болуы керек';

  @override
  String get authErrPasswordMismatch => 'Құпиясөздер сәйкес келмейді';

  @override
  String get authErrEmailExists => 'Бұл Email бұрыннан тіркелген';

  @override
  String get authErrInvalidCredentials => 'Логин немесе құпиясөз қате';

  @override
  String get authErrEmailNotVerified => 'Кірмес бұрын Email-ды растаңыз';

  @override
  String get authErrRateLimited => 'Кіру әрекеті тым көп. 15 минут күтіңіз';

  @override
  String get authErrAccountBanned =>
      '3 рет келмегендіктен (No-Show) аккаунт уақытша бұғатталды';

  @override
  String get authDemoAccountsTitle => 'Жылдам кіру (демо-рөлдер)';

  @override
  String get forcePassTitle => 'Уақытша құпиясөзді ауыстырыңыз';

  @override
  String get forcePassSubtitle =>
      'Серіктес кабинетін қорғау үшін жұмыс алдында тұрақты құпиясөз орнатыңыз';

  @override
  String get forcePassNewLabel => 'Жаңа құпиясөз';

  @override
  String get forcePassSaveButton => 'Құпиясөзді сақтау және кіру';

  @override
  String get onboardingDietaryTitle => 'Тағам талғамдары';

  @override
  String get onboardingDietarySubtitle =>
      'Сүзгілерді белгілеңіз — сәйкес бокстар әрқашан жоғарыда болады';

  @override
  String get onboardingPartnerCta => 'Бизнес үшін: мекеме қосу';

  @override
  String get homeSortLabel => 'Сұрыптау';

  @override
  String get homeGuestBanner =>
      'Қонақ режимі: бокстарды еркін көріңіз, кіру — брондау кезінде.';

  @override
  String get boxDietaryMismatchWarn =>
      'Құрамын тексеріңіз — талғамыңызға сай келмеуі мүмкін';

  @override
  String get screenReserveTitle => 'Бронды растау';

  @override
  String get bookingOfflineTitle => 'Алу кезінде төлеу (Trust Booking)';

  @override
  String get bookingOfflineBody =>
      'Онлайн алдын ала төлем қажет емес — боксты мекеме кассасында төлейсіз. 1 сағат бұрын болдырмай келмей қалсаңыз, Strike беріледі (3 Strike = 30 күнге бұғаттау).';

  @override
  String get bookingOfflineAcceptButton => 'Түсіндім, брондау';

  @override
  String get paymentOfflineBadge =>
      'Алу кезінде төлеу (кассада Kaspi QR / карта / қолма-қол)';

  @override
  String get paymentRuleStrike =>
      'Беру уақытынан кемінде 1 сағат бұрын тегін бас тартуға болады. Келмесеңіз (No-Show) Strike беріледі.';

  @override
  String actionConfirmReserve(String price) {
    return '$price бағасына брондау';
  }

  @override
  String get orderReminder30m =>
      'Еске салғыш: беру уақыты 30 минуттан кейін басталады';

  @override
  String get orderReminder15m =>
      'Үлгеріңіз! Беру уақыты аяқталуына 15 минуттан аз қалды';

  @override
  String orderUrgentClosing(String time) {
    return 'Шұғыл: беру аяқталуына $time!';
  }

  @override
  String get orderRouteChooseMap => 'Картада бағытты ашу';

  @override
  String get orderOpen2Gis => '2GIS арқылы ашу';

  @override
  String get orderOpenYandexMaps => 'Яндекс Картада ашу';

  @override
  String get orderDemoNoShow => 'Демо: келмеді деп белгілеу (No-Show)';

  @override
  String get orderNoShowRecorded =>
      'Келмеу (No-Show) тіркелді. +1 Strike қосылды';

  @override
  String get profileStrikesTitle => 'Сенімділік (Strikes)';

  @override
  String profileStrikesCount(int count) {
    return 'Ереже бұзу: 3-тен $count';
  }

  @override
  String profileBannedUntil(String date) {
    return 'Брондау $date дейін шектелген';
  }

  @override
  String get profileDietSettingsTitle => 'Тағам сүзгілерім';

  @override
  String get shareImageFailed =>
      'Суретті дайындау мүмкін болмады, мәтін көшірілді';

  @override
  String get shareImageReady => 'Карточка бөлісуге дайын!';

  @override
  String get partnerLeadTitle => 'Серіктестікке өтінім';

  @override
  String get partnerLeadSubtitle =>
      'Мекеме байланыстарын қалдырыңыз — комиссиясыз (0%) кабинет қосып, уақытша құпиясөз береміз.';

  @override
  String get partnerLeadEmailLabel => 'Серіктес Email-ы';

  @override
  String get partnerLeadSuccessTitle => 'Өтінім жіберілді!';

  @override
  String get partnerLeadSuccessBody =>
      'Мәртебесі: Тексеруде (PENDING). Әкімші мақұлдаған соң уақытша құпиясөзбен кіресіз.';

  @override
  String get venueTabToday => 'Бүгінгі';

  @override
  String get venueTabArchive => 'Мұрағат (Архив)';

  @override
  String get venueArchiveEmpty => 'Мұрағатта бокстар әлі жоқ';

  @override
  String get venueRepublishButton => 'Бүгінге қайта шығару';

  @override
  String get venueRepublishedSuccess => 'Бокс қайта сатылымға шығарылды!';

  @override
  String get venueTemplatesTitle => 'Менің шаблондарым (1 рет басу)';

  @override
  String get venueSaveAsTemplate => 'Шаблон ретінде сақтау';

  @override
  String venueTemplateApplied(String name) {
    return '«$name» шаблоны қолданылды';
  }

  @override
  String get venueNewBoxVegetarian => 'Вегетариандық бокс';

  @override
  String get venueNewBoxNoCommissionNote =>
      'Платформа комиссиясы: 0% · қонақ орнында төлейді';

  @override
  String get venuePickupEnterPinTitle =>
      'Тапсырыстың 4 таңбалы PIN кодын енгізіңіз';

  @override
  String get venuePickupPinWrong => 'PIN-код қате немесе тапсырыс табылмады';

  @override
  String get venuePickupClear => 'Өшіру';

  @override
  String get venueStatsZeroCommission => 'Комиссия 0% (ұсталымсыз)';

  @override
  String get venueStatsCompletedOrders => 'Берілген тапсырыстар';

  @override
  String get venueStatsNoShowOrders => 'Келмегендер (No-Show)';

  @override
  String get venueStatsLostProfitTitle => 'Жіберілген пайда';

  @override
  String venueStatsLostProfitSubtitle(int count) {
    return 'Өтпей қалған бокстар: $count дана';
  }

  @override
  String get venueQumbekAdviceHighRemaining =>
      'Құмбек кеңесі: өтпей қалған бокстар бар — бағаны 15%-ға түсіріп немесе беру уақытын 30 минутқа шегеріп көріңіз.';

  @override
  String get venueQumbekAdviceHighNoShow =>
      'Құмбек кеңесі: келмеу жағдайлары бар. Қонақтарға беру алдында броньды еске салыңыз.';

  @override
  String get venueQumbekAdviceGreat =>
      'Құмбек кеңесі: тамаша нәтиже! Үздік боксты 1 рет басып жариялау үшін шаблонға сақтаңыз.';

  @override
  String get adminActiveVenuesUsersLabel => 'Белсенді дүкендер / қонақтар';

  @override
  String get adminCompletedBoxesLabel => 'Сатылды (COMPLETED)';

  @override
  String get adminZeroCommissionBadge => 'Комиссиясыз (0%)';

  @override
  String get adminAddPartnerButton => 'Серіктес қосу';

  @override
  String adminTempPasswordCreated(String password, String email) {
    return 'Серіктес қосылды! Уақытша құпиясөз: $password (Email: $email)';
  }

  @override
  String get adminBanVenue => 'Дүкенді бұғаттау';

  @override
  String get adminUnbanVenue => 'Бұғаттан шығару';

  @override
  String adminVenueCompletedCount(int count) {
    return 'Берілді: $count';
  }

  @override
  String adminVenueNoShowCount(int count) {
    return 'No-Show: $count';
  }

  @override
  String get adminDeleteBox => 'Боксты жою';

  @override
  String get adminStrikesTab => 'Strikes және Бандар';

  @override
  String get adminAuditTab => 'Аудит (AuditLogs)';

  @override
  String get adminRemoveStrike => '1 Strike алу';

  @override
  String get adminUnbanUser => 'Банды алу';

  @override
  String adminUserStrikesBadge(int count) {
    return 'Strikes: $count/3';
  }

  @override
  String get adminAuditEmpty => 'Аудит жазбалары әлі жоқ';

  @override
  String get adminTableColVenue => 'Мекеме';

  @override
  String get adminTableColDistrict => 'Аудан';

  @override
  String get adminTableColStatus => 'Мәртебе';

  @override
  String get adminTableColHalal => 'Халал';

  @override
  String get adminTableColStats => 'Берілді / No-Show';

  @override
  String get adminTableColActions => 'Әрекеттер';

  @override
  String get adminFilterBanned => 'Бұғатталғандар';

  @override
  String get navAdminAudit => 'Аудит';

  @override
  String get badgeResaleHot => 'Жануда! · Тез алып кетіңіз';

  @override
  String get badgeResaleTag => 'Қайта сатылым (Resale)';

  @override
  String get venueNewBoxSprintTitle => '15 минуттық Спринт терезесі';

  @override
  String venueNewBoxSprintSubtitle(String window) {
    return 'Сервис ережесі бойынша беру жабылудан 1 сағ бұрын басталып ($window), тек 15 мин болады';
  }

  @override
  String orderSprintTimerLabel(String time) {
    return '15 мин Спринт: $time';
  }

  @override
  String get orderResaleErrorMessage =>
      'Кешіріңіз, сіз үлгермедіңіз. Тапсырыс басқа адамдарға сатылымға шықты';

  @override
  String get orderDemoExpireSprint => 'Демо: 15 мин өтті (00:00 → Resale)';

  @override
  String get fcmStrikeTitle => 'Тапсырыс жойылды (No-Show)';

  @override
  String get fcmStrikeBody =>
      'Тапсырыс жойылды және сізге 1 ескерту (Strike) берілді';
}
