import 'app_localizations.dart';

class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get homeTitle => 'Strona główna';
  @override
  String get greeting => 'Witamy';
  @override
  String get settings => 'Ustawienia';
  @override
  String get language => 'Język';
  @override
  String get measurementSystem => 'System pomiaru';
  @override
  String get pressureUnit => 'Jednostka ciśnienia';
  @override
  String get update => 'Aktualizuj';
  @override
  String get cancel => 'Anuluj';
  @override
  String get addTyre => 'Dodaj oponę';
  @override
  String get save => 'Zapisz';

  // Screen labels
  @override
  String get vehicleId => 'ID Pojazdu';
  @override
  String get currentHours => 'Aktualne Godziny';
  @override
  String get currentKm => 'Aktualne {unit}';
  @override
  String get trackingMethod => 'Metoda Śledzenia';
  @override
  String get manufacturer => 'Producent';
  @override
  String get vehicleType => 'Typ';
  @override
  String get model => 'Model';
  @override
  String get tyreSize => 'Rozmiar Opony';
  @override
  String get removalTread => 'Głębokość Bieżnika Wymiany';
  @override
  String get vehicleComments => 'Komentarze do Pojazdu';
  @override
  String get vehicleDiagram => 'Schemat Pojazdu';
  @override
  String get recommendedPressure => 'Zalecane Ciśnienie';
  @override
  String get submit => 'Prześlij';
  @override
  String get createVehicle => 'Utwórz Nowy Pojazd';
  @override
  String get outsideTread => 'Głębokość Zewnętrzna';
  @override
  String get insideTread => 'Głębokość Wewnętrzna';
  @override
  String get averageTread => 'Średni Bieżnik';
  @override
  String get airPressure => 'Ciśnienie Powietrza';
  @override
  String get lastRecordedDate => 'Ostatnia Data';
  @override
  String get lastRecordedHours => 'Ostatnie Godziny';
  @override
  String get updateHours => 'Aktualizuj Godziny';
  @override
  String get lastRecordedKm => 'Ostatnie {unit}';
  @override
  String get updateKm => 'Aktualizuj {unit}';
  @override
  String get vehicleNumber => 'Numer Pojazdu';
  @override
  String get editVehicle => 'Edytuj Pojazd';

  @override
  String get selectedParentAccountLocation =>
      'Wybrane konto główne i Lokalizacja';
  @override
  String get loadingMasterData => 'Ładowanie danych głównych...';
  @override
  String get creatingVehicle => 'Tworzenie pojazdu...';
  @override
  String get trackingMethodTitle => 'Metoda Śledzenia';
  @override
  String get trackingMethodHours => 'Godziny';
  @override
  String get trackingMethodDistance => 'Odległość';
  @override
  String get trackingMethodBoth => 'Oba';
  @override
  String get searchHint => 'Szukaj...';
  @override
  String get noDataAvailable => 'Brak dostępnych danych';
  @override
  String get noTireInstalled => 'Brak\nOpony';
  @override
  String get axleLabel => 'Oś';
  @override
  String get cancelRequestTitle => 'Anuluj Żądanie';
  @override
  String get cancelRequestMessage =>
      'Czy na pewno chcesz anulować? Niezapisane dane zostaną utracone.';
  @override
  String get cancelRequestYes => 'Tak';
  @override
  String get currentDistance => 'Bieżący';
  @override
  String get enterCurrentDistance => 'Wprowadź bieżącą wartość';
  @override
  String get commentsHint => 'Komentarze tutaj. (Maks. 200 znaków)';

  // ================= CREATE TYRE (STEP 1) =================
  @override
  String get identificationDetails => 'Szczegóły identyfikacji';

  @override
  String get tyreSerialNumber => 'Numer seryjny opony';
  @override
  String get enterTyreSerialNumber => 'Wprowadź numer seryjny';
  @override
  String get tyreSerialRequired => 'Numer seryjny wymagany';
  @override
  String get tyreSerialDuplicate => 'Numer już istnieje';

  @override
  String get brandNumber => 'Numer marki';
  @override
  String get enterBrandNumber => 'Wprowadź numer marki';

  @override
  String get registerDate => 'Data rejestracji';
  @override
  String get registerDateRequired => 'Data rejestracji wymagana';

  @override
  String get evaluationNumber => 'Numer oceny';
  @override
  String get lotNumber => 'Numer partii';
  @override
  String get purchaseOrderNumber => 'Numer zamówienia';

  @override
  String get disposition => 'Dyspozycja';
  @override
  String get status => 'Status';

  @override
  String get currentHoursRequired => 'Godziny wymagane';
  @override
  String get invalidHours => 'Nieprawidłowe godziny';
  @override
  String get negativeHours => 'Nie mogą być ujemne';

  @override
  String get currentKmRequired => 'Wartość wymagana';
  @override
  String get invalidKm => 'Nieprawidłowa wartość';
  @override
  String get negativeKm => 'Nie może być ujemna';

  // ================= CREATE TYRE (STEP 2) =================
  @override
  String get description => 'Opis';

  @override
  String get selectManufacturer => 'Wybierz producenta';
  @override
  String get selectTyreSize => 'Wybierz rozmiar opony';

  @override
  String get starRating => 'Ocena';

  @override
  String get selectType => 'Wybierz typ';

  @override
  String get indCode => 'Kod';
  @override
  String get compound => 'Mieszanka';
  @override
  String get loadRating => 'Indeks nośności';
  @override
  String get speedRating => 'Indeks prędkości';

  @override
  String get requiredField => 'Pole wymagane';

  // ================= BUTTONS =================
  @override
  String get nextBtn => 'Dalej';
  @override
  String get previousBtn => 'Wstecz';
  @override
  String get cancelBtn => 'Anuluj';
  @override
  String get okBtn => 'OK';
  @override
  String get next => 'Dalej';
  @override
  String get previous => 'Wstecz';

  @override
  String get enterValidDetails => 'Wprowadź poprawne dane';
  @override
  String get onlyNumeric => 'Dozwolone tylko liczby';

  @override
  String get originalTread => 'Oryginalny bieżnik';
  @override
  String get removeAt => 'Usuń przy';
  @override
  String get purchaseTread => 'Bieżnik zakupu';
  @override
  String get outside => 'Zewnętrzny';
  @override
  String get inside => 'Wewnętrzny';

  @override
  String get wornWarning => 'Ostrzeżenie: krytyczne zużycie opony';
  @override
  String get treadDepth => 'Głębokość bieżnika';

  // ================= VEHICLE VIEW =================
  @override
  String get vehicleViewTitle => 'Widok pojazdu';
  @override
  String get viewVehicle => 'Zobacz pojazd';
  @override
  String get inspect => 'Inspekcja';
  @override
  String get error => 'Błąd';
  @override
  String get noVehicleId => 'Brak ID pojazdu';
  @override
  String get vehicleNotFound => 'Pojazd nie znaleziony';
  @override
  String get wheelPosition => 'Pozycja koła';
  @override
  String get costs => 'Koszty';

  // ================= TYRE VIEW =================
  @override
  String get viewTyre => 'Zobacz oponę';
  @override
  String get identification => 'Identyfikacja';
  @override
  String get purchasedTread => 'Bieżnik zakupowy';
  @override
  String get middleTread => 'Bieżnik środkowy';
  @override
  String get currentTreadDepth => 'Aktualna głębokość';
  @override
  String get percentageWorn => 'Zużycie %';
  @override
  String get currentPressure => 'Aktualne ciśnienie';
  @override
  String get fillType => 'Typ napełnienia';
  @override
  String get fillCost => 'Koszt napełnienia';
  @override
  String get repairCost => 'Koszt naprawy';
  @override
  String get retreadCost => 'Koszt bieżnikowania';
  @override
  String get warrantyAdjustment => 'Korekta gwarancji';
  @override
  String get costAdjustment => 'Korekta kosztów';
  @override
  String get netCost => 'Koszt netto';
  @override
  String get soldAmount => 'Kwota sprzedaży';

  // ================= HOME & DRAWER =================
  @override
  String get parentAccount => 'Konto nadrzędne';
  @override
  String get location => 'Lokalizacja';
  @override
  String get changeLocationAccount => 'Zmień konto i lokalizację';

  @override
  String get mainMenu => 'Menu główne';
  @override
  String get home => 'Strona główna';
  @override
  String get create => 'Utwórz';
  @override
  String get preferences => 'Preferencje';
  @override
  String get user => 'Użytkownik';
  @override
  String get logout => 'Wyloguj się';

  @override
  String get createVehicleMenu => 'Utwórz pojazd';
  @override
  String get createTyreMenu => 'Utwórz';

  @override
  String get userManagementList => 'Zarządzanie użytkownikami';
  @override
  String get grandparentAccount => 'Konto nadrzędne wyższe';
  @override String get grandparentAccountView => 'Contas superiores vista';        // Portugués (PT)  @override
  @override
  String get startInspection => 'Rozpocznij inspekcję';

  @override
  String get totalVehicles => 'Łącznie pojazdów';
  @override
  String get totalTyres => 'Łącznie opon';

  @override
  String get lastInspection => 'Ostatnia inspekcja';
  @override
  String get sync => 'Synchronizacja';

  @override
  String get unsyncInspection => 'Niesynchronizowane inspekcje';
  @override
  String get syncInspection => 'Zsynchronizowane inspekcje';

  @override
  String get appVersion => 'Wersja aplikacji';
  @override
  String get change => 'Zmień';

  @override
  String get syncSuccess => 'Synchronizacja zakończona';
  @override
  String get syncFailed => 'Synchronizacja nieudana';

  @override
  String get noPermissionCreate => 'Brak uprawnień do tworzenia';

  // ================= CREATE TYRE STEP 2 =================
  @override
  String get manufacture => 'Produkcja';
  @override
  String get tireSize => 'Rozmiar opony';
  @override
  String get searchTireManufacturer => 'Szukaj producenta opon';
  @override
  String get chooseManufacturerFirst => 'Najpierw wybierz producenta';
  @override
  String get chooseSizeFirst => 'Najpierw wybierz rozmiar';
  @override
  String get starRatingSelect => 'Wybierz';
  @override
  String get selectFillType => 'Typ napełnienia';

  // ================= CREATE TYRE STEP 3 =================
  @override
  String get treadDepthUnit => 'Głębokość bieżnika';
  @override
  String get originalTreadUnit => 'Bieżnik oryginalny';
  @override
  String get removeAtUnit => 'Usuń przy';
  @override
  String get purchaseTreadUnit => 'Bieżnik zakupu';
  @override
  String get outsideUnit => 'Zewnętrzny (a)';
  @override
  String get insideUnit => 'Wewnętrzny (c)';
  @override
  String get enterOriginalTread => 'Wprowadź oryginalny bieżnik';
  @override
  String get enterRemoveAt => 'Usuń przy';
  @override
  String get enterPurchaseTread => 'Wprowadź bieżnik zakupu';
  @override
  String get wornPercent => '% zużycia';

  // ================= CREATE TYRE STEP 4 =================
  @override
  String get tireCosts => 'Koszty opony';
  @override
  String get purchaseCostA => 'Koszt zakupu (a)';
  @override
  String get casingValueB => 'Wartość karkasu (B)';
  @override
  String get fillCostC => 'Koszt napełnienia (C)';
  @override
  String get repairsCostD => 'Koszt napraw (D)';
  @override
  String get numberOfRetreads => 'Liczba bieżnikowań';
  @override
  String get retreadCostE => 'Koszt bieżnikowania (E)';
  @override
  String get warrantyAdjustmentF => 'Korekta gwarancyjna (F)';
  @override
  String get costAdjustmentG => 'Korekta kosztów (G)';
  @override
  String get soldAmountH => 'Kwota sprzedaży (H)';
  @override
  String get netCostFormula => 'Koszt netto = (a+d+c+e) - (b+g+h+f)';
  @override
  String get saveAndClone => 'Zapisz i klonuj';
  @override
  String get enterDisposition => 'Wprowadź dyspozycję';
  @override
  String get enterEvaluationNumber => 'Wprowadź numer oceny';
  @override
  String get enterLotNumber => 'Wprowadź numer partii';
  @override
  String get enterPurchaseOrderNumber => 'Wprowadź numer zamówienia';
  @override
  String get enterCurrentHours => 'Wprowadź aktualne godziny';
  @override
  String get enterCurrentKm => 'Wprowadź aktualne KM';
  @override
  String get enterValidNumeric => 'Wprowadź poprawną wartość liczbową.';
  @override
  String get hoursNotNegative => 'Godziny nie mogą być ujemne.';
  @override
  String get kmNotNegative => 'Kilometry ne mogą być ujemne.';
  @override
  String get serialAlreadyExists => 'Ten numer seryjny już istnieje';
  @override
  String get searchIndCode => 'Szukaj kodu IND';
  @override
  String get searchCompound => 'Szukaj mieszanki';
  @override
  String get searchLoadRating => 'Szukaj nośności';
  @override
  String get searchSpeedRating => 'Szukaj prędkości';
  @override
  String get selectItem => 'Wybierz';
  @override
  String get selectPrefix => 'Wybierz ';
  @override
  String get serialNumber => 'Numer seryjny';
  @override
  String get enter => 'Wprowadź';
  @override
  String get selectedAccountLocation => 'Wybrane konto i lokalizacja';
  @override
  String get viewInspections => 'Zobacz inspekcje';
  @override
  String get view => 'Zobacz';
  @override
  String get vehicle => 'Pojazd';
  @override
  String get total => 'Łącznie';
  @override
  String get enterVehicleNumber => 'Wprowadź numer pojazdu';
  @override
  String get editTyre => 'Edytuj oponę';
  @override
  String get clear => 'WYCZYŚĆ';
  @override
  String get set => 'USTAW';
  @override
  String get enterValidNumber => 'Wprowadź poprawny numer';
  @override
  String get allVehicles => 'Wszystkie pojazdy';
  @override
  String get searchVehicles => 'Szukaj pojazdów...';
  @override
  String get filters => 'Filtry';
  @override
  String get applyFilters => 'Zastosuj filtry';
  @override
  String get clearAllFilters => 'Wyczyść wszystkie filtry';
  @override
  String get pendingSync => 'Oczekiwanie na synchronizację';
  @override
  String get make => 'Marka';
  @override
  String get transfer => 'Przenieś';
  @override
  String get delete => 'Usuń';
  @override
  String get own => 'Własne';
  @override
  String get shared => 'Udostępnione';
  @override
  String get select => 'Wybierz';
  @override
  String get searchAccount => 'Szukaj konta';
  @override
  String get searchLocation => 'Szukaj lokalizacji';
  @override
  String get noAccountsFound => 'Nie znaleziono kont';
  @override
  String get noLocationsFound => 'Nie znaleziono lokalizacji';
  @override
  String get inspectTyre => 'Inspekcja opony';
  @override
  String get installTyre => 'Montaż opony';
  @override
  String get airPressureType => 'Typ ciśnienia powietrza';
  @override
  String get cold => 'Zimne';
  @override
  String get hot => 'Gorące';
  @override
  String get wearCondition => 'Stan zużycia';
  @override
  String get casingCondition => 'Stan karkasu';
  @override
  String get listOfPreviousComments => 'Lista poprzednich komentarzy';
  @override
  String get stillRelevant => 'Nadal aktualne';
  @override
  String get uploadImages => 'Prześlij zdjęcia';
  @override
  String get images => 'Zdjęcia';
  @override
  String get confirmRemove => 'Potwierdź usunięcie';
  @override
  String get areYouSureRemoveImage => 'Czy na pewno chcesz usunąć to zdjęcie?';
  @override
  String get removeTire => 'Zdejmij oponę';
  @override
  String get remove => 'Zdejmij';
  @override
  String get all => 'Wszystkie';
  @override
  String get editBtn => 'تعديل';
  @override
  String get takePhoto => 'Foto machen';
  @override
  String get chooseFromGallery => 'Aus Galerie wählen';
  @override
  String get commentsLabel => 'Kommentare';
  @override
  String get yes => 'JA';
  @override
  String get no => 'NEIN';
  @override
  String get upload => 'Prześlij';
  @override
  String get install => 'Zainstaluj';
  @override
  String get tyreType => 'Typ';
  @override
  String get loading => 'Ładowanie...';
  @override
  String get syncAll => 'Synchronizuj wszystko';
  @override
  String get updateDisposition => 'Aktualizuj dyspozycję *';
  @override
  String get removalReason => 'Powód usunięcia';
  @override
  String get selectDisposition => 'Wybierz dyspozycję';
  @override
  String get selectRemovalReason => 'Wybierz powód usunięcia';
  @override
  String get rotatePosition => 'Pozycja rotacji';
  @override
  String get placementError =>
      'Proszę umieścić oponę w gnieździe przed zapisaniem.';
  @override
  String get rotationSavedOffline =>
      'Rotacja zapisana lokalnie. Synchronizacja nastąpi po połączeniu z internetem.';
  @override
  String get rotationSuccessful =>
      'Rotacja pomyślnie zaktualizowana i zapisana.';
  @override
  String get searchInventory => 'Szukaj opony w ekwipunku';
  @override
  String get noInventoryFound => 'Nie znaleziono opon w ekwipunku';
  @override
  String get manufacturerLabel => 'Marka/Producent';
  @override
  String get unsynced => 'Niezsynchronizowane';
  @override
  String get synced => 'Zsynchronizowane';
  @override
  String get unsyncedPending => 'oczekujące inspekcje do synchronizacji';
  @override
  String get offlineSyncMessage =>
      'Tryb offline — połącz się z internetem, aby synchronizować';
  @override
  String get confirmDeleteTitle => 'Usunąć inspekcję?';
  @override
  String get confirmDeleteMessage =>
      'Czy na pewno chcesz trwale usunąć tę inspekcję?';
  @override
  String get viewInspection => 'Zobacz inspekcję';
  @override
  String get syncing => 'Synchronizacja...';
  @override
  String get inspected => 'Zinspekcjonowano';
  @override
  String get deleteInspectionTitle => 'Usunąć inspekcję?';
  @override
  String get deleteInspectionConfirm => 'Trwale usuń inspekcję dla';
  @override
  String get tyresLabel => 'Opony';
  @override
  String get userManagement => 'ZARZĄDZANIE UŻYTKOWNIKAMI';
  @override
  String get createUser => 'Utwórz użytkownika';
  @override
  String get searchUser => 'Szukaj użytkownika';
  @override
  String get deleteUser => 'Usuń użytkownika';
  @override
  String get deleteUserConfirm =>
      'Czy na pewno chcesz usunąć tego użytkownika?';
  @override
  String get username => 'Nazwa użytkownika';
  @override
  String get password => 'Hasło';
  @override
  String get userRole => 'Rola użytkownika';
  @override
  String get loginLabel => 'Logowanie';
  @override
  String get personalLabel => 'Dane osobowe';
  @override
  String get preferenceLabel => 'Preferencje';
  @override
  String get creatingUser => 'Tworzenie użytkownika...';
  @override
  String get grandparentAccountOptions => 'OPCJE KONTA GRANDPARENT';
  @override
  String get grandparentAccountInformation => 'INFORMACJE O KONCIE GRANDPARENT';
  @override
  String get searchGrandparent => 'Szukaj Grandparent';
  @override
  String get active => 'Aktywny';
  @override
  String get inactive => 'Nieaktywny';
  @override
  String get ownedBy => 'Własność';
  @override
  String get createAccount => 'Utwórz konto';
  @override
  String get assignAccount => 'Przypisz konto';
  @override
  String get grandparentNameLabel => 'Nazwa konta Grandparent';
  @override
  String get accountTypeLabel => 'Własność';
  @override
  String get selectParentAccount => 'Konto nadrzędne';
  @override
  String get selectGrandparentAccount => 'Konto Grandparent';
  @override
  String get assignBtn => 'PRZYPISZ';
  @override
  String get firstName => 'Imię';
  @override
  String get middleName => 'Drugie imię';
  @override
  String get lastName => 'Nazwisko';
  @override
  String get phone => 'Telefon';
  @override
  String get country => 'Kraj';
  @override
  String get measurement => 'Pomiar';
  @override
  String get id => 'ID';
  @override
  String get searchVehicleTyre => 'Szukaj pojazdu / opony';
  @override
  String get recentSearch => 'Ostatnie wyszukiwania';
  @override
  String get vehicles => 'Pojazdy';
  @override
  String get recentVehicleNotFound => 'Nie znaleziono ostatniego pojazdu';
  @override
  String get recentTyreNotFound => 'Nie znaleziono ostatniej opony';
  @override
  String get typeToSearch => 'Wpisz, aby wyszukać';
  @override
  String get noVehiclesFound => 'Nie znaleziono pojazdów dla';
  @override
  String get noTyresFound => 'Nie znaleziono opon dla';
  @override
  String get createNewVehicle => 'Utwórz nowy pojazd';
  @override
  String get createNewTyre => 'Utwórz nową oponę';
  @override
  String get confirmRemoveTitle => 'Potwierdź usunięcie';
  @override
  String get confirmRemoveMessage => 'Czy na pewno chcesz usunąć ten element?';
  @override
  String get updateBtn => 'Aktualizuj';
  @override
  String get noRecentVehicleFound => 'Nie znaleziono ostatniego pojazdu';
  @override
  String get noRecentTyreFound => 'Nie znaleziono ostatniej opony';
  @override
  String get noVehiclesFoundFor => 'Nie znaleziono pojazdów dla';
  @override
  String get noTyresFoundFor => 'Nie znaleziono opon dla';
  @override
  String get searchPrefix => 'Szukaj';
  @override
  String createNew(String itemName) => 'Utwórz nowy $itemName';

  @override String get vehicleInspection => 'Przegląd pojazdu';
  @override String get hourWarningMsg => "Nie zaktualizowano godzin, mil i pojazdu.";
  @override String get hours => 'Godziny';
  @override String get km => 'KM';
  @override String get updateHoursKm => 'Aktualizuj godziny / KM';
  @override String get serialNo => 'Numer seryjny';
  @override String get inspectedTire => 'Opona sprawdzona';
  @override String get notInspectedTire => 'Opona niesprawdzona';
  @override String get rotateTyres => 'Rotacja opon';
  @override String get uploadedImages => 'Przesłane obrazy';
  @override String get confirmRemoveImg => 'Potwierdź usunięcie obrazu';
  @override String get viewOnlyDisabled => 'Tylko do odczytu — wysyłanie zablokowane';
  @override String get cancelRequestMsg => 'Czy na pewno chcesz anulować? Stracisz niezapisane dane.';
  @override String get selectedParentAccount => 'Wybrane konto nadrzędne';
  @override String get surveyDate => 'Data ankiety';
  @override String get selectDate => 'Wybierz datę';
  @override String get updateHoursLabel => 'Aktualizuj godziny';
  @override String get enterHours => 'Wpisz godziny';
  @override String get updateKmLabel => 'Aktualizuj KM';
  @override String get enterKm => 'Wpisz KM';
  @override String get updateVehicleDataTitle => 'Aktualizuj dane pojazdu';
  @override String get updateVehicleDataMsg => 'Zmiany te wpłyną na godziny/kilometry opon.\nCzy chcesz kontynuować?';
  @override String get proceed => 'Kontynuuj';
  @override
  String tyreSerialNumbers(String tyreWord) => 'Numer seryjny $tyreWord'; // Order changed
  @override
  String enterItemSerialNumber(String itemName) => 'Wprowadź numer seryjny $itemName';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "Dozwolone są tylko wartości liczbowe";
  @override String get negativeValueError => "Wartość nie może być ujemna";
  @override String get duplicateVehicleError => "Numer pojazdu jest już zajęty";
  @override String get invalidNumberError => "Musi być prawidłowym numerem";
  @override String get enterPrefix => "Wprowadź ";
  @override String recommendedPressureFor(String axle) => "Zalecane ciśnienie dla $axle";
  @override String get numericOnly => "Dozwolone są tylko wartości liczbowe";

  @override String get inventory => '库存';
  @override String get onHold => '暂停';
  @override String get scrap => '报废';
  @override String get repair => '维修';
  @override String get retread => '翻新';
  @override String get edit => '编辑';
  @override String get clone => '克隆';
  @override String get ok => 'OK';

}
