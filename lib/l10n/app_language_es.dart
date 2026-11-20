import 'app_localizations.dart';

class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([super.locale = 'es']);

  @override String get homeTitle => 'Inicio';
  @override String get greeting => 'Bienvenido';
  @override String get settings => 'Configuración';
  @override String get language => 'Idioma';
  @override String get measurementSystem => 'Sistema de medida';
  @override String get pressureUnit => 'Unidad de presión';
  @override String get update => 'Actualizar';
  @override String get cancel => 'Cancelar';
  @override String get addTyre => 'Agregar neumático';
  @override String get save => 'Guardar';

  // Screen labels
  @override String get vehicleId => 'ID del Vehículo';
  @override String get currentHours => 'Horas Actuales';
  @override String get currentKm => '{unit} Actual';
  @override String get trackingMethod => 'Método de Seguimiento';
  @override String get manufacturer => 'Fabricante';
  @override String get vehicleType => 'Tipo';
  @override String get model => 'Modelo';
  @override String get tyreSize => 'Tamaño del Neumático';
  @override String get removalTread => 'Banda de Rodadura de Retiro';
  @override String get vehicleComments => 'Comentarios del Vehículo';
  @override String get vehicleDiagram => 'Diagrama del Vehículo';
  @override String get recommendedPressure => 'Presión Recomendada';
  @override String get submit => 'Enviar';
  @override String get createVehicle => 'Crear Nuevo Vehículo';
  @override String get outsideTread => 'Profundidad de Banda Externa';
  @override String get insideTread => 'Profundidad de Banda Interna';
  @override String get averageTread => 'Banda Promedio';
  @override String get airPressure => 'Presión de Aire';
  @override String get lastRecordedDate => 'Última Fecha Registrada';
  @override String get lastRecordedHours => 'Últimas Horas Registradas';
  @override String get updateHours => 'Actualizar Horas';
  @override String get lastRecordedKm => 'Último {unit} Registrado';
  @override String get updateKm => 'Actualizar {unit}';
  @override String get vehicleNumber => 'Número de Vehículo';
  @override String get editVehicle => 'Editar Vehículo';

  @override String get selectedParentAccountLocation => 'Cuenta principal seleccionada y Ubicación';
  @override String get loadingMasterData => 'Cargando datos maestros...';
  @override String get creatingVehicle => 'Creando vehículo...';
  @override String get trackingMethodTitle => 'Método de Seguimiento';
  @override String get trackingMethodHours => 'Horas';
  @override String get trackingMethodDistance => 'Distancia';
  @override String get trackingMethodBoth => 'Ambos';
  @override String get searchHint => 'Buscar...';
  @override String get noDataAvailable => 'No hay datos disponibles';
  @override String get noTireInstalled => 'Sin\nNeumático\nInstalado';
  @override String get axleLabel => 'Eje';
  @override String get cancelRequestTitle => 'Cancelar Solicitud';
  @override String get cancelRequestMessage => '¿Está seguro de cancelar? Perderá los datos no guardados.';
  @override String get cancelRequestYes => 'Sí';
  @override String get currentDistance => 'Actual';
  @override String get enterCurrentDistance => 'Ingrese el actual';
  @override String get commentsHint => 'Los comentarios van aquí. (Máx. 200 caracteres)';

  // ================= CREATE TYRE (STEP 1) =================
  @override String get identificationDetails => 'Detalles de identificación';

  @override String get tyreSerialNumber => 'Número de serie del neumático';
  @override String get enterTyreSerialNumber => 'Ingrese número de serie';
  @override String get tyreSerialRequired => 'Se requiere número de serie';
  @override String get tyreSerialDuplicate => 'Este número de serie ya existe';

  @override String get brandNumber => 'Número de marca';
  @override String get enterBrandNumber => 'Ingrese número de marca';

  @override String get registerDate => 'Fecha de registro';
  @override String get registerDateRequired => 'La fecha es obligatoria';

  @override String get evaluationNumber => 'Número de evaluación';
  @override String get lotNumber => 'Número de lote';
  @override String get purchaseOrderNumber => 'Número de orden de compra';

  @override String get disposition => 'Disposición';
  @override String get status => 'Estado';

  @override String get currentHoursRequired => 'Horas actuales requeridas';
  @override String get invalidHours => 'Ingrese un valor válido';
  @override String get negativeHours => 'No puede ser negativo';

  @override String get currentKmRequired => 'KM actuales requeridos';
  @override String get invalidKm => 'Ingrese un valor válido';
  @override String get negativeKm => 'No puede ser negativo';

  // ================= CREATE TYRE (STEP 2) =================
  @override String get description => 'Descripción';

  @override String get selectManufacturer => 'Buscar fabricante';
  @override String get selectTyreSize => 'Seleccione tamaño';

  @override String get starRating => 'Clasificación por estrellas';

  @override String get selectType => 'Seleccione tipo';

  @override String get indCode => 'Código Ind.';
  @override String get compound => 'Compuesto';
  @override String get loadRating => 'Índice de carga';
  @override String get speedRating => 'Índice de velocidad';

  @override String get requiredField => 'Este campo es obligatorio';

  // ================= BUTTONS =================
  @override String get nextBtn => 'Siguiente';
  @override String get previousBtn => 'Anterior';
  @override String get cancelBtn => 'Cancelar';
  @override String get okBtn => 'Aceptar';
  @override String get originalTread => "Banda Original";
  @override String get removeAt => "Retirar en";
  @override String get purchaseTread => "Banda de Compra";
  @override String get outside => "Exterior";
  @override String get inside => "Interior";


  @override String get wornWarning =>
      "Advertencia: está reduciendo la banda más allá del punto de retiro establecido.";
  @override String get enterValidDetails => "Ingrese datos válidos.";
  @override String get onlyNumeric => "Solo se permiten valores numéricos.";
  @override String get treadDepth => "Profundidad de banda";
  @override String get next => "Siguiente";
  @override String get previous => "Anterior";

  @override String get viewVehicle => "Ver Vehículo";
  @override String get costs => "Costos";
  @override String get identification => "Identificación";
