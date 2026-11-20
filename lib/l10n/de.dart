import 'app_localizations.dart';

class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override String get homeTitle => 'Startseite';
  @override String get greeting => 'Willkommen';
  @override String get settings => 'Einstellungen';
  @override String get language => 'Sprache';
  @override String get measurementSystem => 'Maßsystem';
  @override String get pressureUnit => 'Druckeinheit';
  @override String get update => 'Aktualisieren';
  @override String get cancel => 'Abbrechen';
  @override String get addTyre => 'Reifen hinzufügen';
  @override String get save => 'Speichern';

  // Screen labels
  @override String get vehicleId => 'Fahrzeug-ID';

  @override String get currentHours => 'Aktuelle Stunden';
  @override String get currentKm => 'Aktuelle {unit}';
  @override String get trackingMethod => 'Verfolgungsmethode';
  @override String get manufacturer => 'Hersteller';
  @override String get vehicleType => 'Typ';
  @override String get model => 'Modell';
  @override String get tyreSize => 'Reifengröße';
  @override String get removalTread => 'Abnahme-Profiltiefe';
  @override String get vehicleComments => 'Fahrzeugkommentare';
  @override String get vehicleDiagram => 'Fahrzeugdiagramm';
  @override String get recommendedPressure => 'Empfohlener Druck';
  @override String get submit => 'Einreichen';
  @override String get createVehicle => 'Neues Fahrzeug erstellen';
  @override String get outsideTread => 'Außenprofiltiefe';
  @override String get insideTread => 'Innenprofiltiefe';
  @override String get averageTread => 'Durchschnittsprofil';
  @override String get airPressure => 'Luftdruck';
  @override String get lastRecordedDate => 'Zuletzt erfasstes Datum';
  @override String get lastRecordedHours => 'Zuletzt erfasste Stunden';
  @override String get updateHours => 'Stunden aktualisieren';
  @override String get lastRecordedKm => 'Zuletzt erfasste {unit}';
  @override String get updateKm => '{unit} aktualisieren';
  @override String get vehicleNumber => 'Fahrzeugnummer';
  @override String get editVehicle => 'Fahrzeug bearbeiten';

  @override String get selectedParentAccountLocation => 'Ausgewähltes Hauptkonto & Standort';
  @override String get loadingMasterData => 'Stammdaten werden geladen...';
  @override String get creatingVehicle => 'Fahrzeug wird erstellt...';
  @override String get trackingMethodTitle => 'Tracking-Methode';
  @override String get trackingMethodHours => 'Stunden';
  @override String get trackingMethodDistance => 'Entfernung';
  @override String get trackingMethodBoth => 'Beides';
  @override String get searchHint => 'Suchen...';
  @override String get noDataAvailable => 'Keine Daten verfügbar';
  @override String get noTireInstalled => 'Kein\nReifen\nInstalliert';
  @override String get axleLabel => 'Achse';
  @override String get cancelRequestTitle => 'Anfrage abbrechen';
  @override String get cancelRequestMessage => 'Möchten Sie wirklich abbrechen? Nicht gespeicherte Daten gehen verloren.';
  @override String get cancelRequestYes => 'Ja';
  @override String get currentDistance => 'Aktuell';
  @override String get enterCurrentDistance => 'Aktuellen Wert eingeben';
  @override String get commentsHint => 'Kommentare hier eingeben. (Max. 200 Zeichen)';

  // ================= CREATE TYRE (STEP 1) =================
  @override String get identificationDetails => 'Identifikationsdetails';

  @override String get tyreSerialNumber => 'Reifen-Seriennummer';
  @override String get enterTyreSerialNumber => 'Seriennummer eingeben';
  @override String get tyreSerialRequired => 'Seriennummer erforderlich';
  @override String get tyreSerialDuplicate => 'Seriennummer bereits vorhanden';

  @override String get brandNumber => 'Markennummer';
  @override String get enterBrandNumber => 'Markennummer eingeben';

  @override String get registerDate => 'Registrierungsdatum';
  @override String get registerDateRequired => 'Registrierungsdatum erforderlich';

  @override String get evaluationNumber => 'Bewertungsnummer';
  @override String get lotNumber => 'Losnummer';
  @override String get purchaseOrderNumber => 'Bestellnummer';

  @override String get disposition => 'Disposition';
  @override String get status => 'Status';

  @override String get currentHoursRequired => 'Aktuelle Stunden erforderlich';
  @override String get invalidHours => 'Ungültige Stunden';
  @override String get negativeHours => 'Stunden dürfen nicht negativ sein';

  @override String get currentKmRequired => 'Aktueller Wert erforderlich';
  @override String get invalidKm => 'Ungültiger Wert';
  @override String get negativeKm => 'Wert darf nicht negativ sein';

  // ================= CREATE TYRE (STEP 2) =================
  @override String get description => 'Beschreibung';

  @override String get selectManufacturer => 'Hersteller auswählen';
  @override String get selectTyreSize => 'Reifengröße auswählen';

  @override String get starRating => 'Bewertung';

  @override String get selectType => 'Typ auswählen';

  @override String get indCode => 'Ind Code';
  @override String get compound => 'Mischung';
  @override String get loadRating => 'Tragfähigkeitsindex';
  @override String get speedRating => 'Geschwindigkeitsindex';

  @override String get requiredField => 'Pflichtfeld';

  // ================= BUTTONS =================
  @override String get nextBtn => 'Weiter';
  @override String get previousBtn => 'Zurück';
  @override String get cancelBtn => 'Abbrechen';
  @override String get okBtn => 'OK';

  @override String get originalTread => "Originalprofil";
  @override String get removeAt => "Entfernen bei";
  @override String get purchaseTread => "Kaufprofil";
  @override String get outside => "Außen";
  @override String get inside => "Innen";



  @override String get wornWarning =>
      "Warnung: Profil unter Sicherheitsgrenze.";
  @override String get enterValidDetails => "Gültige Daten eingeben.";
  @override String get onlyNumeric => "Nur Zahlen erlaubt.";
  @override String get treadDepth => "Profiltiefe";
  @override String get next => 'Próximo';
  @override String get previous => 'Anterior';

  // ================= VEHICLE VIEW =================
  @override String get vehicleViewTitle => 'Fahrzeug anzeigen';
  @override String get viewVehicle => 'Fahrzeug anzeigen';
  @override String get inspect => 'Prüfen';
  @override String get error => 'Fehler';
  @override String get noVehicleId => 'Keine Fahrzeug-ID';
  @override String get vehicleNotFound => 'Fahrzeug nicht gefunden';
  @override String get wheelPosition => 'Radposition';
  @override String get costs => 'Kosten';

  // ================= TYRE VIEW =================
  @override String get viewTyre => 'Reifen anzeigen';
  @override String get identification => 'Identifikation';
  @override String get purchasedTread => 'Gekauftes Profil';
  @override String get middleTread => 'Mittleres Profil';
  @override String get currentTreadDepth => 'Aktuelle Profiltiefe';
  @override String get percentageWorn => 'Verschleiß %';
  @override String get currentPressure => 'Aktueller Druck';
  @override String get fillType => 'Fülltyp';
  @override String get fillCost => 'Füllkosten';
  @override String get repairCost => 'Reparaturkosten';
  @override String get retreadCost => 'Runderneuerungskosten';
  @override String get warrantyAdjustment => 'Garantieanpassung';
  @override String get costAdjustment => 'Kostenanpassung';
  @override String get netCost => 'Nettokosten';
  @override String get soldAmount => 'Verkaufsbetrag';

  // ================= HOME / DRAWER =================
  @override String get parentAccount => 'Hauptkonto';
  @override String get location => 'Standort';
  @override String get changeLocationAccount => 'Konto/Standort ändern';

  @override String get mainMenu => 'Hauptmenü';
  @override String get home => 'Startseite';
  @override String get create => 'Erstellen';
  @override String get preferences => 'Einstellungen';
  @override String get user => 'Benutzer';
  @override String get logout => 'Abmelden';

  @override String get createVehicleMenu => 'Fahrzeug erstellen';
  @override String get createTyreMenu => 'Reifen';

  @override String get userManagementList => 'Benutzerverwaltung';
  @override String get grandparentAccount => 'Haupt-Hauptkonto';
  @override String get grandparentAccountView => 'Hauptkontenansicht';               // Alemán (DE)
  @override String get startInspection => 'Inspektion starten';

  @override String get totalVehicles => 'Gesamtfahrzeuge';
  @override String get totalTyres => 'Gesamtreifen';

  @override String get lastInspection => 'Letzte Inspektion';
  @override String get sync => 'Synchronisieren';

  @override String get unsyncInspection => 'Nicht synchronisiert';
  @override String get syncInspection => 'Synchronisiert';

  @override String get appVersion => 'App-Version';
  @override String get change => 'Ändern';

  @override String get syncSuccess => 'Synchronisierung erfolgreich';
  @override String get syncFailed => 'Synchronisierung fehlgeschlagen';

  @override String get noPermissionCreate => 'Keine Berechtigung zum Erstellen';
  // ================= CREATE TYRE STEP 2 =================
  @override String get manufacture => 'Herstellung';
  @override String get tireSize => 'Reifengröße';
  @override String get searchTireManufacturer => 'Reifenhersteller suchen';
  @override String get chooseManufacturerFirst => 'Zuerst Hersteller auswählen';
  @override String get chooseSizeFirst => 'Zuerst Größe auswählen';
  @override String get starRatingSelect => 'Auswählen';
  @override String get selectFillType => 'Fülltyp';

  // ================= CREATE TYRE STEP 3 =================
  @override String get treadDepthUnit => 'Profiltiefe';
  @override String get originalTreadUnit => 'Originalprofil';
  @override String get removeAtUnit => 'Entfernen bei';
  @override String get purchaseTreadUnit => 'Kaufprofil';
  @override String get outsideUnit => 'Außen (a)';
  @override String get insideUnit => 'Innen (c)';
  @override String get enterOriginalTread => 'Originalprofil eingeben';
  @override String get enterRemoveAt => 'Entfernen bei';
  @override String get enterPurchaseTread => 'Kaufprofil eingeben';
  @override String get wornPercent => '% verschlissen';

  // ================= CREATE TYRE STEP 4 =================
  @override String get tireCosts => 'Reifenkosten';
  @override String get purchaseCostA => 'Anschaffungskosten (a)';
  @override String get casingValueB => 'Karkassenwert (B)';
  @override String get fillCostC => 'Füllkosten (C)';
  @override String get repairsCostD => 'Reparaturkosten (D)';
  @override String get numberOfRetreads => 'Anzahl Runderneuerungen';
  @override String get retreadCostE => 'Runderneuerungskosten (E)';
  @override String get warrantyAdjustmentF => 'Garantieanpassung (F)';
  @override String get costAdjustmentG => 'Kostenanpassung (G)';
  @override String get soldAmountH => 'Verkaufsbetrag (H)';
  @override String get netCostFormula => 'Nettokosten = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'Speichern & Klonen';
  @override String get enterDisposition => 'Disposition eingeben';
  @override String get enterEvaluationNumber => 'Bewertungsnummer eingeben';
  @override String get enterLotNumber => 'Losnummer eingeben';
  @override String get enterPurchaseOrderNumber => 'Bestellnummer eingeben';
  @override String get enterCurrentHours => 'Aktuelle Stunden eingeben';
  @override String get enterCurrentKm => 'Aktuelle KM eingeben';
  @override String get enterValidNumeric => 'Bitte einen gültigen numerischen Wert eingeben.';
  @override String get hoursNotNegative => 'Stunden können nicht negativ sein.';
  @override String get kmNotNegative => 'KM können nicht negativ sein.';
  @override String get serialAlreadyExists => 'Diese Seriennummer existiert bereits';
  @override String get searchIndCode => 'IND-Code suchen';
  @override String get searchCompound => 'Mischung suchen';
  @override String get searchLoadRating => 'Tragfähigkeit suchen';
  @override String get searchSpeedRating => 'Geschwindigkeit suchen';
  @override String get selectItem => 'Auswählen';
  @override String get selectPrefix => 'Wählen Sie ';
  @override String get serialNumber => 'Seriennummer';
  @override String get enter => 'Eingeben';
  @override String get selectedAccountLocation => 'Ausgewähltes Konto & Standort';
  @override String get viewInspections => 'Inspektionen anzeigen';
  @override String get view => 'Anzeigen';
  @override String get vehicle => 'Fahrzeug';
  @override String get total => 'Gesamt';
  @override String get enterVehicleNumber => 'Fahrzeugnummer eingeben';
  @override String get editTyre => 'Reifen bearbeiten';
  @override String get clear => 'LÖSCHEN';
  @override String get set => 'FESTLEGEN';
  @override String get enterValidNumber => 'Gültige Nummer eingeben';
  @override String get allVehicles => 'Alle Fahrzeuge';
  @override String get searchVehicles => 'Fahrzeuge suchen...';
  @override String get filters => 'Filter';
  @override String get applyFilters => 'Filter anwenden';
  @override String get clearAllFilters => 'Alle Filter löschen';
  @override String get pendingSync => 'Ausstehende Synchronisation';
  @override String get make => 'Marke';
  @override String get transfer => 'Übertragen';
  @override String get delete => 'Löschen';
  @override String get own => 'Eigen';
  @override String get shared => 'Geteilt';
  @override String get select => 'Auswählen';
  @override String get searchAccount => 'Konto suchen';
  @override String get searchLocation => 'Standort suchen';
  @override String get noAccountsFound => 'Keine Konten gefunden';
  @override String get noLocationsFound => 'Keine Standorte gefunden';
  @override String get inspectTyre => 'Reifen prüfen';
  @override String get installTyre => 'Reifen montieren';
  @override String get airPressureType => 'Luftdrucktyp';
  @override String get cold => 'Kalt';
  @override String get hot => 'Heiß';
  @override String get wearCondition => 'Verschleißzustand';
  @override String get casingCondition => 'Karkassenzustand';
  @override String get listOfPreviousComments => 'Liste früherer Kommentare';
  @override String get stillRelevant => 'Immer noch relevant';
  @override String get uploadImages => 'Bilder hochladen';
  @override String get images => 'Bilder';
  @override String get confirmRemove => 'Löschen bestätigen';
  @override String get areYouSureRemoveImage => 'Sind Sie sicher, dass Sie dieses Bild entfernen möchten?';
  @override String get removeTire => 'Reifen entfernen';
  @override String get remove => 'Entfernen';
  @override String get all => 'Alle';
  @override String get editBtn => 'Bearbeiten';
  @override String get takePhoto => 'Foto machen';
  @override String get chooseFromGallery => 'Aus Galerie wählen';

  @override String get commentsLabel => 'Kommentare';
  @override String get yes => 'JA';
  @override String get no => 'NEIN';
  @override String get upload => 'Hochladen';
  @override String get install => 'Installieren';
  @override String get tyreType => 'Typ';
  @override String get loading => 'Laden...';
  @override String get syncAll => 'Alle synchronisieren';
  @override String get updateDisposition => 'Disposition aktualisieren *';
  @override String get removalReason => 'Grund für den Ausbau';
  @override String get selectDisposition => 'Disposition wählen';
  @override String get selectRemovalReason => 'Ausbaugrund wählen';
  @override String get rotatePosition => 'Position rotieren';
  @override String get placementError => 'Bitte platzieren Sie den Reifen vor dem Speichern in einem Slot.';
  @override String get rotationSavedOffline => 'Rotation lokal gespeichert. Synchronisierung erfolgt bei Internetverbindung.';
  @override String get rotationSuccessful => 'Reifenrotation erfolgreich aktualisiert und gespeichert.';
  @override String get searchInventory => 'Reifen im Inventar suchen';
  @override String get noInventoryFound => 'Keine Reifen im Inventar gefunden';
  @override String get manufacturerLabel => 'Marke/Hersteller';
  @override String get unsynced => 'Nicht synchronisiert';
  @override String get synced => 'Synchronisiert';
  @override String get unsyncedPending => 'nicht synchronisierte Inspektion(en) ausstehend';
  @override String get offlineSyncMessage => 'Offline — Internet verbinden zum Synchronisieren';
  @override String get confirmDeleteTitle => 'Inspektion löschen?';
  @override String get confirmDeleteMessage => 'Diese Inspektion dauerhaft löschen?';
  @override String get viewInspection => 'Inspektion ansehen';
  @override String get syncing => 'Synchronisierung...';
  @override String get inspected => 'Inspektionsdatum';
  @override String get deleteInspectionTitle => 'Inspektion löschen?';
  @override String get deleteInspectionConfirm => 'Inspektion dauerhaft löschen für';
  @override String get tyresLabel => 'Reifen';
  @override String get userManagement => 'BENUTZERVERWALTUNG';
  @override String get createUser => 'Benutzer erstellen';
  @override String get searchUser => 'Benutzer suchen';
  @override String get deleteUser => 'Benutzer löschen';
  @override String get deleteUserConfirm => 'Sind Sie sicher, dass Sie diesen Benutzer löschen möchten?';
  @override String get username => 'Benutzername';
  @override String get password => 'Passwort';
  @override String get userRole => 'Benutzerrolle';
  @override String get loginLabel => 'Anmeldung';
  @override String get personalLabel => 'Persönlich';
  @override String get preferenceLabel => 'Präferenz';
  @override String get creatingUser => 'Benutzer wird erstellt...';
  @override String get grandparentAccountOptions => 'GRANDPARENT KONTO-OPTIONEN';
  @override String get grandparentAccountInformation => 'GRANDPARENT KONTO-INFORMATIONEN';
  @override String get searchGrandparent => 'Grandparent suchen';
  @override String get active => 'Aktiv';
  @override String get inactive => 'Inaktiv';
  @override String get ownedBy => 'Eigentum von';
  @override String get createAccount => 'Konto erstellen';
  @override String get assignAccount => 'Konto zuweisen';
  @override String get grandparentNameLabel => 'Grandparent Kontoname';
  @override String get accountTypeLabel => 'Eigentum';
  @override String get selectParentAccount => 'Elternkonto';
  @override String get selectGrandparentAccount => 'Grandparent Konto';
  @override String get assignBtn => 'ZUWEISEN';
  @override String get firstName => 'Vorname';
  @override String get middleName => 'Zweiter Vorname';
  @override String get lastName => 'Nachname';
  @override String get phone => 'Telefon';
  @override String get country => 'Land';
  @override String get measurement => 'Messung';
  @override String get id => 'ID';

  @override String get searchVehicleTyre => 'Fahrzeug / Reifen suchen';
  @override String get recentSearch => 'Letzte Suchen';
  @override String get vehicles => 'Fahrzeuge';
  @override String get recentVehicleNotFound => 'Keine aktuellen Fahrzeuge gefunden';
  @override String get recentTyreNotFound => 'Keine aktuellen Reifen gefunden';
  @override String get typeToSearch => 'Zum Suchen tippen';
  @override String get noVehiclesFound => 'Keine Fahrzeuge gefunden für';
  @override String get noTyresFound => 'Keine Reifen gefunden für';
  @override String get createNewVehicle => 'Neues Fahrzeug erstellen';
  @override String get createNewTyre => 'Neuen Reifen erstellen';
  @override String get confirmRemoveTitle => 'Löschen bestätigen';
  @override String get confirmRemoveMessage => 'Sind Sie sicher, dass Sie dieses Element löschen möchten?';
  @override String get updateBtn => 'Aktualisieren';

  @override String get noRecentVehicleFound => 'Kein aktuelles Fahrzeug gefunden';
  @override String get noRecentTyreFound => 'Kein aktueller Reifen gefunden';
  @override String get noVehiclesFoundFor => 'Keine Fahrzeuge gefunden für';
  @override String get noTyresFoundFor => 'Keine Reifen gefunden für';
  @override String get searchPrefix => 'Suche';
  @override
  String createNew(String itemName) => 'Neuen $itemName erstellen';

  @override String get vehicleInspection => 'Fahrzeuginspektion';
  @override String get hourWarningMsg => "Sie haben die Stunden, Meilen und das Fahrzeug nicht aktualisiert.";
  @override String get hours => 'Stunden';
  @override String get km => 'KM';
  @override String get updateHoursKm => 'Stunden / KM aktualisieren';
  @override String get serialNo => 'Seriennummer';
  @override String get inspectedTire => 'Geprüfter Reifen';
  @override String get notInspectedTire => 'Nicht geprüfter Reifen';
  @override String get rotateTyres => 'Reifen rotieren';
  @override String get uploadedImages => 'Hochgeladene Bilder';
  @override String get confirmRemoveImg => 'Bildlöschung bestätigen';
  @override String get viewOnlyDisabled => 'Nur Anzeige — Übermittlung deaktiviert';
  @override String get cancelRequestMsg => 'Sind Sie sicher, dass Sie abbrechen möchten? Nicht gespeicherte Daten gehen verloren.';
  @override String get selectedParentAccount => 'Ausgewähltes Hauptkonto';
  @override String get surveyDate => 'Erhebungsdatum';
  @override String get selectDate => 'Datum auswählen';
  @override String get updateHoursLabel => 'Stunden aktualisieren';
  @override String get enterHours => 'Stunden eingeben';
  @override String get updateKmLabel => 'KM aktualisieren';
  @override String get enterKm => 'KM eingeben';
  @override String get updateVehicleDataTitle => 'Fahrzeugdaten aktualisieren';
  @override String get updateVehicleDataMsg => 'Diese Änderungen wirken sich auf die Betriebsstunden/KM der Reifen aus.\nMöchten Sie fortfahren?';
  @override String get proceed => 'Fortfahren';
  @override
  String tyreSerialNumbers(String tyreWord) => '$tyreWord-Seriennummer';
  @override
  @override
  String enterItemSerialNumber(String itemName) => '$itemName-Seriennummer eingeben'; // ✅ German grammar: "Enter" comes at the end
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';
  @override String get numericOnlyError => "Nur numerische Werte zulässig";
  @override String get negativeValueError => "Wert darf nicht negativ sein";
  @override String get duplicateVehicleError => "Fahrzeugnummer bereits vergeben";
  @override String get invalidNumberError => "Muss eine gültige Nummer sein";
  @override String get enterPrefix => "Eingeben ";
  @override String recommendedPressureFor(String axle) => "Empfohlener Druck für $axle";
  @override String get numericOnly => "Nur numerische Werte zulässig";

  @override String get inventory => 'Inventar';
  @override String get onHold => 'In Wartestellung';
  @override String get scrap => 'Schrott';
  @override String get repair => 'Reparatur';
  @override String get retread => 'Runderneuerung';
  @override String get edit => 'Bearbeiten';
  @override String get clone => 'Klonen';
  String get ok => 'OK';
}