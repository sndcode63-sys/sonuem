import 'app_localizations.dart';

class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([super.locale = 'pt']);

  @override String get homeTitle => 'Início';
  @override String get greeting => 'Bem-vindo';
  @override String get settings => 'Configurações';
  @override String get language => 'Idioma';
  @override String get measurementSystem => 'Sistema de medição';
  @override String get pressureUnit => 'Unidade de pressão';
  @override String get update => 'Atualizar';
  @override String get cancel => 'Cancelar';
  @override String get addTyre => 'Adicionar pneu';
  @override String get save => 'Salvar';

  // Screen labels
  @override String get vehicleId => 'ID do Veículo';
  @override String get currentHours => 'Horas Atuais';
  @override String get currentKm => '{unit} Atual';
  @override String get trackingMethod => 'Método de Rastreamento';
  @override String get manufacturer => 'Fabricante';
  @override String get vehicleType => 'Tipo';
  @override String get model => 'Modelo';
  @override String get tyreSize => 'Tamanho do Pneu';
  @override String get removalTread => 'Banda de Rodagem de Remoção';
  @override String get vehicleComments => 'Comentários do Veículo';
  @override String get vehicleDiagram => 'Diagrama do Veículo';
  @override String get recommendedPressure => 'Pressão Recomendada';
  @override String get submit => 'Enviar';
  @override String get createVehicle => 'Criar Novo Veículo';
  @override String get outsideTread => 'Profundidade Banda Externa';
  @override String get insideTread => 'Profundidade Banda Interna';
  @override String get averageTread => 'Banda Média';
  @override String get airPressure => 'Pressão do Ar';
  @override String get lastRecordedDate => 'Última Data Registrada';
  @override String get lastRecordedHours => 'Últimas Horas Registradas';
  @override String get updateHours => 'Atualizar Horas';
  @override String get lastRecordedKm => 'Último {unit} Registrado';
  @override String get updateKm => 'Atualizar {unit}';
  @override String get vehicleNumber => 'Número do Veículo';
  @override String get editVehicle => 'Editar Veículo';

  @override String get selectedParentAccountLocation => 'Conta principal selecionada e localização';
  @override String get loadingMasterData => 'Carregando dados principais...';
  @override String get creatingVehicle => 'Criando veículo...';
  @override String get trackingMethodTitle => 'Método de Rastreamento';
  @override String get trackingMethodHours => 'Horas';
  @override String get trackingMethodDistance => 'Distância';
  @override String get trackingMethodBoth => 'Ambos';
  @override String get searchHint => 'Pesquisar...';
  @override String get noDataAvailable => 'Nenhum dado disponível';
  @override String get noTireInstalled => 'Sem\nPneu\nInstalado';
  @override String get axleLabel => 'Eixo';
  @override String get cancelRequestTitle => 'Cancelar Solicitação';
  @override String get cancelRequestMessage => 'Tem certeza que deseja cancelar? Os dados não salvos serão perdidos.';
  @override String get cancelRequestYes => 'Sim';
  @override String get currentDistance => 'Atual';
  @override String get enterCurrentDistance => 'Inserir valor atual';
  @override String get commentsHint => 'Os comentários vão aqui. (Máx. 200 caracteres)';

  // ================= STEP 1 =================
  @override String get identificationDetails => 'Detalhes de identificação';

  @override String get tyreSerialNumber => 'Número de série do pneu';
  @override String get enterTyreSerialNumber => 'Digite o número de série';
  @override String get tyreSerialRequired => 'Número de série obrigatório';
  @override String get tyreSerialDuplicate => 'Este número de série já existe';

  @override String get brandNumber => 'Número da marca';
  @override String get enterBrandNumber => 'Digite o número da marca';

  @override String get registerDate => 'Data de registro';
  @override String get registerDateRequired => 'Data obrigatória';

  @override String get evaluationNumber => 'Número de avaliação';
  @override String get lotNumber => 'Número do lote';
  @override String get purchaseOrderNumber => 'Número do pedido';

  @override String get disposition => 'Disposição';
  @override String get status => 'Status';

  @override String get currentHoursRequired => 'Horas atuais obrigatórias';
  @override String get invalidHours => 'Digite um valor válido';
  @override String get negativeHours => 'Não pode ser negativo';

  @override String get currentKmRequired => 'KM atuais obrigatórios';
  @override String get invalidKm => 'Digite um valor válido';
  @override String get negativeKm => 'Não pode ser negativo';

  // ================= STEP 2 =================
  @override String get description => 'Descrição';

  @override String get selectManufacturer => 'Buscar fabricante';
  @override String get selectTyreSize => 'Selecionar tamanho';

  @override String get starRating => 'Classificação por estrelas';

  @override String get selectType => 'Selecionar tipo';

  @override String get indCode => 'Código Ind.';
  @override String get compound => 'Composto';
  @override String get loadRating => 'Índice de carga';
  @override String get speedRating => 'Índice de velocidade';

  @override String get requiredField => '⚠️ Insira dados válidos';

  // ================= BUTTONS =================
  @override String get nextBtn => 'Próximo';
  @override String get previousBtn => 'Anterior';
  @override String get cancelBtn => 'Cancelar';
  @override String get okBtn => 'OK';
  @override String get enterValidDetails => 'Insira dados válidos';
  @override String get onlyNumeric => 'Apenas valores numéricos são permitidos';
  @override String get originalTread => 'Banda original';
  @override String get removeAt => 'Remover em';
  @override String get purchaseTread => 'Banda de compra';
  @override String get outside => 'Exterior';
  @override String get inside => 'Interior';
  @override String get wornWarning => 'Aviso: desgaste crítico do pneu';
  @override String get treadDepth => 'Profundidade da banda';
  @override String get next => 'Próximo';
  @override String get previous => 'Anterior';

  // ================= VEHICLE VIEW =================
  @override String get vehicleViewTitle => 'Ver Veículo';
  @override String get viewVehicle => 'Ver Veículo';
  @override String get inspect => 'Inspecionar';
  @override String get error => 'Erro';
  @override String get noVehicleId => 'Sem ID do veículo';
  @override String get vehicleNotFound => 'Veículo não encontrado';
  @override String get wheelPosition => 'Posição da roda';
  @override String get costs => 'Custos';

