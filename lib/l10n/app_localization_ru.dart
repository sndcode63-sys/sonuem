import 'app_localizations.dart';

class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([super.locale = 'ru']);

  @override String get homeTitle => 'Главная';
  @override String get greeting => 'Добро пожаловать';
  @override String get settings => 'Настройки';
  @override String get language => 'Язык';
  @override String get measurementSystem => 'Система измерений';
  @override String get pressureUnit => 'Единица давления';
  @override String get update => 'Обновить';
  @override String get cancel => 'Отмена';
  @override String get addTyre => 'Добавить шину';
  @override String get save => 'Сохранить';

  // Screen labels
  @override String get vehicleId => 'ID ТС';
  @override String get currentHours => 'Текущие часы';
  @override String get currentKm => 'Текущий {unit}';
  @override String get trackingMethod => 'Метод отслеживания';
  @override String get manufacturer => 'Производитель';
  @override String get vehicleType => 'Тип';
  @override String get model => 'Модель';
  @override String get tyreSize => 'Размер шины';
  @override String get removalTread => 'Глубина протектора (замена)';
  @override String get vehicleComments => 'Комментарии к ТС';
  @override String get vehicleDiagram => 'Схема ТС';
  @override String get recommendedPressure => 'Рекомендуемое давление';
  @override String get submit => 'Отправить';
  @override String get createVehicle => 'Создать ТС';
  @override String get outsideTread => 'Внешний протектор';
  @override String get insideTread => 'Внутренний протектор';
  @override String get averageTread => 'Средний протектор';
  @override String get airPressure => 'Давление воздуха';
  @override String get lastRecordedDate => 'Последняя дата';
  @override String get lastRecordedHours => 'Последние часы';
  @override String get updateHours => 'Обновить часы';
  @override String get lastRecordedKm => 'Последний {unit}';
  @override String get updateKm => 'Обновить {unit}';
  @override String get vehicleNumber => 'Номер ТС';
  @override String get editVehicle => 'Редактировать ТС';

  @override String get selectedParentAccountLocation => 'Выбранный основной аккаунт и местоположение';
  @override String get loadingMasterData => 'Загрузка данных...';
  @override String get creatingVehicle => 'Создание ТС...';
  @override String get trackingMethodTitle => 'Метод отслеживания';
  @override String get trackingMethodHours => 'Часы';
  @override String get trackingMethodDistance => 'Расстояние';
  @override String get trackingMethodBoth => 'Оба';
  @override String get searchHint => 'Поиск...';
  @override String get noDataAvailable => 'Нет данных';
  @override String get noTireInstalled => 'Нет\nшины';
  @override String get axleLabel => 'Ось';
  @override String get cancelRequestTitle => 'Отменить запрос';
  @override String get cancelRequestMessage => 'Вы уверены? Несохранённые данные будут потеряны.';
  @override String get cancelRequestYes => 'Да';
  @override String get currentDistance => 'Текущий';
  @override String get enterCurrentDistance => 'Введите текущее значение';
  @override String get commentsHint => 'Введите комментарий (до 200 символов)';

  // ================= STEP 1 =================
  @override String get identificationDetails => 'Идентификационные данные';

  @override String get tyreSerialNumber => 'Серийный номер шины';
  @override String get enterTyreSerialNumber => 'Введите серийный номер';
  @override String get tyreSerialRequired => 'Требуется серийный номер';
  @override String get tyreSerialDuplicate => 'Этот номер уже существует';

  @override String get brandNumber => 'Номер бренда';
  @override String get enterBrandNumber => 'Введите номер бренда';

  @override String get registerDate => 'Дата регистрации';
  @override String get registerDateRequired => 'Дата обязательна';

  @override String get evaluationNumber => 'Номер оценки';
  @override String get lotNumber => 'Номер партии';
  @override String get purchaseOrderNumber => 'Номер заказа';

  @override String get disposition => 'Статус';
  @override String get status => 'Состояние';

  @override String get currentHoursRequired => 'Введите текущие часы';
  @override String get invalidHours => 'Неверное значение';
  @override String get negativeHours => 'Не может быть отрицательным';

  @override String get currentKmRequired => 'Введите текущий пробег';
  @override String get invalidKm => 'Неверное значение';
  @override String get negativeKm => 'Не может быть отрицательным';

  // ================= STEP 2 =================
  @override String get description => 'Описание';

  @override String get selectManufacturer => 'Выберите производителя';
  @override String get selectTyreSize => 'Выберите размер';

  @override String get starRating => 'Рейтинг';

  @override String get selectType => 'Выберите тип';

  @override String get indCode => 'Код';
  @override String get compound => 'Состав';
  @override String get loadRating => 'Индекс нагрузки';
  @override String get speedRating => 'Индекс скорости';

  @override String get requiredField => '⚠️ Введите корректные данные';

  // ================= BUTTONS =================
  @override String get nextBtn => 'Далее';
  @override String get previousBtn => 'Назад';
  @override String get cancelBtn => 'Отмена';
  @override String get okBtn => 'ОК';
  @override String get next => 'Далее';
  @override String get previous => 'Назад';

  @override String get enterValidDetails => 'Введите корректные данные';
  @override String get onlyNumeric => 'Только числа';
  @override String get originalTread => 'Оригинальный протектор';
  @override String get removeAt => 'Удалить на';
  @override String get purchaseTread => 'Покупной протектор';
  @override String get outside => 'Внешний';
  @override String get inside => 'Внутренний';
  @override String get wornWarning => 'Предупреждение износа';
  @override String get treadDepth => 'Глубина протектора';

  // ================= VEHICLE VIEW =================
  @override String get vehicleViewTitle => 'Просмотр ТС';
  @override String get viewVehicle => 'Просмотр ТС';
  @override String get inspect => 'Осмотр';
  @override String get error => 'Ошибка';
  @override String get noVehicleId => 'Нет ID ТС';
  @override String get vehicleNotFound => 'ТС не найдено';
  @override String get wheelPosition => 'Положение колеса';
  @override String get costs => 'Затраты';

  // ================= TYRE VIEW =================
  @override String get viewTyre => 'Просмотр шины';
  @override String get identification => 'Идентификация';
  @override String get purchasedTread => 'Купленный протектор';
  @override String get middleTread => 'Средний протектор';
  @override String get currentTreadDepth => 'Текущая глубина';
  @override String get percentageWorn => '% износа';
  @override String get currentPressure => 'Текущее давление';
  @override String get fillType => 'Тип заполнения';
  @override String get fillCost => 'Стоимость заполнения';
  @override String get repairCost => 'Стоимость ремонта';
  @override String get retreadCost => 'Стоимость восстановления';
  @override String get warrantyAdjustment => 'Гарантийная корректировка';
  @override String get costAdjustment => 'Корректировка стоимости';
  @override String get netCost => 'Чистая стоимость';
  @override String get soldAmount => 'Сумма продажи';

  // ================= HOME / DRAWER =================
  @override String get parentAccount => 'Основной аккаунт';
  @override String get location => 'Местоположение';
  @override String get changeLocationAccount => 'Изменить аккаунт/локацию';

  @override String get mainMenu => 'Главное меню';
  @override String get home => 'Главная';
  @override String get create => 'Создать';
  @override String get preferences => 'Настройки';
  @override String get user => 'Пользователь';
  @override String get logout => 'Выйти';

  @override String get createVehicleMenu => 'Создать ТС';
  @override String get createTyreMenu => 'Создать';

  @override String get userManagementList => 'Управление пользователями';
  @override String get grandparentAccount => 'Главный аккаунт';
  @override String get grandparentAccountView => 'Contas superiores vista';        // Portugués (PT)
  @override String get startInspection => 'Начать осмотр';

  @override String get totalVehicles => 'Всего ТС';
  @override String get totalTyres => 'Всего шин';

  @override String get lastInspection => 'Последний осмотр';
  @override String get sync => 'Синхронизация';

  @override String get unsyncInspection => 'Не синхронизировано';
  @override String get syncInspection => 'Синхронизировано';

  @override String get appVersion => 'Версия приложения';
  @override String get change => 'Изменить';

  @override String get syncSuccess => 'Синхронизация успешна';
  @override String get syncFailed => 'Ошибка синхронизации';

  @override String get noPermissionCreate => 'Нет разрешения на создание';

  // ... (existing code)

  // ================= CREATE TYRE STEP 2 =================
  @override String get manufacture => 'Производство';
  @override String get tireSize => 'Размер шины';
  @override String get searchTireManufacturer => 'Поиск производителя шин';
  @override String get chooseManufacturerFirst => 'Сначала выберите производителя';
  @override String get chooseSizeFirst => 'Сначала выберите размер';
  @override String get starRatingSelect => 'Выбрать';
  @override String get selectFillType => 'Тип заполнения';

  // ================= CREATE TYRE STEP 3 =================
  @override String get treadDepthUnit => 'Глубина протектора';
  @override String get originalTreadUnit => 'Оригинальный протектор';
  @override String get removeAtUnit => 'Удалить на';
  @override String get purchaseTreadUnit => 'Покупной протектор';
  @override String get outsideUnit => 'Внешний (a)';
  @override String get insideUnit => 'Внутренний (c)';
  @override String get enterOriginalTread => 'Введите ориг. протектор';
  @override String get enterRemoveAt => 'Удалить на';
  @override String get enterPurchaseTread => 'Введите покупной протектор';
  @override String get wornPercent => '% износа';

  // ================= CREATE TYRE STEP 4 =================
  @override String get tireCosts => 'Затраты на шину';
  @override String get purchaseCostA => 'Стоимость покупки (a)';
  @override String get casingValueB => 'Стоимость каркаса (B)';
  @override String get fillCostC => 'Стоимость заполнения (C)';
  @override String get repairsCostD => 'Стоимость ремонта (D)';
  @override String get numberOfRetreads => 'Кол-во восстановлений';
  @override String get retreadCostE => 'Стоимость восстановления (E)';
  @override String get warrantyAdjustmentF => 'Гарант. корректировка (F)';
  @override String get costAdjustmentG => 'Корректировка стоимости (G)';
  @override String get soldAmountH => 'Сумма продажи (H)';
  @override String get netCostFormula => 'Чистая стоимость = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'Сохранить и клонировать';
  @override String get enterDisposition => 'Введите статус';
  @override String get enterEvaluationNumber => 'Введите номер оценки';
  @override String get enterLotNumber => 'Введите номер партии';
  @override String get enterPurchaseOrderNumber => 'Введите номер заказа';
  @override String get enterCurrentHours => 'Введите текущие часы';
  @override String get enterCurrentKm => 'Введите текущий пробег';
  @override String get enterValidNumeric => 'Введите корректное число.';
  @override String get hoursNotNegative => 'Часы не могут быть отрицательными.';
  @override String get kmNotNegative => 'Пробег не может быть отрицательным.';
  @override String get serialAlreadyExists => 'Этот серийный номер уже существует';
  @override String get searchIndCode => 'Поиск кода Ind.';
  @override String get searchCompound => 'Поиск состава';
  @override String get searchLoadRating => 'Поиск индекса нагрузки';
  @override String get searchSpeedRating => 'Поиск индекса скорости';
  @override String get selectItem => 'Выбрать';
  @override String get selectPrefix => 'Выбрать ';
  @override String get serialNumber => 'Серийный номер';
  @override String get enter => 'Ввод';
  @override String get selectedAccountLocation => 'Выбранный аккаунт и местоположение';
  @override String get viewInspections => 'Просмотр осмотров';
  @override String get view => 'Просмотр';
  @override String get vehicle => 'Транспортное средство';
  @override String get total => 'Всего';
  @override String get enterVehicleNumber => 'Введите номер ТС';
  @override String get editTyre => 'Редактировать шину';
  @override String get clear => 'ОЧИСТИТЬ';
  @override String get set => 'УСТАНОВИТЬ';
  @override String get enterValidNumber => 'Введите корректное число';
  @override String get allVehicles => 'Все транспортные средства';
  @override String get searchVehicles => 'Поиск ТС...';
  @override String get filters => 'Фильтры';
  @override String get applyFilters => 'Применить фильтры';
  @override String get clearAllFilters => 'Очистить все фильтры';
  @override String get pendingSync => 'Ожидание синхронизации';
  @override String get make => 'Марка';
  @override String get transfer => 'Перевод';
  @override String get delete => 'Удалить';
  @override String get own => 'Собственный';
  @override String get shared => 'Общий';
  @override String get select => 'Выбрать';
  @override String get searchAccount => 'Поиск аккаунта';
  @override String get searchLocation => 'Поиск местоположения';
  @override String get noAccountsFound => 'Аккаунты не найдены';
  @override String get noLocationsFound => 'Местоположения не найдены';
  @override String get inspectTyre => 'Осмотр шины';
  @override String get installTyre => 'Установка шины';
  @override String get airPressureType => 'Тип давления воздуха';
  @override String get cold => 'Холодное';
  @override String get hot => 'Горячее';
  @override String get wearCondition => 'Состояние износа';
  @override String get casingCondition => 'Состояние каркаса';
  @override String get listOfPreviousComments => 'Список предыдущих комментариев';
  @override String get stillRelevant => 'Все еще актуально';
  @override String get uploadImages => 'Загрузить изображения';
  @override String get images => 'Изображения';
  @override String get confirmRemove => 'Подтвердить удаление';
  @override String get areYouSureRemoveImage => 'Вы уверены, что хотите удалить это изображение?';
  @override String get removeTire => 'Снять шину';
  @override String get remove => 'Снять';
  @override String get all => 'Все';
  @override String get editBtn => 'Изменить';
  @override String get takePhoto => 'Сделать фото';
  @override String get chooseFromGallery => 'Выбрать из галереи';

  @override String get commentsLabel => 'Комментарии';
  @override String get yes => 'ДА';
  @override String get no => 'НЕТ';
  @override String get upload => 'Загрузить';
  @override String get install => 'Установить';
  @override String get tyreType => 'Тип';
  @override String get loading => 'Chargement...';
  @override String get syncAll => 'Tout synchroniser';
  @override String get updateDisposition => 'Mettre à jour la disposition *';
  @override String get removalReason => 'Motif de dépose';
  @override String get selectDisposition => 'Sélectionner la disposition';
  @override String get selectRemovalReason => 'Sélectionner le motif de dépose';
  @override String get rotatePosition => 'Rotation de position';
  @override String get placementError => 'Veuillez placer le pneu dans un emplacement avant d\'enregistrer.';
  @override String get rotationSavedOffline => 'Rotation enregistrée localement. Synchronisation dès que possible.';
  @override String get rotationSuccessful => 'Rotation mise à jour et enregistrée avec succès.';
  @override String get searchInventory => 'Rechercher un pneu dans l\'inventaire';
  @override String get noInventoryFound => 'Aucun pneu trouvé dans l\'inventaire';
  @override String get manufacturerLabel => 'Marque/Fabricant';
  @override String get unsynced => 'Non synchronisé';
  @override String get synced => 'Synchronisé';
  @override String get unsyncedPending => 'inspection(s) en attente de synchronisation';
  @override String get offlineSyncMessage => 'Hors ligne — connectez-vous à Internet pour synchroniser';
  @override String get confirmDeleteTitle => 'Supprimer l\'inspection ?';
  @override String get confirmDeleteMessage => 'Supprimer définitivement cette inspection ?';
  @override String get viewInspection => 'Ver inspeção';
  @override String get syncing => 'Sincronizando...';
  @override String get inspected => 'Inspecionado';
  @override String get deleteInspectionTitle => 'Excluir inspeção?';
  @override String get deleteInspectionConfirm => 'Excluir permanentemente a inspeção para';
  @override String get tyresLabel => 'Шины';
  @override String get userManagement => 'УПРАВЛЕНИЕ ПОЛЬЗОВАТЕЛЯМИ';
  @override String get createUser => 'Создать пользователя';
  @override String get searchUser => 'Поиск пользователя';
  @override String get deleteUser => 'Удалить пользователя';
  @override String get deleteUserConfirm => 'Вы уверены, что хотите удалить этого пользователя?';
  @override String get username => 'Имя пользователя';
  @override String get password => 'Пароль';
  @override String get userRole => 'Роль пользователя';
  @override String get loginLabel => 'Вход';
  @override String get personalLabel => 'Личные данные';
  @override String get preferenceLabel => 'Настройки';
  @override String get creatingUser => 'Создание пользователя...';
  @override String get grandparentAccountOptions => 'ОПЦИИ АККАУНТА GRANDPARENT';
  @override String get grandparentAccountInformation => 'ИНФОРМАЦИЯ ОБ АККАУНТЕ GRANDPARENT';
  @override String get searchGrandparent => 'Поиск Grandparent';
  @override String get active => 'Активен';
  @override String get inactive => 'Неактивен';
  @override String get ownedBy => 'Владелец';
  @override String get createAccount => 'Создать аккаунт';
  @override String get assignAccount => 'Назначить аккаунт';
  @override String get grandparentNameLabel => 'Имя аккаунта Grandparent';
  @override String get accountTypeLabel => 'Владение';
  @override String get selectParentAccount => 'Родительский аккаунт';
  @override String get selectGrandparentAccount => 'Аккаунт Grandparent';
  @override String get assignBtn => 'НАЗНАЧИТЬ';
  @override String get firstName => 'Имя';
  @override String get middleName => 'Отчество';
  @override String get lastName => 'Фамилия';
  @override String get phone => 'Телефон';
  @override String get country => 'Страна';
  @override String get measurement => 'Измерение';
  @override String get id => 'ID';
  @override String get searchVehicleTyre => 'Поиск автомобиля / шины';
  @override String get recentSearch => 'Последние запросы';
  @override String get vehicles => 'Транспорт';
  @override String get recentVehicleNotFound => 'Последние автомобили не найдены';
  @override String get recentTyreNotFound => 'Последние шины не найдены';
  @override String get typeToSearch => 'Введите для поиска';
  @override String get noVehiclesFound => 'Автомобили не найдены по запросу';
  @override String get noTyresFound => 'Шины не найдены по запросу';
  @override String get createNewVehicle => 'Создать новый автомобиль';
  @override String get createNewTyre => 'Создать новую шину';
  @override String get confirmRemoveTitle => 'Подтвердить удаление';
  @override String get confirmRemoveMessage => 'Вы уверены, что хотите удалить этот элемент?';
  @override String get updateBtn => 'Обновить';
  @override String get noRecentVehicleFound => 'Последние автомобили не найдены';
  @override String get noRecentTyreFound => 'Последние шины не найдены';
  @override String get noVehiclesFoundFor => 'Автомобили не найдены по запросу';
  @override String get noTyresFoundFor => 'Шины не найдены по запросу';
  @override String get searchPrefix => 'Поиск';
  @override
  String createNew(String itemName) => 'Создать новый $itemName';

  @override String get vehicleInspection => 'Осмотр транспортного средства';
  @override String get hourWarningMsg => "Вы не обновили часы, пробег и данные автомобиля.";
  @override String get hours => 'Часы';
  @override String get km => 'КМ';
  @override String get updateHoursKm => 'Обновить Часы / КМ';
  @override String get serialNo => 'Серийный номер';
  @override String get inspectedTire => 'Осмотренная шина';
  @override String get notInspectedTire => 'Неосмотренная шина';
  @override String get rotateTyres => 'Перестановка шин';
  @override String get uploadedImages => 'Загруженные изображения';
  @override String get confirmRemoveImg => 'Подтвердить удаление изображения';
  @override String get viewOnlyDisabled => 'Только просмотр — отправка отключена';
  @override String get cancelRequestMsg => 'Вы уверены, что хотите отменить? Несохраненные данные будут потеряны.';
  @override String get selectedParentAccount => 'Выбранная основная учетная запись';
  @override String get surveyDate => 'Дата осмотра';
  @override String get selectDate => 'Выберите дату';
  @override String get updateHoursLabel => 'Обновить часы';
  @override String get enterHours => 'Введите часы';
  @override String get updateKmLabel => 'Обновить КМ';
  @override String get enterKm => 'Введите КМ';
  @override String get updateVehicleDataTitle => 'Обновить данные автомобиля';
  @override String get updateVehicleDataMsg => 'Эти изменения повлияют на часы/пробег шин.\nЖелаете продолжить?';
  @override String get proceed => 'Продолжить';
  @override
  String tyreSerialNumbers(String tyreWord) => 'Серийный номер $tyreWord';
  @override
  String enterItemSerialNumber(String itemName) => 'Введите серийный номер $itemName';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "Допускаются только числовые значения";
  @override String get negativeValueError => "Значение не может быть отрицательным";
  @override String get duplicateVehicleError => "Номер уже занят";
  @override String get invalidNumberError => "Должно быть числом";
  @override String get enterPrefix => "Введите ";
  @override String recommendedPressureFor(String axle) => "Давление для $axle";
  @override String get numericOnly => "Допускаются только числовые значения";

  @override String get inventory => 'Инвентарь';
  @override String get onHold => 'На удержании';
  @override String get scrap => 'Утиль';
  @override String get repair => 'Ремонт';
  @override String get retread => 'Восстановление';
  @override String get edit => 'Редактировать';
  @override String get clone => 'Клонировать';
  @override String get ok => 'ОК';
}