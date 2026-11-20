import 'app_localizations.dart';

class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([super.locale = 'it']);

  @override String get homeTitle => 'Home';
  @override String get greeting => 'Benvenuto';
  @override String get settings => 'Impostazioni';
  @override String get language => 'Lingua';
  @override String get measurementSystem => 'Sistema di misura';
  @override String get pressureUnit => 'Unità di pressione';
  @override String get update => 'Aggiorna';
  @override String get cancel => 'Annulla';
  @override String get addTyre => 'Aggiungi pneumatico';
  @override String get save => 'Salva';

  // Screen labels
  @override String get vehicleId => 'ID Veicolo';
  @override String get currentHours => 'Ore Attuali';
  @override String get currentKm => '{unit} Attuale';
  @override String get trackingMethod => 'Metodo di Tracciamento';
  @override String get manufacturer => 'Produttore';
  @override String get vehicleType => 'Tipo';
  @override String get model => 'Modello';
  @override String get tyreSize => 'Dimensione Pneumatico';
  @override String get removalTread => 'Battistrada di Rimozione';
  @override String get vehicleComments => 'Commenti Veicolo';
  @override String get vehicleDiagram => 'Diagramma Veicolo';
  @override String get recommendedPressure => 'Pressione Consigliata';
  @override String get submit => 'Invia';
  @override String get createVehicle => 'Crea Nuovo Veicolo';
  @override String get outsideTread => 'Profondità Battistrada Esterno';
  @override String get insideTread => 'Profondità Battistrada Interno';
  @override String get averageTread => 'Battistrada Medio';
  @override String get airPressure => 'Pressione Aria';
  @override String get lastRecordedDate => 'Ultima Data Registrata';
  @override String get lastRecordedHours => 'Ultime Ore Registrate';
  @override String get updateHours => 'Aggiorna Ore';
  @override String get lastRecordedKm => 'Ultima {unit} Registrata';
  @override String get updateKm => 'Aggiorna {unit}';
  @override String get vehicleNumber => 'Numero Veicolo';
  @override String get editVehicle => 'Modifica Veicolo';

  @override String get selectedParentAccountLocation => 'Account principale selezionato e posizione';
  @override String get loadingMasterData => 'Caricamento dati principali...';
  @override String get creatingVehicle => 'Creazione veicolo...';
  @override String get trackingMethodTitle => 'Metodo di Tracciamento';
  @override String get trackingMethodHours => 'Ore';
  @override String get trackingMethodDistance => 'Distanza';
  @override String get trackingMethodBoth => 'Entrambi';
  @override String get searchHint => 'Cerca...';
  @override String get noDataAvailable => 'Nessun dato disponibile';
  @override String get noTireInstalled => 'Nessun\nPneumatico\nInstallato';
  @override String get axleLabel => 'Asse';
  @override String get cancelRequestTitle => 'Annulla richiesta';
  @override String get cancelRequestMessage => 'Sei sicuro di voler annullare? I dati non salvati andranno persi.';
  @override String get cancelRequestYes => 'Sì';
  @override String get currentDistance => 'Attuale';
  @override String get enterCurrentDistance => 'Inserisci il valore attuale';
  @override String get commentsHint => 'I commenti vanno qui. (Max 200 caratteri)';

  // ================= STEP 1 =================
  @override String get identificationDetails => 'Dettagli di identificazione';

  @override String get tyreSerialNumber => 'Numero di serie del pneumatico';
  @override String get enterTyreSerialNumber => 'Inserisci numero di serie';
  @override String get tyreSerialRequired => 'Numero di serie obbligatorio';
  @override String get tyreSerialDuplicate => 'Questo numero di serie esiste già';

  @override String get brandNumber => 'Numero marchio';
  @override String get enterBrandNumber => 'Inserisci numero marchio';

  @override String get registerDate => 'Data di registrazione';
  @override String get registerDateRequired => 'Data obbligatoria';

  @override String get evaluationNumber => 'Numero valutazione';
  @override String get lotNumber => 'Numero lotto';
  @override String get purchaseOrderNumber => 'Numero ordine di acquisto';

  @override String get disposition => 'Disposizione';
  @override String get status => 'Stato';

  @override String get currentHoursRequired => 'Ore attuali obbligatorie';
  @override String get invalidHours => 'Inserisci un valore valido';
  @override String get negativeHours => 'Non può essere negativo';

  @override String get currentKmRequired => 'KM attuali obbligatori';
  @override String get invalidKm => 'Inserisci un valore valido';
  @override String get negativeKm => 'Non può essere negativo';

  // ================= STEP 2 =================
  @override String get description => 'Descrizione';

  @override String get selectManufacturer => 'Cerca produttore';
  @override String get selectTyreSize => 'Seleziona dimensione';

  @override String get starRating => 'Valutazione stelle';

  @override String get selectType => 'Seleziona tipo';

  @override String get indCode => 'Codice Ind.';
  @override String get compound => 'Composto';
  @override String get loadRating => 'Indice di carico';
  @override String get speedRating => 'Indice di velocità';

  @override String get requiredField => '⚠️ Inserisci dati validi';

  // ================= BUTTONS =================
  @override String get nextBtn => 'Avanti';
  @override String get previousBtn => 'Indietro';
  @override String get cancelBtn => 'Annulla';
  @override String get okBtn => 'OK';

  @override String get next => 'Avanti';
  @override String get previous => 'Indietro';

  @override String get enterValidDetails => 'Inserisci dati validi';
  @override String get onlyNumeric => 'Solo valori numerici';
  @override String get originalTread => 'Battistrada originale';
  @override String get removeAt => 'Rimuovi a';
  @override String get purchaseTread => 'Battistrada acquisto';
  @override String get outside => 'Esterno';
  @override String get inside => 'Interno';
  @override String get wornWarning => 'Attenzione: usura critica';
  @override String get treadDepth => 'Profondità battistrada';
  @override String get vehicleViewTitle => 'Visualizza Veicolo';
  @override String get viewVehicle => 'Visualizza Veicolo';
  @override String get inspect => 'Ispeziona';
  @override String get error => 'Errore';
  @override String get noVehicleId => 'ID veicolo mancante';
  @override String get vehicleNotFound => 'Veicolo non trovato';
  @override String get wheelPosition => 'Posizione ruota';
  @override String get costs => 'Costi';
  @override String get viewTyre => 'Visualizza Pneumatico';
  @override String get identification => 'Identificazione';
  @override String get purchasedTread => 'Battistrada acquistato';
  @override String get middleTread => 'Battistrada centrale';
  @override String get currentTreadDepth => 'Profondità attuale';
  @override String get percentageWorn => '% Usura';
  @override String get currentPressure => 'Pressione attuale';
  @override String get fillType => 'Tipo riempimento';
  @override String get fillCost => 'Costo riempimento';
  @override String get repairCost => 'Costo riparazione';
  @override String get retreadCost => 'Costo ricostruzione';
  @override String get warrantyAdjustment => 'Aggiustamento garanzia';
  @override String get costAdjustment => 'Aggiustamento costo';
  @override String get netCost => 'Costo netto';
  @override String get soldAmount => 'Importo vendita';

  // ================= HOME / DRAWER =================
  @override String get parentAccount => 'Account principale';
  @override String get location => 'Posizione';
  @override String get changeLocationAccount => 'Cambia account e posizione';

  @override String get mainMenu => 'Menu principale';
  @override String get home => 'Home';
  @override String get create => 'Crea';
  @override String get preferences => 'Preferenze';
  @override String get user => 'Utente';
  @override String get logout => 'Logout';

  @override String get createVehicleMenu => 'Crea veicolo';
  @override String get createTyreMenu => 'Crea';

  @override String get userManagementList => 'Gestione utenti';
  @override String get grandparentAccount => 'Account superiore';
  @override String get startInspection => 'Inizia ispezione';
  @override String get grandparentAccountView => 'Account superiori vista';        // Italiano (IT)

  @override String get totalVehicles => 'Totale veicoli';
  @override String get totalTyres => 'Totale pneumatici';

  @override String get lastInspection => 'Ultima ispezione';
  @override String get sync => 'Sincronizza';

  @override String get unsyncInspection => 'Ispezione non sincronizzata';
  @override String get syncInspection => 'Ispezione sincronizzata';

  @override String get appVersion => 'Versione app';
  @override String get change => 'Cambia';

  @override String get syncSuccess => 'Sincronizzazione riuscita';
  @override String get syncFailed => 'Sincronizzazione fallita';

  @override String get noPermissionCreate => 'Nessun permesso per creare';

  // ... (existing code)

  // ================= CREATE TYRE STEP 2 =================
  @override String get manufacture => 'Fabbricazione';
  @override String get tireSize => 'Dimensione pneumatico';
  @override String get searchTireManufacturer => 'Cerca produttore pneumatici';
  @override String get chooseManufacturerFirst => 'Scegli prima il produttore';
  @override String get chooseSizeFirst => 'Scegli prima la dimensione';
  @override String get starRatingSelect => 'Seleziona';
  @override String get selectFillType => 'Tipo riempimento';

  // ================= CREATE TYRE STEP 3 =================
  @override String get treadDepthUnit => 'Profundità battistrada';
  @override String get originalTreadUnit => 'Battistrada originale';
  @override String get removeAtUnit => 'Rimuovi a';
  @override String get purchaseTreadUnit => 'Battistrada acquisto';
  @override String get outsideUnit => 'Esterno (a)';
  @override String get insideUnit => 'Interno (c)';
  @override String get enterOriginalTread => 'Inserisci battistrada originale';
  @override String get enterRemoveAt => 'Rimuovi a';
  @override String get enterPurchaseTread => 'Inserisci battistrada acquisto';
  @override String get wornPercent => '% usura';

  // ================= CREATE TYRE STEP 4 =================
  @override String get tireCosts => 'Costi pneumatico';
  @override String get purchaseCostA => 'Costo acquisto (a)';
  @override String get casingValueB => 'Valore carcassa (B)';
  @override String get fillCostC => 'Costo riempimento (C)';
  @override String get repairsCostD => 'Costo riparazioni (D)';
  @override String get numberOfRetreads => 'Numero di ricostruzioni';
  @override String get retreadCostE => 'Costo ricostruzione (E)';
  @override String get warrantyAdjustmentF => 'Aggiustamento garanzia (F)';
  @override String get costAdjustmentG => 'Aggiustamento costo (G)';
  @override String get soldAmountH => 'Importo vendita (H)';
  @override String get netCostFormula => 'Costo netto = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'Salva e Clona';
  @override String get enterDisposition => 'Inserisci disposizione';
  @override String get enterEvaluationNumber => 'Inserisci numero valutazione';
  @override String get enterLotNumber => 'Inserisci numero lotto';
  @override String get enterPurchaseOrderNumber => 'Inserisci numero ordine';
  @override String get enterCurrentHours => 'Inserisci ore attuali';
  @override String get enterCurrentKm => 'Inserisci KM attuali';
  @override String get enterValidNumeric => 'Inserisci un valore numerico valido.';
  @override String get hoursNotNegative => 'Le ore non possono essere negative.';
  @override String get kmNotNegative => 'I KM non possono essere negativi.';
  @override String get serialAlreadyExists => 'Questo numero di serie esiste già';
  @override String get searchIndCode => 'Cerca codice Ind.';
  @override String get searchCompound => 'Cerca composto';
  @override String get searchLoadRating => 'Cerca indice di carico';
  @override String get searchSpeedRating => 'Cerca indice di velocità';
  @override String get selectItem => 'Seleziona';
  @override String get selectPrefix => 'Seleziona ';
  @override String get serialNumber => 'Numero di serie';
  @override String get enter => 'Inserisci';
  @override String get selectedAccountLocation => 'Account e posizione selezionati';
  @override String get viewInspections => 'Visualizza ispezioni';
  @override String get view => 'Visualizza';
  @override String get vehicle => 'Veicolo';
  @override String get total => 'Totale';
  @override String get enterVehicleNumber => 'Inserisci il numero del veicolo';
  @override String get editTyre => 'Modifica pneumatico';
  @override String get clear => 'CANCELLA';
  @override String get set => 'IMPOSTA';
  @override String get enterValidNumber => 'Inserisci un numero valido';
  @override String get allVehicles => 'Tutti i veicoli';
  @override String get searchVehicles => 'Cerca veicoli...';
  @override String get filters => 'Filtri';
  @override String get applyFilters => 'Applica filtri';
  @override String get clearAllFilters => 'Cancella tutti i filtri';
  @override String get pendingSync => 'Sincronizzazione in sospeso';
  @override String get make => 'Marca';
  @override String get transfer => 'Trasferisci';
  @override String get delete => 'Elimina';
  @override String get own => 'Proprio';
  @override String get shared => 'Condiviso';
  @override String get select => 'Seleziona';
  @override String get searchAccount => 'Cerca account';
  @override String get searchLocation => 'Cerca posizione';
  @override String get noAccountsFound => 'Nessun account trovato';
  @override String get noLocationsFound => 'Nessuna posizione trovata';
  @override String get inspectTyre => 'Ispeziona pneumatico';
  @override String get installTyre => 'Installa pneumatico';
  @override String get airPressureType => 'Tipo di pressione dell\'aria';
  @override String get cold => 'Freddo';
  @override String get hot => 'Caldo';
  @override String get wearCondition => 'Condizioni di usura';
  @override String get casingCondition => 'Condizioni carcassa';
  @override String get listOfPreviousComments => 'Elenco commenti precedenti';
  @override String get stillRelevant => 'Ancora rilevante';
  @override String get uploadImages => 'Carica immagini';
  @override String get images => 'Immagini';
  @override String get confirmRemove => 'Conferma rimozione';
  @override String get areYouSureRemoveImage => 'Sei sicuro di voler rimuovere questa immagine?';
  @override String get removeTire => 'Rimuovi pneumatico';
  @override String get remove => 'Rimuovi';
  @override String get all => 'Tutti';
  @override String get editBtn => 'Modifica';
  @override String get takePhoto => 'Scatta foto';
  @override String get chooseFromGallery => 'Scegli dalla galleria';
  @override String get commentsLabel => 'Commenti';
  @override String get yes => 'SÌ';
  @override String get no => 'NO';
  @override String get upload => 'Carica';
  @override String get install => 'Installa';
  @override String get tyreType => 'Tipo';
  @override String get loading => 'Caricamento...';
  @override String get syncAll => 'Sincronizza tutto';
  @override String get updateDisposition => 'Aggiorna disposizione *';
  @override String get removalReason => 'Motivo della rimozione';
  @override String get selectDisposition => 'Seleziona disposizione';
  @override String get selectRemovalReason => 'Seleziona motivo rimozione';
  @override String get rotatePosition => 'Ruota posizione';
  @override String get placementError => 'Si prega di posizionare lo pneumatico in uno slot prima di salvare.';
  @override String get rotationSavedOffline => 'Rotazione salvata localmente. Verrà sincronizzata quando internet sarà disponibile.';
  @override String get rotationSuccessful => 'Rotazione pneumatici aggiornata e salvata con successo.';
  @override String get searchInventory => 'Cerca pneumatico nell\'inventario';
  @override String get noInventoryFound => 'Nessuno pneumatico trovato nell\'inventario';
  @override String get manufacturerLabel => 'Marca/Produttore';
  @override String get unsynced => 'Non sincronizzato';
  @override String get synced => 'Sincronizzato';
  @override String get unsyncedPending => 'ispezioni non sincronizzate in attesa';
  @override String get offlineSyncMessage => 'Offline — connetti internet per sincronizzare';
  @override String get confirmDeleteTitle => 'Eliminare l\'ispezione?';
  @override String get confirmDeleteMessage => 'Eliminare definitivamente questa ispezione?';
  @override String get viewInspection => 'Visualizza ispezione';
  @override String get syncing => 'Sincronizzazione...';
  @override String get inspected => 'Ispezionato';
  @override String get deleteInspectionTitle => 'Eliminare l\'ispezione?';
  @override String get deleteInspectionConfirm => 'Elimina definitivamente l\'ispezione per';
  @override String get tyresLabel => 'Pneumatici';
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
  @override String get searchVehicleTyre => 'Cerca veicolo / pneumatico';
  @override String get recentSearch => 'Ricerca recente';
  @override String get vehicles => 'Veicoli';
  @override String get recentVehicleNotFound => 'Nessun veicolo recente trovato';
  @override String get recentTyreNotFound => 'Nessun pneumatico recente trovato';
  @override String get typeToSearch => 'Digita per cercare';
  @override String get noVehiclesFound => 'Nessun veicolo trovato per';
  @override String get noTyresFound => 'Nessun pneumatico trovato per';
  @override String get createNewVehicle => 'Crea nuovo veicolo';
  @override String get createNewTyre => 'Crea nuovo pneumatico';
  @override String get confirmRemoveTitle => 'Conferma rimozione';
  @override String get confirmRemoveMessage => 'Sei sicuro di voler rimuovere questo elemento?';
  @override String get updateBtn => 'Aggiorna';
  @override String get noRecentVehicleFound => 'Nessun veicolo recente trovato';
  @override String get noRecentTyreFound => 'Nessun pneumatico recente trovato';
  @override String get noVehiclesFoundFor => 'Nessun veicolo trovato per';
  @override String get noTyresFoundFor => 'Nessun pneumatico trovato per';
  @override String get searchPrefix => 'Cerca';
  @override
  String createNew(String itemName) => 'Crea nuovo $itemName';


  @override String get vehicleInspection => 'Ispezione veicolo';
  @override String get hourWarningMsg => "Non hai aggiornato le ore, i chilometri e il veicolo.";
  @override String get hours => 'Ore';
  @override String get km => 'KM';
  @override String get updateHoursKm => 'Aggiorna Ore / KM';
  @override String get serialNo => 'Numero di serie';
  @override String get inspectedTire => 'Pneumatico ispezionato';
  @override String get notInspectedTire => 'Pneumatico non ispezionato';
  @override String get rotateTyres => 'Ruota pneumatici';
  @override String get uploadedImages => 'Immagini caricate';
  @override String get confirmRemoveImg => 'Conferma rimozione immagine';
  @override String get viewOnlyDisabled => 'Solo visualizzazione — Invio disabilitato';
  @override String get cancelRequestMsg => 'Sei sicuro di voler annullare? Perderai i dati non salvati.';
  @override String get selectedParentAccount => 'Account principale selezionato';
  @override String get surveyDate => 'Data del sondaggio';
  @override String get selectDate => 'Seleziona data';
  @override String get updateHoursLabel => 'Aggiorna ore';
  @override String get enterHours => 'Inserisci ore';
  @override String get updateKmLabel => 'Aggiorna KM';
  @override String get enterKm => 'Inserisci KM';
  @override String get updateVehicleDataTitle => 'Aggiorna dati veicolo';
  @override String get updateVehicleDataMsg => 'Queste modifiche influenzeranno le ore/KM degli pneumatici.\nVuoi procedere?';
  @override String get proceed => 'Procedi';
  @override
  String tyreSerialNumbers(String tyreWord) => 'Numero di serie $tyreWord';
  @override
  String enterItemSerialNumber(String itemName) => 'Inserire il numero di serie $itemName';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "Sono ammessi solo valori numerici";
  @override String get negativeValueError => "Il valore non può essere negativo";
  @override String get duplicateVehicleError => "Numero veicolo già esistente";
  @override String get invalidNumberError => "Deve essere un numero valido";
  @override String get enterPrefix => "Inserire ";
  @override String recommendedPressureFor(String axle) => "Pressione consigliata per $axle";
  @override String get numericOnly => "Sono ammessi solo valori numerici";

  @override String get inventory => 'Inventar';
  @override String get onHold => 'In Wartestellung';
  @override String get scrap => 'Schrott';
  @override String get repair => 'Reparatur';
  @override String get retread => 'Runderneuerung';
  @override String get edit => 'Bearbeiten';
  @override String get clone => 'Klonen';
  @override String get ok => 'OK';

}