// ================= TYRE VIEW =================
  @override String get viewTyre => 'Ver Pneu';
  @override String get identification => 'Identificação';
  @override String get purchasedTread => 'Banda comprada';
  @override String get middleTread => 'Banda central';
  @override String get currentTreadDepth => 'Profundidade atual';
  @override String get percentageWorn => '% Desgaste';
  @override String get currentPressure => 'Pressão atual';
  @override String get fillType => 'Tipo de enchimento';
  @override String get fillCost => 'Custo de enchimento';
  @override String get repairCost => 'Custo de reparo';
  @override String get retreadCost => 'Custo de recapagem';
  @override String get warrantyAdjustment => 'Ajuste de garantia';
  @override String get costAdjustment => 'Ajuste de custo';
  @override String get netCost => 'Custo líquido';
  @override String get soldAmount => 'Valor vendido';


  // ================= HOME / DRAWER =================
  @override String get parentAccount => 'Conta principal';
  @override String get location => 'Localização';
  @override String get changeLocationAccount => 'Alterar conta/localização';

  @override String get mainMenu => 'Menu principal';
  @override String get home => 'Início';
  @override String get create => 'Criar';
  @override String get preferences => 'Preferências';
  @override String get user => 'Usuário';
  @override String get logout => 'Sair';

  @override String get createVehicleMenu => 'Criar veículo';
  @override String get createTyreMenu => 'Criar';

  @override String get userManagementList => 'Gestão de usuários';
  @override String get grandparentAccount => 'Conta superior';
  @override String get startInspection => 'Iniciar inspeção';
  @override String get grandparentAccountView => 'Konta nadrzędne widok';

  @override String get totalVehicles => 'Total de veículos';
  @override String get totalTyres => 'Total de pneus';

  @override String get lastInspection => 'Última inspeção';
  @override String get sync => 'Sincronizar';

  @override String get unsyncInspection => 'Inspeções não sincronizadas';
  @override String get syncInspection => 'Inspeções sincronizadas';

  @override String get appVersion => 'Versão do app';
  @override String get change => 'Alterar';

  @override String get syncSuccess => 'Sincronização concluída';
  @override String get syncFailed => 'Falha na sincronização';

  @override String get noPermissionCreate => 'Sem permissão para criar';

  // ... (existing code)

  // ================= CREATE TYRE STEP 2 =================
  @override String get manufacture => 'Fabricação';
  @override String get tireSize => 'Tamanho do pneu';
  @override String get searchTireManufacturer => 'Buscar fabricante de pneus';
  @override String get chooseManufacturerFirst => 'Escolha o fabricante primeiro';
  @override String get chooseSizeFirst => 'Escolha o tamanho primeiro';
  @override String get starRatingSelect => 'Selecionar';
  @override String get selectFillType => 'Tipo de enchimento';

  // ================= CREATE TYRE STEP 3 =================
  @override String get treadDepthUnit => 'Profundidade da banda';
  @override String get originalTreadUnit => 'Banda original';
  @override String get removeAtUnit => 'Remover em';
  @override String get purchaseTreadUnit => 'Banda de compra';
  @override String get outsideUnit => 'Exterior (a)';
  @override String get insideUnit => 'Interior (c)';
  @override String get enterOriginalTread => 'Inserir banda original';
  @override String get enterRemoveAt => 'Remover em';
  @override String get enterPurchaseTread => 'Inserir banda de compra';
  @override String get wornPercent => '% de desgaste';

  // ================= CREATE TYRE STEP 4 =================
  @override String get tireCosts => 'Custos do pneu';
  @override String get purchaseCostA => 'Custo de compra (a)';
  @override String get casingValueB => 'Valor da carcaça (B)';
  @override String get fillCostC => 'Custo de enchimento (C)';
  @override String get repairsCostD => 'Custo de reparos (D)';
  @override String get numberOfRetreads => 'Número de recapagens';
  @override String get retreadCostE => 'Custo de recapagem (E)';
  @override String get warrantyAdjustmentF => 'Ajuste de garantia (F)';
  @override String get costAdjustmentG => 'Ajuste de custo (G)';
  @override String get soldAmountH => 'Valor vendido (H)';
  @override String get netCostFormula => 'Custo líquido = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'Salvar e Clonar';
  @override String get enterDisposition => 'Inserir disposição';
  @override String get enterEvaluationNumber => 'Inserir número de avaliação';
  @override String get enterLotNumber => 'Inserir número do lote';
  @override String get enterPurchaseOrderNumber => 'Inserir número do pedido';
  @override String get enterCurrentHours => 'Inserir horas atuais';
  @override String get enterCurrentKm => 'Inserir KM atuais';
  @override String get enterValidNumeric => 'Insira um valor numérico válido.';
  @override String get hoursNotNegative => 'Horas atuais não podem ser negativas.';
  @override String get kmNotNegative => 'KM atuais não podem ser negativos.';
  @override String get serialAlreadyExists => 'Este número de série já existe';
  @override String get searchIndCode => 'Buscar código Ind.';
  @override String get searchCompound => 'Buscar composto';
  @override String get searchLoadRating => 'Buscar índice de carga';
  @override String get searchSpeedRating => 'Buscar índice de velocidade';
  @override String get selectItem => 'Selecionar';
  @override String get selectPrefix => 'Selecionar ';
  @override String get serialNumber => 'Número de série';
  @override String get enter => 'Inserir';
  @override String get selectedAccountLocation => 'Conta e localização selecionadas';
  @override String get viewInspections => 'Visualizar inspeções';
  @override String get view => 'Visualizar';
  @override String get vehicle => 'Veículo';
  @override String get total => 'Total';
  @override String get enterVehicleNumber => 'Inserir número do veículo';
  @override String get editTyre => 'Editar pneu';
  @override String get clear => 'LIMPAR';
  @override String get set => 'DEFINIR';
  @override String get enterValidNumber => 'Insira um número válido';
  @override String get allVehicles => 'Todos os veículos';
  @override String get searchVehicles => 'Pesquisar veículos...';
  @override String get filters => 'Filtros';
  @override String get applyFilters => 'Aplicar filtros';
  @override String get clearAllFilters => 'Limpar todos os filtros';
  @override String get pendingSync => 'Sincronização pendente';
  @override String get make => 'Marca';
  @override String get transfer => 'Transferir';
  @override String get delete => 'Excluir';
  @override String get own => 'Próprio';
  @override String get shared => 'Compartilhado';
  @override String get select => 'Selecionar';
  @override String get searchAccount => 'Pesquisar conta';
  @override String get searchLocation => 'Pesquisar localização';
  @override String get noAccountsFound => 'Nenhuma conta encontrada';
  @override String get noLocationsFound => 'Nenhuma localização encontrada';
  @override String get inspectTyre => 'Inspecionar pneu';
  @override String get installTyre => 'Instalar pneu';
  @override String get airPressureType => 'Tipo de pressão de ar';
  @override String get cold => 'Frio';
  @override String get hot => 'Quente';
  @override String get wearCondition => 'Condição de desgaste';
  @override String get casingCondition => 'Condição da carcaça';
  @override String get listOfPreviousComments => 'Lista de comentários anteriores';
  @override String get stillRelevant => 'Ainda relevante';
  @override String get uploadImages => 'Carregar imagens';
  @override String get images => 'Imagens';
  @override String get confirmRemove => 'Confirmar remoção';
  @override String get areYouSureRemoveImage => 'Tem certeza de que deseja remover esta imagem?';
  @override String get removeTire => 'Remover pneu';
  @override String get remove => 'Remover';
  @override String get all => 'Todos';
  @override String get editBtn => 'Editar';

  @override String get takePhoto => 'Tirar foto';
  @override String get chooseFromGallery => 'Escolher da galeria';

  @override String get commentsLabel => 'Comentários';
  @override String get yes => 'SIM';
  @override String get no => 'NÃO';
  @override String get upload => 'Carregar';
  @override String get install => 'Instalar';
  @override String get tyreType => 'Tipo';
  @override String get loading => 'Carregando...';
  @override String get syncAll => 'Sincronizar tudo';
  @override String get updateDisposition => 'Atualizar disposição *';
  @override String get removalReason => 'Motivo da remoção';
  @override String get selectDisposition => 'Selecionar disposição';
  @override String get selectRemovalReason => 'Selecionar motivo de remoção';
  @override String get rotatePosition => 'Girar posição';
  @override String get placementError => 'Por favor, coloque o pneu em um slot antes de salvar.';
  @override String get rotationSavedOffline => 'Rotação salva localmente. Sincronizará quando a internet estiver disponível.';
  @override String get rotationSuccessful => 'Rotação de pneus atualizada e salva com sucesso.';
  @override String get searchInventory => 'Buscar pneu no estoque';
  @override String get noInventoryFound => 'Nenhum pneu encontrado no estoque';
  @override String get manufacturerLabel => 'Marca/Fabricante';
  @override String get unsynced => 'Não sincronizado';
  @override String get synced => 'Sincronizado';
  @override String get unsyncedPending => 'inspeções pendentes de sincronização';
  @override String get offlineSyncMessage => 'Offline — conecte a internet para sincronizar';
  @override String get confirmDeleteTitle => 'Excluir inspeção?';
  @override String get confirmDeleteMessage => 'Excluir permanentemente esta inspeção?';
  @override String get viewInspection => 'Ver inspeção';
  @override String get syncing => 'Sincronizando...';
  @override String get inspected => 'Inspecionado';
  @override String get deleteInspectionTitle => 'Excluir inspeção?';
  @override String get deleteInspectionConfirm => 'Excluir permanentemente a inspeção para';
  @override String get tyresLabel => 'Pneus';
  @override String get userManagement => 'GESTÃO DE UTILIZADORES';
  @override String get createUser => 'Criar Utilizador';
  @override String get searchUser => 'Procurar Utilizador';
  @override String get deleteUser => 'Eliminar Utilizador';
  @override String get deleteUserConfirm => 'Tem a certeza de que deseja eliminar este utilizador?';
  @override String get username => 'Nome de utilizador';
  @override String get password => 'Palavra-passe';
  @override String get userRole => 'Função do Utilizador';
  @override String get loginLabel => 'Acesso';
  @override String get personalLabel => 'Pessoal';
  @override String get preferenceLabel => 'Preferência';
  @override String get creatingUser => 'A criar utilizador...';

