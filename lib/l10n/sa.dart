import 'app_localizations.dart';

class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([super.locale = 'ar']);

  @override String get homeTitle => 'الرئيسية';
  @override String get greeting => 'مرحبا';
  @override String get settings => 'الإعدادات';
  @override String get language => 'اللغة';
  @override String get measurementSystem => 'نظام القياس';
  @override String get pressureUnit => 'وحدة الضغط';
  @override String get update => 'تحديث';
  @override String get cancel => 'إلغاء';
  @override String get addTyre => 'إضافة إطار';
  @override String get save => 'حفظ';

  // Screen labels
  @override String get vehicleId => 'معرف المركبة';
  @override String get currentHours => 'الساعات الحالية';
  @override String get currentKm => '{unit} الحالي';
  @override String get trackingMethod => 'طريقة التتبع';
  @override String get manufacturer => 'الشركة المصنعة';
  @override String get vehicleType => 'النوع';
  @override String get model => 'الطراز';
  @override String get tyreSize => 'حجم الإطار';
  @override String get removalTread => 'عمق مداس الإزالة';
  @override String get vehicleComments => 'تعليقات المركبة';
  @override String get vehicleDiagram => 'مخطط المركبة';
  @override String get recommendedPressure => 'الضغط الموصى به';
  @override String get submit => 'إرسال';
  @override String get createVehicle => 'إنشاء مركبة جديدة';
  @override String get outsideTread => 'عمق المداس الخارجي';
  @override String get insideTread => 'عمق المداس الداخلي';
  @override String get averageTread => 'متوسط المداس';
  @override String get airPressure => 'ضغط الهواء';
  @override String get lastRecordedDate => 'آخر تاريخ مسجل';
  @override String get lastRecordedHours => 'آخر ساعات مسجلة';
  @override String get updateHours => 'تحديث الساعات';
  @override String get lastRecordedKm => 'آخر {unit} مسجل';
  @override String get updateKm => 'تحديث {unit}';
  @override String get vehicleNumber => 'رقم المركبة';
  @override String get editVehicle => 'تعديل المركبة';

  @override String get selectedParentAccountLocation => 'الحساب الرئيسي المحدد والموقع';
  @override String get loadingMasterData => 'جارٍ تحميل البيانات الرئيسية...';
  @override String get creatingVehicle => 'جارٍ إنشاء المركبة...';
  @override String get trackingMethodTitle => 'طريقة التتبع';
  @override String get trackingMethodHours => 'ساعات';
  @override String get trackingMethodDistance => 'مسافة';
  @override String get trackingMethodBoth => 'كلاهما';
  @override String get searchHint => 'بحث...';
  @override String get noDataAvailable => 'لا توجد بيانات متاحة';
  @override String get noTireInstalled => 'لا\nإطار\nمثبت';
  @override String get axleLabel => 'محور';
  @override String get cancelRequestTitle => 'إلغاء الطلب';
  @override String get cancelRequestMessage => 'هل أنت متأكد من الإلغاء؟ ستُفقد البيانات غير المحفوظة.';
  @override String get cancelRequestYes => 'نعم';
  @override String get currentDistance => 'الحالي';
  @override String get enterCurrentDistance => 'أدخل القيمة الحالية';
  @override String get commentsHint => 'اكتب التعليقات هنا. (حد أقصى 200 حرف)';
  // CREATE TYRE (STEP 1)
  @override String get identificationDetails => 'تفاصيل التعريف';
  @override String get tyreSerialNumber => 'رقم تسلسلي للإطار';
  @override String get enterTyreSerialNumber => 'أدخل الرقم التسلسلي للإطار';
  @override String get tyreSerialRequired => 'رقم الإطار مطلوب';
  @override String get tyreSerialDuplicate => 'رقم الإطار مكرر';

  @override String get brandNumber => 'رقم العلامة التجارية';
  @override String get enterBrandNumber => 'أدخل رقم العلامة التجارية';

  @override String get registerDate => 'تاريخ التسجيل';
  @override String get registerDateRequired => 'تاريخ التسجيل مطلوب';

  @override String get evaluationNumber => 'رقم التقييم';
  @override String get lotNumber => 'رقم الدفعة';
  @override String get purchaseOrderNumber => 'رقم أمر الشراء';

  @override String get disposition => 'الحالة';
  @override String get status => 'الوضع';

  @override String get currentHoursRequired => 'الساعات الحالية مطلوبة';
  @override String get invalidHours => 'ساعات غير صالحة';
  @override String get negativeHours => 'لا يمكن أن تكون الساعات سالبة';

  @override String get currentKmRequired => 'المسافة مطلوبة';
  @override String get invalidKm => 'مسافة غير صالحة';
  @override String get negativeKm => 'المسافة لا يمكن أن تكون سالبة';

  // CREATE TYRE (STEP 2)
  @override String get description => 'الوصف';
  @override String get selectManufacturer => 'اختر الشركة المصنعة';
  @override String get selectTyreSize => 'اختر حجم الإطار';
  @override String get starRating => 'التقييم';
  @override String get selectType => 'اختر النوع';
  @override String get indCode => 'رمز IND';
  @override String get compound => 'المركب';
  @override String get loadRating => 'تصنيف الحمولة';
  @override String get speedRating => 'تصنيف السرعة';

  @override String get requiredField => 'هذا الحقل مطلوب';

  // BUTTONS
  @override String get nextBtn => 'التالي';
  @override String get previousBtn => 'السابق';
  @override String get cancelBtn => 'إلغاء';
  @override String get okBtn => 'حسناً';

  @override String get originalTread => "عمق البداية";
  @override String get removeAt => "نقطة الإزالة";
  @override String get purchaseTread => "عمق الشراء";
  @override String get outside => "خارجي";
  @override String get inside => "داخلي";


  @override String get wornWarning =>
      "تحذير: الإطار تحت الحد الآمن.";
  @override String get enterValidDetails => "أدخل بيانات صحيحة.";
  @override String get onlyNumeric => "أرقام فقط.";
  @override String get treadDepth => "عمق المداس";
  @override String get next => 'التالي';
  @override String get previous => 'السابق';

  @override String get vehicleViewTitle => 'عرض المركبة';
  @override String get inspect => 'فحص';
  @override String get error => 'خطأ';
  @override String get noVehicleId => 'لا يوجد معرف للمركبة';
  @override String get vehicleNotFound => 'المركبة غير موجودة';
  @override String get wheelPosition => 'موضع العجلة';

  @override String get costAdjustment => 'تعديل التكلفة';
  @override String get currentPressure => 'الضغط الحالي';
  @override String get currentTreadDepth => 'عمق المداس الحالي';
  @override String get percentageWorn => 'نسبة التآكل';

  @override String get fillType => 'نوع التعبئة';
  @override String get fillCost => 'تكلفة التعبئة';
  @override String get repairCost => 'تكلفة الإصلاح';
  @override String get retreadCost => 'تكلفة إعادة التدوير';
  @override String get warrantyAdjustment => 'تعديل الضمان';

  @override String get netCost => 'التكلفة الصافية';
  @override String get soldAmount => 'المبلغ المباع';

  @override String get costs => 'التكاليف';

  @override String get identification => 'التعريف';

  @override String get middleTread => 'عمق المداس الأوسط';

  @override String get purchasedTread => 'مداس الشراء';
  @override String get viewTyre => 'عرض الإطار';
  @override String get viewVehicle => 'عرض المركبة';

  // ================= HOME & DRAWER =================
  @override String get parentAccount => 'الحساب الرئيسي';
  @override String get location => 'الموقع';
  @override String get changeLocationAccount => 'تغيير الحساب والموقع';

  @override String get mainMenu => 'القائمة الرئيسية';
  @override String get home => 'الرئيسية';
  @override String get create => 'إنشاء';
  @override String get preferences => 'التفضيلات';
  @override String get user => 'المستخدم';
  @override String get logout => 'تسجيل الخروج';

  @override String get createVehicleMenu => 'إنشاء مركبة';
  @override String get createTyreMenu => 'جديد';

  @override String get userManagementList => 'إدارة المستخدمين';
  @override String get grandparentAccount => 'الحساب الأعلى';
  @override String get grandparentAccountView => 'الحسابات العليا عرض';
  @override String get startInspection => 'بدء الفحص';

  @override String get totalVehicles => 'إجمالي المركبات';
  @override String get totalTyres => 'إجمالي الإطارات';


  @override String get lastInspection => 'آخر فحص';
  @override String get sync => 'مزامنة';

  @override String get unsyncInspection => 'فحوصات غير متزامنة';
  @override String get syncInspection => 'فحوصات متزامنة';

  @override String get appVersion => 'إصدار التطبيق';
  @override String get change => 'تغيير';

  @override String get syncSuccess => 'تمت المزامنة بنجاح';
  @override String get syncFailed => 'فشل المزامنة';

  @override String get noPermissionCreate => 'لا يوجد إذن للإنشاء';


  // ================= CREATE TYRE STEP 2 =================
  @override String get manufacture => 'التصنيع';
  @override String get tireSize => 'حجم الإطار';
  @override String get searchTireManufacturer => 'البحث عن الشركة المصنعة';
  @override String get chooseManufacturerFirst => 'اختر الشركة المصnعة أولاً';
  @override String get chooseSizeFirst => 'اختر الحجم أولاً';
  @override String get starRatingSelect => 'اختر';
  @override String get selectFillType => 'نوع التعبئة';

  // ================= CREATE TYRE STEP 3 =================
  @override String get treadDepthUnit => 'عمق المداس';
  @override String get originalTreadUnit => 'المداس الأصلي';
  @override String get removeAtUnit => 'الإزالة عند';
  @override String get purchaseTreadUnit => 'مداس الشراء';
  @override String get outsideUnit => 'خارجي (أ)';
  @override String get insideUnit => 'داخلي (ج)';
  @override String get enterOriginalTread => 'أدخل عمق المداس الأصلي';
  @override String get enterRemoveAt => 'نقطة الإزالة';
  @override String get enterPurchaseTread => 'أدخل مداس الشراء';
  @override String get wornPercent => 'نسبة التآكل';

  // ================= CREATE TYRE STEP 4 =================
  @override String get tireCosts => 'تكاليف الإطار';
  @override String get purchaseCostA => 'تكلفة الشراء (أ)';
  @override String get casingValueB => 'قيمة الهيكل (B)';
  @override String get fillCostC => 'تكلفة التعبئة (C)';
  @override String get repairsCostD => 'تكلفة الإصلاحات (D)';
  @override String get numberOfRetreads => 'عدد مرات التجديد';
  @override String get retreadCostE => 'تكلفة التجديد (E)';
  @override String get warrantyAdjustmentF => 'تعديل الضمان (F)';
  @override String get costAdjustmentG => 'تعديل التكلفة (G)';
  @override String get soldAmountH => 'المبلغ المباع (H)';
  @override String get netCostFormula => 'صافي التكلفة = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'حفظ واستنساخ';
  @override String get enterDisposition => 'أدخل الحالة';
  @override String get enterEvaluationNumber => 'أدخل رقم التقييم';
  @override String get enterLotNumber => 'أدخل رقم الدفعة';
  @override String get enterPurchaseOrderNumber => 'أدخل رقم أمر الشراء';
  @override String get enterCurrentHours => 'أدخل الساعات الحالية';
  @override String get enterCurrentKm => 'أدخل الكيلومترات الحالية';
  @override String get enterValidNumeric => 'يرجى إدخال قيمة عددية صالحة.';
  @override String get hoursNotNegative => 'الساعات الحالية لا يمكن أن تكون سالبة.';
  @override String get kmNotNegative => 'الكيلومترات الحالية لا يمكن أن تكون سالبة.';
  @override String get serialAlreadyExists => 'رقم التسلسل هذا موجود بالفعل';
  @override String get searchIndCode => 'بحث عن رمز IND';
  @override String get searchCompound => 'بحث عن المركب';
  @override String get searchLoadRating => 'بحث عن تصنيف الحمولة';
  @override String get searchSpeedRating => 'بحث عن تصنيف السرعة';
  @override String get selectItem => 'اختر';
  @override String get selectPrefix => 'اختر ';
  @override String get serialNumber => 'الرقم التسلسلي';
  @override String get enter => 'إدخال';
  @override String get selectedAccountLocation => 'الحساب والموقع المختار';
  @override String get viewInspections => 'عرض الفحوصات';
  @override String get view => 'عرض';
  @override String get vehicle => 'مركبة';
  @override String get total => 'إجمالي';
  @override String get enterVehicleNumber => 'أدخل رقم المركبة';
  @override String get editTyre => 'تعديل الإطار';
  @override String get clear => 'مسح';
  @override String get set => 'تعيين';
  @override String get enterValidNumber => 'أدخل رقماً صالحاً';
  @override String get allVehicles => 'جميع المركبات';
  @override String get searchVehicles => 'البحث عن المركبات...';
  @override String get filters => 'الفلاتر';
  @override String get applyFilters => 'تطبيق الفلاتر';
  @override String get clearAllFilters => 'مسح جميع الفلاتر';
  @override String get pendingSync => 'انتظار المزامنة';
  @override String get make => 'العلامة التجارية';
  @override String get transfer => 'نقل';
  @override String get delete => 'حذف';
  @override String get own => 'خاص';
  @override String get shared => 'مشترك';
  @override String get select => 'اختيار';
  @override String get searchAccount => 'البحث عن حساب';
  @override String get searchLocation => 'البحث عن موقع';
  @override String get noAccountsFound => 'لم يتم العثور على حسابات';
  @override String get noLocationsFound => 'لم يتم العثور على مواقع';
  @override String get inspectTyre => 'فحص الإطار';
  @override String get installTyre => 'تركيب الإطار';
  @override String get airPressureType => 'نوع ضغط الهواء';
  @override String get cold => 'بارد';
  @override String get hot => 'ساخن';
  @override String get wearCondition => 'حالة التآكل';
  @override String get casingCondition => 'حالة الهيكل';
  @override String get listOfPreviousComments => 'قائمة التعليقات السابقة';
  @override String get stillRelevant => 'لا يزال ذا صلة';
  @override String get uploadImages => 'تحميل الصور';
  @override String get images => 'صور';
  @override String get confirmRemove => 'تأكيد الحذف';
  @override String get areYouSureRemoveImage => 'هل أنت متأكد من حذف هذه الصورة؟';
  @override String get removeTire => 'إزالة الإطار';
  @override String get remove => 'إزالة';
  @override String get all => 'الكل';
  @override String get editBtn => 'تعديل';
  @override String get takePhoto => 'التقاط صورة';
  @override String get chooseFromGallery => 'اختر من المعرض';

  @override String get commentsLabel => 'تعليقات';
  @override String get yes => 'نعم';
  @override String get no => 'لا';
  @override String get upload => 'رفع';
  @override String get install => 'تثبيت';
  @override String get tyreType => 'النوع';
  @override String get loading => 'جارٍ التحميل...';
  @override String get syncAll => 'مزامنة الكل';
  @override String get updateDisposition => 'تحديث الحالة *';
  @override String get removalReason => 'سبب الإزالة';
  @override String get selectDisposition => 'اختر الحالة';
  @override String get selectRemovalReason => 'اختر سبب الإزالة';
  @override String get rotatePosition => 'تبديل الموضع';
  @override String get placementError => 'يرجى وضع الإطار في مكانه قبل الحفظ.';
  @override String get rotationSavedOffline => 'تم حفظ التبديل محلياً. ستتم المزامنة عند توفر الإنترنت.';
  @override String get rotationSuccessful => 'تم تحديث وحفظ التبديل بنجاح.';
  @override String get searchInventory => 'البحث عن إطار في المخزون';
  @override String get noInventoryFound => 'لم يتم العثور على إطارات في المخزون';
  @override String get manufacturerLabel => 'العلامة التجارية / المصنع';
  @override String get unsynced => 'غير متزامن';
  @override String get synced => 'تمت المزامنة';
  @override String get unsyncedPending => 'عمليات تفتيش معلقة بانتظار المزامنة';
  @override String get offlineSyncMessage => 'غير متصل — اتصل بالإنترنت للمزامنة';
  @override String get confirmDeleteTitle => 'حذف التفتيش؟';
  @override String get confirmDeleteMessage => 'هل تريد حذف هذا التفتيش نهائياً؟';
  @override String get viewInspection => 'عرض التفتيش';
  @override String get syncing => 'جاري المزامنة...';
  @override String get inspected => 'تم فحصها';
  @override String get deleteInspectionTitle => 'حذف التفتيش؟';
  @override String get deleteInspectionConfirm => 'حذف التفتيش نهائيًا لـ';
  @override String get tyresLabel => 'إطارات';
  @override String get userManagement => 'إدارة المستخدمين';
  @override String get createUser => 'إنشاء مستخدم';
  @override String get searchUser => 'البحث عن مستخدم';
  @override String get deleteUser => 'حذف المستخدم';
  @override String get deleteUserConfirm => 'هل أنت متأكد أنك تريد حذف هذا المستخدم؟';
  @override String get username => 'اسم المستخدم';
  @override String get password => 'كلمة المرور';
  @override String get userRole => 'دور المستخدم';
  @override String get loginLabel => 'تسجيل الدخول';
  @override String get personalLabel => 'شخصي';
  @override String get preferenceLabel => 'تفضيل';
  @override String get creatingUser => 'جاري إنشاء مستخدم...';
  @override String get grandparentAccountOptions => 'خيارات حساب Grandparent';
  @override String get grandparentAccountInformation => 'معلومات حساب Grandparent';
  @override String get searchGrandparent => 'البحث عن Grandparent';
  @override String get active => 'نشط';
  @override String get inactive => 'غير نشط';
  @override String get ownedBy => 'مملوك من قبل';
  @override String get createAccount => 'إنشاء حساب';
  @override String get assignAccount => 'تعيين حساب';
  @override String get grandparentNameLabel => 'اسم حساب Grandparent';
  @override String get accountTypeLabel => 'مملوك';
  @override String get selectParentAccount => 'الحساب الرئيسي';
  @override String get selectGrandparentAccount => 'حساب Grandparent';
  @override String get assignBtn => 'تعيين';
  @override String get firstName => 'الاسم الأول';
  @override String get middleName => 'الاسم الأوسط';
  @override String get lastName => 'اسم العائلة';
  @override String get phone => 'هاتف';
  @override String get country => 'بلد';
  @override String get measurement => 'قياس';
  @override String get id => 'ID';
  @override String get searchVehicleTyre => 'البحث عن مركبة / إطار';
  @override String get recentSearch => 'البحث الأخير';
  @override String get vehicles => 'مركبات';
  @override String get recentVehicleNotFound => 'لم يتم العثور على مركبات حديثة';
  @override String get recentTyreNotFound => 'لم يتم العثور على إطارات حديثة';
  @override String get typeToSearch => 'اكتب للبحث';
  @override String get noVehiclesFound => 'لم يتم العثور على مركبات لـ';
  @override String get noTyresFound => 'لم يتم العثور على إطارات لـ';
  @override String get createNewVehicle => 'إنشاء مركبة جديدة';
  @override String get createNewTyre => 'إنشاء إطار جديد';
  @override String get confirmRemoveTitle => 'تأكيد الحذف';
  @override String get confirmRemoveMessage => 'هل أنت متأكد أنك تريد حذف هذا العنصر؟';
  @override String get updateBtn => 'تحديث';
  @override String get noRecentVehicleFound => 'لم يتم العثور على مركبات حديثة';
  @override String get noRecentTyreFound => 'لم يتم العثور على إطارات حديثة';
  @override String get noVehiclesFoundFor => 'لم يتم العثور على مركبات لـ';
  @override String get noTyresFoundFor => 'لم يتم العثور على إطارات لـ';
  @override String get searchPrefix => 'بحث';
  @override
  String createNew(String itemName) => 'جديد $itemName إنشاء';

  @override String get vehicleInspection => 'فحص المركبة';
  @override String get hourWarningMsg => "لم تقم بتحديث الساعات والأميال والمركبة.";
  @override String get hours => 'ساعات';
  @override String get km => 'كم';
  @override String get updateHoursKm => 'تحديث الساعات / كم';
  @override String get serialNo => 'الرقم التسلسلي';
  @override String get inspectedTire => 'إطار مفحوص';
  @override String get notInspectedTire => 'إطار غير مفحوص';
  @override String get rotateTyres => 'تدوير الإطارات';
  @override String get uploadedImages => 'الصور المرفوعة';
  @override String get confirmRemoveImg => 'تأكيد حذف الصورة';
  @override String get viewOnlyDisabled => 'للعرض فقط — تم تعطيل الإرسال';
  @override String get cancelRequestMsg => 'هل أنت متأكد أنك تريد الإلغاء؟ ستفقد البيانات غير المحفوظة.';
  @override String get selectedParentAccount => 'الحساب الرئيسي المختار';
  @override String get surveyDate => 'تاريخ المسح';
  @override String get selectDate => 'اختر التاريخ';
  @override String get updateHoursLabel => 'تحديث الساعات';
  @override String get enterHours => 'أدخل الساعات';
  @override String get updateKmLabel => 'تحديث كم';
  @override String get enterKm => 'أدخل كم';
  @override String get updateVehicleDataTitle => 'تحديث بيانات المركبة';
  @override String get updateVehicleDataMsg => 'ستؤثر هذه التغييرات على ساعات/كم الإطارات.\nهل ترغب في المتابعة؟';
  @override String get proceed => 'متابعة';
  @override
  String tyreSerialNumbers(String tyreWord) => 'الرقم التسلسلي لـ $tyreWord'; // Right-to-left context
  @override
  String enterItemSerialNumber(String itemName) => 'أدخل الرقم التسلسلي لـ $itemName';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';
  @override String get numericOnlyError => "مسموح فقط بالقيم الرقمية";
  @override String get negativeValueError => "لا يمكن أن تكون القيمة سالبة";
  @override String get duplicateVehicleError => "رقم المركبة مأخوذ بالفعل";
  @override String get invalidNumberError => "يجب أن يكون رقماً صالحاً";
  @override String get enterPrefix => "أدخل ";
 @override String recommendedPressureFor(String axle) => "الضغط الموصى به لـ $axle";
  @override String get numericOnly => "مسموح فقط بالقيم الرقمية";

  @override String get inventory => 'المخزون';
  @override String get onHold => 'قيد الانتظار';
  @override String get scrap => 'خردة';
  @override String get repair => 'إصلاح';
  @override String get retread => 'تجديد';
  @override String get edit => 'تعديل';
  @override String get clone => 'استنساخ';
  @override String get ok => 'موافق';

}