import 'app_localizations.dart';

class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([super.locale = 'zh']);

  @override String get homeTitle => '主页';
  @override String get greeting => '欢迎';
  @override String get settings => '设置';
  @override String get language => '语言';
  @override String get measurementSystem => '测量系统';
  @override String get pressureUnit => '压力单位';
  @override String get update => '更新';
  @override String get cancel => '取消';
  @override String get addTyre => '添加轮胎';
  @override String get save => '保存';




  // Screen labels
  @override String get vehicleId => '车辆编号';
  @override String get currentHours => '当前小时数';
  @override String get currentKm => '当前{unit}';
  @override String get trackingMethod => '追踪方式';
  @override String get manufacturer => '制造商';
  @override String get vehicleType => '类型';
  @override String get model => '型号';
  @override String get tyreSize => '轮胎尺寸';
  @override String get removalTread => '更换胎纹深度';
  @override String get vehicleComments => '车辆备注';
  @override String get vehicleDiagram => '车辆图示';
  @override String get recommendedPressure => '建议气压';
  @override String get submit => '提交';
  @override String get createVehicle => '新建车辆';
  @override String get outsideTread => '外侧胎纹深度';
  @override String get insideTread => '内侧胎纹深度';
  @override String get averageTread => '平均胎纹';
  @override String get airPressure => '气压';
  @override String get lastRecordedDate => '最近记录日期';
  @override String get lastRecordedHours => '最近记录小时数';
  @override String get updateHours => '更新小时数';
  @override String get lastRecordedKm => '最近记录{unit}';
  @override String get updateKm => '更新{unit}';
  @override String get vehicleNumber => '车辆号码';
  @override String get editVehicle => '编辑车辆';

  @override String get selectedParentAccountLocation => '已选父账户和位置';
  @override String get loadingMasterData => '正在加载主数据...';
  @override String get creatingVehicle => '正在创建车辆...';
  @override String get trackingMethodTitle => '追踪方式';
  @override String get trackingMethodHours => '小时';
  @override String get trackingMethodDistance => '距离';
  @override String get trackingMethodBoth => '两者';
  @override String get searchHint => '搜索...';
  @override String get noDataAvailable => '无可用数据';
  @override String get noTireInstalled => '未\n安装\n轮胎';
  @override String get axleLabel => '车轴';
  @override String get cancelRequestTitle => '取消请求';
  @override String get cancelRequestMessage => '您确定要取消吗？未保存的数据将会丢失。';
  @override String get cancelRequestYes => '是';
  @override String get currentDistance => '当前';
  @override String get enterCurrentDistance => '输入当前值';
  @override String get commentsHint => '请在此输入备注。（最多200个字符）';

  // ================= CREATE TYRE (STEP 1) =================
  @override String get identificationDetails => '识别信息';

  @override String get tyreSerialNumber => '轮胎序列号';
  @override String get enterTyreSerialNumber => '输入轮胎序列号';
  @override String get tyreSerialRequired => '轮胎序列号是必填项';
  @override String get tyreSerialDuplicate => '轮胎序列号已存在';

  @override String get brandNumber => '品牌编号';
  @override String get enterBrandNumber => '输入品牌编号';

  @override String get registerDate => '登记日期';
  @override String get registerDateRequired => '登记日期是必填项';

  @override String get evaluationNumber => '评估编号';
  @override String get lotNumber => '批次号';
  @override String get purchaseOrderNumber => '采购订单号';

  @override String get disposition => '处置';
  @override String get status => '状态';

  @override String get currentHoursRequired => '当前小时数必填';
  @override String get invalidHours => '无效的小时数';
  @override String get negativeHours => '小时数不能为负';

  @override String get currentKmRequired => '当前{unit}为必填';
  @override String get invalidKm => '无效的{unit}';
  @override String get negativeKm => '{unit}不能为负';

  // ================= CREATE TYRE (STEP 2) =================
  @override String get description => '描述';

  @override String get selectManufacturer => '选择制造商';
  @override String get selectTyreSize => '选择轮胎尺寸';

  @override String get starRating => '星级评分';

  @override String get selectType => '选择类型';

  @override String get indCode => 'IND代码';
  @override String get compound => '化合物';
  @override String get loadRating => '负载等级';
  @override String get speedRating => '速度等级';

  @override String get requiredField => '此字段为必填项';

  // ================= BUTTONS =================
  @override String get nextBtn => '下一步';
  @override String get previousBtn => '上一步';
  @override String get cancelBtn => '取消';
  @override String get okBtn => '确定';

  @override String get originalTread => "原始胎纹";
  @override String get removeAt => "移除点";
  @override String get purchaseTread => "购买胎纹";
  @override String get outside => "外侧";
  @override String get inside => "内侧";



  @override String get wornWarning => "警告：胎纹已低于安全标准。";
  @override String get enterValidDetails => "请输入有效数据。";
  @override String get onlyNumeric => "仅允许数字。";
  @override String get treadDepth => "胎纹深度";
  @override String get next => '下一步';
  @override String get previous => '上一步';

  // ================= VEHICLE VIEW =================
  @override String get vehicleViewTitle => '车辆查看';
  @override String get viewVehicle => '查看车辆';
  @override String get inspect => '检查';
  @override String get error => '错误';
  @override String get noVehicleId => '无车辆ID';
  @override String get vehicleNotFound => '未找到车辆';
  @override String get wheelPosition => '轮胎位置';
  @override String get costs => '成本';

  // ================= TYRE VIEW =================
  @override String get viewTyre => '查看轮胎';
  @override String get identification => '识别信息';
  @override String get purchasedTread => '购买胎纹';
  @override String get middleTread => '中部胎纹';
  @override String get currentTreadDepth => '当前胎纹深度';
  @override String get percentageWorn => '磨损百分比';
  @override String get currentPressure => '当前气压';
  @override String get fillType => '填充类型';
  @override String get fillCost => '填充费用';
  @override String get repairCost => '维修费用';
  @override String get retreadCost => '翻新费用';
  @override String get warrantyAdjustment => '保修调整';
  @override String get costAdjustment => '成本调整';
  @override String get netCost => '净成本';
  @override String get soldAmount => '销售金额';

  // ================= HOME / DRAWER =================
  @override String get parentAccount => '主账户';
  @override String get location => '位置';
  @override String get changeLocationAccount => '更改账户/位置';

  @override String get mainMenu => '主菜单';
  @override String get home => '主页';
  @override String get create => '创建';
  @override String get preferences => '偏好设置';
  @override String get user => '用户';
  @override String get logout => '退出登录';

  @override String get createVehicleMenu => '创建车辆';
  @override String get createTyreMenu => '新';

  @override String get userManagementList => '用户管理';
  @override String get grandparentAccount => '顶级账户';
  @override String get grandparentAccountView => '顶级账户视图';                        // Chino (ZH)
  @override String get startInspection => '开始检查';

  @override String get totalVehicles => '车辆总数';
  @override String get totalTyres => '轮胎总数';

  @override String get lastInspection => '最近检查';
  @override String get sync => '同步';

  @override String get unsyncInspection => '未同步检查';
  @override String get syncInspection => '已同步检查';

  @override String get appVersion => '应用版本';
  @override String get change => '更改';

  @override String get syncSuccess => '同步成功';
  @override String get syncFailed => '同步失败';

  @override String get noPermissionCreate => '无创建权限';

  // ================= CREATE TYRE STEP 2 =================
  @override String get manufacture => '生产信息';
  @override String get tireSize => '轮胎尺寸';
  @override String get searchTireManufacturer => '搜索轮胎制造商';
  @override String get chooseManufacturerFirst => '请先选择制造商';
  @override String get chooseSizeFirst => '请先选择尺寸';
  @override String get starRatingSelect => '选择';
  @override String get selectFillType => '填充类型';

  // ================= CREATE TYRE STEP 3 =================
  @override String get treadDepthUnit => '胎纹深度';
  @override String get originalTreadUnit => '原始胎纹';
  @override String get removeAtUnit => '移除点';
  @override String get purchaseTreadUnit => '购买胎纹';
  @override String get outsideUnit => '外侧 (a)';
  @override String get insideUnit => '内侧 (c)';
  @override String get enterOriginalTread => '输入原始胎纹深度';
  @override String get enterRemoveAt => '移除点';
  @override String get enterPurchaseTread => '输入购买时的胎纹深度';
  @override String get wornPercent => '磨损比例';

  // ================= CREATE TYRE STEP 4 =================
  @override String get tireCosts => '轮胎成本';
  @override String get purchaseCostA => '购买成本 (a)';
  @override String get casingValueB => '胎体价值 (B)';
  @override String get fillCostC => '填充成本 (C)';
  @override String get repairsCostD => '维修成本 (D)';
  @override String get numberOfRetreads => '翻新次数';
  @override String get retreadCostE => '翻新成本 (E)';
  @override String get warrantyAdjustmentF => '保修调整 (F)';
  @override String get costAdjustmentG => '成本调整 (G)';
  @override String get soldAmountH => '销售金额 (H)';
  @override String get netCostFormula => '净成本 = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => '保存并克隆';
  @override String get enterDisposition => '输入处置信息';
  @override String get enterEvaluationNumber => '输入评估编号';
  @override String get enterLotNumber => '输入批次号';
  @override String get enterPurchaseOrderNumber => '输入采购订单号';
  @override String get enterCurrentHours => '输入当前小时数';
  @override String get enterCurrentKm => '输入当前公里数';
  @override String get enterValidNumeric => '请输入有效的数字。';
  @override String get hoursNotNegative => '当前小时数不能为负。';
  @override String get kmNotNegative => '当前公里数不能为负。';
  @override String get serialAlreadyExists => '此序列号已存在';
  @override String get searchIndCode => '搜索 IND 代码';
  @override String get searchCompound => '搜索化合物';
  @override String get searchLoadRating => '搜索负载等级';
  @override String get searchSpeedRating => '搜索速度等级';
  @override String get selectItem => '选择';
  @override String get selectPrefix => '选择 ';
  @override String get serialNumber => '序列号';
  @override String get enter => '确认'; // Or '输入' (Input)
  @override String get selectedAccountLocation => '已选账户与位置';
  @override String get viewInspections => '查看检查记录';
  @override String get view => '查看';
  @override String get vehicle => '车辆';
  @override String get total => '总计';
  @override String get enterVehicleNumber => '输入车辆号码';
  @override String get editTyre => '编辑轮胎';
  @override String get clear => '清除';
  @override String get set => '设置';
  @override String get enterValidNumber => '请输入有效数字';
  @override String get allVehicles => '所有车辆';
  @override String get searchVehicles => '搜索车辆...';
  @override String get filters => '筛选';
  @override String get applyFilters => '应用筛选';
  @override String get clearAllFilters => '清除所有筛选';
  @override String get pendingSync => '待同步';
  @override String get make => '品牌';
  @override String get transfer => '转移';
  @override String get delete => '删除';
  @override String get own => '自有';
  @override String get shared => '共享';
  @override String get select => '选择';
  @override String get searchAccount => '搜索账户';
  @override String get searchLocation => '搜索位置';
  @override String get noAccountsFound => '未找到账户';
  @override String get noLocationsFound => '未找到位置';
  @override String get inspectTyre => '检查轮胎';
  @override String get installTyre => '安装轮胎';
  @override String get airPressureType => '气压类型';
  @override String get cold => '冷态';
  @override String get hot => '热态';
  @override String get wearCondition => '磨损情况';
  @override String get casingCondition => '胎体情况';
  @override String get listOfPreviousComments => '之前备注列表';
  @override String get stillRelevant => '仍然相关';
  @override String get uploadImages => '上传图片';
  @override String get images => '图片';
  @override String get confirmRemove => '确认移除';
  @override String get areYouSureRemoveImage => '您确定要移除这张图片吗？';
  @override String get removeTire => '卸下轮胎';
  @override String get remove => '卸下';
  @override String get all => '所有';
  @override String get editBtn => '编辑';
  @override String get takePhoto => 'Сделать фото';
  @override String get chooseFromGallery => 'Выбрать из галереи';
  @override String get commentsLabel => 'Комментарии';
  @override String get yes => 'ДА';
  @override String get no => 'НЕТ';
  @override String get upload => '上传';
  @override String get install => '安装';
  @override String get tyreType => '类型';
  @override String get loading => '加载中...';
  @override String get syncAll => '全部同步';
  @override String get updateDisposition => '更新处置状态 *';
  @override String get removalReason => '拆卸原因';
  @override String get selectDisposition => '选择处置状态';
  @override String get selectRemovalReason => '选择拆卸原因';
  @override String get rotatePosition => '旋转位置';
  @override String get placementError => '保存前请先将轮胎放入槽位。';
  @override String get rotationSavedOffline => '轮换已在本地保存。有网络时将同步。';
  @override String get rotationSuccessful => '轮胎轮换已成功更新并保存。';
  @override String get searchInventory => '从库存中搜索轮胎';
  @override String get noInventoryFound => '未发现库存轮胎';
  @override String get manufacturerLabel => '品牌/制造商';
  @override String get unsynced => '未同步';
  @override String get synced => '已同步';
  @override String get unsyncedPending => '待同步的检查项';
  @override String get offlineSyncMessage => '离线 — 请连接网络进行同步';
  @override String get confirmDeleteTitle => '删除检查？';
  @override String get confirmDeleteMessage => '确定要永久删除此检查吗？';
  @override String get viewInspection => 'Просмотреть проверку';
  @override String get syncing => 'Синхронизация...';
  @override String get inspected => 'Проверено';
  @override String get deleteInspectionTitle => 'Удалить проверку?';
  @override String get deleteInspectionConfirm => 'Безвозвратно удалить проверку для';
  @override String get tyresLabel => '轮胎';
  @override String get userManagement => '用户管理';
  @override String get createUser => '创建用户';
  @override String get searchUser => '搜索用户';
  @override String get deleteUser => '删除用户';
  @override String get deleteUserConfirm => '您确定要删除此用户吗？';
  @override String get username => '用户名';
  @override String get password => '密码';
  @override String get userRole => '用户角色';
  @override String get loginLabel => '登录';
  @override String get personalLabel => '个人资料';
  @override String get preferenceLabel => '偏好设置';
  @override String get creatingUser => '正在创建用户...';
  @override String get grandparentAccountOptions => 'GRANDPARENT 账户选项';
  @override String get grandparentAccountInformation => 'GRANDPARENT 账户信息';
  @override String get searchGrandparent => '搜索 Grandparent';
  @override String get active => '激活';
  @override String get inactive => '未激活';
  @override String get ownedBy => '所有者';
  @override String get createAccount => '创建账户';
  @override String get assignAccount => '分配账户';
  @override String get grandparentNameLabel => 'Grandparent 账户名称';
  @override String get accountTypeLabel => '所有权';
  @override String get selectParentAccount => '父账户';
  @override String get selectGrandparentAccount => 'Grandparent 账户';
  @override String get assignBtn => '分配';
  @override String get firstName => '名字';
  @override String get middleName => '中间名';
  @override String get lastName => '姓氏';
  @override String get phone => '电话';
  @override String get country => '国家';
  @override String get measurement => '测量';
  @override String get id => 'ID';
  @override String get searchVehicleTyre => '搜索车辆/轮胎';
  @override String get recentSearch => '最近搜索';
  @override String get vehicles => '车辆';
  @override String get recentVehicleNotFound => '未找到最近的车辆';
  @override String get recentTyreNotFound => '未找到最近的轮胎';
  @override String get typeToSearch => '输入以搜索';
  @override String get noVehiclesFound => '未找到相关车辆';
  @override String get noTyresFound => '未找到相关轮胎';
  @override String get createNewVehicle => '创建新车辆';
  @override String get createNewTyre => '创建新轮胎';
  @override String get confirmRemoveTitle => '确认移除';
  @override String get confirmRemoveMessage => '您确定要移除此项吗？';
  @override String get updateBtn => '更新';
  @override String get noRecentVehicleFound => '未找到最近的车辆';
  @override String get noRecentTyreFound => '未找到最近的轮胎';
  @override String get noVehiclesFoundFor => '未找到相关车辆：';
  @override String get noTyresFoundFor => '未找到相关轮胎：';
  @override String get searchPrefix => '搜索';
  @override
  String createNew(String itemName) => '创建新$itemName';

  @override String get vehicleInspection => '车辆检查';
  @override String get hourWarningMsg => "您尚未更新小时数、里程和车辆信息。";
  @override String get hours => '小时';
  @override String get km => '公里';
  @override String get updateHoursKm => '更新小时/公里';
  @override String get serialNo => '序列号';
  @override String get inspectedTire => '已检查轮胎';
  @override String get notInspectedTire => '未检查轮胎';
  @override String get rotateTyres => '轮胎换位';
  @override String get uploadedImages => '已上传图片';
  @override String get confirmRemoveImg => '确认删除图片';
  @override String get viewOnlyDisabled => '仅供查看 — 提交已禁用';
  @override String get cancelRequestMsg => '您确定要取消吗？未保存的数据将会丢失。';
  @override String get selectedParentAccount => '已选父级账户';
  @override String get surveyDate => '调查日期';
  @override String get selectDate => '选择日期';
  @override String get updateHoursLabel => '更新小时';
  @override String get enterHours => '输入小时';
  @override String get updateKmLabel => '更新公里';
  @override String get enterKm => '输入公里';
  @override String get updateVehicleDataTitle => '更新车辆数据';
  @override String get updateVehicleDataMsg => '这些更改将影响轮胎的小时/公里数。\n是否继续？';
  @override String get proceed => '继续';
  @override
  String tyreSerialNumbers(String tyreWord) => '$tyreWord序列号';
  @override
  String enterItemSerialNumber(String itemName) => '输入$itemName序列号';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "仅允许输入数字";
  @override String get negativeValueError => "值不能为负数";
  @override String get duplicateVehicleError => "车辆编号已被占用";
  @override String get invalidNumberError => "必须是有效的数字";
  @override String get enterPrefix => "输入 ";
  @override String recommendedPressureFor(String axle) => "$axle 的推荐压力";
  @override String get numericOnly => "仅允许输入数字";

  @override String get inventory => '库存';
  @override String get onHold => '暂停';
  @override String get scrap => '报废';
  @override String get repair => '维修';
  @override String get retread => '翻新';
  @override String get edit => '编辑';
  @override String get clone => '克隆';
  @override String get ok => '确定';
}