// Grandparent Account
  @override String get grandparentAccountOptions => 'OPÇÕES DE CONTA GRANDPARENT';
  @override String get grandparentAccountInformation => 'INFORMAÇÃO DE CONTA GRANDPARENT';
  @override String get searchGrandparent => 'Procurar Grandparent';
  @override String get active => 'Ativo';
  @override String get inactive => 'Inativo';
  @override String get ownedBy => 'Propriedade de';
  @override String get createAccount => 'Criar Conta';
  @override String get assignAccount => 'Atribuir Conta';
  @override String get grandparentNameLabel => 'Nome da Conta Grandparent';
  @override String get accountTypeLabel => 'Propriedade';
  @override String get selectParentAccount => 'Conta Pai';
  @override String get selectGrandparentAccount => 'Conta Grandparent';
  @override String get assignBtn => 'ATRIBUIR';

// Common / Reusable
  @override String get firstName => 'Primeiro Nome';
  @override String get middleName => 'Nome do Meio';
  @override String get lastName => 'Apelido';
  @override String get phone => 'Telefone';
  @override String get country => 'País';
  @override String get measurement => 'Medição';
  @override String get id => 'ID';
  @override String get searchVehicleTyre => 'Procurar Veículo / Pneu';
  @override String get recentSearch => 'Pesquisa Recente';
  @override String get vehicles => 'Veículos';
  @override String get recentVehicleNotFound => 'Nenhum veículo recente encontrado';
  @override String get recentTyreNotFound => 'Nenhum pneu recente encontrado';
  @override String get typeToSearch => 'Digite para pesquisar';
  @override String get noVehiclesFound => 'Nenhum veículo encontrado para';
  @override String get noTyresFound => 'Nenhum pneu encontrado para';
  @override String get createNewVehicle => 'Criar Novo Veículo';
  @override String get createNewTyre => 'Criar Novo Pneu';
  @override String get confirmRemoveTitle => 'Confirmar Remoção';
  @override String get confirmRemoveMessage => 'Tem a certeza de que deseja remover este item?';
  @override String get updateBtn => 'Atualizar';
  @override String get noRecentVehicleFound => 'Nenhum veículo recente encontrado';
  @override String get noRecentTyreFound => 'Nenhum pneu recente encontrado';
  @override String get noVehiclesFoundFor => 'Nenhum veículo encontrado para';
  @override String get noTyresFoundFor => 'Nenhum pneu encontrado para';
  @override String get searchPrefix => 'Procurar';
  @override
  String createNew(String itemName) => 'Criar novo $itemName';


  @override String get vehicleInspection => 'Inspeção do Veículo';
  @override String get hourWarningMsg => "Não atualizou as horas, quilómetros e o veículo.";
  @override String get hours => 'Horas';
  @override String get km => 'KM';
  @override String get updateHoursKm => 'Atualizar Horas / KM';
  @override String get serialNo => 'Número de série';
  @override String get inspectedTire => 'Pneu Inspecionado';
  @override String get notInspectedTire => 'Pneu Não Inspecionado';
  @override String get rotateTyres => 'Rodar Pneus';
  @override String get uploadedImages => 'Imagens Carregadas';
  @override String get confirmRemoveImg => 'Confirmar remoção da imagem';
  @override String get viewOnlyDisabled => 'Apenas Visualização — Submissão Desativada';
  @override String get cancelRequestMsg => 'Tem a certeza de que deseja cancelar? Perderá os dados não guardados.';
  @override String get selectedParentAccount => 'Conta Principal Selecionada';
  @override String get surveyDate => 'Data da Inspeção';
  @override String get selectDate => 'Selecionar Data';
  @override String get updateHoursLabel => 'Atualizar Horas';
  @override String get enterHours => 'Inserir Horas';
  @override String get updateKmLabel => 'Atualizar KM';
  @override String get enterKm => 'Inserir KM';
  @override String get updateVehicleDataTitle => 'Atualizar Dados do Veículo';
  @override String get updateVehicleDataMsg => 'Estas alterações afetarão as horas/KM dos pneus.\nDeseja prosseguir?';
  @override String get proceed => 'Prosseguir';
  @override
  String tyreSerialNumbers(String tyreWord) => 'Número de série do $tyreWord';
  @override
  String enterItemSerialNumber(String itemName) => 'Insira o número de série do $itemName';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "Apenas valores numéricos são permitidos";
  @override String get negativeValueError => "O valor não pode ser negativo";
  @override String get duplicateVehicleError => "O número do veículo já está em uso";
  @override String get invalidNumberError => "Deve ser um número válido";
  @override String get enterPrefix => "Digitar ";
  @override String recommendedPressureFor(String axle) => "Pressão recomendada para $axle";
  @override String get numericOnly => "Apenas valores numéricos são permitidos";

  @override String get inventory => 'Inventário';
  @override String get onHold => 'Em espera';
  @override String get scrap => 'Sucata';
  @override String get repair => 'Reparo';
  @override String get retread => 'Recapagem';
  @override String get edit => 'Editar';
  @override String get clone => 'Clonar';
  @override String get ok => 'OK';

}