import 'app_localizations.dart';

class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([super.locale = 'fr']);

  @override String get homeTitle => 'Accueil';
  @override String get greeting => 'Bienvenue';
  @override String get settings => 'Paramètres';
  @override String get language => 'Langue';
  @override String get measurementSystem => 'Système de mesure';
  @override String get pressureUnit => 'Unité de pression';
  @override String get update => 'Mettre à jour';
  @override String get cancel => 'Annuler';
  @override String get addTyre => 'Ajouter un pneu';
  @override String get save => 'Enregistrer';

  // Existing
  @override String get vehicleId => 'ID Véhicule';
  @override String get currentHours => 'Heures Actuelles';
  @override String get currentKm => '{unit} Actuel';
  @override String get trackingMethod => 'Méthode de Suivi';
  @override String get manufacturer => 'Fabricant';
  @override String get vehicleType => 'Type';
  @override String get model => 'Modèle';
  @override String get tyreSize => 'Taille du Pneu';
  @override String get removalTread => 'Profondeur de Dépose';
  @override String get vehicleComments => 'Commentaires Véhicule';
  @override String get vehicleDiagram => 'Schéma du Véhicule';
  @override String get recommendedPressure => 'Pression Recommandée';
  @override String get submit => 'Soumettre';
  @override String get createVehicle => 'Créer un Nouveau Véhicule';
  @override String get outsideTread => 'Profondeur Externe';
  @override String get insideTread => 'Profondeur Interne';
  @override String get averageTread => 'Profondeur Moyenne';
  @override String get airPressure => "Pression d'Air";
  @override String get lastRecordedDate => 'Dernière Date Enregistrée';
  @override String get lastRecordedHours => 'Dernières Heures Enregistrées';
  @override String get updateHours => 'Mettre à Jour les Heures';
  @override String get lastRecordedKm => 'Dernière {unit} Enregistrée';
  @override String get updateKm => 'Mettre à Jour {unit}';
  @override String get vehicleNumber => 'Numéro de Véhicule';
  @override String get editVehicle => 'Modifier le Véhicule';

  @override String get selectedParentAccountLocation => 'Compte principal sélectionné & Emplacement';
  @override String get loadingMasterData => 'Chargement des données de base...';
  @override String get creatingVehicle => 'Création du véhicule...';
  @override String get trackingMethodTitle => 'Méthode de Suivi';
  @override String get trackingMethodHours => 'Heures';
  @override String get trackingMethodDistance => 'Distance';
  @override String get trackingMethodBoth => 'Les deux';
  @override String get searchHint => 'Rechercher...';
  @override String get noDataAvailable => 'Aucune donnée disponible';
  @override String get noTireInstalled => 'Aucun\nPneu\nInstallé';
  @override String get axleLabel => 'Essieu';
  @override String get cancelRequestTitle => 'Annuler la Demande';
  @override String get cancelRequestMessage => 'Êtes-vous sûr ? Les données non enregistrées seront perdues.';
  @override String get cancelRequestYes => 'Oui';
  @override String get currentDistance => 'Actuel';
  @override String get enterCurrentDistance => 'Entrer la valeur actuelle';
  @override String get commentsHint => 'Commentaires ici (Max 200 caractères)';

  // NEW
  @override String get identificationDetails => 'Détails d’identification';
  @override String get tyreSerialNumber => 'Numéro de série du pneu';
  @override String get enterTyreSerialNumber => 'Entrer le numéro de série';
  @override String get tyreSerialRequired => 'Numéro requis';
  @override String get tyreSerialDuplicate => 'Numéro déjà existant';

  @override String get brandNumber => 'Numéro de marque';
  @override String get enterBrandNumber => 'Entrer le numéro';

  @override String get registerDate => 'Date d’enregistrement';
  @override String get registerDateRequired => 'Date requise';

  @override String get evaluationNumber => 'Numéro d’évaluation';
  @override String get lotNumber => 'Numéro de lot';
  @override String get purchaseOrderNumber => 'Numéro de commande';

  @override String get disposition => 'Disposition';
  @override String get status => 'Statut';

  @override String get currentHoursRequired => 'Heures requises';
  @override String get invalidHours => 'Heures invalides';
  @override String get negativeHours => 'Valeur négative non autorisée';

  @override String get currentKmRequired => 'Valeur requise';
  @override String get invalidKm => 'Valeur invalide';
  @override String get negativeKm => 'Valeur négative non autorisée';

  @override String get description => 'Description';
  @override String get selectManufacturer => 'Sélectionner fabricant';
  @override String get selectTyreSize => 'Sélectionner taille';
  @override String get starRating => 'Évaluation';
  @override String get selectType => 'Sélectionner type';
  @override String get indCode => 'Code';
  @override String get compound => 'Composé';
  @override String get loadRating => 'Indice de charge';
  @override String get speedRating => 'Indice de vitesse';
  @override String get requiredField => 'Champ requis';

  @override String get nextBtn => 'Suivant';
  @override String get previousBtn => 'Précédent';
  @override String get cancelBtn => 'Annuler';
  @override String get okBtn => 'OK';

  @override String get originalTread => "Profondeur initiale";
  @override String get removeAt => "Retirer à";
  @override String get purchaseTread => "Profondeur achat";
  @override String get outside => "Extérieur";
  @override String get inside => "Intérieur";
  @override String get next => 'Suivant';
  @override String get previous => 'Précédent';


  @override String get wornWarning =>
      "Avertissement : pneu au-delà de la limite.";
  @override String get enterValidDetails => "Entrer des données valides.";
  @override String get onlyNumeric => "Chiffres uniquement.";
  @override String get treadDepth => "Profondeur";

  // ================= VEHICLE VIEW =================
  @override String get vehicleViewTitle => 'Vue véhicule';
  @override String get viewVehicle => 'Voir véhicule';
  @override String get inspect => 'Inspecter';
  @override String get error => 'Erreur';
  @override String get noVehicleId => 'Aucun ID véhicule';
  @override String get vehicleNotFound => 'Véhicule introuvable';
  @override String get wheelPosition => 'Position roue';
  @override String get costs => 'Coûts';

  // ================= TYRE VIEW =================
  @override String get viewTyre => 'Voir pneu';
  @override String get identification => 'Identification';
  @override String get purchasedTread => 'Profondeur achat';
  @override String get middleTread => 'Profondeur milieu';
  @override String get currentTreadDepth => 'Profondeur actuelle';
  @override String get percentageWorn => 'Usure %';
  @override String get currentPressure => 'Pression actuelle';
  @override String get fillType => 'Type de remplissage';
  @override String get fillCost => 'Coût remplissage';
  @override String get repairCost => 'Coût réparation';
  @override String get retreadCost => 'Coût rechapage';
  @override String get warrantyAdjustment => 'Ajustement garantie';
  @override String get costAdjustment => 'Ajustement coût';
  @override String get netCost => 'Coût net';
  @override String get soldAmount => 'Montant vendu';

  // ================= HOME & DRAWER =================
  @override String get home => 'Accueil';



  @override String get createVehicleMenu => 'Créer véhicule';


  @override String get logout => 'Déconnexion';

  @override String get appVersion => 'Version de l\'application';
  @override String get change => 'Changer';
  @override String get changeLocationAccount => 'Changer compte et emplacement';
  @override String get create => 'Créer';
  @override String get mainMenu => 'Menu principal';
  @override String get parentAccount => 'Compte principal';
  @override String get location => 'Emplacement';
  @override String get createTyreMenu => 'Créer';
  @override String get user => 'Utilisateur';
  @override String get preferences => 'Préférences';
  @override String get sync => 'Synchronisation';
  @override String get syncSuccess => 'Synchronisation réussie';
  @override String get syncFailed => 'Échec de synchronisation';
  @override String get totalVehicles => 'Total véhicules';
  @override String get totalTyres => 'Total pneus';
  @override String get lastInspection => 'Dernière inspection';
  @override String get unsyncInspection => 'Non synchronisé';
  @override String get syncInspection => 'Synchronisé';
  @override String get noPermissionCreate => 'Pas de permission';
  @override String get grandparentAccount => 'Compte grand-parent';
  @override String get grandparentAccountView => 'Comptes grand-parent vue';       // Francés (FR)
  @override String get startInspection => 'Commencer l\'inspection';
  @override String get userManagementList => 'Gestion des utilisateurs';



  @override String get manufacture => 'Fabrication';
  @override String get searchTireManufacturer => 'Chercher fabricant de pneus';
  @override String get chooseManufacturerFirst => 'Choisir le fabricant d’abord';
  @override String get chooseSizeFirst => 'Choisir la taille d’abord';
  @override String get starRatingSelect => 'Sélectionner';
  @override String get selectFillType => 'Type de remplissage';

  @override String get treadDepthUnit => 'Profondeur de gomme';
  @override String get originalTreadUnit => 'Gomme initiale';
  @override String get removeAtUnit => 'Retrait à';
  @override String get purchaseTreadUnit => 'Gomme à l’achat';
  @override String get outsideUnit => 'Extérieur (a)';
  @override String get insideUnit => 'Intérieur (c)';
  @override String get enterOriginalTread => 'Entrer gomme initiale';
  @override String get enterRemoveAt => 'Point de retrait';
  @override String get enterPurchaseTread => 'Entrer gomme à l’achat';
  @override String get wornPercent => '% usé';

  @override String get tireCosts => 'Coûts du pneu';
  @override String get purchaseCostA => 'Prix d’achat (a)';
  @override String get casingValueB => 'Valeur carcasse (B)';
  @override String get fillCostC => 'Coût remplissage (C)';
  @override String get repairsCostD => 'Coût réparations (D)';
  @override String get numberOfRetreads => 'Nombre de rechapages';
  @override String get retreadCostE => 'Coût rechapage (E)';
  @override String get warrantyAdjustmentF => 'Ajustement garantie (F)';
  @override String get costAdjustmentG => 'Ajustement coût (G)';
  @override String get soldAmountH => 'Montant vendu (H)';
  @override String get netCostFormula => 'Coût Net = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'Sauvegarder & Cloner';
  @override String get enterDisposition => 'Entrer disposition';
  @override String get enterEvaluationNumber => 'Entrer numéro d’évaluation';
  @override String get enterLotNumber => 'Entrer numéro de lot';
  @override String get enterPurchaseOrderNumber => 'Entrer numéro de commande';
  @override String get enterCurrentHours => 'Entrer heures actuelles';
  @override String get enterCurrentKm => 'Entrer KM actuels';
  @override String get enterValidNumeric => 'Entrer une valeur numérique valide.';
  @override String get hoursNotNegative => 'Les heures ne peuvent pas être négatives.';
  @override String get kmNotNegative => 'Les KM ne peuvent pas être négatifs.';
  @override String get serialAlreadyExists => 'Ce numéro de série existe déjà';
  @override String get searchIndCode => 'Chercher code IND';
  @override String get searchCompound => 'Chercher composé';
  @override String get searchLoadRating => 'Chercher indice de charge';
  @override String get searchSpeedRating => 'Chercher indice de vitesse';
  @override String get selectItem => 'Sélectionner';
  @override String get selectPrefix => 'Sélectionner ';
  @override String get tireSize => 'Taille du pneu';
  @override String get serialNumber => 'Numéro de série';
  @override String get enter => 'Entrer';
  @override String get selectedAccountLocation => 'Compte et emplacement sélectionnés';
  @override String get viewInspections => 'Voir les inspections';
  @override String get view => 'Voir';
  @override String get vehicle => 'Véhicule';
  @override String get total => 'Total';
  @override String get enterVehicleNumber => 'Entrer le numéro du véhicule';
  @override String get editTyre => 'Modifier le pneu';
  @override String get clear => 'EFFACER';
  @override String get set => 'DÉFINIR';
  @override String get enterValidNumber => 'Entrer un nombre valide';
  @override String get allVehicles => 'Tous les véhicules';
  @override String get searchVehicles => 'Rechercher des véhicules...';
  @override String get filters => 'Filtres';
  @override String get applyFilters => 'Appliquer les filtres';
  @override String get clearAllFilters => 'Effacer tous les filtres';
  @override String get pendingSync => 'Synchronisation en attente';
  @override String get make => 'Marque';
  @override String get transfer => 'Transférer';
  @override String get delete => 'Supprimer';
  @override String get own => 'Propre';
  @override String get shared => 'Partagé';
  @override String get select => 'Sélectionner';
  @override String get searchAccount => 'Rechercher un compte';
  @override String get searchLocation => 'Rechercher un emplacement';
  @override String get noAccountsFound => 'Aucun compte trouvé';
  @override String get noLocationsFound => 'Aucun emplacement trouvé';
  @override String get inspectTyre => 'Inspecter le pneu';
  @override String get installTyre => 'Installer le pneu';
  @override String get airPressureType => 'Type de pression d\'air';
  @override String get cold => 'Froid';
  @override String get hot => 'Chaud';
  @override String get wearCondition => 'État d\'usure';
  @override String get casingCondition => 'État de la carcasse';
  @override String get listOfPreviousComments => 'Liste des commentaires précédents';
  @override String get stillRelevant => 'Toujours pertinent';
  @override String get uploadImages => 'Charger des images';
  @override String get images => 'Images';
  @override String get confirmRemove => 'Confirmer la suppression';
  @override String get areYouSureRemoveImage => 'Voulez-vous vraiment supprimer cette image ?';
  @override String get removeTire => 'Retirer le pneu';
  @override String get remove => 'Retirer';
  @override String get all => 'Tous';
  @override String get editBtn => 'Modifier';

  @override String get takePhoto => 'Prendre une photo';
  @override String get chooseFromGallery => 'Choisir dans la galerie';

  @override String get commentsLabel => 'Commentaires';
  @override String get yes => 'OUI';
  @override String get no => 'NON';
  @override String get upload => 'Télécharger';
  @override String get install => 'Installer';
  @override String get tyreType => 'Type';
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
  @override String get viewInspection => 'Voir l\'inspection';
  @override String get syncing => 'Synchronisation...';
  @override String get inspected => 'Inspecté';
  @override String get deleteInspectionTitle => 'Supprimer l\'inspection ?';
  @override String get deleteInspectionConfirm => 'Supprimer définitivement l\'inspection pour';
  @override String get tyresLabel => 'Pneus';
  @override String get userManagement => 'GESTION DES UTILISATEURS';
  @override String get createUser => 'Créer un utilisateur';
  @override String get searchUser => 'Rechercher un utilisateur';
  @override String get deleteUser => 'Supprimer l\'utilisateur';
  @override String get deleteUserConfirm => 'Êtes-vous sûr de vouloir supprimer cet utilisateur ?';
  @override String get username => 'Nom d\'utilisateur';
  @override String get password => 'Mot de passe';
  @override String get userRole => 'Rôle de l\'utilisateur';
  @override String get loginLabel => 'Connexion';
  @override String get personalLabel => 'Personnel';
  @override String get preferenceLabel => 'Préférence';
  @override String get creatingUser => 'Création de l\'utilisateur...';
  @override String get grandparentAccountOptions => 'OPTIONS DU COMPTE GRANDPARENT';
  @override String get grandparentAccountInformation => 'INFORMATIONS DU COMPTE GRANDPARENT';
  @override String get searchGrandparent => 'Rechercher Grandparent';
  @override String get active => 'Actif';
  @override String get inactive => 'Inactif';
  @override String get ownedBy => 'Appartient à';
  @override String get createAccount => 'Créer un compte';
  @override String get assignAccount => 'Assigner un compte';
  @override String get grandparentNameLabel => 'Nom du compte Grandparent';
  @override String get accountTypeLabel => 'Propriété';
  @override String get selectParentAccount => 'Compte parent';
  @override String get selectGrandparentAccount => 'Compte Grandparent';
  @override String get assignBtn => 'ASSIGNER';
  @override String get firstName => 'Prénom';
  @override String get middleName => 'Deuxième prénom';
  @override String get lastName => 'Nom';
  @override String get phone => 'Téléphone';
  @override String get country => 'Pays';
  @override String get measurement => 'Mesure';
  @override String get id => 'ID';

  @override String get searchVehicleTyre => 'Rechercher véhicule / pneu';
  @override String get recentSearch => 'Recherches récentes';
  @override String get vehicles => 'Véhicules';
  @override String get recentVehicleNotFound => 'Aucun véhicule récent trouvé';
  @override String get recentTyreNotFound => 'Aucun pneu récent trouvé';
  @override String get typeToSearch => 'Tapez pour rechercher';
  @override String get noVehiclesFound => 'Aucun véhicule trouvé pour';
  @override String get noTyresFound => 'Aucun pneu trouvé pour';
  @override String get createNewVehicle => 'Créer un nouveau véhicule';
  @override String get createNewTyre => 'Créer un nouveau pneu';
  @override String get confirmRemoveTitle => 'Confirmer la suppression';
  @override String get confirmRemoveMessage => 'Êtes-vous sûr de vouloir supprimer cet élément ?';
  @override String get updateBtn => 'Mettre à jour';

  @override String get noRecentVehicleFound => 'Aucun véhicule récent trouvé';
  @override String get noRecentTyreFound => 'Aucun pneu récent trouvé';
  @override String get noVehiclesFoundFor => 'Aucun véhicule trouvé pour';
  @override String get noTyresFoundFor => 'Aucun pneu trouvé pour';
  @override String get searchPrefix => 'Rechercher';
  @override
  String createNew(String itemName) => 'Créer nouveau $itemName';

  @override String get vehicleInspection => 'Inspection du véhicule';
  @override String get hourWarningMsg => "Vous n'avez pas mis à jour les heures, les miles et le véhicule.";
  @override String get hours => 'Heures';
  @override String get km => 'KM';
  @override String get updateHoursKm => 'Mettre à jour Heures / KM';
  @override String get serialNo => 'Numéro de série';
  @override String get inspectedTire => 'Pneu inspecté';
  @override String get notInspectedTire => 'Pneu non inspecté';
  @override String get rotateTyres => 'Permuter les pneus';
  @override String get uploadedImages => 'Images téléchargées';
  @override String get confirmRemoveImg => 'Confirmer la suppression de l\'image';
  @override String get viewOnlyDisabled => 'Affichage uniquement — Envoi désactivé';
  @override String get cancelRequestMsg => 'Êtes-vous sûr de vouloir annuler ? Vous perdrez les données non enregistrées.';
  @override String get selectedParentAccount => 'Compte parent sélectionné';
  @override String get surveyDate => 'Date de l\'enquête';
  @override String get selectDate => 'Sélectionner une date';
  @override String get updateHoursLabel => 'Mettre à jour les heures';
  @override String get enterHours => 'Entrez les heures';
  @override String get updateKmLabel => 'Mettre à jour les KM';
  @override String get enterKm => 'Entrez les KM';
  @override String get updateVehicleDataTitle => 'Mettre à jour les données du véhicule';
  @override String get updateVehicleDataMsg => 'Ces modifications affecteront les heures/KM des pneus.\nVoulez-vous continuer ?';
  @override String get proceed => 'Continuer';
  @override
  String tyreSerialNumbers(String tyreWord) => 'Numéro de série du $tyreWord';
  @override
  String enterItemSerialNumber(String itemName) => 'Entrez le numéro de série du $itemName';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "Seules les valeurs numériques sont autorisées";
  @override String get negativeValueError => "La valeur ne peut pas être négative";
  @override String get duplicateVehicleError => "Le numéro de véhicule est déjà pris";
  @override String get invalidNumberError => "Doit être un nombre valide";
  @override String get enterPrefix => "Entrer ";
  @override String recommendedPressureFor(String axle) => "Pression recommandée pour $axle";
  @override String get numericOnly => "Seules les valeurs numériques sont autorisées";

  @override String get inventory => 'Inventario';
  @override String get onHold => 'En espera';
  @override String get scrap => 'Desecho';
  @override String get repair => 'Reparación';
  @override String get retread => 'Recauchutado';
  @override String get edit => 'Editar';
  @override String get clone => 'Clonar';
  @override String get ok => 'OK';

}