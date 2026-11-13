// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'toıdym';

  @override
  String get brandPhrase => 'Ас болсын!';

  @override
  String get brandSlogan => 'Спасай вкусную еду до −70%';

  @override
  String get qyzylKitapTitle => 'Қызыл кітап';

  @override
  String get qumbekName => 'Құмбек';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageTitle => 'Язык приложения';

  @override
  String get navBoxes => 'Боксы';

  @override
  String get navMap => 'Карта';

  @override
  String get navOrders => 'Заказы';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navVenueBoxes => 'Боксы';

  @override
  String get navVenuePickup => 'Выдача';

  @override
  String get navVenueStats => 'Итоги';

  @override
  String get districtEsil => 'Есиль';

  @override
  String get districtAlmaty => 'Алматы';

  @override
  String get districtSaryarka => 'Сарыарка';

  @override
  String get districtBaiqonyr => 'Байқоңыр';

  @override
  String get districtAllAstana => 'Вся Астана';

  @override
  String get cityAstana => 'Астана';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryBakery => 'Выпечка';

  @override
  String get categoryHotFood => 'Горячее';

  @override
  String get categoryHalal => 'Халал';

  @override
  String get categoryCoffee => 'Кофе';

  @override
  String get categoryGrocery => 'Магазин';

  @override
  String get badgeHalal => 'Халал';

  @override
  String get badgeEndingSoon => 'Скоро закончатся';

  @override
  String badgeLeftCount(int count) {
    return 'Осталось $count';
  }

  @override
  String get badgeSoldOut => 'Разобрали';

  @override
  String pickupToday(String window) {
    return 'Забрать сегодня $window';
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
    return '$count боксов рядом ждут спасения';
  }

  @override
  String get actionStart => 'Начать';

  @override
  String get actionRepresentVenue => 'Я представляю заведение';

  @override
  String get actionRetry => 'Повторить';

  @override
  String actionReserveFor(String price) {
    return 'Забронировать за $price';
  }

  @override
  String actionPayAmount(String price) {
    return 'Оплатить $price';
  }

  @override
  String get actionLogin => 'Войти';

  @override
  String get actionLogout => 'Выйти';

  @override
  String get actionDone => 'Готово';

  @override
  String get actionCancel => 'Отменить';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionNext => 'Далее';

  @override
  String get actionBack => 'Назад';

  @override
  String get actionShare => 'Поделиться';

  @override
  String get actionDetails => 'Подробнее';

  @override
  String get actionRoute => 'Маршрут';

  @override
  String get actionCall => 'Позвонить';

  @override
  String get actionResetFilters => 'Сбросить фильтры';

  @override
  String get actionAddToFavorites => 'Добавить в избранное';

  @override
  String get actionRemoveFromFavorites => 'Убрать из избранного';

  @override
  String get actionSwitchToVenue => 'Режим заведения';

  @override
  String get actionSwitchToBuyer => 'Покупатель';

  @override
  String get actionBecomePartner => 'Стать партнёром';

  @override
  String get stateErrorTitle => 'Не удалось загрузить';

  @override
  String get stateErrorSubtitle => 'Проверьте соединение и попробуйте ещё раз';

  @override
  String get stateEmptyBoxesTitle => 'Рядом пока нет боксов';

  @override
  String get stateEmptyBoxesSubtitle =>
      'Құмбек ищет новые предложения — загляните чуть позже или смените фильтр';

  @override
  String get onboardingLocationTitle => 'Где спасать боксы?';

  @override
  String get onboardingLocationSubtitle =>
      'Разрешите геопозицию или выберите район Астаны — аккаунт пока не нужен';

  @override
  String get onboardingDetectLocation => 'Определить геопозицию';

  @override
  String onboardingLocationDetected(String district) {
    return 'Определено: Астана, $district';
  }

  @override
  String get onboardingOrChooseDistrict => 'Или выберите район вручную';

  @override
  String get homeGreeting => 'Сәлем! Что спасём сегодня?';

  @override
  String homeGreetingNamed(String name) {
    return 'Сәлем, $name! Выберите бокс';
  }

  @override
  String get homeSearchHint => 'Поиск бокса или заведения';

  @override
  String get homeViewList => 'Список';

  @override
  String get homeViewMap => 'На карте';

  @override
  String get homeNotificationsTitle => 'Уведомления';

  @override
  String get homeMarkAllRead => 'Прочитать все';

  @override
  String get homeEndingSoonSection => 'Скоро закончатся';

  @override
  String get homeAllBoxesSection => 'Все предложения';

  @override
  String get homeSimulateError => 'Проверить экран ошибки';

  @override
  String get mapYouAreHere => 'Вы здесь';

  @override
  String get mapCenterOnMe => 'Центрировать';

  @override
  String get mapOpenInList => 'Списком';

  @override
  String get boxDetailSurpriseTitle => 'Что обычно внутри';

  @override
  String get boxDetailSurpriseDisclaimer =>
      'Состав зависит от того, что осталось за день. Не совпало с описанием — можно отказаться при получении.';

  @override
  String get boxDetailAllergensTitle => 'Аллергены';

  @override
  String get boxDetailAllergensEmpty => 'Основные аллергены не указаны';

  @override
  String get boxDetailAllergensNote =>
      'При аллергии уточните состав на месте до получения.';

  @override
  String get boxDetailPickupOnlyBadge => 'Только самовывоз';

  @override
  String get boxDetailReviewsTitle => 'Отзывы гостей';

  @override
  String boxDetailShareMessage(String title, String venue, String price) {
    return 'Спасаю бокс «$title» в $venue за $price через toıdym!';
  }

  @override
  String boxDetailRouteOpening(String address, String lat, String lng) {
    return 'Маршрут до $address (Астана): $lat, $lng';
  }

  @override
  String get authPhoneTitle => 'Войдите, чтобы спасти бокс';

  @override
  String get authPhoneSubtitle =>
      'Отправим короткий код в SMS для подтверждения заказа';

  @override
  String get authPhoneLabel => 'Номер телефона';

  @override
  String get authPhoneHint => '+7 (777) 123-45-67';

  @override
  String get authSendCode => 'Получить код';

  @override
  String get authSmsTitle => 'Введите код из SMS';

  @override
  String authSmsSubtitle(String phone) {
    return 'Мы отправили 4-значный код на $phone';
  }

  @override
  String get authSmsHint => 'Введите 4-значный код (демо: 1234)';

  @override
  String get authConfirmCode => 'Подтвердить';

  @override
  String get authChangePhone => 'Изменить номер';

  @override
  String get authInvalidCode => 'Неверный код. Для демо используйте 1234';

  @override
  String get guestBenefitsTitle => 'Войдите в аккаунт';

  @override
  String get guestBenefitsSubtitle =>
      'Сохраняйте любимые места, копите спасённые боксы и открывайте жителей «Қызыл кітап»';

  @override
  String get guestBenefitOrders => 'История всех заказов и быстрый доступ к QR';

  @override
  String get guestBenefitStats =>
      'Подсчёт спасённых килограммов еды и экономии';

  @override
  String get guestBenefitKitap => 'Коллекция редких животных «Қызыл кітап»';

  @override
  String get paymentQuantityLabel => 'Количество боксов';

  @override
  String get paymentMethodTitle => 'Способ оплаты';

  @override
  String get paymentKaspi => 'Kaspi.kz';

  @override
  String get paymentKaspiHint => 'Счёт придёт в приложение Kaspi';

  @override
  String get paymentCard => 'Банковская карта';

  @override
  String get paymentCardNumberLabel => 'Номер карты';

  @override
  String get paymentCardExpiryLabel => 'Срок (ММ/ГГ)';

  @override
  String get paymentCardCvvLabel => 'CVV';

  @override
  String get paymentCardInvalid => 'Проверьте данные карты';

  @override
  String get paymentRegularPrice => 'Обычная цена';

  @override
  String get paymentYouSave => 'Вы экономите';

  @override
  String get paymentTotal => 'Итого';

  @override
  String get paymentRuleRefund =>
      'Если заведение отменит бокс, бронь аннулируется без штрафа (Strike не начисляется).';

  @override
  String get paymentRuleCharity =>
      'Не успели в окно без отмены за 1 час — начисляется Strike (3 Strike = бан 30 дней).';

  @override
  String get paymentSimulateError => 'Демо: имитировать сбой бронирования';

  @override
  String get paymentProcessing => 'Оформляем бронь...';

  @override
  String orderTitle(String number) {
    return 'Заказ $number';
  }

  @override
  String get orderShowQrHint => 'Покажите QR или назовите код на кассе';

  @override
  String get orderPinLabel => 'Код выдачи';

  @override
  String orderCountdownBefore(String time) {
    return 'До выдачи $time';
  }

  @override
  String orderCountdownDuring(String time) {
    return 'Окно выдачи открыто · осталось $time';
  }

  @override
  String get orderCountdownEnded => 'Окно выдачи завершилось';

  @override
  String get orderCancelButton => 'Отменить заказ';

  @override
  String get orderCancelBlockedHint =>
      'Отменить можно не позднее чем за 1 час до начала выдачи';

  @override
  String get orderCancelConfirmTitle => 'Отменить заказ?';

  @override
  String get orderCancelConfirmBody =>
      'Бокс снова станет доступен другим покупателям без начисления Strike.';

  @override
  String get orderProblemButton => 'Проблема с заказом';

  @override
  String get orderDemoCompletePickup => 'Демо: заведение выдало заказ';

  @override
  String get orderCallDialogTitle => 'Позвонить в заведение';

  @override
  String orderCallDialogBody(String phone) {
    return 'Контактный номер: $phone';
  }

  @override
  String get complaintTitle => 'Проблема с заказом';

  @override
  String get complaintSubtitle =>
      'Опишите, что пошло не так. Жалоба принимается в течение 24 часов после получения, ответ — до 3 рабочих дней.';

  @override
  String get complaintNoteHint =>
      'Например: состав сильно отличался от описания или бокс оказался несвежим';

  @override
  String get complaintAddPhoto => 'Прикрепить фото';

  @override
  String get complaintPhotoAdded => 'Фото прикреплено';

  @override
  String get complaintSubmit => 'Отправить жалобу';

  @override
  String get complaintSubmittedToast =>
      'Жалоба принята. Ответим в течение 3 рабочих дней';

  @override
  String get complaintAlreadySent => 'Жалоба по этому заказу уже отправлена';

  @override
  String successSavedSubtitle(String amount) {
    return 'Вы спасли бокс и сэкономили $amount';
  }

  @override
  String get successRateTitle => 'Как вам бокс?';

  @override
  String get successTagTasty => 'Вкусно';

  @override
  String get successTagPlenty => 'Много еды';

  @override
  String get successTagFresh => 'Свежее';

  @override
  String get successTagPolite => 'Вежливо';

  @override
  String get successCommentHint => 'Пара слов для заведения (необязательно)';

  @override
  String get successShareStories => 'Поделиться в сторис';

  @override
  String get successStoriesTitle => 'Открытка для сторис';

  @override
  String get successStoriesSaved =>
      'Открытка скопирована для публикации в сторис!';

  @override
  String get ordersTabActive => 'Активные';

  @override
  String get ordersTabPast => 'Прошедшие';

  @override
  String get ordersEmptyActiveTitle => 'Нет активных заказов';

  @override
  String get ordersEmptyActiveSubtitle =>
      'Выберите вкусный бокс на вечер и заберите его без очередей';

  @override
  String get ordersEmptyPastTitle => 'Прошедших заказов пока нет';

  @override
  String get ordersEmptyPastSubtitle =>
      'Здесь появится история ваших спасённых боксов';

  @override
  String get ordersOpenQr => 'Открыть QR';

  @override
  String get orderStatusPaid => 'Оплачено';

  @override
  String get orderStatusReady => 'Готов к выдаче';

  @override
  String get orderStatusPickedUp => 'Получен';

  @override
  String get orderStatusCancelled => 'Отменён';

  @override
  String get orderStatusExpired => 'Время вышло';

  @override
  String get profileBoxesSaved => 'Боксов спасено';

  @override
  String get profileKgSaved => 'Еды не в мусор';

  @override
  String get profileMoneySaved => 'Сэкономлено';

  @override
  String get profileFavoritesTitle => 'Избранное';

  @override
  String get profileFavoritesEmpty =>
      'Нажмите на сердечко у бокса, чтобы не потерять любимое заведение';

  @override
  String get profileFavoriteAlerts => 'Боксы в любимых местах';

  @override
  String get profileFavoriteAlertsSubtitle =>
      'Напоминать, когда любимые места выставляют боксы';

  @override
  String get profileSnowfallAnimation => 'Анимация снегопада';

  @override
  String get profileSnowfallSubtitle =>
      'Зимняя праздничная атмосфера в приложении';

  @override
  String get profileCharityTitle => 'Подвешенный бокс для фонда';

  @override
  String get profileCharitySubtitle =>
      'Оплатите бокс — мы передадим его в благотворительный фонд Астаны';

  @override
  String get profileCharityConfirm => 'Подарить бокс фонду';

  @override
  String get profileCharitySuccess =>
      'Спасибо! Вы оплатили подвешенный бокс для фонда';

  @override
  String get profileRoleDemoTitle => 'Роль и панели системы';

  @override
  String get profileRoleBuyer => 'Покупатель';

  @override
  String get profileRoleOwner => 'Владелец магазина';

  @override
  String get profileRoleCashier => 'Кассир';

  @override
  String get profileRoleAdmin => 'Администратор';

  @override
  String get actionSwitchToAdmin => 'Админ-панель';

  @override
  String get actionOpenAdminDemo => 'Админ-панель';

  @override
  String get navAdminOverview => 'Сводка';

  @override
  String get navAdminVenues => 'Магазины';

  @override
  String get navAdminBoxes => 'Боксы';

  @override
  String get navAdminComplaints => 'Жалобы';

  @override
  String get screenAdminOverviewTitle => 'Админ-панель · Сводка';

  @override
  String get screenAdminVenuesTitle => 'Магазины и Халал';

  @override
  String get screenAdminBoxesTitle => 'Каталог боксов';

  @override
  String get screenAdminComplaintsTitle => 'Жалобы и заказы';

  @override
  String get adminGmvLabel => 'Оборот (GMV)';

  @override
  String get adminCommissionLabel => 'Комиссия 15%';

  @override
  String get adminVenuesCountLabel => 'Магазины';

  @override
  String get adminOpenComplaintsLabel => 'Открытые жалобы';

  @override
  String get adminPendingQueueTitle => 'Требуют проверки';

  @override
  String get adminRecentOrdersTitle => 'Последние заказы';

  @override
  String get adminFilterAll => 'Все';

  @override
  String get adminFilterPending => 'На проверке';

  @override
  String get adminFilterApproved => 'Одобренные';

  @override
  String get adminFilterRejected => 'Отклонённые';

  @override
  String get adminApproveVenue => 'Одобрить магазин';

  @override
  String get adminRejectVenue => 'На доработку';

  @override
  String get adminVerifyHalal => 'Подтвердить Халал';

  @override
  String get adminRejectHalal => 'Отклонить Халал';

  @override
  String get adminHalalStatusVerified => 'Халал проверен';

  @override
  String get adminHalalStatusPending => 'Халал на проверке';

  @override
  String get adminHalalStatusRejected => 'Халал отклонён';

  @override
  String get adminHalalStatusNone => 'Без Халал';

  @override
  String get adminRejectReasonHint => 'Укажите замечание для магазина';

  @override
  String get adminHideBox => 'Снять с публикации';

  @override
  String get adminRestoreBox => 'Вернуть в продажу';

  @override
  String get adminBoxStatusActive => 'Активен';

  @override
  String get adminBoxStatusSoldOut => 'Разобрали';

  @override
  String get adminBoxStatusDisabled => 'Скрыт';

  @override
  String get adminComplaintsTab => 'Жалобы';

  @override
  String get adminAllOrdersTab => 'Все заказы';

  @override
  String get adminComplaintTakeInReview => 'Взять в работу';

  @override
  String get adminComplaintRefund => 'Решить с возвратом';

  @override
  String get adminComplaintResolve => 'Закрыть с ответом';

  @override
  String get adminComplaintResolutionHint =>
      'Ответ покупателю (до 3 раб. дней)';

  @override
  String get adminComplaintStatusOpen => 'Открыта';

  @override
  String get adminComplaintStatusInReview => 'В работе';

  @override
  String get adminComplaintStatusResolved => 'Решена';

  @override
  String get adminComplaintStatusRefunded => 'Возврат оформлен';

  @override
  String get adminNoComplaintsTitle => 'Открытых жалоб нет';

  @override
  String get adminNoComplaintsSubtitle =>
      'Все обращения покупателей уже рассмотрены';

  @override
  String get venueModerationPendingBanner =>
      'Магазин на проверке: боксы появятся у покупателей после одобрения администратором.';

  @override
  String get venueModerationRejectedBanner => 'Заявка требует правок';

  @override
  String get venueSettingsHalalNumber => 'Номер халал-сертификата';

  @override
  String get venueSettingsSubmitHalal => 'Отправить на проверку Халал';

  @override
  String get animalQumbek => 'Құмбек';

  @override
  String get animalIrbis => 'Ирбис';

  @override
  String get animalSaigak => 'Сайгак';

  @override
  String get animalSeal => 'Тюлень';

  @override
  String qyzylKitapProgress(int saved, int target, int left, String animal) {
    return '$saved из $target боксов — ещё $left, и откроется $animal';
  }

  @override
  String get qyzylKitapAllUnlocked =>
      'Все жители «Қызыл кітап» открыты! Вы спасаете планету каждый день.';

  @override
  String get qyzylKitapUnlocked => 'Открыт';

  @override
  String qyzylKitapLockedLeft(int count) {
    return 'ещё $count боксов';
  }

  @override
  String get qyzylKitapNoMoneyNote =>
      'Коллекция отмечает ваш вклад в спасение еды — бонусы на деньги не обмениваются.';

  @override
  String get venueOnboardingStep1 => 'Заведение';

  @override
  String get venueOnboardingStep2 => 'Адрес и часы';

  @override
  String get venueOnboardingStep3 => 'Реквизиты';

  @override
  String get venueOnboardingStep4 => 'Договор';

  @override
  String get venueNameLabel => 'Название заведения';

  @override
  String get venueAddressLabel => 'Адрес в Астане';

  @override
  String get venuePhoneLabel => 'Телефон для связи';

  @override
  String get venueBinLabel => 'БИН / ИИН';

  @override
  String get venueIbanLabel => 'ИИК (IBAN)';

  @override
  String get venueBikLabel => 'БИК';

  @override
  String get venueContractText =>
      'Стандартный договор партнёрства toıdym: комиссия 15% с проданных боксов, еженедельные выплаты по понедельникам. Наличные расчёты и продажа запрещённых товаров не допускаются.';

  @override
  String get venueContractAgree => 'Принимаю условия договора оферты';

  @override
  String get venueSubmitApplication => 'Отправить заявку';

  @override
  String get venueStatusPending => 'На проверке';

  @override
  String get venueStatusApproved => 'Одобрено';

  @override
  String get venueStatusRejected => 'Нужно исправить';

  @override
  String get venueDemoStatusSwitch => 'Демо-статус заявки';

  @override
  String get venueOpenDashboard => 'Перейти в кабинет';

  @override
  String get venueTodaySold => 'Продано';

  @override
  String get venueTodayWaiting => 'Ждут выдачи';

  @override
  String get venueTodayRevenue => 'Выручка';

  @override
  String get venueQumbekTip =>
      'Публикуйте боксы до 16:00 — так покупатели заметят их заранее';

  @override
  String get venueInSale => 'В продаже';

  @override
  String get venueStockLabel => 'Остаток';

  @override
  String get venueNewBoxButton => 'Новый бокс';

  @override
  String get venueNewBoxTitleField => 'Название бокса';

  @override
  String get venueNewBoxType => 'Тип бокса';

  @override
  String get venueNewBoxSurprise => 'Сюрприз-бокс';

  @override
  String get venueNewBoxSet => 'Конкретный набор';

  @override
  String get venueNewBoxInside => 'Что может быть внутри';

  @override
  String get venueNewBoxOriginalPrice => 'Обычная цена (₸)';

  @override
  String get venueNewBoxDiscountPrice => 'Цена в toıdym (₸)';

  @override
  String venueNewBoxAutoDiscount(int percent) {
    return 'Скидка: $percent%';
  }

  @override
  String get venueNewBoxLowDiscountWarn =>
      'Скидка меньше 50% — публикация невозможна';

  @override
  String venueNewBoxYouReceive(String amount) {
    return 'Вы получите: $amount с бокса';
  }

  @override
  String get venueNewBoxQuantity => 'Количество боксов';

  @override
  String get venueNewBoxWindowStart => 'Начало выдачи';

  @override
  String get venueNewBoxWindowEnd => 'Конец выдачи';

  @override
  String get venueNewBoxRepeatDays => 'Повтор по дням недели';

  @override
  String get venueNewBoxAllergens => 'Аллергены';

  @override
  String get venueNewBoxPreviewButton => 'Предпросмотр';

  @override
  String get venueNewBoxPublishButton => 'Опубликовать';

  @override
  String get venueNewBoxHalalNoCertHint =>
      'Загрузите и подтвердите халал-сертификат в настройках';

  @override
  String get venuePickupScannerHint => 'Наведите камеру на QR покупателя';

  @override
  String get venuePickupSimulateQr => 'Демо: скан QR первого заказа';

  @override
  String get venuePickupPinHint => '4-значный код';

  @override
  String get venuePickupGiveButton => 'Выдать заказ';

  @override
  String get venuePickupWaitingTitle => 'Ждут выдачи';

  @override
  String get venuePickupEmptyWaiting => 'Нет заказов, ожидающих выдачи';

  @override
  String venuePickupSuccess(String number) {
    return 'Заказ $number выдан!';
  }

  @override
  String get venuePickupCancelTitle => 'Отменить заказ';

  @override
  String get venuePickupCancelReasonHint =>
      'Причина отмены (деньги вернутся покупателю автоматически)';

  @override
  String get venueStatsDay => 'День';

  @override
  String get venueStatsWeek => 'Неделя';

  @override
  String get venueStatsMonth => 'Месяц';

  @override
  String get venueStatsFoodSaved => 'Спасённая еда';

  @override
  String get venueStatsCommission => 'Комиссия';

  @override
  String get venueStatsNextPayout => 'Следующая выплата';

  @override
  String get venueStatsPayoutHistory => 'История выплат';

  @override
  String get venueStatsReviews => 'Рейтинг и отзывы';

  @override
  String get venueSettingsWorkHours => 'Часы работы';

  @override
  String get venueSettingsStaff => 'Сотрудники';

  @override
  String get venueSettingsAddCashier => 'Добавить кассира';

  @override
  String get venueSettingsCashierName => 'Имя кассира';

  @override
  String get venueSettingsSupport => 'Поддержка партнёров';

  @override
  String get venueSettingsSupportText =>
      'Telegram @toidym_partner · +7 (7172) 55-00-11';

  @override
  String get ruleDiscountTooLow => 'Скидка должна быть не меньше 50%';

  @override
  String get ruleWindowTooShort =>
      'Окно выдачи должно длиться минимум 30 минут';

  @override
  String get ruleWindowOutsideHours =>
      'Окно выдачи должно быть в рабочие часы заведения';

  @override
  String get rulePublishTooLate =>
      'Публикация возможна не позднее чем за 2 часа до начала выдачи';

  @override
  String get ruleHalalCertRequired =>
      'Метка «Халал» доступна только с проверенным сертификатом';

  @override
  String get ruleProhibitedItems =>
      'Запрещена продажа алкоголя, табака и просроченных продуктов';

  @override
  String get ruleInvalidPrice =>
      'Укажите корректную обычную цену и цену в toıdym';

  @override
  String get ruleInvalidQuantity => 'Количество боксов должно быть больше нуля';

  @override
  String timerMinutesShort(int minutes) {
    return '$minutes мин';
  }

  @override
  String timerHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String weightKg(String value) {
    return '$value кг';
  }

  @override
  String get screenOnboardingTitle => 'Добро пожаловать в toıdym';

  @override
  String get screenHomeTitle => 'Боксы рядом';

  @override
  String get screenMapTitle => 'Карта боксов';

  @override
  String get screenBoxDetailTitle => 'О боксе';

  @override
  String get screenPaymentTitle => 'Оплата заказа';

  @override
  String get screenOrderTitle => 'Активный заказ';

  @override
  String get screenSuccessTitle => 'Ас болсын!';

  @override
  String get screenOrdersHistoryTitle => 'Мои заказы';

  @override
  String get screenProfileTitle => 'Профиль';

  @override
  String get screenQyzylKitapTitle => 'Қызыл кітап';

  @override
  String get screenVenueOnboardingTitle => 'Подключение заведения';

  @override
  String get screenVenueBoxesTodayTitle => 'Боксы сегодня';

  @override
  String get screenVenueNewBoxTitle => 'Новый бокс';

  @override
  String get screenVenuePickupTitle => 'Выдача заказов';

  @override
  String get screenVenueStatsTitle => 'Итоги и выплаты';

  @override
  String get screenVenueSettingsTitle => 'Настройки заведения';

  @override
  String get phaseFoundationStubNote => 'Каркас экрана';

  @override
  String get dietHalalOnly => 'Только Халал';

  @override
  String get dietVegetarian => 'Вегетарианское';

  @override
  String get dietNutFree => 'Без орехов';

  @override
  String get sortNearest => 'Ближайшие';

  @override
  String get sortEndingSoon => 'Скоро закончатся';

  @override
  String get sortMaxDiscount => 'Макс. скидка';

  @override
  String get venueStatusBanned => 'Заблокирован';

  @override
  String get orderStatusReserved => 'Забронировано';

  @override
  String get orderStatusCompleted => 'Выдано';

  @override
  String get orderStatusCancelledByUser => 'Отменено вами';

  @override
  String get orderStatusCancelledByVenue => 'Отменено заведением';

  @override
  String get orderStatusNoShow => 'Неявка (Strike)';

  @override
  String get paymentOnSite => 'Оплата при получении';

  @override
  String get adminBoxStatusExpired => 'В архиве';

  @override
  String get authLoginTitle => 'Вход в toıdym';

  @override
  String get authRegisterTitle => 'Регистрация';

  @override
  String get authTabLogin => 'Вход';

  @override
  String get authTabRegister => 'Регистрация';

  @override
  String get authNameLabel => 'Имя';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailOrPhoneLabel => 'Email или телефон';

  @override
  String get authPasswordLabel => 'Пароль';

  @override
  String get authPasswordHint => 'Мин. 8 символов, 1 цифра и 1 заглавная буква';

  @override
  String get authConfirmPasswordLabel => 'Повторите пароль';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String authForgotPasswordSent(String email) {
    return 'Ссылка для сброса пароля отправлена на $email';
  }

  @override
  String get authVerifyEmailTitle => 'Подтвердите Email';

  @override
  String authVerifyEmailBody(String email) {
    return 'Мы отправили письмо со ссылкой подтверждения на $email. Для демо нажмите кнопку ниже.';
  }

  @override
  String get authVerifyEmailDemoButton => 'Демо: подтвердить Email';

  @override
  String get authVerifiedSuccess => 'Email подтверждён! Теперь можно войти.';

  @override
  String get authErrInvalidPhone =>
      'Введите корректный казахстанский номер +7 (7XX) XXX-XX-XX';

  @override
  String get authErrInvalidEmail => 'Введите корректный Email';

  @override
  String get authErrWeakPassword =>
      'Пароль должен содержать от 8 символов, 1 цифру и 1 заглавную букву';

  @override
  String get authErrPasswordMismatch => 'Пароли не совпадают';

  @override
  String get authErrEmailExists =>
      'Пользователь с таким Email уже зарегистрирован';

  @override
  String get authErrInvalidCredentials => 'Неверный логин или пароль';

  @override
  String get authErrEmailNotVerified => 'Подтвердите Email перед входом';

  @override
  String get authErrRateLimited =>
      'Слишком много попыток входа. Подождите 15 минут';

  @override
  String get authErrAccountBanned =>
      'Аккаунт временно заблокирован из-за 3 пропусков (No-Show)';

  @override
  String get authDemoAccountsTitle => 'Быстрый вход (демо-роли)';

  @override
  String get forcePassTitle => 'Смените временный пароль';

  @override
  String get forcePassSubtitle =>
      'Для защиты кабинета партнёра задайте постоянный пароль перед работой';

  @override
  String get forcePassNewLabel => 'Новый пароль';

  @override
  String get forcePassSaveButton => 'Сохранить пароль и войти';

  @override
  String get onboardingDietaryTitle => 'Предпочтения в еде';

  @override
  String get onboardingDietarySubtitle =>
      'Отметьте фильтры — подходящие боксы всегда будут выше';

  @override
  String get onboardingPartnerCta => 'Для бизнеса: подключить заведение';

  @override
  String get homeSortLabel => 'Сортировка';

  @override
  String get homeGuestBanner =>
      'Гостевой режим: просматривайте боксы свободно, вход — при бронировании.';

  @override
  String get boxDietaryMismatchWarn =>
      'Проверьте состав — может не подходить по фильтру';

  @override
  String get screenReserveTitle => 'Подтверждение брони';

  @override
  String get bookingOfflineTitle => 'Оплата при получении (Trust Booking)';

  @override
  String get bookingOfflineBody =>
      'Онлайн-предоплата не нужна — вы оплачиваете бокс на кассе при получении. Если не заберёте заказ без отмены за 1 час, будет начислен Strike (3 Strike = бан на 30 дней).';

  @override
  String get bookingOfflineAcceptButton => 'Понимаю, забронировать';

  @override
  String get paymentOfflineBadge =>
      'Оплата при получении (Kaspi QR / карта / наличные на кассе)';

  @override
  String get paymentRuleStrike =>
      'Бесплатная отмена возможна не позднее чем за 1 час до выдачи. За неявку (No-Show) начисляется Strike.';

  @override
  String actionConfirmReserve(String price) {
    return 'Забронировать за $price';
  }

  @override
  String get orderReminder30m =>
      'Напоминание: окно выдачи начинается через 30 минут';

  @override
  String get orderReminder15m =>
      'Успевайте! До закрытия окна выдачи осталось менее 15 минут';

  @override
  String orderUrgentClosing(String time) {
    return 'Срочно: до конца выдачи $time!';
  }

  @override
  String get orderRouteChooseMap => 'Открыть маршрут в картах';

  @override
  String get orderOpen2Gis => 'Открыть в 2GIS';

  @override
  String get orderOpenYandexMaps => 'Открыть в Яндекс Картах';

  @override
  String get orderDemoNoShow => 'Демо: отметить неявку (No-Show)';

  @override
  String get orderNoShowRecorded =>
      'Отмечена неявка (No-Show). Начислен +1 Strike';

  @override
  String get profileStrikesTitle => 'Надёжность (Strikes)';

  @override
  String profileStrikesCount(int count) {
    return 'Нарушений: $count из 3';
  }

  @override
  String profileBannedUntil(String date) {
    return 'Бронирование ограничено до $date';
  }

  @override
  String get profileDietSettingsTitle => 'Мои фильтры питания';

  @override
  String get shareImageFailed =>
      'Не удалось подготовить картинку, текст скопирован';

  @override
  String get shareImageReady => 'Карточка подготовлена к отправке!';

  @override
  String get partnerLeadTitle => 'Заявка на партнёрство';

  @override
  String get partnerLeadSubtitle =>
      'Оставьте контакты заведения — подключим кабинет без комиссии (0%) и выдадим временный пароль.';

  @override
  String get partnerLeadEmailLabel => 'Email партнёра';

  @override
  String get partnerLeadSuccessTitle => 'Заявка отправлена!';

  @override
  String get partnerLeadSuccessBody =>
      'Статус: На проверке (PENDING). После одобрения администратором вход откроется с временным паролем.';

  @override
  String get venueTabToday => 'Бүгінгі (Сегодня)';

  @override
  String get venueTabArchive => 'Мұрағат (Архив)';

  @override
  String get venueArchiveEmpty => 'Архивных боксов пока нет';

  @override
  String get venueRepublishButton => 'Перевыставить на сегодня';

  @override
  String get venueRepublishedSuccess => 'Бокс перевыставлен в продажу!';

  @override
  String get venueTemplatesTitle => 'Менің шаблондарым (в 1 клик)';

  @override
  String get venueSaveAsTemplate => 'Сохранить как шаблон';

  @override
  String venueTemplateApplied(String name) {
    return 'Шаблон «$name» применён';
  }

  @override
  String get venueNewBoxVegetarian => 'Вегетарианский бокс';

  @override
  String get venueNewBoxNoCommissionNote =>
      'Комиссия платформы: 0% · гость платит на кассе';

  @override
  String get venuePickupEnterPinTitle => 'Введите 4-значный PIN заказа';

  @override
  String get venuePickupPinWrong => 'Неверный PIN-код или заказ не найден';

  @override
  String get venuePickupClear => 'Сброс';

  @override
  String get venueStatsZeroCommission => 'Комиссия 0% (без удержаний)';

  @override
  String get venueStatsCompletedOrders => 'Выдано заказов';

  @override
  String get venueStatsNoShowOrders => 'Неявки (No-Show)';

  @override
  String get venueStatsLostProfitTitle => 'Упущенная выгода';

  @override
  String venueStatsLostProfitSubtitle(int count) {
    return 'Невыкупленных боксов: $count шт.';
  }

  @override
  String get venueQumbekAdviceHighRemaining =>
      'Совет Құмбек: остались невыкупленные боксы — снизьте цену на 15% или сдвиньте окно выдачи на 30 мин позже.';

  @override
  String get venueQumbekAdviceHighNoShow =>
      'Совет Құмбек: были неявки (No-Show). Напоминайте гостям подтвердить бронь за час до выдачи.';

  @override
  String get venueQumbekAdviceGreat =>
      'Совет Құмбек: отличная оборачиваемость! Сохраните лучший бокс в шаблоны для публикации в 1 клик.';

  @override
  String get adminActiveVenuesUsersLabel => 'Активные магазины / гости';

  @override
  String get adminCompletedBoxesLabel => 'Продано (COMPLETED)';

  @override
  String get adminZeroCommissionBadge => 'Без комиссии (0%)';

  @override
  String get adminAddPartnerButton => 'Добавить партнёра';

  @override
  String adminTempPasswordCreated(String password, String email) {
    return 'Партнёр подключён! Временный пароль: $password (Email: $email)';
  }

  @override
  String get adminBanVenue => 'Заблокировать магазин';

  @override
  String get adminUnbanVenue => 'Разблокировать';

  @override
  String adminVenueCompletedCount(int count) {
    return 'Выдано: $count';
  }

  @override
  String adminVenueNoShowCount(int count) {
    return 'No-Show: $count';
  }

  @override
  String get adminDeleteBox => 'Удалить бокс';

  @override
  String get adminStrikesTab => 'Strikes и Баны';

  @override
  String get adminAuditTab => 'Аудит (AuditLogs)';

  @override
  String get adminRemoveStrike => 'Снять 1 Strike';

  @override
  String get adminUnbanUser => 'Снять бан';

  @override
  String adminUserStrikesBadge(int count) {
    return 'Strikes: $count/3';
  }

  @override
  String get adminAuditEmpty => 'Записей аудита пока нет';

  @override
  String get adminTableColVenue => 'Заведение';

  @override
  String get adminTableColDistrict => 'Район';

  @override
  String get adminTableColStatus => 'Статус';

  @override
  String get adminTableColHalal => 'Халал';

  @override
  String get adminTableColStats => 'Выдано / No-Show';

  @override
  String get adminTableColActions => 'Действия';

  @override
  String get adminFilterBanned => 'Заблокированные';

  @override
  String get navAdminAudit => 'Аудит';

  @override
  String get badgeResaleHot => 'Горит! · Заберите срочно';

  @override
  String get badgeResaleTag => 'Авто-перепродажа (Resale)';

  @override
  String get venueNewBoxSprintTitle => 'Спринт-окно 15 минут';

  @override
  String venueNewBoxSprintSubtitle(String window) {
    return 'По правилу сервиса выдача начинается за 1 ч до закрытия ($window) и длится ровно 15 мин';
  }

  @override
  String orderSprintTimerLabel(String time) {
    return '15-мин Спринт: $time';
  }

  @override
  String get orderResaleErrorMessage =>
      'Извините, вы не успели. Заказ выставлен на перепродажу другим пользователям';

  @override
  String get orderDemoExpireSprint => 'Демо: 15 мин вышли (00:00 → Resale)';

  @override
  String get fcmStrikeTitle => 'Заказ аннулирован (No-Show)';

  @override
  String get fcmStrikeBody =>
      'Заказ аннулирован, вам начислено 1 предупреждение (Strike)';
}
