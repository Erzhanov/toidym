import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'toıdym'**
  String get appName;

  /// No description provided for @brandPhrase.
  ///
  /// In ru, this message translates to:
  /// **'Ас болсын!'**
  String get brandPhrase;

  /// No description provided for @brandSlogan.
  ///
  /// In ru, this message translates to:
  /// **'Спасай вкусную еду до −70%'**
  String get brandSlogan;

  /// No description provided for @qyzylKitapTitle.
  ///
  /// In ru, this message translates to:
  /// **'Қызыл кітап'**
  String get qyzylKitapTitle;

  /// No description provided for @qumbekName.
  ///
  /// In ru, this message translates to:
  /// **'Құмбек'**
  String get qumbekName;

  /// No description provided for @languageRu.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @languageKk.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get languageKk;

  /// No description provided for @languageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык приложения'**
  String get languageTitle;

  /// No description provided for @navBoxes.
  ///
  /// In ru, this message translates to:
  /// **'Боксы'**
  String get navBoxes;

  /// No description provided for @navMap.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get navMap;

  /// No description provided for @navOrders.
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get navOrders;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @navVenueBoxes.
  ///
  /// In ru, this message translates to:
  /// **'Боксы'**
  String get navVenueBoxes;

  /// No description provided for @navVenuePickup.
  ///
  /// In ru, this message translates to:
  /// **'Выдача'**
  String get navVenuePickup;

  /// No description provided for @navVenueStats.
  ///
  /// In ru, this message translates to:
  /// **'Итоги'**
  String get navVenueStats;

  /// No description provided for @districtEsil.
  ///
  /// In ru, this message translates to:
  /// **'Есиль'**
  String get districtEsil;

  /// No description provided for @districtAlmaty.
  ///
  /// In ru, this message translates to:
  /// **'Алматы'**
  String get districtAlmaty;

  /// No description provided for @districtSaryarka.
  ///
  /// In ru, this message translates to:
  /// **'Сарыарка'**
  String get districtSaryarka;

  /// No description provided for @districtBaiqonyr.
  ///
  /// In ru, this message translates to:
  /// **'Байқоңыр'**
  String get districtBaiqonyr;

  /// No description provided for @districtAllAstana.
  ///
  /// In ru, this message translates to:
  /// **'Вся Астана'**
  String get districtAllAstana;

  /// No description provided for @cityAstana.
  ///
  /// In ru, this message translates to:
  /// **'Астана'**
  String get cityAstana;

  /// No description provided for @categoryAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get categoryAll;

  /// No description provided for @categoryBakery.
  ///
  /// In ru, this message translates to:
  /// **'Выпечка'**
  String get categoryBakery;

  /// No description provided for @categoryHotFood.
  ///
  /// In ru, this message translates to:
  /// **'Горячее'**
  String get categoryHotFood;

  /// No description provided for @categoryHalal.
  ///
  /// In ru, this message translates to:
  /// **'Халал'**
  String get categoryHalal;

  /// No description provided for @categoryCoffee.
  ///
  /// In ru, this message translates to:
  /// **'Кофе'**
  String get categoryCoffee;

  /// No description provided for @categoryGrocery.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get categoryGrocery;

  /// No description provided for @badgeHalal.
  ///
  /// In ru, this message translates to:
  /// **'Халал'**
  String get badgeHalal;

  /// No description provided for @badgeEndingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро закончатся'**
  String get badgeEndingSoon;

  /// No description provided for @badgeLeftCount.
  ///
  /// In ru, this message translates to:
  /// **'Осталось {count}'**
  String badgeLeftCount(int count);

  /// No description provided for @badgeSoldOut.
  ///
  /// In ru, this message translates to:
  /// **'Разобрали'**
  String get badgeSoldOut;

  /// No description provided for @pickupToday.
  ///
  /// In ru, this message translates to:
  /// **'Забрать сегодня {window}'**
  String pickupToday(String window);

  /// No description provided for @distanceKm.
  ///
  /// In ru, this message translates to:
  /// **'{value} км'**
  String distanceKm(String value);

  /// No description provided for @distanceMeters.
  ///
  /// In ru, this message translates to:
  /// **'{value} м'**
  String distanceMeters(int value);

  /// No description provided for @reviewsCountShort.
  ///
  /// In ru, this message translates to:
  /// **'({count})'**
  String reviewsCountShort(int count);

  /// No description provided for @boxesWaitingCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} боксов рядом ждут спасения'**
  String boxesWaitingCount(int count);

  /// No description provided for @actionStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get actionStart;

  /// No description provided for @actionRepresentVenue.
  ///
  /// In ru, this message translates to:
  /// **'Я представляю заведение'**
  String get actionRepresentVenue;

  /// No description provided for @actionRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get actionRetry;

  /// No description provided for @actionReserveFor.
  ///
  /// In ru, this message translates to:
  /// **'Забронировать за {price}'**
  String actionReserveFor(String price);

  /// No description provided for @actionPayAmount.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить {price}'**
  String actionPayAmount(String price);

  /// No description provided for @actionLogin.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get actionLogin;

  /// No description provided for @actionLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get actionLogout;

  /// No description provided for @actionDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get actionDone;

  /// No description provided for @actionCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get actionSave;

  /// No description provided for @actionNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get actionBack;

  /// No description provided for @actionShare.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get actionShare;

  /// No description provided for @actionDetails.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get actionDetails;

  /// No description provided for @actionRoute.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут'**
  String get actionRoute;

  /// No description provided for @actionCall.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить'**
  String get actionCall;

  /// No description provided for @actionResetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get actionResetFilters;

  /// No description provided for @actionAddToFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в избранное'**
  String get actionAddToFavorites;

  /// No description provided for @actionRemoveFromFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get actionRemoveFromFavorites;

  /// No description provided for @actionSwitchToVenue.
  ///
  /// In ru, this message translates to:
  /// **'Режим заведения'**
  String get actionSwitchToVenue;

  /// No description provided for @actionSwitchToBuyer.
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get actionSwitchToBuyer;

  /// No description provided for @actionBecomePartner.
  ///
  /// In ru, this message translates to:
  /// **'Стать партнёром'**
  String get actionBecomePartner;

  /// No description provided for @stateErrorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get stateErrorTitle;

  /// No description provided for @stateErrorSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте соединение и попробуйте ещё раз'**
  String get stateErrorSubtitle;

  /// No description provided for @stateEmptyBoxesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Рядом пока нет боксов'**
  String get stateEmptyBoxesTitle;

  /// No description provided for @stateEmptyBoxesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Құмбек ищет новые предложения — загляните чуть позже или смените фильтр'**
  String get stateEmptyBoxesSubtitle;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Где спасать боксы?'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingLocationSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите геопозицию или выберите район Астаны — аккаунт пока не нужен'**
  String get onboardingLocationSubtitle;

  /// No description provided for @onboardingDetectLocation.
  ///
  /// In ru, this message translates to:
  /// **'Определить геопозицию'**
  String get onboardingDetectLocation;

  /// No description provided for @onboardingLocationDetected.
  ///
  /// In ru, this message translates to:
  /// **'Определено: Астана, {district}'**
  String onboardingLocationDetected(String district);

  /// No description provided for @onboardingOrChooseDistrict.
  ///
  /// In ru, this message translates to:
  /// **'Или выберите район вручную'**
  String get onboardingOrChooseDistrict;

  /// No description provided for @homeGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Сәлем! Что спасём сегодня?'**
  String get homeGreeting;

  /// No description provided for @homeGreetingNamed.
  ///
  /// In ru, this message translates to:
  /// **'Сәлем, {name}! Выберите бокс'**
  String homeGreetingNamed(String name);

  /// No description provided for @homeSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск бокса или заведения'**
  String get homeSearchHint;

  /// No description provided for @homeViewList.
  ///
  /// In ru, this message translates to:
  /// **'Список'**
  String get homeViewList;

  /// No description provided for @homeViewMap.
  ///
  /// In ru, this message translates to:
  /// **'На карте'**
  String get homeViewMap;

  /// No description provided for @homeNotificationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get homeNotificationsTitle;

  /// No description provided for @homeMarkAllRead.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать все'**
  String get homeMarkAllRead;

  /// No description provided for @homeEndingSoonSection.
  ///
  /// In ru, this message translates to:
  /// **'Скоро закончатся'**
  String get homeEndingSoonSection;

  /// No description provided for @homeAllBoxesSection.
  ///
  /// In ru, this message translates to:
  /// **'Все предложения'**
  String get homeAllBoxesSection;

  /// No description provided for @homeSimulateError.
  ///
  /// In ru, this message translates to:
  /// **'Проверить экран ошибки'**
  String get homeSimulateError;

  /// No description provided for @mapYouAreHere.
  ///
  /// In ru, this message translates to:
  /// **'Вы здесь'**
  String get mapYouAreHere;

  /// No description provided for @mapCenterOnMe.
  ///
  /// In ru, this message translates to:
  /// **'Центрировать'**
  String get mapCenterOnMe;

  /// No description provided for @mapOpenInList.
  ///
  /// In ru, this message translates to:
  /// **'Списком'**
  String get mapOpenInList;

  /// No description provided for @boxDetailSurpriseTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что обычно внутри'**
  String get boxDetailSurpriseTitle;

  /// No description provided for @boxDetailSurpriseDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Состав зависит от того, что осталось за день. Не совпало с описанием — можно отказаться при получении.'**
  String get boxDetailSurpriseDisclaimer;

  /// No description provided for @boxDetailAllergensTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аллергены'**
  String get boxDetailAllergensTitle;

  /// No description provided for @boxDetailAllergensEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Основные аллергены не указаны'**
  String get boxDetailAllergensEmpty;

  /// No description provided for @boxDetailAllergensNote.
  ///
  /// In ru, this message translates to:
  /// **'При аллергии уточните состав на месте до получения.'**
  String get boxDetailAllergensNote;

  /// No description provided for @boxDetailPickupOnlyBadge.
  ///
  /// In ru, this message translates to:
  /// **'Только самовывоз'**
  String get boxDetailPickupOnlyBadge;

  /// No description provided for @boxDetailReviewsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы гостей'**
  String get boxDetailReviewsTitle;

  /// No description provided for @boxDetailShareMessage.
  ///
  /// In ru, this message translates to:
  /// **'Спасаю бокс «{title}» в {venue} за {price} через toıdym!'**
  String boxDetailShareMessage(String title, String venue, String price);

  /// No description provided for @boxDetailRouteOpening.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут до {address} (Астана): {lat}, {lng}'**
  String boxDetailRouteOpening(String address, String lat, String lng);

  /// No description provided for @authPhoneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы спасти бокс'**
  String get authPhoneTitle;

  /// No description provided for @authPhoneSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Отправим короткий код в SMS для подтверждения заказа'**
  String get authPhoneSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In ru, this message translates to:
  /// **'+7 (777) 123-45-67'**
  String get authPhoneHint;

  /// No description provided for @authSendCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get authSendCode;

  /// No description provided for @authSmsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите код из SMS'**
  String get authSmsTitle;

  /// No description provided for @authSmsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили 4-значный код на {phone}'**
  String authSmsSubtitle(String phone);

  /// No description provided for @authSmsHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите 4-значный код (демо: 1234)'**
  String get authSmsHint;

  /// No description provided for @authConfirmCode.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get authConfirmCode;

  /// No description provided for @authChangePhone.
  ///
  /// In ru, this message translates to:
  /// **'Изменить номер'**
  String get authChangePhone;

  /// No description provided for @authInvalidCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код. Для демо используйте 1234'**
  String get authInvalidCode;

  /// No description provided for @guestBenefitsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт'**
  String get guestBenefitsTitle;

  /// No description provided for @guestBenefitsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняйте любимые места, копите спасённые боксы и открывайте жителей «Қызыл кітап»'**
  String get guestBenefitsSubtitle;

  /// No description provided for @guestBenefitOrders.
  ///
  /// In ru, this message translates to:
  /// **'История всех заказов и быстрый доступ к QR'**
  String get guestBenefitOrders;

  /// No description provided for @guestBenefitStats.
  ///
  /// In ru, this message translates to:
  /// **'Подсчёт спасённых килограммов еды и экономии'**
  String get guestBenefitStats;

  /// No description provided for @guestBenefitKitap.
  ///
  /// In ru, this message translates to:
  /// **'Коллекция редких животных «Қызыл кітап»'**
  String get guestBenefitKitap;

  /// No description provided for @paymentQuantityLabel.
  ///
  /// In ru, this message translates to:
  /// **'Количество боксов'**
  String get paymentQuantityLabel;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In ru, this message translates to:
  /// **'Способ оплаты'**
  String get paymentMethodTitle;

  /// No description provided for @paymentKaspi.
  ///
  /// In ru, this message translates to:
  /// **'Kaspi.kz'**
  String get paymentKaspi;

  /// No description provided for @paymentKaspiHint.
  ///
  /// In ru, this message translates to:
  /// **'Счёт придёт в приложение Kaspi'**
  String get paymentKaspiHint;

  /// No description provided for @paymentCard.
  ///
  /// In ru, this message translates to:
  /// **'Банковская карта'**
  String get paymentCard;

  /// No description provided for @paymentCardNumberLabel.
  ///
  /// In ru, this message translates to:
  /// **'Номер карты'**
  String get paymentCardNumberLabel;

  /// No description provided for @paymentCardExpiryLabel.
  ///
  /// In ru, this message translates to:
  /// **'Срок (ММ/ГГ)'**
  String get paymentCardExpiryLabel;

  /// No description provided for @paymentCardCvvLabel.
  ///
  /// In ru, this message translates to:
  /// **'CVV'**
  String get paymentCardCvvLabel;

  /// No description provided for @paymentCardInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте данные карты'**
  String get paymentCardInvalid;

  /// No description provided for @paymentRegularPrice.
  ///
  /// In ru, this message translates to:
  /// **'Обычная цена'**
  String get paymentRegularPrice;

  /// No description provided for @paymentYouSave.
  ///
  /// In ru, this message translates to:
  /// **'Вы экономите'**
  String get paymentYouSave;

  /// No description provided for @paymentTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get paymentTotal;

  /// No description provided for @paymentRuleRefund.
  ///
  /// In ru, this message translates to:
  /// **'Если заведение отменит бокс, бронь аннулируется без штрафа (Strike не начисляется).'**
  String get paymentRuleRefund;

  /// No description provided for @paymentRuleCharity.
  ///
  /// In ru, this message translates to:
  /// **'Не успели в окно без отмены за 1 час — начисляется Strike (3 Strike = бан 30 дней).'**
  String get paymentRuleCharity;

  /// No description provided for @paymentSimulateError.
  ///
  /// In ru, this message translates to:
  /// **'Демо: имитировать сбой бронирования'**
  String get paymentSimulateError;

  /// No description provided for @paymentProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Оформляем бронь...'**
  String get paymentProcessing;

  /// No description provided for @orderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ {number}'**
  String orderTitle(String number);

  /// No description provided for @orderShowQrHint.
  ///
  /// In ru, this message translates to:
  /// **'Покажите QR или назовите код на кассе'**
  String get orderShowQrHint;

  /// No description provided for @orderPinLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код выдачи'**
  String get orderPinLabel;

  /// No description provided for @orderCountdownBefore.
  ///
  /// In ru, this message translates to:
  /// **'До выдачи {time}'**
  String orderCountdownBefore(String time);

  /// No description provided for @orderCountdownDuring.
  ///
  /// In ru, this message translates to:
  /// **'Окно выдачи открыто · осталось {time}'**
  String orderCountdownDuring(String time);

  /// No description provided for @orderCountdownEnded.
  ///
  /// In ru, this message translates to:
  /// **'Окно выдачи завершилось'**
  String get orderCountdownEnded;

  /// No description provided for @orderCancelButton.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ'**
  String get orderCancelButton;

  /// No description provided for @orderCancelBlockedHint.
  ///
  /// In ru, this message translates to:
  /// **'Отменить можно не позднее чем за 1 час до начала выдачи'**
  String get orderCancelBlockedHint;

  /// No description provided for @orderCancelConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ?'**
  String get orderCancelConfirmTitle;

  /// No description provided for @orderCancelConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Бокс снова станет доступен другим покупателям без начисления Strike.'**
  String get orderCancelConfirmBody;

  /// No description provided for @orderProblemButton.
  ///
  /// In ru, this message translates to:
  /// **'Проблема с заказом'**
  String get orderProblemButton;

  /// No description provided for @orderDemoCompletePickup.
  ///
  /// In ru, this message translates to:
  /// **'Демо: заведение выдало заказ'**
  String get orderDemoCompletePickup;

  /// No description provided for @orderCallDialogTitle.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить в заведение'**
  String get orderCallDialogTitle;

  /// No description provided for @orderCallDialogBody.
  ///
  /// In ru, this message translates to:
  /// **'Контактный номер: {phone}'**
  String orderCallDialogBody(String phone);

  /// No description provided for @complaintTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проблема с заказом'**
  String get complaintTitle;

  /// No description provided for @complaintSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Опишите, что пошло не так. Жалоба принимается в течение 24 часов после получения, ответ — до 3 рабочих дней.'**
  String get complaintSubtitle;

  /// No description provided for @complaintNoteHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: состав сильно отличался от описания или бокс оказался несвежим'**
  String get complaintNoteHint;

  /// No description provided for @complaintAddPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить фото'**
  String get complaintAddPhoto;

  /// No description provided for @complaintPhotoAdded.
  ///
  /// In ru, this message translates to:
  /// **'Фото прикреплено'**
  String get complaintPhotoAdded;

  /// No description provided for @complaintSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить жалобу'**
  String get complaintSubmit;

  /// No description provided for @complaintSubmittedToast.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба принята. Ответим в течение 3 рабочих дней'**
  String get complaintSubmittedToast;

  /// No description provided for @complaintAlreadySent.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба по этому заказу уже отправлена'**
  String get complaintAlreadySent;

  /// No description provided for @successSavedSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Вы спасли бокс и сэкономили {amount}'**
  String successSavedSubtitle(String amount);

  /// No description provided for @successRateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как вам бокс?'**
  String get successRateTitle;

  /// No description provided for @successTagTasty.
  ///
  /// In ru, this message translates to:
  /// **'Вкусно'**
  String get successTagTasty;

  /// No description provided for @successTagPlenty.
  ///
  /// In ru, this message translates to:
  /// **'Много еды'**
  String get successTagPlenty;

  /// No description provided for @successTagFresh.
  ///
  /// In ru, this message translates to:
  /// **'Свежее'**
  String get successTagFresh;

  /// No description provided for @successTagPolite.
  ///
  /// In ru, this message translates to:
  /// **'Вежливо'**
  String get successTagPolite;

  /// No description provided for @successCommentHint.
  ///
  /// In ru, this message translates to:
  /// **'Пара слов для заведения (необязательно)'**
  String get successCommentHint;

  /// No description provided for @successShareStories.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться в сторис'**
  String get successShareStories;

  /// No description provided for @successStoriesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Открытка для сторис'**
  String get successStoriesTitle;

  /// No description provided for @successStoriesSaved.
  ///
  /// In ru, this message translates to:
  /// **'Открытка скопирована для публикации в сторис!'**
  String get successStoriesSaved;

  /// No description provided for @ordersTabActive.
  ///
  /// In ru, this message translates to:
  /// **'Активные'**
  String get ordersTabActive;

  /// No description provided for @ordersTabPast.
  ///
  /// In ru, this message translates to:
  /// **'Прошедшие'**
  String get ordersTabPast;

  /// No description provided for @ordersEmptyActiveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных заказов'**
  String get ordersEmptyActiveTitle;

  /// No description provided for @ordersEmptyActiveSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите вкусный бокс на вечер и заберите его без очередей'**
  String get ordersEmptyActiveSubtitle;

  /// No description provided for @ordersEmptyPastTitle.
  ///
  /// In ru, this message translates to:
  /// **'Прошедших заказов пока нет'**
  String get ordersEmptyPastTitle;

  /// No description provided for @ordersEmptyPastSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появится история ваших спасённых боксов'**
  String get ordersEmptyPastSubtitle;

  /// No description provided for @ordersOpenQr.
  ///
  /// In ru, this message translates to:
  /// **'Открыть QR'**
  String get ordersOpenQr;

  /// No description provided for @orderStatusPaid.
  ///
  /// In ru, this message translates to:
  /// **'Оплачено'**
  String get orderStatusPaid;

  /// No description provided for @orderStatusReady.
  ///
  /// In ru, this message translates to:
  /// **'Готов к выдаче'**
  String get orderStatusReady;

  /// No description provided for @orderStatusPickedUp.
  ///
  /// In ru, this message translates to:
  /// **'Получен'**
  String get orderStatusPickedUp;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusExpired.
  ///
  /// In ru, this message translates to:
  /// **'Время вышло'**
  String get orderStatusExpired;

  /// No description provided for @profileBoxesSaved.
  ///
  /// In ru, this message translates to:
  /// **'Боксов спасено'**
  String get profileBoxesSaved;

  /// No description provided for @profileKgSaved.
  ///
  /// In ru, this message translates to:
  /// **'Еды не в мусор'**
  String get profileKgSaved;

  /// No description provided for @profileMoneySaved.
  ///
  /// In ru, this message translates to:
  /// **'Сэкономлено'**
  String get profileMoneySaved;

  /// No description provided for @profileFavoritesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get profileFavoritesTitle;

  /// No description provided for @profileFavoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на сердечко у бокса, чтобы не потерять любимое заведение'**
  String get profileFavoritesEmpty;

  /// No description provided for @profileFavoriteAlerts.
  ///
  /// In ru, this message translates to:
  /// **'Боксы в любимых местах'**
  String get profileFavoriteAlerts;

  /// No description provided for @profileFavoriteAlertsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Напоминать, когда любимые места выставляют боксы'**
  String get profileFavoriteAlertsSubtitle;

  /// No description provided for @profileSnowfallAnimation.
  ///
  /// In ru, this message translates to:
  /// **'Анимация снегопада'**
  String get profileSnowfallAnimation;

  /// No description provided for @profileSnowfallSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Зимняя праздничная атмосфера в приложении'**
  String get profileSnowfallSubtitle;

  /// No description provided for @profileCharityTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подвешенный бокс для фонда'**
  String get profileCharityTitle;

  /// No description provided for @profileCharitySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Оплатите бокс — мы передадим его в благотворительный фонд Астаны'**
  String get profileCharitySubtitle;

  /// No description provided for @profileCharityConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подарить бокс фонду'**
  String get profileCharityConfirm;

  /// No description provided for @profileCharitySuccess.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо! Вы оплатили подвешенный бокс для фонда'**
  String get profileCharitySuccess;

  /// No description provided for @profileRoleDemoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Роль и панели системы'**
  String get profileRoleDemoTitle;

  /// No description provided for @profileRoleBuyer.
  ///
  /// In ru, this message translates to:
  /// **'Покупатель'**
  String get profileRoleBuyer;

  /// No description provided for @profileRoleOwner.
  ///
  /// In ru, this message translates to:
  /// **'Владелец магазина'**
  String get profileRoleOwner;

  /// No description provided for @profileRoleCashier.
  ///
  /// In ru, this message translates to:
  /// **'Кассир'**
  String get profileRoleCashier;

  /// No description provided for @profileRoleAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Администратор'**
  String get profileRoleAdmin;

  /// No description provided for @actionSwitchToAdmin.
  ///
  /// In ru, this message translates to:
  /// **'Админ-панель'**
  String get actionSwitchToAdmin;

  /// No description provided for @actionOpenAdminDemo.
  ///
  /// In ru, this message translates to:
  /// **'Админ-панель'**
  String get actionOpenAdminDemo;

  /// No description provided for @navAdminOverview.
  ///
  /// In ru, this message translates to:
  /// **'Сводка'**
  String get navAdminOverview;

  /// No description provided for @navAdminVenues.
  ///
  /// In ru, this message translates to:
  /// **'Магазины'**
  String get navAdminVenues;

  /// No description provided for @navAdminBoxes.
  ///
  /// In ru, this message translates to:
  /// **'Боксы'**
  String get navAdminBoxes;

  /// No description provided for @navAdminComplaints.
  ///
  /// In ru, this message translates to:
  /// **'Жалобы'**
  String get navAdminComplaints;

  /// No description provided for @screenAdminOverviewTitle.
  ///
  /// In ru, this message translates to:
  /// **'Админ-панель · Сводка'**
  String get screenAdminOverviewTitle;

  /// No description provided for @screenAdminVenuesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Магазины и Халал'**
  String get screenAdminVenuesTitle;

  /// No description provided for @screenAdminBoxesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Каталог боксов'**
  String get screenAdminBoxesTitle;

  /// No description provided for @screenAdminComplaintsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Жалобы и заказы'**
  String get screenAdminComplaintsTitle;

  /// No description provided for @adminGmvLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оборот (GMV)'**
  String get adminGmvLabel;

  /// No description provided for @adminCommissionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия 15%'**
  String get adminCommissionLabel;

  /// No description provided for @adminVenuesCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Магазины'**
  String get adminVenuesCountLabel;

  /// No description provided for @adminOpenComplaintsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Открытые жалобы'**
  String get adminOpenComplaintsLabel;

  /// No description provided for @adminPendingQueueTitle.
  ///
  /// In ru, this message translates to:
  /// **'Требуют проверки'**
  String get adminPendingQueueTitle;

  /// No description provided for @adminRecentOrdersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Последние заказы'**
  String get adminRecentOrdersTitle;

  /// No description provided for @adminFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get adminFilterAll;

  /// No description provided for @adminFilterPending.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get adminFilterPending;

  /// No description provided for @adminFilterApproved.
  ///
  /// In ru, this message translates to:
  /// **'Одобренные'**
  String get adminFilterApproved;

  /// No description provided for @adminFilterRejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонённые'**
  String get adminFilterRejected;

  /// No description provided for @adminApproveVenue.
  ///
  /// In ru, this message translates to:
  /// **'Одобрить магазин'**
  String get adminApproveVenue;

  /// No description provided for @adminRejectVenue.
  ///
  /// In ru, this message translates to:
  /// **'На доработку'**
  String get adminRejectVenue;

  /// No description provided for @adminVerifyHalal.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить Халал'**
  String get adminVerifyHalal;

  /// No description provided for @adminRejectHalal.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить Халал'**
  String get adminRejectHalal;

  /// No description provided for @adminHalalStatusVerified.
  ///
  /// In ru, this message translates to:
  /// **'Халал проверен'**
  String get adminHalalStatusVerified;

  /// No description provided for @adminHalalStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'Халал на проверке'**
  String get adminHalalStatusPending;

  /// No description provided for @adminHalalStatusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Халал отклонён'**
  String get adminHalalStatusRejected;

  /// No description provided for @adminHalalStatusNone.
  ///
  /// In ru, this message translates to:
  /// **'Без Халал'**
  String get adminHalalStatusNone;

  /// No description provided for @adminRejectReasonHint.
  ///
  /// In ru, this message translates to:
  /// **'Укажите замечание для магазина'**
  String get adminRejectReasonHint;

  /// No description provided for @adminHideBox.
  ///
  /// In ru, this message translates to:
  /// **'Снять с публикации'**
  String get adminHideBox;

  /// No description provided for @adminRestoreBox.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть в продажу'**
  String get adminRestoreBox;

  /// No description provided for @adminBoxStatusActive.
  ///
  /// In ru, this message translates to:
  /// **'Активен'**
  String get adminBoxStatusActive;

  /// No description provided for @adminBoxStatusSoldOut.
  ///
  /// In ru, this message translates to:
  /// **'Разобрали'**
  String get adminBoxStatusSoldOut;

  /// No description provided for @adminBoxStatusDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Скрыт'**
  String get adminBoxStatusDisabled;

  /// No description provided for @adminComplaintsTab.
  ///
  /// In ru, this message translates to:
  /// **'Жалобы'**
  String get adminComplaintsTab;

  /// No description provided for @adminAllOrdersTab.
  ///
  /// In ru, this message translates to:
  /// **'Все заказы'**
  String get adminAllOrdersTab;

  /// No description provided for @adminComplaintTakeInReview.
  ///
  /// In ru, this message translates to:
  /// **'Взять в работу'**
  String get adminComplaintTakeInReview;

  /// No description provided for @adminComplaintRefund.
  ///
  /// In ru, this message translates to:
  /// **'Решить с возвратом'**
  String get adminComplaintRefund;

  /// No description provided for @adminComplaintResolve.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть с ответом'**
  String get adminComplaintResolve;

  /// No description provided for @adminComplaintResolutionHint.
  ///
  /// In ru, this message translates to:
  /// **'Ответ покупателю (до 3 раб. дней)'**
  String get adminComplaintResolutionHint;

  /// No description provided for @adminComplaintStatusOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыта'**
  String get adminComplaintStatusOpen;

  /// No description provided for @adminComplaintStatusInReview.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get adminComplaintStatusInReview;

  /// No description provided for @adminComplaintStatusResolved.
  ///
  /// In ru, this message translates to:
  /// **'Решена'**
  String get adminComplaintStatusResolved;

  /// No description provided for @adminComplaintStatusRefunded.
  ///
  /// In ru, this message translates to:
  /// **'Возврат оформлен'**
  String get adminComplaintStatusRefunded;

  /// No description provided for @adminNoComplaintsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Открытых жалоб нет'**
  String get adminNoComplaintsTitle;

  /// No description provided for @adminNoComplaintsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Все обращения покупателей уже рассмотрены'**
  String get adminNoComplaintsSubtitle;

  /// No description provided for @venueModerationPendingBanner.
  ///
  /// In ru, this message translates to:
  /// **'Магазин на проверке: боксы появятся у покупателей после одобрения администратором.'**
  String get venueModerationPendingBanner;

  /// No description provided for @venueModerationRejectedBanner.
  ///
  /// In ru, this message translates to:
  /// **'Заявка требует правок'**
  String get venueModerationRejectedBanner;

  /// No description provided for @venueSettingsHalalNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер халал-сертификата'**
  String get venueSettingsHalalNumber;

  /// No description provided for @venueSettingsSubmitHalal.
  ///
  /// In ru, this message translates to:
  /// **'Отправить на проверку Халал'**
  String get venueSettingsSubmitHalal;

  /// No description provided for @animalQumbek.
  ///
  /// In ru, this message translates to:
  /// **'Құмбек'**
  String get animalQumbek;

  /// No description provided for @animalIrbis.
  ///
  /// In ru, this message translates to:
  /// **'Ирбис'**
  String get animalIrbis;

  /// No description provided for @animalSaigak.
  ///
  /// In ru, this message translates to:
  /// **'Сайгак'**
  String get animalSaigak;

  /// No description provided for @animalSeal.
  ///
  /// In ru, this message translates to:
  /// **'Тюлень'**
  String get animalSeal;

  /// No description provided for @qyzylKitapProgress.
  ///
  /// In ru, this message translates to:
  /// **'{saved} из {target} боксов — ещё {left}, и откроется {animal}'**
  String qyzylKitapProgress(int saved, int target, int left, String animal);

  /// No description provided for @qyzylKitapAllUnlocked.
  ///
  /// In ru, this message translates to:
  /// **'Все жители «Қызыл кітап» открыты! Вы спасаете планету каждый день.'**
  String get qyzylKitapAllUnlocked;

  /// No description provided for @qyzylKitapUnlocked.
  ///
  /// In ru, this message translates to:
  /// **'Открыт'**
  String get qyzylKitapUnlocked;

  /// No description provided for @qyzylKitapLockedLeft.
  ///
  /// In ru, this message translates to:
  /// **'ещё {count} боксов'**
  String qyzylKitapLockedLeft(int count);

  /// No description provided for @qyzylKitapNoMoneyNote.
  ///
  /// In ru, this message translates to:
  /// **'Коллекция отмечает ваш вклад в спасение еды — бонусы на деньги не обмениваются.'**
  String get qyzylKitapNoMoneyNote;

  /// No description provided for @venueOnboardingStep1.
  ///
  /// In ru, this message translates to:
  /// **'Заведение'**
  String get venueOnboardingStep1;

  /// No description provided for @venueOnboardingStep2.
  ///
  /// In ru, this message translates to:
  /// **'Адрес и часы'**
  String get venueOnboardingStep2;

  /// No description provided for @venueOnboardingStep3.
  ///
  /// In ru, this message translates to:
  /// **'Реквизиты'**
  String get venueOnboardingStep3;

  /// No description provided for @venueOnboardingStep4.
  ///
  /// In ru, this message translates to:
  /// **'Договор'**
  String get venueOnboardingStep4;

  /// No description provided for @venueNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название заведения'**
  String get venueNameLabel;

  /// No description provided for @venueAddressLabel.
  ///
  /// In ru, this message translates to:
  /// **'Адрес в Астане'**
  String get venueAddressLabel;

  /// No description provided for @venuePhoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Телефон для связи'**
  String get venuePhoneLabel;

  /// No description provided for @venueBinLabel.
  ///
  /// In ru, this message translates to:
  /// **'БИН / ИИН'**
  String get venueBinLabel;

  /// No description provided for @venueIbanLabel.
  ///
  /// In ru, this message translates to:
  /// **'ИИК (IBAN)'**
  String get venueIbanLabel;

  /// No description provided for @venueBikLabel.
  ///
  /// In ru, this message translates to:
  /// **'БИК'**
  String get venueBikLabel;

  /// No description provided for @venueContractText.
  ///
  /// In ru, this message translates to:
  /// **'Стандартный договор партнёрства toıdym: комиссия 15% с проданных боксов, еженедельные выплаты по понедельникам. Наличные расчёты и продажа запрещённых товаров не допускаются.'**
  String get venueContractText;

  /// No description provided for @venueContractAgree.
  ///
  /// In ru, this message translates to:
  /// **'Принимаю условия договора оферты'**
  String get venueContractAgree;

  /// No description provided for @venueSubmitApplication.
  ///
  /// In ru, this message translates to:
  /// **'Отправить заявку'**
  String get venueSubmitApplication;

  /// No description provided for @venueStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get venueStatusPending;

  /// No description provided for @venueStatusApproved.
  ///
  /// In ru, this message translates to:
  /// **'Одобрено'**
  String get venueStatusApproved;

  /// No description provided for @venueStatusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Нужно исправить'**
  String get venueStatusRejected;

  /// No description provided for @venueDemoStatusSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Демо-статус заявки'**
  String get venueDemoStatusSwitch;

  /// No description provided for @venueOpenDashboard.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в кабинет'**
  String get venueOpenDashboard;

  /// No description provided for @venueTodaySold.
  ///
  /// In ru, this message translates to:
  /// **'Продано'**
  String get venueTodaySold;

  /// No description provided for @venueTodayWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ждут выдачи'**
  String get venueTodayWaiting;

  /// No description provided for @venueTodayRevenue.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get venueTodayRevenue;

  /// No description provided for @venueQumbekTip.
  ///
  /// In ru, this message translates to:
  /// **'Публикуйте боксы до 16:00 — так покупатели заметят их заранее'**
  String get venueQumbekTip;

  /// No description provided for @venueInSale.
  ///
  /// In ru, this message translates to:
  /// **'В продаже'**
  String get venueInSale;

  /// No description provided for @venueStockLabel.
  ///
  /// In ru, this message translates to:
  /// **'Остаток'**
  String get venueStockLabel;

  /// No description provided for @venueNewBoxButton.
  ///
  /// In ru, this message translates to:
  /// **'Новый бокс'**
  String get venueNewBoxButton;

  /// No description provided for @venueNewBoxTitleField.
  ///
  /// In ru, this message translates to:
  /// **'Название бокса'**
  String get venueNewBoxTitleField;

  /// No description provided for @venueNewBoxType.
  ///
  /// In ru, this message translates to:
  /// **'Тип бокса'**
  String get venueNewBoxType;

  /// No description provided for @venueNewBoxSurprise.
  ///
  /// In ru, this message translates to:
  /// **'Сюрприз-бокс'**
  String get venueNewBoxSurprise;

  /// No description provided for @venueNewBoxSet.
  ///
  /// In ru, this message translates to:
  /// **'Конкретный набор'**
  String get venueNewBoxSet;

  /// No description provided for @venueNewBoxInside.
  ///
  /// In ru, this message translates to:
  /// **'Что может быть внутри'**
  String get venueNewBoxInside;

  /// No description provided for @venueNewBoxOriginalPrice.
  ///
  /// In ru, this message translates to:
  /// **'Обычная цена (₸)'**
  String get venueNewBoxOriginalPrice;

  /// No description provided for @venueNewBoxDiscountPrice.
  ///
  /// In ru, this message translates to:
  /// **'Цена в toıdym (₸)'**
  String get venueNewBoxDiscountPrice;

  /// No description provided for @venueNewBoxAutoDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка: {percent}%'**
  String venueNewBoxAutoDiscount(int percent);

  /// No description provided for @venueNewBoxLowDiscountWarn.
  ///
  /// In ru, this message translates to:
  /// **'Скидка меньше 50% — публикация невозможна'**
  String get venueNewBoxLowDiscountWarn;

  /// No description provided for @venueNewBoxYouReceive.
  ///
  /// In ru, this message translates to:
  /// **'Вы получите: {amount} с бокса'**
  String venueNewBoxYouReceive(String amount);

  /// No description provided for @venueNewBoxQuantity.
  ///
  /// In ru, this message translates to:
  /// **'Количество боксов'**
  String get venueNewBoxQuantity;

  /// No description provided for @venueNewBoxWindowStart.
  ///
  /// In ru, this message translates to:
  /// **'Начало выдачи'**
  String get venueNewBoxWindowStart;

  /// No description provided for @venueNewBoxWindowEnd.
  ///
  /// In ru, this message translates to:
  /// **'Конец выдачи'**
  String get venueNewBoxWindowEnd;

  /// No description provided for @venueNewBoxRepeatDays.
  ///
  /// In ru, this message translates to:
  /// **'Повтор по дням недели'**
  String get venueNewBoxRepeatDays;

  /// No description provided for @venueNewBoxAllergens.
  ///
  /// In ru, this message translates to:
  /// **'Аллергены'**
  String get venueNewBoxAllergens;

  /// No description provided for @venueNewBoxPreviewButton.
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр'**
  String get venueNewBoxPreviewButton;

  /// No description provided for @venueNewBoxPublishButton.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get venueNewBoxPublishButton;

  /// No description provided for @venueNewBoxHalalNoCertHint.
  ///
  /// In ru, this message translates to:
  /// **'Загрузите и подтвердите халал-сертификат в настройках'**
  String get venueNewBoxHalalNoCertHint;

  /// No description provided for @venuePickupScannerHint.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR покупателя'**
  String get venuePickupScannerHint;

  /// No description provided for @venuePickupSimulateQr.
  ///
  /// In ru, this message translates to:
  /// **'Демо: скан QR первого заказа'**
  String get venuePickupSimulateQr;

  /// No description provided for @venuePickupPinHint.
  ///
  /// In ru, this message translates to:
  /// **'4-значный код'**
  String get venuePickupPinHint;

  /// No description provided for @venuePickupGiveButton.
  ///
  /// In ru, this message translates to:
  /// **'Выдать заказ'**
  String get venuePickupGiveButton;

  /// No description provided for @venuePickupWaitingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ждут выдачи'**
  String get venuePickupWaitingTitle;

  /// No description provided for @venuePickupEmptyWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Нет заказов, ожидающих выдачи'**
  String get venuePickupEmptyWaiting;

  /// No description provided for @venuePickupSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Заказ {number} выдан!'**
  String venuePickupSuccess(String number);

  /// No description provided for @venuePickupCancelTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заказ'**
  String get venuePickupCancelTitle;

  /// No description provided for @venuePickupCancelReasonHint.
  ///
  /// In ru, this message translates to:
  /// **'Причина отмены (деньги вернутся покупателю автоматически)'**
  String get venuePickupCancelReasonHint;

  /// No description provided for @venueStatsDay.
  ///
  /// In ru, this message translates to:
  /// **'День'**
  String get venueStatsDay;

  /// No description provided for @venueStatsWeek.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get venueStatsWeek;

  /// No description provided for @venueStatsMonth.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get venueStatsMonth;

  /// No description provided for @venueStatsFoodSaved.
  ///
  /// In ru, this message translates to:
  /// **'Спасённая еда'**
  String get venueStatsFoodSaved;

  /// No description provided for @venueStatsCommission.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия'**
  String get venueStatsCommission;

  /// No description provided for @venueStatsNextPayout.
  ///
  /// In ru, this message translates to:
  /// **'Следующая выплата'**
  String get venueStatsNextPayout;

  /// No description provided for @venueStatsPayoutHistory.
  ///
  /// In ru, this message translates to:
  /// **'История выплат'**
  String get venueStatsPayoutHistory;

  /// No description provided for @venueStatsReviews.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг и отзывы'**
  String get venueStatsReviews;

  /// No description provided for @venueSettingsWorkHours.
  ///
  /// In ru, this message translates to:
  /// **'Часы работы'**
  String get venueSettingsWorkHours;

  /// No description provided for @venueSettingsStaff.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудники'**
  String get venueSettingsStaff;

  /// No description provided for @venueSettingsAddCashier.
  ///
  /// In ru, this message translates to:
  /// **'Добавить кассира'**
  String get venueSettingsAddCashier;

  /// No description provided for @venueSettingsCashierName.
  ///
  /// In ru, this message translates to:
  /// **'Имя кассира'**
  String get venueSettingsCashierName;

  /// No description provided for @venueSettingsSupport.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка партнёров'**
  String get venueSettingsSupport;

  /// No description provided for @venueSettingsSupportText.
  ///
  /// In ru, this message translates to:
  /// **'Telegram @toidym_partner · +7 (7172) 55-00-11'**
  String get venueSettingsSupportText;

  /// No description provided for @ruleDiscountTooLow.
  ///
  /// In ru, this message translates to:
  /// **'Скидка должна быть не меньше 50%'**
  String get ruleDiscountTooLow;

  /// No description provided for @ruleWindowTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Окно выдачи должно длиться минимум 30 минут'**
  String get ruleWindowTooShort;

  /// No description provided for @ruleWindowOutsideHours.
  ///
  /// In ru, this message translates to:
  /// **'Окно выдачи должно быть в рабочие часы заведения'**
  String get ruleWindowOutsideHours;

  /// No description provided for @rulePublishTooLate.
  ///
  /// In ru, this message translates to:
  /// **'Публикация возможна не позднее чем за 2 часа до начала выдачи'**
  String get rulePublishTooLate;

  /// No description provided for @ruleHalalCertRequired.
  ///
  /// In ru, this message translates to:
  /// **'Метка «Халал» доступна только с проверенным сертификатом'**
  String get ruleHalalCertRequired;

  /// No description provided for @ruleProhibitedItems.
  ///
  /// In ru, this message translates to:
  /// **'Запрещена продажа алкоголя, табака и просроченных продуктов'**
  String get ruleProhibitedItems;

  /// No description provided for @ruleInvalidPrice.
  ///
  /// In ru, this message translates to:
  /// **'Укажите корректную обычную цену и цену в toıdym'**
  String get ruleInvalidPrice;

  /// No description provided for @ruleInvalidQuantity.
  ///
  /// In ru, this message translates to:
  /// **'Количество боксов должно быть больше нуля'**
  String get ruleInvalidQuantity;

  /// No description provided for @timerMinutesShort.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String timerMinutesShort(int minutes);

  /// No description provided for @timerHoursMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String timerHoursMinutes(int hours, int minutes);

  /// No description provided for @weightKg.
  ///
  /// In ru, this message translates to:
  /// **'{value} кг'**
  String weightKg(String value);

  /// No description provided for @screenOnboardingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать в toıdym'**
  String get screenOnboardingTitle;

  /// No description provided for @screenHomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Боксы рядом'**
  String get screenHomeTitle;

  /// No description provided for @screenMapTitle.
  ///
  /// In ru, this message translates to:
  /// **'Карта боксов'**
  String get screenMapTitle;

  /// No description provided for @screenBoxDetailTitle.
  ///
  /// In ru, this message translates to:
  /// **'О боксе'**
  String get screenBoxDetailTitle;

  /// No description provided for @screenPaymentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оплата заказа'**
  String get screenPaymentTitle;

  /// No description provided for @screenOrderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Активный заказ'**
  String get screenOrderTitle;

  /// No description provided for @screenSuccessTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ас болсын!'**
  String get screenSuccessTitle;

  /// No description provided for @screenOrdersHistoryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get screenOrdersHistoryTitle;

  /// No description provided for @screenProfileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get screenProfileTitle;

  /// No description provided for @screenQyzylKitapTitle.
  ///
  /// In ru, this message translates to:
  /// **'Қызыл кітап'**
  String get screenQyzylKitapTitle;

  /// No description provided for @screenVenueOnboardingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подключение заведения'**
  String get screenVenueOnboardingTitle;

  /// No description provided for @screenVenueBoxesTodayTitle.
  ///
  /// In ru, this message translates to:
  /// **'Боксы сегодня'**
  String get screenVenueBoxesTodayTitle;

  /// No description provided for @screenVenueNewBoxTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый бокс'**
  String get screenVenueNewBoxTitle;

  /// No description provided for @screenVenuePickupTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выдача заказов'**
  String get screenVenuePickupTitle;

  /// No description provided for @screenVenueStatsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Итоги и выплаты'**
  String get screenVenueStatsTitle;

  /// No description provided for @screenVenueSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки заведения'**
  String get screenVenueSettingsTitle;

  /// No description provided for @phaseFoundationStubNote.
  ///
  /// In ru, this message translates to:
  /// **'Каркас экрана'**
  String get phaseFoundationStubNote;

  /// No description provided for @dietHalalOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только Халал'**
  String get dietHalalOnly;

  /// No description provided for @dietVegetarian.
  ///
  /// In ru, this message translates to:
  /// **'Вегетарианское'**
  String get dietVegetarian;

  /// No description provided for @dietNutFree.
  ///
  /// In ru, this message translates to:
  /// **'Без орехов'**
  String get dietNutFree;

  /// No description provided for @sortNearest.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшие'**
  String get sortNearest;

  /// No description provided for @sortEndingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро закончатся'**
  String get sortEndingSoon;

  /// No description provided for @sortMaxDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Макс. скидка'**
  String get sortMaxDiscount;

  /// No description provided for @venueStatusBanned.
  ///
  /// In ru, this message translates to:
  /// **'Заблокирован'**
  String get venueStatusBanned;

  /// No description provided for @orderStatusReserved.
  ///
  /// In ru, this message translates to:
  /// **'Забронировано'**
  String get orderStatusReserved;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Выдано'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelledByUser.
  ///
  /// In ru, this message translates to:
  /// **'Отменено вами'**
  String get orderStatusCancelledByUser;

  /// No description provided for @orderStatusCancelledByVenue.
  ///
  /// In ru, this message translates to:
  /// **'Отменено заведением'**
  String get orderStatusCancelledByVenue;

  /// No description provided for @orderStatusNoShow.
  ///
  /// In ru, this message translates to:
  /// **'Неявка (Strike)'**
  String get orderStatusNoShow;

  /// No description provided for @paymentOnSite.
  ///
  /// In ru, this message translates to:
  /// **'Оплата при получении'**
  String get paymentOnSite;

  /// No description provided for @adminBoxStatusExpired.
  ///
  /// In ru, this message translates to:
  /// **'В архиве'**
  String get adminBoxStatusExpired;

  /// No description provided for @authLoginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход в toıdym'**
  String get authLoginTitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get authRegisterTitle;

  /// No description provided for @authTabLogin.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get authTabLogin;

  /// No description provided for @authTabRegister.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get authTabRegister;

  /// No description provided for @authNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get authNameLabel;

  /// No description provided for @authEmailLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailOrPhoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email или телефон'**
  String get authEmailOrPhoneLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Мин. 8 символов, 1 цифра и 1 заглавная буква'**
  String get authPasswordHint;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordSent.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка для сброса пароля отправлена на {email}'**
  String authForgotPasswordSent(String email);

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите Email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailBody.
  ///
  /// In ru, this message translates to:
  /// **'Мы отправили письмо со ссылкой подтверждения на {email}. Для демо нажмите кнопку ниже.'**
  String authVerifyEmailBody(String email);

  /// No description provided for @authVerifyEmailDemoButton.
  ///
  /// In ru, this message translates to:
  /// **'Демо: подтвердить Email'**
  String get authVerifyEmailDemoButton;

  /// No description provided for @authVerifiedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Email подтверждён! Теперь можно войти.'**
  String get authVerifiedSuccess;

  /// No description provided for @authErrInvalidPhone.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный казахстанский номер +7 (7XX) XXX-XX-XX'**
  String get authErrInvalidPhone;

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный Email'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать от 8 символов, 1 цифру и 1 заглавную букву'**
  String get authErrWeakPassword;

  /// No description provided for @authErrPasswordMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get authErrPasswordMismatch;

  /// No description provided for @authErrEmailExists.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь с таким Email уже зарегистрирован'**
  String get authErrEmailExists;

  /// No description provided for @authErrInvalidCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный логин или пароль'**
  String get authErrInvalidCredentials;

  /// No description provided for @authErrEmailNotVerified.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите Email перед входом'**
  String get authErrEmailNotVerified;

  /// No description provided for @authErrRateLimited.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток входа. Подождите 15 минут'**
  String get authErrRateLimited;

  /// No description provided for @authErrAccountBanned.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт временно заблокирован из-за 3 пропусков (No-Show)'**
  String get authErrAccountBanned;

  /// No description provided for @authDemoAccountsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Быстрый вход (демо-роли)'**
  String get authDemoAccountsTitle;

  /// No description provided for @forcePassTitle.
  ///
  /// In ru, this message translates to:
  /// **'Смените временный пароль'**
  String get forcePassTitle;

  /// No description provided for @forcePassSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Для защиты кабинета партнёра задайте постоянный пароль перед работой'**
  String get forcePassSubtitle;

  /// No description provided for @forcePassNewLabel.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get forcePassNewLabel;

  /// No description provided for @forcePassSaveButton.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить пароль и войти'**
  String get forcePassSaveButton;

  /// No description provided for @onboardingDietaryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения в еде'**
  String get onboardingDietaryTitle;

  /// No description provided for @onboardingDietarySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте фильтры — подходящие боксы всегда будут выше'**
  String get onboardingDietarySubtitle;

  /// No description provided for @onboardingPartnerCta.
  ///
  /// In ru, this message translates to:
  /// **'Для бизнеса: подключить заведение'**
  String get onboardingPartnerCta;

  /// No description provided for @homeSortLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get homeSortLabel;

  /// No description provided for @homeGuestBanner.
  ///
  /// In ru, this message translates to:
  /// **'Гостевой режим: просматривайте боксы свободно, вход — при бронировании.'**
  String get homeGuestBanner;

  /// No description provided for @boxDietaryMismatchWarn.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте состав — может не подходить по фильтру'**
  String get boxDietaryMismatchWarn;

  /// No description provided for @screenReserveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждение брони'**
  String get screenReserveTitle;

  /// No description provided for @bookingOfflineTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оплата при получении (Trust Booking)'**
  String get bookingOfflineTitle;

  /// No description provided for @bookingOfflineBody.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн-предоплата не нужна — вы оплачиваете бокс на кассе при получении. Если не заберёте заказ без отмены за 1 час, будет начислен Strike (3 Strike = бан на 30 дней).'**
  String get bookingOfflineBody;

  /// No description provided for @bookingOfflineAcceptButton.
  ///
  /// In ru, this message translates to:
  /// **'Понимаю, забронировать'**
  String get bookingOfflineAcceptButton;

  /// No description provided for @paymentOfflineBadge.
  ///
  /// In ru, this message translates to:
  /// **'Оплата при получении (Kaspi QR / карта / наличные на кассе)'**
  String get paymentOfflineBadge;

  /// No description provided for @paymentRuleStrike.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатная отмена возможна не позднее чем за 1 час до выдачи. За неявку (No-Show) начисляется Strike.'**
  String get paymentRuleStrike;

  /// No description provided for @actionConfirmReserve.
  ///
  /// In ru, this message translates to:
  /// **'Забронировать за {price}'**
  String actionConfirmReserve(String price);

  /// No description provided for @orderReminder30m.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание: окно выдачи начинается через 30 минут'**
  String get orderReminder30m;

  /// No description provided for @orderReminder15m.
  ///
  /// In ru, this message translates to:
  /// **'Успевайте! До закрытия окна выдачи осталось менее 15 минут'**
  String get orderReminder15m;

  /// No description provided for @orderUrgentClosing.
  ///
  /// In ru, this message translates to:
  /// **'Срочно: до конца выдачи {time}!'**
  String orderUrgentClosing(String time);

  /// No description provided for @orderRouteChooseMap.
  ///
  /// In ru, this message translates to:
  /// **'Открыть маршрут в картах'**
  String get orderRouteChooseMap;

  /// No description provided for @orderOpen2Gis.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в 2GIS'**
  String get orderOpen2Gis;

  /// No description provided for @orderOpenYandexMaps.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в Яндекс Картах'**
  String get orderOpenYandexMaps;

  /// No description provided for @orderDemoNoShow.
  ///
  /// In ru, this message translates to:
  /// **'Демо: отметить неявку (No-Show)'**
  String get orderDemoNoShow;

  /// No description provided for @orderNoShowRecorded.
  ///
  /// In ru, this message translates to:
  /// **'Отмечена неявка (No-Show). Начислен +1 Strike'**
  String get orderNoShowRecorded;

  /// No description provided for @profileStrikesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Надёжность (Strikes)'**
  String get profileStrikesTitle;

  /// No description provided for @profileStrikesCount.
  ///
  /// In ru, this message translates to:
  /// **'Нарушений: {count} из 3'**
  String profileStrikesCount(int count);

  /// No description provided for @profileBannedUntil.
  ///
  /// In ru, this message translates to:
  /// **'Бронирование ограничено до {date}'**
  String profileBannedUntil(String date);

  /// No description provided for @profileDietSettingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои фильтры питания'**
  String get profileDietSettingsTitle;

  /// No description provided for @shareImageFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подготовить картинку, текст скопирован'**
  String get shareImageFailed;

  /// No description provided for @shareImageReady.
  ///
  /// In ru, this message translates to:
  /// **'Карточка подготовлена к отправке!'**
  String get shareImageReady;

  /// No description provided for @partnerLeadTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заявка на партнёрство'**
  String get partnerLeadTitle;

  /// No description provided for @partnerLeadSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Оставьте контакты заведения — подключим кабинет без комиссии (0%) и выдадим временный пароль.'**
  String get partnerLeadSubtitle;

  /// No description provided for @partnerLeadEmailLabel.
  ///
  /// In ru, this message translates to:
  /// **'Email партнёра'**
  String get partnerLeadEmailLabel;

  /// No description provided for @partnerLeadSuccessTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отправлена!'**
  String get partnerLeadSuccessTitle;

  /// No description provided for @partnerLeadSuccessBody.
  ///
  /// In ru, this message translates to:
  /// **'Статус: На проверке (PENDING). После одобрения администратором вход откроется с временным паролем.'**
  String get partnerLeadSuccessBody;

  /// No description provided for @venueTabToday.
  ///
  /// In ru, this message translates to:
  /// **'Бүгінгі (Сегодня)'**
  String get venueTabToday;

  /// No description provided for @venueTabArchive.
  ///
  /// In ru, this message translates to:
  /// **'Мұрағат (Архив)'**
  String get venueTabArchive;

  /// No description provided for @venueArchiveEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Архивных боксов пока нет'**
  String get venueArchiveEmpty;

  /// No description provided for @venueRepublishButton.
  ///
  /// In ru, this message translates to:
  /// **'Перевыставить на сегодня'**
  String get venueRepublishButton;

  /// No description provided for @venueRepublishedSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Бокс перевыставлен в продажу!'**
  String get venueRepublishedSuccess;

  /// No description provided for @venueTemplatesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Менің шаблондарым (в 1 клик)'**
  String get venueTemplatesTitle;

  /// No description provided for @venueSaveAsTemplate.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить как шаблон'**
  String get venueSaveAsTemplate;

  /// No description provided for @venueTemplateApplied.
  ///
  /// In ru, this message translates to:
  /// **'Шаблон «{name}» применён'**
  String venueTemplateApplied(String name);

  /// No description provided for @venueNewBoxVegetarian.
  ///
  /// In ru, this message translates to:
  /// **'Вегетарианский бокс'**
  String get venueNewBoxVegetarian;

  /// No description provided for @venueNewBoxNoCommissionNote.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия платформы: 0% · гость платит на кассе'**
  String get venueNewBoxNoCommissionNote;

  /// No description provided for @venuePickupEnterPinTitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите 4-значный PIN заказа'**
  String get venuePickupEnterPinTitle;

  /// No description provided for @venuePickupPinWrong.
  ///
  /// In ru, this message translates to:
  /// **'Неверный PIN-код или заказ не найден'**
  String get venuePickupPinWrong;

  /// No description provided for @venuePickupClear.
  ///
  /// In ru, this message translates to:
  /// **'Сброс'**
  String get venuePickupClear;

  /// No description provided for @venueStatsZeroCommission.
  ///
  /// In ru, this message translates to:
  /// **'Комиссия 0% (без удержаний)'**
  String get venueStatsZeroCommission;

  /// No description provided for @venueStatsCompletedOrders.
  ///
  /// In ru, this message translates to:
  /// **'Выдано заказов'**
  String get venueStatsCompletedOrders;

  /// No description provided for @venueStatsNoShowOrders.
  ///
  /// In ru, this message translates to:
  /// **'Неявки (No-Show)'**
  String get venueStatsNoShowOrders;

  /// No description provided for @venueStatsLostProfitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Упущенная выгода'**
  String get venueStatsLostProfitTitle;

  /// No description provided for @venueStatsLostProfitSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Невыкупленных боксов: {count} шт.'**
  String venueStatsLostProfitSubtitle(int count);

  /// No description provided for @venueQumbekAdviceHighRemaining.
  ///
  /// In ru, this message translates to:
  /// **'Совет Құмбек: остались невыкупленные боксы — снизьте цену на 15% или сдвиньте окно выдачи на 30 мин позже.'**
  String get venueQumbekAdviceHighRemaining;

  /// No description provided for @venueQumbekAdviceHighNoShow.
  ///
  /// In ru, this message translates to:
  /// **'Совет Құмбек: были неявки (No-Show). Напоминайте гостям подтвердить бронь за час до выдачи.'**
  String get venueQumbekAdviceHighNoShow;

  /// No description provided for @venueQumbekAdviceGreat.
  ///
  /// In ru, this message translates to:
  /// **'Совет Құмбек: отличная оборачиваемость! Сохраните лучший бокс в шаблоны для публикации в 1 клик.'**
  String get venueQumbekAdviceGreat;

  /// No description provided for @adminActiveVenuesUsersLabel.
  ///
  /// In ru, this message translates to:
  /// **'Активные магазины / гости'**
  String get adminActiveVenuesUsersLabel;

  /// No description provided for @adminCompletedBoxesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Продано (COMPLETED)'**
  String get adminCompletedBoxesLabel;

  /// No description provided for @adminZeroCommissionBadge.
  ///
  /// In ru, this message translates to:
  /// **'Без комиссии (0%)'**
  String get adminZeroCommissionBadge;

  /// No description provided for @adminAddPartnerButton.
  ///
  /// In ru, this message translates to:
  /// **'Добавить партнёра'**
  String get adminAddPartnerButton;

  /// No description provided for @adminTempPasswordCreated.
  ///
  /// In ru, this message translates to:
  /// **'Партнёр подключён! Временный пароль: {password} (Email: {email})'**
  String adminTempPasswordCreated(String password, String email);

  /// No description provided for @adminBanVenue.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать магазин'**
  String get adminBanVenue;

  /// No description provided for @adminUnbanVenue.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get adminUnbanVenue;

  /// No description provided for @adminVenueCompletedCount.
  ///
  /// In ru, this message translates to:
  /// **'Выдано: {count}'**
  String adminVenueCompletedCount(int count);

  /// No description provided for @adminVenueNoShowCount.
  ///
  /// In ru, this message translates to:
  /// **'No-Show: {count}'**
  String adminVenueNoShowCount(int count);

  /// No description provided for @adminDeleteBox.
  ///
  /// In ru, this message translates to:
  /// **'Удалить бокс'**
  String get adminDeleteBox;

  /// No description provided for @adminStrikesTab.
  ///
  /// In ru, this message translates to:
  /// **'Strikes и Баны'**
  String get adminStrikesTab;

  /// No description provided for @adminAuditTab.
  ///
  /// In ru, this message translates to:
  /// **'Аудит (AuditLogs)'**
  String get adminAuditTab;

  /// No description provided for @adminRemoveStrike.
  ///
  /// In ru, this message translates to:
  /// **'Снять 1 Strike'**
  String get adminRemoveStrike;

  /// No description provided for @adminUnbanUser.
  ///
  /// In ru, this message translates to:
  /// **'Снять бан'**
  String get adminUnbanUser;

  /// No description provided for @adminUserStrikesBadge.
  ///
  /// In ru, this message translates to:
  /// **'Strikes: {count}/3'**
  String adminUserStrikesBadge(int count);

  /// No description provided for @adminAuditEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Записей аудита пока нет'**
  String get adminAuditEmpty;

  /// No description provided for @adminTableColVenue.
  ///
  /// In ru, this message translates to:
  /// **'Заведение'**
  String get adminTableColVenue;

  /// No description provided for @adminTableColDistrict.
  ///
  /// In ru, this message translates to:
  /// **'Район'**
  String get adminTableColDistrict;

  /// No description provided for @adminTableColStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get adminTableColStatus;

  /// No description provided for @adminTableColHalal.
  ///
  /// In ru, this message translates to:
  /// **'Халал'**
  String get adminTableColHalal;

  /// No description provided for @adminTableColStats.
  ///
  /// In ru, this message translates to:
  /// **'Выдано / No-Show'**
  String get adminTableColStats;

  /// No description provided for @adminTableColActions.
  ///
  /// In ru, this message translates to:
  /// **'Действия'**
  String get adminTableColActions;

  /// No description provided for @adminFilterBanned.
  ///
  /// In ru, this message translates to:
  /// **'Заблокированные'**
  String get adminFilterBanned;

  /// No description provided for @navAdminAudit.
  ///
  /// In ru, this message translates to:
  /// **'Аудит'**
  String get navAdminAudit;

  /// No description provided for @badgeResaleHot.
  ///
  /// In ru, this message translates to:
  /// **'Горит! · Заберите срочно'**
  String get badgeResaleHot;

  /// No description provided for @badgeResaleTag.
  ///
  /// In ru, this message translates to:
  /// **'Авто-перепродажа (Resale)'**
  String get badgeResaleTag;

  /// No description provided for @venueNewBoxSprintTitle.
  ///
  /// In ru, this message translates to:
  /// **'Спринт-окно 15 минут'**
  String get venueNewBoxSprintTitle;

  /// No description provided for @venueNewBoxSprintSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'По правилу сервиса выдача начинается за 1 ч до закрытия ({window}) и длится ровно 15 мин'**
  String venueNewBoxSprintSubtitle(String window);

  /// No description provided for @orderSprintTimerLabel.
  ///
  /// In ru, this message translates to:
  /// **'15-мин Спринт: {time}'**
  String orderSprintTimerLabel(String time);

  /// No description provided for @orderResaleErrorMessage.
  ///
  /// In ru, this message translates to:
  /// **'Извините, вы не успели. Заказ выставлен на перепродажу другим пользователям'**
  String get orderResaleErrorMessage;

  /// No description provided for @orderDemoExpireSprint.
  ///
  /// In ru, this message translates to:
  /// **'Демо: 15 мин вышли (00:00 → Resale)'**
  String get orderDemoExpireSprint;

  /// No description provided for @fcmStrikeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ аннулирован (No-Show)'**
  String get fcmStrikeTitle;

  /// No description provided for @fcmStrikeBody.
  ///
  /// In ru, this message translates to:
  /// **'Заказ аннулирован, вам начислено 1 предупреждение (Strike)'**
  String get fcmStrikeBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