// Vehicle + Tyre extra keys
  @override String get vehicleViewTitle => "Ver Vehículo";
  @override String get inspect => "Inspeccionar";
  @override String get error => "Error";
  @override String get noVehicleId => "No se proporcionó ID";
  @override String get vehicleNotFound => "Vehículo no encontrado";
  @override String get wheelPosition => "Posición de rueda";

// Tyre view
  @override String get viewTyre => "Ver Neumático";
  @override String get purchasedTread => "Banda comprada";
  @override String get middleTread => "Banda media";
  @override String get currentTreadDepth => "Profundidad actual";
  @override String get percentageWorn => "% Desgaste";
  @override String get currentPressure => "Presión actual";
  @override String get fillType => "Tipo de relleno";
  @override String get fillCost => "Costo de relleno";
  @override String get repairCost => "Costo de reparación";
  @override String get retreadCost => "Costo de reencauche";
  @override String get warrantyAdjustment => "Ajuste de garantía";
  @override String get costAdjustment => "Ajuste de costo";
  @override String get netCost => "Costo neto";
  @override String get soldAmount => "Monto vendido";

  // ================= HOME / DRAWER =================
  @override String get parentAccount => 'Cuenta principal';
  @override String get location => 'Ubicación';
  @override String get changeLocationAccount => 'Cambiar cuenta y ubicación';

  @override String get mainMenu => 'Menú principal';
  @override String get home => 'Inicio';
  @override String get create => 'Crear';
  @override String get preferences => 'Preferencias';
  @override String get user => 'Usuario';
  @override String get logout => 'Cerrar sesión';

  @override String get createVehicleMenu => 'Crear vehículo';
  @override String get createTyreMenu => 'Crear ';

  @override String get userManagementList => 'Gestión de usuarios';
  @override String get grandparentAccount => 'Cuenta superior';
  @override String get startInspection => 'Iniciar inspección';
  @override String get grandparentAccountView => 'Cuentas superiores vista';
  @override String get totalVehicles => 'Total vehículos';
  @override String get totalTyres => 'Total neumáticos';

  @override String get lastInspection => 'Última inspección';
  @override String get sync => 'Sincronizar';

  @override String get unsyncInspection => 'Inspección no sincronizada';
  @override String get syncInspection => 'Inspección sincronizada';

  @override String get appVersion => 'Versión de la app';
  @override String get change => 'Cambiar';

  @override String get syncSuccess => 'Sincronización exitosa';
  @override String get syncFailed => 'Error de sincronización';

  @override String get noPermissionCreate => 'Sin permiso para crear';

  // ================= CREATE TYRE STEP 2 (missing additions) =================
  @override String get manufacture => 'Fabricación';
  @override String get tireSize => 'Tamaño del neumático';
  @override String get searchTireManufacturer => 'Buscar fabricante de neumáticos';
  @override String get chooseManufacturerFirst => 'Elija primero el fabricante';
  @override String get chooseSizeFirst => 'Elija primero el tamaño';
  @override String get starRatingSelect => 'Seleccionar';
  @override String get selectFillType => 'Tipo de relleno';

  // ================= CREATE TYRE STEP 3 (missing additions) =================
  @override String get treadDepthUnit => 'Profundidad de banda';
  @override String get originalTreadUnit => 'Banda original';
  @override String get removeAtUnit => 'Retirar en';
  @override String get purchaseTreadUnit => 'Banda de compra';
  @override String get outsideUnit => 'Exterior (a)';
  @override String get insideUnit => 'Interior (c)';
  @override String get enterOriginalTread => 'Ingrese banda original';
  @override String get enterRemoveAt => 'Retirar en';
  @override String get enterPurchaseTread => 'Ingrese banda de compra';
  @override String get wornPercent => '% de desgaste';

  // ================= CREATE TYRE STEP 4 (missing additions) =================
  @override String get tireCosts => 'Costos del neumático';
  @override String get purchaseCostA => 'Costo de compra (a)';
  @override String get casingValueB => 'Valor de carcasa (B)';
  @override String get fillCostC => 'Costo de relleno (C)';
  @override String get repairsCostD => 'Costo de reparaciones (D)';
  @override String get numberOfRetreads => 'Número de reencauches';
  @override String get retreadCostE => 'Costo de reencauche (E)';
  @override String get warrantyAdjustmentF => 'Ajuste de garantía (F)';
  @override String get costAdjustmentG => 'Ajuste de costo (G)';
  @override String get soldAmountH => 'Monto vendido (H)';
  @override String get netCostFormula => 'Costo neto = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'Guardar y clonar';
  @override String get enterDisposition => 'Ingrese disposición';
  @override String get enterEvaluationNumber => 'Ingrese número de evaluación';
  @override String get enterLotNumber => 'Ingrese número de lote';
  @override String get enterPurchaseOrderNumber => 'Ingrese número de orden de compra';
  @override String get enterCurrentHours => 'Ingrese horas actuales';
  @override String get enterCurrentKm => 'Ingrese KM actuales';
  @override String get enterValidNumeric => 'Ingrese un valor numérico válido.';
  @override String get hoursNotNegative => 'Las horas actuales no pueden ser negativas.';
  @override String get kmNotNegative => 'Los KM actuales no pueden ser negativos.';
  @override String get serialAlreadyExists => 'Este número de serie ya existe';
  @override String get searchIndCode => 'Buscar código Ind.';
  @override String get searchCompound => 'Buscar compuesto';
  @override String get searchLoadRating => 'Buscar índice de carga';
  @override String get searchSpeedRating => 'Buscar índice de velocidad';
  @override String get selectItem => 'Seleccionar';
  @override String get selectPrefix => 'Seleccionar ';
  @override String get serialNumber => 'Número de serie';
  @override String get enter => 'Ingresar';
  @override String get selectedAccountLocation => 'Cuenta y ubicación seleccionadas';
  @override String get viewInspections => 'Ver inspecciones';
  @override String get view => 'Ver';
  @override String get vehicle => 'Vehículo';
  @override String get total => 'Total';
  @override String get enterVehicleNumber => 'Ingrese el número de vehículo';
  @override String get editTyre => 'Editar neumático';
  @override String get clear => 'LIMPIAR';
  @override String get set => 'ESTABLECER';
  @override String get enterValidNumber => 'Ingrese un número válido';
  @override String get allVehicles => 'Todos los vehículos';
  @override String get searchVehicles => 'Buscar vehículos...';
  @override String get filters => 'Filtros';
  @override String get applyFilters => 'Aplicar filtros';
  @override String get clearAllFilters => 'Limpiar todos los filtros';
  @override String get pendingSync => 'Sincronización pendiente';
  @override String get make => 'Marca';
  @override String get transfer => 'Transferir';
  @override String get delete => 'Eliminar';
  @override String get own => 'Propio';
  @override String get shared => 'Compartido';
  @override String get select => 'Seleccionar';
  @override String get searchAccount => 'Buscar cuenta';
  @override String get searchLocation => 'Buscar ubicación';
  @override String get noAccountsFound => 'No se encontraron cuentas';
  @override String get noLocationsFound => 'No se encontraron ubicaciones';
  @override String get inspectTyre => 'Inspeccionar neumático';
  @override String get installTyre => 'Instalar neumático';
  @override String get airPressureType => 'Tipo de presión de aire';
  @override String get cold => 'Frío';
  @override String get hot => 'Caliente';
  @override String get wearCondition => 'Condición de desgaste';
  @override String get casingCondition => 'Condición de la carcasa';
  @override String get listOfPreviousComments => 'Lista de comentarios anteriores';
  @override String get stillRelevant => 'Sigue siendo relevante';
  @override String get uploadImages => 'Subir imágenes';
  @override String get images => 'Imágenes';
  @override String get confirmRemove => 'Confirmar eliminación';
  @override String get areYouSureRemoveImage => '¿Está seguro de eliminar esta imagen?';
  @override String get removeTire => 'Quitar neumático';
  @override String get remove => 'Quitar';
  @override String get all => 'Todos';
  @override String get editBtn => 'Editar';

  @override String get takePhoto => 'Tomar foto';
  @override String get chooseFromGallery => 'Elegir de la galería';

  @override String get commentsLabel => 'Comentarios';
  @override String get yes => 'SÍ';
  @override String get no => 'NO';
  @override String get upload => 'Subir';
  @override String get install => 'Instalar';
  @override String get tyreType => 'Tipo';
  @override String get loading => 'Cargando...';
  @override String get syncAll => 'Sincronizar todo';
  @override String get updateDisposition => 'Actualizar disposición *';
  @override String get removalReason => 'Motivo de remoción';
  @override String get selectDisposition => 'Seleccionar disposición';
  @override String get selectRemovalReason => 'Seleccionar motivo de remoción';
  @override String get rotatePosition => 'Posición de rotación';
  @override String get placementError => 'Coloque el neumático en una ranura antes de guardar.';
  @override String get rotationSavedOffline => 'Rotación guardada localmente. Se sincronizará cuando haya internet.';
  @override String get rotationSuccessful => 'Rotación actualizada y guardada con éxito.';
  @override String get searchInventory => 'Buscar neumático en inventario';
  @override String get noInventoryFound => 'No se encontraron neumáticos en el inventario';
  @override String get manufacturerLabel => 'Marca/Fabricante';
  @override String get unsynced => 'No sincronizado';
  @override String get synced => 'Sincronizado';
  @override String get unsyncedPending => 'inspecciones pendientes de sincronizar';
  @override String get offlineSyncMessage => 'Fuera de línea: conéctese a Internet para sincronizar';
  @override String get confirmDeleteTitle => '¿Eliminar inspección?';
  @override String get confirmDeleteMessage => '¿Eliminar permanentemente esta inspección?';
  @override String get viewInspection => 'Ver inspección';
  @override String get syncing => 'Sincronizando...';
  @override String get inspected => 'Inspeccionado';
  @override String get deleteInspectionTitle => '¿Eliminar inspección?';
  @override String get deleteInspectionConfirm => 'Eliminar permanentemente la inspección para';
  @override String get tyresLabel => 'Neumáticos';
  @override String get userManagement => 'GESTIÓN DE USUARIOS';
  @override String get createUser => 'Crear usuario';
  @override String get searchUser => 'Buscar usuario';
  @override String get deleteUser => 'Eliminar usuario';
  @override String get deleteUserConfirm => '¿Está seguro de que desea eliminar a este usuario?';
  @override String get username => 'Nombre de usuario';
  @override String get password => 'Contraseña';
  @override String get userRole => 'Rol de usuario';
  @override String get loginLabel => 'Acceso';
  @override String get personalLabel => 'Personal';
  @override String get preferenceLabel => 'Preferencia';
  @override String get creatingUser => 'Creando usuario...';
  @override String get grandparentAccountOptions => 'OPCIONES DE CUENTA GRANDPARENT';
  @override String get grandparentAccountInformation => 'INFORMACIÓN DE CUENTA GRANDPARENT';
  @override String get searchGrandparent => 'Buscar Grandparent';
  @override String get active => 'Activo';
  @override String get inactive => 'Inactivo';
  @override String get ownedBy => 'Propiedad de';
  @override String get createAccount => 'Crear cuenta';
  @override String get assignAccount => 'Asignar cuenta';
  @override String get grandparentNameLabel => 'Nombre de cuenta Grandparent';
  @override String get accountTypeLabel => 'Propiedad';
  @override String get selectParentAccount => 'Cuenta principal';
  @override String get selectGrandparentAccount => 'Cuenta Grandparent';
  @override String get assignBtn => 'ASIGNAR';
  @override String get firstName => 'Nombre';
  @override String get middleName => 'Segundo nombre';
  @override String get lastName => 'Apellido';
  @override String get phone => 'Teléfono';
  @override String get country => 'País';
  @override String get measurement => 'Medición';
  @override String get id => 'ID';
  @override String get searchVehicleTyre => 'Buscar vehículo / neumático';
  @override String get recentSearch => 'Búsqueda reciente';
  @override String get vehicles => 'Vehículos';
  @override String get recentVehicleNotFound => 'No se encontró ningún vehículo reciente';
  @override String get recentTyreNotFound => 'No se encontró ningún neumático reciente';
  @override String get typeToSearch => 'Escriba para buscar';
  @override String get noVehiclesFound => 'No se encontraron vehículos para';
  @override String get noTyresFound => 'No se encontraron neumáticos para';
  @override String get createNewVehicle => 'Crear nuevo vehículo';
  @override String get createNewTyre => 'Crear nuevo neumático';
  @override String get confirmRemoveTitle => 'Confirmar eliminación';
  @override String get confirmRemoveMessage => '¿Está seguro de que desea eliminar este elemento?';
  @override String get updateBtn => 'Actualizar';
  @override String get noRecentVehicleFound => 'No se encontró ningún vehículo reciente';
  @override String get noRecentTyreFound => 'No se encontró ningún neumático reciente';
  @override String get noVehiclesFoundFor => 'No se encontraron vehículos para';
  @override String get noTyresFoundFor => 'No se encontraron neumáticos para';
  @override String get searchPrefix => 'Buscar';
  @override
  String createNew(String itemName) => 'Crear nuevo $itemName';

  @override String get vehicleInspection => 'Inspección de vehículos';
  @override String get hourWarningMsg => "No has actualizado las horas, millas y el vehículo.";
  @override String get hours => 'Horas';
  @override String get km => 'KM';
  @override String get updateHoursKm => 'Actualizar Horas / KM';
  @override String get serialNo => 'Número de serie';
  @override String get inspectedTire => 'Neumático inspeccionado';
  @override String get notInspectedTire => 'Neumático no inspeccionado';
  @override String get rotateTyres => 'Rotar neumáticos';
  @override String get uploadedImages => 'Imágenes subidas';
  @override String get confirmRemoveImg => 'Confirmar eliminación de imagen';
  @override String get viewOnlyDisabled => 'Solo lectura — Envío desactivado';
  @override String get cancelRequestMsg => '¿Estás seguro de que deseas cancelar? Perderás los datos no guardados.';
  @override String get selectedParentAccount => 'Cuenta principal seleccionada';
  @override String get surveyDate => 'Fecha de la encuesta';
  @override String get selectDate => 'Seleccionar fecha';
  @override String get updateHoursLabel => 'Actualizar horas';
  @override String get enterHours => 'Ingrese horas';
  @override String get updateKmLabel => 'Actualizar KM';
  @override String get enterKm => 'Ingrese KM';
  @override String get updateVehicleDataTitle => 'Actualizar datos del vehículo';
  @override String get updateVehicleDataMsg => 'Estos cambios afectarán las horas/KM de los neumáticos.\n¿Desea continuar?';
  @override String get proceed => 'Proceder';
  @override
  String tyreSerialNumbers(String tyreWord) => 'Número de serie de $tyreWord';
  @override
  String enterItemSerialNumber(String itemName) => '$itemName-Seriennummer eingeben'; // ✅ German grammar: "Enter" comes at the end
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "Solo se permiten valores numéricos";
  @override String get negativeValueError => "El valor no puede ser negativo";
  @override String get duplicateVehicleError => "El número de vehículo ya existe";
  @override String get invalidNumberError => "Debe ser un número válido";
  @override String get enterPrefix => "Ingrese ";
  @override String recommendedPressureFor(String axle) => "Presión recomendada para $axle";
  @override String get numericOnly => "Solo se permiten valores numéricos";

  @override String get inventory => 'Inventario';
  @override String get onHold => 'En espera';
  @override String get scrap => 'Desecho';
  @override String get repair => 'Reparación';
  @override String get retread => 'Recauchutado';
  @override String get edit => 'Editar';
  @override String get clone => 'Clonar';
  @override String get ok => 'Aceptar';
}