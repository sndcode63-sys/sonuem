import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'hive_prefe.dart';
import 'local_helper.dart';

/// Multilingual localization helper specifically for Inspection Approval screens
/// and Pending Guard dialogs across all 10 supported languages in EmTrack.
class ApprovalLocalizations {
  final String langCode;
  final BuildContext? context;

  ApprovalLocalizations(this.langCode, [this.context]);

  static ApprovalLocalizations of([BuildContext? ctx]) {
    final context = ctx ?? Get.context;
    String code = 'en';

    if (context != null) {
      final loc = Localizations.maybeLocaleOf(context);
      if (loc != null && loc.languageCode.isNotEmpty) {
        code = loc.languageCode;
      }
    }

    if (code == 'en') {
      final savedCode = HivePref.get<String>('pref_language_code');
      if (savedCode != null && savedCode.isNotEmpty) {
        code = savedCode.toLowerCase();
      } else {
        final display = HivePref.get<String>('pref_language_display') ?? '';
        code = _displayToCode(display);
      }
    }

    return ApprovalLocalizations(code, context);
  }

  static String _displayToCode(String display) {
    final d = display.toLowerCase();
    if (d.contains('español') || d.contains('espanol')) return 'es';
    if (d.contains('deutsch')) return 'de';
    if (d.contains('italiano')) return 'it';
    if (d.contains('français') || d.contains('francais')) return 'fr';
    if (d.contains('中文') || d.contains('chinese')) return 'zh';
    if (d.contains('русский') || d.contains('russian')) return 'ru';
    if (d.contains('português') || d.contains('portugues')) return 'pt';
    if (d.contains('polski') || d.contains('polish')) return 'pl';
    if (d.contains('arabic') || d.contains('العربية')) return 'ar';
    return 'en';
  }

  bool get isUK {
    final display = HivePref.get<String>('pref_language_display') ?? '';
    return display == 'English(uk/Australia)';
  }

  /// Singular tyre/tire name respecting UK vs US and current language
  String tyreName() {
    if (context != null) return LocaleHelper.tyreName(context!);
    if (langCode == 'en') return isUK ? 'Tyre' : 'Tire';
    return _t({
      'es': 'Neumático',
      'de': 'Reifen',
      'fr': 'Pneu',
      'it': 'Pneumatico',
      'pt': 'Pneu',
      'ru': 'Шина',
      'zh': '轮胎',
      'ar': 'إطار',
      'pl': 'Opona',
    }, isUK ? 'Tyre' : 'Tire');
  }

  /// Plural tyres/tires name respecting UK vs US and current language
  String tyresName() {
    if (context != null) return LocaleHelper.tyresName(context!);
    if (langCode == 'en') return isUK ? 'Tyres' : 'Tires';
    return _t({
      'es': 'Neumáticos',
      'de': 'Reifen',
      'fr': 'Pneus',
      'it': 'Pneumatici',
      'pt': 'Pneus',
      'ru': 'Шины',
      'zh': '轮胎',
      'ar': 'إطارات',
      'pl': 'Opony',
    }, isUK ? 'Tyres' : 'Tires');
  }

  String _t(Map<String, String> values, String fallbackEn) {
    return values[langCode] ?? fallbackEn;
  }

  // ══════════════════════════════════════════════════════════
  // PENDING APPROVAL GUARD DIALOG
  // ══════════════════════════════════════════════════════════

  String get approvalPending => _t({
    'es': 'Aprobación pendiente',
    'de': 'Genehmigung ausstehend',
    'fr': 'En attente d\'approbation',
    'it': 'In attesa di approvazione',
    'pt': 'Aprovação pendente',
    'ru': 'Ожидает одобрения',
    'zh': '等待审批',
    'ar': 'في انتظار الموافقة',
    'pl': 'Oczekuje na zatwierdzenie',
  }, 'Approval Pending');

  String get cannotInstallTyre => _t({
    'es': 'No se puede instalar ${tyreName().toLowerCase()}',
    'de': 'Kann ${tyreName()} nicht montieren',
    'fr': 'Impossible d\'installer le ${tyreName().toLowerCase()}',
    'it': 'Impossibile installare il ${tyreName().toLowerCase()}',
    'pt': 'Não é possível instalar o ${tyreName().toLowerCase()}',
    'ru': 'Невозможно установить шину',
    'zh': '无法安装${tyreName()}',
    'ar': 'لا يمكن تثبيت ${tyreName()}',
    'pl': 'Nie można zamontować ${tyreName().toLowerCase()}',
  }, 'Cannot Install ${tyreName()}');

  String get cannotUpdateHoursKm => _t({
    'es': 'No se puede actualizar Horas/KM',
    'de': 'Stunden/KM können nicht aktualisiert werden',
    'fr': 'Impossible de mettre à jour Heures/KM',
    'it': 'Impossibile aggiornare Ore/KM',
    'pt': 'Não é possível atualizar Horas/KM',
    'ru': 'Невозможно обновить часы/км',
    'zh': '无法更新小时/公里',
    'ar': 'لا يمكن تحديث الساعات/كم',
    'pl': 'Nie można zaktualizować Godzin/KM',
  }, 'Cannot Update Hours/KM');

  String get cannotEditVehicle => _t({
    'es': 'No se puede editar el vehículo',
    'de': 'Fahrzeug kann nicht bearbeitet werden',
    'fr': 'Impossible de modifier le véhicule',
    'it': 'Impossibile modificare il veicolo',
    'pt': 'Não é possível editar o veículo',
    'ru': 'Невозможно редактировать автомобиль',
    'zh': '无法编辑车辆',
    'ar': 'لا يمكن تعديل المركبة',
    'pl': 'Nie można edytować pojazdu',
  }, 'Cannot Edit Vehicle');

  String get cannotInspectTyre => _t({
    'es': 'No se puede inspeccionar el ${tyreName().toLowerCase()}',
    'de': 'Kann ${tyreName()} nicht prüfen',
    'fr': 'Impossible d\'inspecter le ${tyreName().toLowerCase()}',
    'it': 'Impossibile ispezionare il ${tyreName().toLowerCase()}',
    'pt': 'Não é possível inspecionar o ${tyreName().toLowerCase()}',
    'ru': 'Невозможно осмотреть шину',
    'zh': '无法检查${tyreName()}',
    'ar': 'لا يمكن فحص ${tyreName()}',
    'pl': 'Nie można skontrolować ${tyreName().toLowerCase()}',
  }, 'Cannot Inspect ${tyreName()}');

  String get cannotRotateTyres => _t({
    'es': 'No se pueden rotar los ${tyresName().toLowerCase()}',
    'de': 'Kann ${tyresName()} nicht rotieren',
    'fr': 'Impossible de permuter les ${tyresName().toLowerCase()}',
    'it': 'Impossibile ruotare i ${tyresName().toLowerCase()}',
    'pt': 'Não é possível rodiziar os ${tyresName().toLowerCase()}',
    'ru': 'Невозможно переставить шины',
    'zh': '无法轮换${tyresName()}',
    'ar': 'لا يمكن تدوير ${tyresName()}',
    'pl': 'Nie można zamienić miejscami ${tyresName().toLowerCase()}',
  }, 'Cannot Rotate ${tyresName()}');

  String get cannotUploadImage => _t({
    'es': 'No se puede subir imagen',
    'de': 'Bild kann nicht hochgeladen werden',
    'fr': 'Impossible de télécharger l\'image',
    'it': 'Impossibile caricare l\'immagine',
    'pt': 'Não é possível carregar imagem',
    'ru': 'Невозможно загрузить изображение',
    'zh': '无法上传图片',
    'ar': 'لا يمكن تحميل الصورة',
    'pl': 'Nie można przesłać zdjęcia',
  }, 'Cannot Upload Image');

  String get cannotDeleteImage => _t({
    'es': 'No se puede eliminar imagen',
    'de': 'Bild kann nicht gelöscht werden',
    'fr': 'Impossible de supprimer l\'image',
    'it': 'Impossibile eliminare l\'immagine',
    'pt': 'Não é possível excluir imagem',
    'ru': 'Невозможно удалить изображение',
    'zh': '无法删除图片',
    'ar': 'لا يمكن حذف الصورة',
    'pl': 'Nie można usunąć zdjęcia',
  }, 'Cannot Delete Image');

  String get cannotEditTyre => _t({
    'es': 'No se puede editar ${tyreName().toLowerCase()}',
    'de': 'Kann ${tyreName()} nicht bearbeiten',
    'fr': 'Impossible de modifier le ${tyreName().toLowerCase()}',
    'it': 'Impossibile modificare il ${tyreName().toLowerCase()}',
    'pt': 'Não é possível editar o ${tyreName().toLowerCase()}',
    'ru': 'Невозможно редактировать шину',
    'zh': '无法编辑${tyreName()}',
    'ar': 'لا يمكن تعديل ${tyreName()}',
    'pl': 'Nie można edytować ${tyreName().toLowerCase()}',
  }, 'Cannot Edit ${tyreName()}');

  String get cannotCloneTyre => _t({
    'es': 'No se puede clonar ${tyreName().toLowerCase()}',
    'de': 'Kann ${tyreName()} nicht klonen',
    'fr': 'Impossible de cloner le ${tyreName().toLowerCase()}',
    'it': 'Impossibile clonare il ${tyreName().toLowerCase()}',
    'pt': 'Não é possível clonar o ${tyreName().toLowerCase()}',
    'ru': 'Невозможно клонировать шину',
    'zh': '无法克隆${tyreName()}',
    'ar': 'لا يمكن استنساخ ${tyreName()}',
    'pl': 'Nie można sklonować ${tyreName().toLowerCase()}',
  }, 'Cannot Clone ${tyreName()}');

  String get cannotSubmitInspection => _t({
    'es': 'No se puede enviar inspección',
    'de': 'Inspektion kann nicht übermittelt werden',
    'fr': 'Impossible de soumettre l\'inspection',
    'it': 'Impossibile inviare l\'ispezione',
    'pt': 'Não é possível enviar inspeção',
    'ru': 'Невозможно отправить инспекцию',
    'zh': '无法提交检查',
    'ar': 'لا يمكن إرسال الفحص',
    'pl': 'Nie można przesłać inspekcji',
  }, 'Cannot Submit Inspection');

  String get pendingInspectionWaitingMsg => _t({
    'es': 'Una inspección previa de este vehículo aún está esperando aprobación. ',
    'de': 'Eine vorherige Inspektion dieses Fahrzeugs wartet noch auf die Genehmigung. ',
    'fr': 'Une inspection précédente de ce véhicule est toujours en attente d\'approbation. ',
    'it': 'Una precedente ispezione di questo veicolo è ancora in attesa di approvazione. ',
    'pt': 'Uma inspeção anterior deste veículo ainda está aguardando aprovação. ',
    'ru': 'Предыдущая инспекция этого автомобиля все еще ожидает одобрения. ',
    'zh': '该车辆之前的检查仍在等待审批。',
    'ar': 'فحص سابق لهذه المركبة لا يزال قيد انتظار الموافقة. ',
    'pl': 'Poprzednia inspekcja tego pojazdu nadal oczekuje na zatwierdzenie. ',
  }, 'A previous inspection of this vehicle is still waiting for approval. ');

  String pendingActionUnlockedMsg(String actionDetail) {
    return _t({
      'es': '${pendingInspectionWaitingMsg}Podrá $actionDetail una vez que sea aprobada o rechazada.',
      'de': '${pendingInspectionWaitingMsg}Sie können $actionDetail, sobald sie genehmigt oder abgelehnt wurde.',
      'fr': '${pendingInspectionWaitingMsg}Vous pourrez $actionDetail une fois qu\'elle sera approuvée ou rejetée.',
      'it': '${pendingInspectionWaitingMsg}Potrai $actionDetail una volta approvata o rifiutata.',
      'pt': '${pendingInspectionWaitingMsg}Você poderá $actionDetail assim que for aprovada ou rejeitada.',
      'ru': '$pendingInspectionWaitingMsgВы сможете $actionDetail после одобрения или отклонения.',
      'zh': '$pendingInspectionWaitingMsg审批通过或驳回后即可$actionDetail。',
      'ar': '$pendingInspectionWaitingMsgيمكنك $actionDetail بمجرد الموافقة عليها أو رفضها.',
      'pl': '${pendingInspectionWaitingMsg}Możesz $actionDetail po zatwierdzeniu lub odrzuceniu.',
    }, '${pendingInspectionWaitingMsg}You can $actionDetail once it is approved or rejected.');
  }

  String get installTyreAction => _t({
    'es': 'instalar un ${tyreName().toLowerCase()}',
    'de': 'einen ${tyreName()} montieren',
    'fr': 'installer un ${tyreName().toLowerCase()}',
    'it': 'installare un ${tyreName().toLowerCase()}',
    'pt': 'instalar um ${tyreName().toLowerCase()}',
    'ru': 'установить шину',
    'zh': '安装${tyreName()}',
    'ar': 'تثبيت ${tyreName()}',
    'pl': 'zamontować ${tyreName().toLowerCase()}',
  }, 'install a ${tyreName().toLowerCase()}');

  String get updateHoursKmAction => _t({
    'es': 'actualizar horas/km',
    'de': 'Stunden/KM aktualisieren',
    'fr': 'mettre à jour les heures/km',
    'it': 'aggiornare ore/km',
    'pt': 'atualizar horas/km',
    'ru': 'обновить часы/км',
    'zh': '更新小时/公里',
    'ar': 'تحديث الساعات/كم',
    'pl': 'zaktualizować godziny/km',
  }, 'update hours/km');

  String get editVehicleAction => _t({
    'es': 'editar este vehículo',
    'de': 'dieses Fahrzeug bearbeiten',
    'fr': 'modifier ce véhicule',
    'it': 'modificare questo veicolo',
    'pt': 'editar este veículo',
    'ru': 'редактировать этот автомобиль',
    'zh': '编辑此车辆',
    'ar': 'تعديل هذه المركبة',
    'pl': 'edytować ten pojazd',
  }, 'edit this vehicle');

  String get inspectTyreAction => _t({
    'es': 'inspeccionar ${tyresName().toLowerCase()}',
    'de': '${tyresName()} prüfen',
    'fr': 'inspecter les ${tyresName().toLowerCase()}',
    'it': 'ispezionare i ${tyresName().toLowerCase()}',
    'pt': 'inspecionar ${tyresName().toLowerCase()}',
    'ru': 'осмотреть шины',
    'zh': '检查${tyresName()}',
    'ar': 'فحص ${tyresName()}',
    'pl': 'skontrolować ${tyresName().toLowerCase()}',
  }, 'inspect ${tyresName().toLowerCase()}');

  String get rotateTyresAction => _t({
    'es': 'rotar ${tyresName().toLowerCase()}',
    'de': '${tyresName()} rotieren',
    'fr': 'permuter les ${tyresName().toLowerCase()}',
    'it': 'ruotare i ${tyresName().toLowerCase()}',
    'pt': 'rodiziar ${tyresName().toLowerCase()}',
    'ru': 'переставить шины',
    'zh': '轮换${tyresName()}',
    'ar': 'تدوير ${tyresName()}',
    'pl': 'zamienić ${tyresName().toLowerCase()}',
  }, 'rotate ${tyresName().toLowerCase()}');

  String get uploadImagesAction => _t({
    'es': 'subir imágenes',
    'de': 'Bilder hochladen',
    'fr': 'télécharger des images',
    'it': 'caricare immagini',
    'pt': 'carregar imagens',
    'ru': 'загрузить изображения',
    'zh': '上传图片',
    'ar': 'تحميل الصور',
    'pl': 'przesłać zdjęcia',
  }, 'upload images');

  String get deleteImagesAction => _t({
    'es': 'eliminar imágenes',
    'de': 'Bilder löschen',
    'fr': 'supprimer des images',
    'it': 'eliminare immagini',
    'pt': 'excluir imagens',
    'ru': 'удалить изображения',
    'zh': '删除图片',
    'ar': 'حذف الصور',
    'pl': 'usunąć zdjęcia',
  }, 'delete images');

  String get editTyreAction => _t({
    'es': 'editar un ${tyreName().toLowerCase()}',
    'de': 'einen ${tyreName()} bearbeiten',
    'fr': 'modifier un ${tyreName().toLowerCase()}',
    'it': 'modificare un ${tyreName().toLowerCase()}',
    'pt': 'editar um ${tyreName().toLowerCase()}',
    'ru': 'редактировать шину',
    'zh': '编辑${tyreName()}',
    'ar': 'تعديل ${tyreName()}',
    'pl': 'edytować ${tyreName().toLowerCase()}',
  }, 'edit a ${tyreName().toLowerCase()}');

  String get cloneTyreAction => _t({
    'es': 'clonar un ${tyreName().toLowerCase()}',
    'de': 'einen ${tyreName()} klonen',
    'fr': 'cloner un ${tyreName().toLowerCase()}',
    'it': 'clonare un ${tyreName().toLowerCase()}',
    'pt': 'clonar um ${tyreName().toLowerCase()}',
    'ru': 'клонировать шину',
    'zh': '克隆${tyreName()}',
    'ar': 'استنساخ ${tyreName()}',
    'pl': 'sklonować ${tyreName().toLowerCase()}',
  }, 'clone a ${tyreName().toLowerCase()}');

  String get submitInspectionAction => _t({
    'es': 'enviar una nueva inspección',
    'de': 'eine neue Inspektion übermitteln',
    'fr': 'soumettre une nouvelle inspection',
    'it': 'inviare una nuova ispezione',
    'pt': 'enviar uma nova inspeção',
    'ru': 'отправить новую инспекцию',
    'zh': '提交新检查',
    'ar': 'إرسال فحص جديد',
    'pl': 'przesłać nową inspekcję',
  }, 'submit a new inspection');

  String get submittedBy => _t({
    'es': 'Enviado por',
    'de': 'Eingereicht von',
    'fr': 'Soumis par',
    'it': 'Inviato da',
    'pt': 'Enviado por',
    'ru': 'Отправлено',
    'zh': '提交人',
    'ar': 'مقدم من',
    'pl': 'Przesłane przez',
  }, 'Submitted by');

  String get submittedOn => _t({
    'es': 'Enviado el',
    'de': 'Eingereicht am',
    'fr': 'Soumis le',
    'it': 'Inviato il',
    'pt': 'Enviado em',
    'ru': 'Дата отправки',
    'zh': '提交时间',
    'ar': 'تاريخ التقديم',
    'pl': 'Przesłano dnia',
  }, 'Submitted on');

  String get pendingLockFootnote => _t({
    'es': 'Las inspecciones, cambios de neumáticos y actualizaciones de horas/km están bloqueados hasta que el aprobador apruebe o rechace.',
    'de': 'Inspektionen, Reifenwechsel und Stunden-/KM-Aktualisierungen sind gesperrt, bis die Genehmigung erteilt oder abgelehnt wird.',
    'fr': 'Les inspections, changements de pneus et mises à jour d\'heures/km sont verrouillés jusqu\'à approbation ou rejet.',
    'it': 'Ispezioni, cambi pneumatici e aggiornamenti ore/km sono bloccati fino all\'approvazione o al rifiuto.',
    'pt': 'Inspeções, trocas de pneus e atualizações de horas/km estão bloqueadas até aprovação ou rejeição.',
    'ru': 'Инспекция, замена шин и обновление часов/км заблокированы до одобрения или отклонения.',
    'zh': '在审批者批准或驳回之前，检查、轮胎更换和小时/公里更新均被锁定。',
    'ar': 'الفحص وتغيير الإطارات وتحديثات الساعات/كم مقفلة حتى يوافق المعتمد أو يرفض.',
    'pl': 'Inspekcje, wymiany opon oraz aktualizacje godzin/km są zablokowane do momentu zatwierdzenia lub odrzucenia.',
  }, 'Inspection, ${tyreName().toLowerCase()} changes and hours/km updates are locked until the approver approves or rejects.');

  // ── Offline submit, abhi tak sync nahi hua ──
  String get syncPending => _t({
    'es': 'Sincronización pendiente',
    'de': 'Synchronisierung ausstehend',
    'fr': 'Synchronisation en attente',
    'it': 'Sincronizzazione in sospeso',
    'pt': 'Sincronização pendente',
    'ru': 'Ожидает синхронизации',
    'zh': '等待同步',
    'ar': 'في انتظار المزامنة',
    'pl': 'Oczekuje na synchronizację',
  }, 'Sync Pending');

  String get syncPendingMsg => _t({
    'es': 'La inspección de este vehículo se envió sin conexión y aún no se ha sincronizado. ',
    'de': 'Die Inspektion dieses Fahrzeugs wurde offline übermittelt und noch nicht synchronisiert. ',
    'fr': 'L\'inspection de ce véhicule a été soumise hors ligne et n\'est pas encore synchronisée. ',
    'it': 'L\'ispezione di questo veicolo è stata inviata offline e non è ancora sincronizzata. ',
    'pt': 'A inspeção deste veículo foi enviada offline e ainda não foi sincronizada. ',
    'ru': 'Инспекция этого автомобиля была отправлена офлайн и ещё не синхронизирована. ',
    'zh': '该车辆的检查是离线提交的，尚未同步。',
    'ar': 'تم إرسال فحص هذه المركبة دون اتصال ولم تتم مزامنته بعد. ',
    'pl': 'Inspekcja tego pojazdu została przesłana offline i nie została jeszcze zsynchronizowana. ',
  }, 'This vehicle\'s inspection was submitted offline and has not synced yet. ');

  String syncPendingActionMsg(String actionDetail) {
    return _t({
      'es': '${syncPendingMsg}Podrá $actionDetail una vez sincronizada.',
      'de': '${syncPendingMsg}Sie können $actionDetail, sobald sie synchronisiert wurde.',
      'fr': '${syncPendingMsg}Vous pourrez $actionDetail une fois la synchronisation terminée.',
      'it': '${syncPendingMsg}Potrai $actionDetail una volta sincronizzata.',
      'pt': '${syncPendingMsg}Você poderá $actionDetail assim que for sincronizada.',
      'ru': '$syncPendingMsgВы сможете $actionDetail после синхронизации.',
      'zh': '$syncPendingMsg同步完成后即可$actionDetail。',
      'ar': '$syncPendingMsgيمكنك $actionDetail بعد اكتمال المزامنة.',
      'pl': '${syncPendingMsg}Będzie można $actionDetail po synchronizacji.',
    }, '${syncPendingMsg}You can $actionDetail once it is synced.');
  }

  String get syncPendingFootnote => _t({
    'es': 'Conéctese a internet y sincronice. Hasta entonces, las inspecciones, cambios de neumáticos, imágenes y actualizaciones de horas/km están bloqueados.',
    'de': 'Stellen Sie eine Internetverbindung her und synchronisieren Sie. Bis dahin sind Inspektionen, Reifenwechsel, Bilder und Stunden-/KM-Aktualisierungen gesperrt.',
    'fr': 'Connectez-vous à Internet et synchronisez. D\'ici là, inspections, changements de pneus, images et mises à jour d\'heures/km sont verrouillés.',
    'it': 'Connettiti a Internet e sincronizza. Fino ad allora ispezioni, cambi pneumatici, immagini e aggiornamenti ore/km sono bloccati.',
    'pt': 'Conecte-se à internet e sincronize. Até lá, inspeções, trocas de pneus, imagens e atualizações de horas/km ficam bloqueadas.',
    'ru': 'Подключитесь к интернету и выполните синхронизацию. До этого инспекции, замена шин, изображения и обновление часов/км заблокированы.',
    'zh': '请连接网络并同步。在此之前，检查、轮胎更换、图片及小时/公里更新均被锁定。',
    'ar': 'اتصل بالإنترنت وقم بالمزامنة. حتى ذلك الحين، الفحص وتغيير الإطارات والصور وتحديثات الساعات/كم مقفلة.',
    'pl': 'Połącz się z internetem i zsynchronizuj. Do tego czasu inspekcje, wymiany opon, zdjęcia i aktualizacje godzin/km są zablokowane.',
  }, 'Connect to the internet and sync. Until then, inspection, ${tyreName().toLowerCase()} changes, images and hours/km updates are locked.');

  String get okGotIt => _t({
    'es': 'Entendido',
    'de': 'OK, Verstanden',
    'fr': 'D\'accord, compris',
    'it': 'OK, Ho capito',
    'pt': 'OK, Entendido',
    'ru': 'Понятно',
    'zh': '好的，知道了',
    'ar': 'حسناً، فهمت',
    'pl': 'Rozumiem',
  }, 'OK, Got it');

  // ══════════════════════════════════════════════════════════
  // SEARCH / IW SCREEN (iw.dart)
  // ══════════════════════════════════════════════════════════

  String get inspectionVehicleTire => _t({
    'es': 'Inspección Vehículo / ${tyreName()}',
    'de': 'Inspektion Fahrzeug / ${tyreName()}',
    'fr': 'Inspection Véhicule / ${tyreName()}',
    'it': 'Ispezione Veicolo / ${tyreName()}',
    'pt': 'Inspeção Veículo / ${tyreName()}',
    'ru': 'Инспекция ТС / ${tyreName()}',
    'zh': '检查车辆 / ${tyreName()}',
    'ar': 'فحص المركبة / ${tyreName()}',
    'pl': 'Inspekcja Pojazdu / ${tyreName()}',
  }, 'Inspection Vehicle / ${tyreName()}');

  String get searchInspectionVehicleTire => _t({
    'es': 'Buscar Vehículo / ${tyreName()} de inspección',
    'de': 'Inspektionsfahrzeug / ${tyreName()} suchen',
    'fr': 'Rechercher Véhicule / ${tyreName()} d\'inspection',
    'it': 'Cerca Veicolo / ${tyreName()} di ispezione',
    'pt': 'Buscar Veículo / ${tyreName()} de inspeção',
    'ru': 'Поиск ТС / ${tyreName()}',
    'zh': '搜索检查车辆 / ${tyreName()}',
    'ar': 'بحث عن مركبة / ${tyreName()} للفحص',
    'pl': 'Szukaj Pojazdu / ${tyreName()} do inspekcji',
  }, 'Search Inspection Vehicle / ${tyreName()}');

  String get searchInspectionVehicleDialog => _t({
    'es': 'Buscar vehículo de inspección...',
    'de': 'Inspektionsfahrzeug suchen...',
    'fr': 'Rechercher véhicule d\'inspection...',
    'it': 'Cerca veicolo di ispezione...',
    'pt': 'Buscar veículo de inspeção...',
    'ru': 'Поиск автомобиля...',
    'zh': '搜索检查车辆...',
    'ar': 'بحث عن مركبة للفحص...',
    'pl': 'Szukaj pojazdu do inspekcji...',
  }, 'Search Inspection Vehicle...');

  String get inspectionVehicles => _t({
    'es': 'Vehículos de inspección',
    'de': 'Inspektionsfahrzeuge',
    'fr': 'Véhicules d\'inspection',
    'it': 'Veicoli di ispezione',
    'pt': 'Veículos de inspeção',
    'ru': 'Автомобили на инспекции',
    'zh': '检查车辆',
    'ar': 'مركبات الفحص',
    'pl': 'Pojazdy do inspekcji',
  }, 'Inspection Vehicles');

  String get inspectionTires => _t({
    'es': '${tyresName()} de inspección',
    'de': 'Inspektions-${tyresName()}',
    'fr': '${tyresName()} d\'inspection',
    'it': '${tyresName()} di ispezione',
    'pt': '${tyresName()} de inspeção',
    'ru': 'Шины на инспекции',
    'zh': '检查${tyresName()}',
    'ar': '${tyresName()} الفحص',
    'pl': '${tyresName()} do inspekcji',
  }, 'Inspection ${tyresName()}');

  String get noVehicleSelected => _t({
    'es': 'Ningún vehículo seleccionado',
    'de': 'Kein Fahrzeug ausgewählt',
    'fr': 'Aucun véhicule sélectionné',
    'it': 'Nessun veicolo selezionato',
    'pt': 'Nenhum veículo selecionado',
    'ru': 'Транспорт не выбран',
    'zh': '未选择车辆',
    'ar': 'لم يتم اختيار مركبة',
    'pl': 'Nie wybrano pojazdu',
  }, 'No vehicle selected');

  String get noTyreSelected => _t({
    'es': 'Ningún ${tyreName().toLowerCase()} seleccionado',
    'de': 'Kein ${tyreName()} ausgewählt',
    'fr': 'Aucun ${tyreName().toLowerCase()} sélectionné',
    'it': 'Nessun ${tyreName().toLowerCase()} selezionato',
    'pt': 'Nenhum ${tyreName().toLowerCase()} seleccionado',
    'ru': 'Шина не выбрана',
    'zh': '未选择${tyreName()}',
    'ar': 'لم يتم اختيار ${tyreName()}',
    'pl': 'Nie wybrano ${tyreName().toLowerCase()}',
  }, 'No ${tyreName().toLowerCase()} selected');

  String get pendingRemoval => _t({
    'es': 'Retiro pendiente',
    'de': 'Ausstehender Ausbau',
    'fr': 'Retrait en attente',
    'it': 'Rimozione in attesa',
    'pt': 'Remoção pendente',
    'ru': 'Ожидает снятия',
    'zh': '待拆卸',
    'ar': 'إزالة معلقة',
    'pl': 'Oczekuje na demontaż',
  }, 'Pending Removal');

  String removedFromPosition(String pos) => _t({
    'es': 'Retirado de posición $pos',
    'de': 'Von Position $pos entfernt',
    'fr': 'Retiré de la position $pos',
    'it': 'Rimosso dalla posizione $pos',
    'pt': 'Removido da posição $pos',
    'ru': 'Снято с позиции $pos',
    'zh': '已从位置 $pos 拆卸',
    'ar': 'تمت الإزالة من الموضع $pos',
    'pl': 'Zdemontowano z pozycji $pos',
  }, 'Removed from Position $pos');

  String get removedFromVehicle => _t({
    'es': 'Retirado del vehículo',
    'de': 'Vom Fahrzeug entfernt',
    'fr': 'Retiré du véhicule',
    'it': 'Rimosso dal veicolo',
    'pt': 'Removido do veículo',
    'ru': 'Снято с автомобиля',
    'zh': '已从车辆拆卸',
    'ar': 'تمت الإزالة من المركبة',
    'pl': 'Zdemontowano z pojazdu',
  }, 'Removed from Vehicle');

  String position(String pos) => _t({
    'es': 'Posición: $pos',
    'de': 'Position: $pos',
    'fr': 'Position : $pos',
    'it': 'Posizione: $pos',
    'pt': 'Posição: $pos',
    'ru': 'Позиция: $pos',
    'zh': '位置：$pos',
    'ar': 'الموضع: $pos',
    'pl': 'Pozycja: $pos',
  }, 'Position: $pos');

  String get approved => _t({
    'es': 'Aprobado',
    'de': 'Genehmigt',
    'fr': 'Approuvé',
    'it': 'Approvato',
    'pt': 'Aprovado',
    'ru': 'Одобрено',
    'zh': '已批准',
    'ar': 'تمت الموافقة',
    'pl': 'Zatwierdzono',
  }, 'Approved');

  String get rejected => _t({
    'es': 'Rechazado',
    'de': 'Abgelehnt',
    'fr': 'Rejeté',
    'it': 'Rifiutato',
    'pt': 'Rejeitado',
    'ru': 'Отклонено',
    'zh': '已驳回',
    'ar': 'مرفوض',
    'pl': 'Odrzucono',
  }, 'Rejected');

  String get pending => _t({
    'es': 'Pendiente',
    'de': 'Ausstehend',
    'fr': 'En attente',
    'it': 'In sospeso',
    'pt': 'Pendente',
    'ru': 'В ожидании',
    'zh': '待处理',
    'ar': 'معلق',
    'pl': 'Oczekuje',
  }, 'Pending');

  String get vehiclesTab => _t({
    'es': 'VEHÍCULOS',
    'de': 'FAHRZEUGE',
    'fr': 'VÉHICULES',
    'it': 'VEICOLI',
    'pt': 'VEÍCULOS',
    'ru': 'АВТОМОБИЛИ',
    'zh': '车辆',
    'ar': 'المركبات',
    'pl': 'POJAZDY',
  }, 'VEHICLES');

  String get tiresTab => tyresName().toUpperCase();

  String get noItemsFound => _t({
    'es': 'No se encontraron elementos',
    'de': 'Keine Elemente gefunden',
    'fr': 'Aucun élément trouvé',
    'it': 'Nessun elemento trovato',
    'pt': 'Nenhum item encontrado',
    'ru': 'Элементы не найдены',
    'zh': '未找到项目',
    'ar': 'لم يتم العثور على عناصر',
    'pl': 'Nie znaleziono elementów',
  }, 'No items found');

  // ══════════════════════════════════════════════════════════
  // ADD VEHICLE SCREEN (add.dart)
  // ══════════════════════════════════════════════════════════

  String get addVehicle => _t({
    'es': 'Agregar Vehículo',
    'de': 'Fahrzeug hinzufügen',
    'fr': 'Ajouter un véhicule',
    'it': 'Aggiungi Veicolo',
    'pt': 'Adicionar Veículo',
    'ru': 'Добавить автомобиль',
    'zh': '添加车辆',
    'ar': 'إضافة مركبة',
    'pl': 'Dodaj pojazd',
  }, 'Add Vehicle');

  String get vehicleNumberRequired => _t({
    'es': 'Número de vehículo *',
    'de': 'Fahrzeugnummer *',
    'fr': 'Numéro de véhicule *',
    'it': 'Numero del veicolo *',
    'pt': 'Número do veículo *',
    'ru': 'Номер автомобиля *',
    'zh': '车牌号 *',
    'ar': 'رقم المركبة *',
    'pl': 'Numer pojazdu *',
  }, 'Vehicle Number *');

  String get vehicleType => _t({
    'es': 'Tipo de vehículo',
    'de': 'Fahrzeugtyp',
    'fr': 'Type de véhicule',
    'it': 'Tipo di veicolo',
    'pt': 'Tipo de veículo',
    'ru': 'Тип автомобиля',
    'zh': '车辆类型',
    'ar': 'نوع المركبة',
    'pl': 'Typ pojazdu',
  }, 'Vehicle Type');

  String get make => _t({
    'es': 'Marca',
    'de': 'Marke',
    'fr': 'Marque',
    'it': 'Marca',
    'pt': 'Marca',
    'ru': 'Марка',
    'zh': '品牌',
    'ar': 'الشركة المصنعة',
    'pl': 'Marka',
  }, 'Make');

  String get model => _t({
    'es': 'Modelo',
    'de': 'Modell',
    'fr': 'Modèle',
    'it': 'Modello',
    'pt': 'Modelo',
    'ru': 'Модель',
    'zh': '型号',
    'ar': 'الموديل',
    'pl': 'Model',
  }, 'Model');

  String get axleConfig => _t({
    'es': 'Configuración de ejes',
    'de': 'Achskonfiguration',
    'fr': 'Configuration des essieux',
    'it': 'Configurazione assi',
    'pt': 'Configuração do eixo',
    'ru': 'Конфигурация осей',
    'zh': '车桥配置',
    'ar': 'تكوين المحاور',
    'pl': 'Konfiguracja osi',
  }, 'Axle Config');

  String get tireSize => _t({
    'es': 'Tamaño de ${tyreName().toLowerCase()}',
    'de': '${tyreName()}größe',
    'fr': 'Taille du ${tyreName().toLowerCase()}',
    'it': 'Misura del ${tyreName().toLowerCase()}',
    'pt': 'Tamanho do ${tyreName().toLowerCase()}',
    'ru': 'Размер шины',
    'zh': '${tyreName()}尺寸',
    'ar': 'مقاس ${tyreName()}',
    'pl': 'Rozmiar ${tyreName().toLowerCase()}',
  }, '${tyreName()} Size');

  String get kilometers => _t({
    'es': 'Kilómetros',
    'de': 'Kilometer',
    'fr': 'Kilomètres',
    'it': 'Chilometri',
    'pt': 'Quilômetros',
    'ru': 'Километры',
    'zh': '公里',
    'ar': 'كيلومترات',
    'pl': 'Kilometry',
  }, 'Kilometers');

  String get comments => _t({
    'es': 'Comentarios',
    'de': 'Kommentare',
    'fr': 'Commentaires',
    'it': 'Commenti',
    'pt': 'Comentários',
    'ru': 'Комментарии',
    'zh': '备注',
    'ar': 'تعليقات',
    'pl': 'Komentarze',
  }, 'Comments');

  String get commentsHint => _t({
    'es': 'Comentarios aquí (Máximo 200 caracteres)',
    'de': 'Kommentare hier eingeben (Max. 200 Zeichen)',
    'fr': 'Les commentaires vont ici (Max 200 caractères)',
    'it': 'Inserisci qui i commenti (Max 200 caratteri)',
    'pt': 'Comentários aqui (Máximo 200 caracteres)',
    'ru': 'Введите комментарии (до 200 символов)',
    'zh': '在此输入备注（最多200字符）',
    'ar': 'اكتب التعليقات هنا (بحد أقصى 200 حرف)',
    'pl': 'Wpisz komentarz (Maksymalnie 200 znaków)',
  }, 'Comments go here (Max 200 characters)');

  String get required => _t({
    'es': 'Requerido',
    'de': 'Erforderlich',
    'fr': 'Requis',
    'it': 'Obbligatorio',
    'pt': 'Obrigatório',
    'ru': 'Обязательно',
    'zh': '必填',
    'ar': 'مطلوب',
    'pl': 'Wymagane',
  }, 'Required');

  String get success => _t({
    'es': 'Éxito',
    'de': 'Erfolg',
    'fr': 'Succès',
    'it': 'Successo',
    'pt': 'Sucesso',
    'ru': 'Успешно',
    'zh': '成功',
    'ar': 'نجاح',
    'pl': 'Sukces',
  }, 'Success');

  String vehicleAddedSuccessfully(String vehicleNo) => _t({
    'es': 'Vehículo $vehicleNo agregado con éxito.',
    'de': 'Fahrzeug $vehicleNo erfolgreich hinzugefügt.',
    'fr': 'Véhicule $vehicleNo ajouté avec succès.',
    'it': 'Veicolo $vehicleNo aggiunto con successo.',
    'pt': 'Veículo $vehicleNo adicionado com sucesso.',
    'ru': 'Автомобиль $vehicleNo успешно добавлен.',
    'zh': '车辆 $vehicleNo 添加成功。',
    'ar': 'تمت إضافة المركبة $vehicleNo بنجاح.',
    'pl': 'Pojazd $vehicleNo został pomyślnie dodany.',
  }, 'Vehicle $vehicleNo added successfully.');

  // ══════════════════════════════════════════════════════════
  // TYRE SCREEN (tyre.dart)
  // ══════════════════════════════════════════════════════════

  String get tireInspectionDetails => _t({
    'es': 'Detalles de inspección de ${tyreName().toLowerCase()}',
    'de': '${tyreName()}-Inspektionsdetails',
    'fr': 'Détails de l\'inspection du ${tyreName().toLowerCase()}',
    'it': 'Dettagli ispezione ${tyreName().toLowerCase()}',
    'pt': 'Detalhes da inspeção do ${tyreName().toLowerCase()}',
    'ru': 'Детали инспекции шины',
    'zh': '${tyreName()}检查详情',
    'ar': 'تفاصيل فحص ${tyreName()}',
    'pl': 'Szczegóły inspekcji ${tyreName().toLowerCase()}',
  }, '${tyreName()} Inspection Details');

  String get vehicleNumberLabel => _t({
    'es': 'Número de vehículo:',
    'de': 'Fahrzeugnummer:',
    'fr': 'Numéro de véhicule :',
    'it': 'Numero veicolo:',
    'pt': 'Número do veículo:',
    'ru': 'Номер автомобиля:',
    'zh': '车牌号：',
    'ar': 'رقم المركبة:',
    'pl': 'Numer pojazdu:',
  }, 'Vehicle Number:');

  String get tireSerialNumberLabel => _t({
    'es': 'Número de serie de ${tyreName().toLowerCase()}:',
    'de': '${tyreName()}-Seriennummer:',
    'fr': 'Numéro de série du ${tyreName().toLowerCase()} :',
    'it': 'Numero di serie del ${tyreName().toLowerCase()}:',
    'pt': 'Número de série do ${tyreName().toLowerCase()}:',
    'ru': 'Серийный номер шины:',
    'zh': '${tyreName()}序列号：',
    'ar': 'الرقم التسلسلي لـ ${tyreName()}:',
    'pl': 'Numer seryjny ${tyreName().toLowerCase()}:',
  }, '${tyreName()} Serial Number:');

  String get wheelPositionLabel => _t({
    'es': 'Posición de rueda:',
    'de': 'Radposition:',
    'fr': 'Position de la roue :',
    'it': 'Posizione ruota:',
    'pt': 'Posição da roda:',
    'ru': 'Позиция колеса:',
    'zh': '轮位：',
    'ar': 'موضع العجلة:',
    'pl': 'Pozycja koła:',
  }, 'Wheel Position:');

  String get lastInspectionLabel => _t({
    'es': 'Última inspección:',
    'de': 'Letzte Inspektion:',
    'fr': 'Dernière inspection :',
    'it': 'Ultima ispezione:',
    'pt': 'Última inspeção:',
    'ru': 'Последняя инспекция:',
    'zh': '上次检查：',
    'ar': 'آخر فحص:',
    'pl': 'Ostatnia inspekcja:',
  }, 'Last Inspection:');

  String get treadDepthInformation => _t({
    'es': 'Información de profundidad de banda',
    'de': 'Profiltiefen-Informationen',
    'fr': 'Informations sur la profondeur de sculpture',
    'it': 'Informazioni profondità battistrada',
    'pt': 'Informações de profundidade do piso',
    'ru': 'Информация о глубине протектора',
    'zh': '花纹深度信息',
    'ar': 'معلومات عمق المداس',
    'pl': 'Informacje o głębokości bieżnika',
  }, 'Tread Depth Information');

  String get airPressureAndConditions => _t({
    'es': 'Presión de aire y condiciones',
    'de': 'Luftdruck & Bedingungen',
    'fr': 'Pression d\'air et conditions',
    'it': 'Pressione dell\'aria e condizioni',
    'pt': 'Pressão do ar e condições',
    'ru': 'Давление воздуха и условия',
    'zh': '气压和状况',
    'ar': 'ضغط الهواء والحالة',
    'pl': 'Ciśnienie powietrza i stan',
  }, 'Air Pressure & Conditions');

  String get noCommentsProvided => _t({
    'es': 'No se proporcionaron comentarios',
    'de': 'Keine Kommentare angegeben',
    'fr': 'Aucun commentaire fourni',
    'it': 'Nessun commento fornito',
    'pt': 'Nenhum comentário fornecido',
    'ru': 'Комментарии отсутствуют',
    'zh': '未提供备注',
    'ar': 'لم يتم تقديم أي تعليقات',
    'pl': 'Brak komentarzy',
  }, 'No comments provided');

  String get inspectionImages => _t({
    'es': 'Imágenes de inspección',
    'de': 'Inspektionsbilder',
    'fr': 'Images d\'inspection',
    'it': 'Immagini di ispezione',
    'pt': 'Imagens da inspeção',
    'ru': 'Фотографии инспекции',
    'zh': '检查图片',
    'ar': 'صور الفحص',
    'pl': 'Zdjęcia z inspekcji',
  }, 'Inspection Images');

  String get noUploadedImagesHere => _t({
    'es': 'No hay imágenes subidas disponibles aquí',
    'de': 'Hier sind keine hochgeladenen Bilder verfügbar',
    'fr': 'Aucune image téléchargée disponible ici',
    'it': 'Nessuna immagine caricata disponibile qui',
    'pt': 'Nenhuma imagem enviada disponível aqui',
    'ru': 'Здесь нет загруженных изображений',
    'zh': '此处没有可用的已上传图片',
    'ar': 'لا توجد صور محملة متاحة هنا',
    'pl': 'Brak przesłanych zdjęć',
  }, 'No Uploaded Images Available Here');

  // ══════════════════════════════════════════════════════════
  // VEHICLE SCREEN (vehicle.dart)
  // ══════════════════════════════════════════════════════════

  String get getVehicleInspectionData => _t({
    'es': 'Obtener datos de inspección del vehículo',
    'de': 'Fahrzeug-Inspektionsdaten abrufen',
    'fr': 'Obtenir les données d\'inspection du véhicule',
    'it': 'Ottieni dati ispezione veicolo',
    'pt': 'Obter dados de inspeção do veículo',
    'ru': 'Данные инспекции автомобиля',
    'zh': '获取车辆检查数据',
    'ar': 'الحصول على بيانات فحص المركبة',
    'pl': 'Pobierz dane inspekcji pojazdu',
  }, 'Get Vehicle Inspection Data');

  String get vehicleDiagram => _t({
    'es': 'Diagrama del vehículo',
    'de': 'Fahrzeugdiagramm',
    'fr': 'Diagramme du véhicule',
    'it': 'Diagramma del veicolo',
    'pt': 'Diagrama do veículo',
    'ru': 'Схема автомобиля',
    'zh': '车辆示意图',
    'ar': 'مخطط المركبة',
    'pl': 'Schemat pojazdu',
  }, 'Vehicle Diagram');

  String get vehicleComments => _t({
    'es': 'Comentarios del vehículo',
    'de': 'Fahrzeugkommentare',
    'fr': 'Commentaires sur le véhicule',
    'it': 'Commenti del veicolo',
    'pt': 'Comentários do veículo',
    'ru': 'Комментарии к автомобилю',
    'zh': '车辆备注',
    'ar': 'تعليقات المركبة',
    'pl': 'Komentarze do pojazdu',
  }, 'Vehicle Comments');

  String get inspectionComments => _t({
    'es': 'Comentarios de inspección',
    'de': 'Inspektionskommentare',
    'fr': 'Commentaires d\'inspection',
    'it': 'Commenti di ispezione',
    'pt': 'Comentários de inspeção',
    'ru': 'Комментарии к проверке',
    'zh': '检查备注',
    'ar': 'تعليقات الفحص',
    'pl': 'Komentarze do kontroli',
  }, 'Inspection Comments');

  String get approverNote => _t({
    'es': 'Nota del aprobador',
    'de': 'Genehmiger-Hinweis',
    'fr': 'Note de l\'approbateur',
    'it': 'Nota dell\'approvatore',
    'pt': 'Nota do aprovador',
    'ru': 'Примечание утверждающего',
    'zh': '审批人备注',
    'ar': 'ملاحظة المعتمد',
    'pl': 'Uwaga zatwierdzającego',
  }, 'Approver Note');

  String get vehicleNumber => _t({
    'es': 'Número de vehículo',
    'de': 'Fahrzeugnummer',
    'fr': 'Numéro de véhicule',
    'it': 'Numero del veicolo',
    'pt': 'Número do veículo',
    'ru': 'Номер автомобиля',
    'zh': '车牌号',
    'ar': 'رقم المركبة',
    'pl': 'Numer pojazdu',
  }, 'Vehicle Number');

  String get hours => _t({
    'es': 'Horas',
    'de': 'Stunden',
    'fr': 'Heures',
    'it': 'Ore',
    'pt': 'Horas',
    'ru': 'Часы',
    'zh': '小时',
    'ar': 'ساعات',
    'pl': 'Godziny',
  }, 'Hours');

  String get approve => _t({
    'es': 'Aprobar',
    'de': 'Genehmigen',
    'fr': 'Approuver',
    'it': 'Approva',
    'pt': 'Aprovar',
    'ru': 'Одобрить',
    'zh': '批准',
    'ar': 'موافقة',
    'pl': 'Zatwierdź',
  }, 'Approve');

  String get reject => _t({
    'es': 'Rechazar',
    'de': 'Ablehnen',
    'fr': 'Rejeter',
    'it': 'Rifiuta',
    'pt': 'Rejeitar',
    'ru': 'Отклонить',
    'zh': '驳回',
    'ar': 'رفض',
    'pl': 'Odrzuć',
  }, 'Reject');

  String get approveInspection => _t({
    'es': 'Aprobar inspección',
    'de': 'Inspektion genehmigen',
    'fr': 'Approuver l\'inspection',
    'it': 'Approva ispezione',
    'pt': 'Aprovar inspeção',
    'ru': 'Одобрить инспекцию',
    'zh': '批准检查',
    'ar': 'الموافقة على الفحص',
    'pl': 'Zatwierdź inspekcję',
  }, 'Approve Inspection');

  String get rejectInspection => _t({
    'es': 'Rechazar inspección',
    'de': 'Inspektion ablehnen',
    'fr': 'Rejeter l\'inspection',
    'it': 'Rifiuta ispezione',
    'pt': 'Rejeitar inspeção',
    'ru': 'Отклонить инспекцию',
    'zh': '驳回检查',
    'ar': 'رفض الفحص',
    'pl': 'Odrzuć inspekcję',
  }, 'Reject Inspection');

  String get enterRemarkApproval => _t({
    'es': 'Ingrese comentario para aprobación',
    'de': 'Bemerkung zur Genehmigung eingeben',
    'fr': 'Entrez une remarque pour l\'approbation',
    'it': 'Inserisci nota per l\'approvazione',
    'pt': 'Insira a observação para aprovação',
    'ru': 'Введите примечание для одобрения',
    'zh': '输入批准备注',
    'ar': 'أدخل ملاحظة للموافقة',
    'pl': 'Wpisz uwagę do zatwierdzenia',
  }, 'Enter remark for approval');

  String get enterReasonRejection => _t({
    'es': 'Ingrese motivo de rechazo',
    'de': 'Grund für die Ablehnung eingeben',
    'fr': 'Entrez le motif du rejet',
    'it': 'Inserisci motivo del rifiuto',
    'pt': 'Insira o motivo da rejeição',
    'ru': 'Введите причину отклонения',
    'zh': '输入驳回原因',
    'ar': 'أدخل سبب الرفض',
    'pl': 'Wpisz powód odrzucenia',
  }, 'Enter reason for rejection');

  String get remarkIsRequired => _t({
    'es': 'El comentario es obligatorio',
    'de': 'Bemerkung ist erforderlich',
    'fr': 'La remarque est requise',
    'it': 'La nota è obbligatoria',
    'pt': 'A observação é obrigatória',
    'ru': 'Примечание обязательно',
    'zh': '必须填写备注',
    'ar': 'الملاحظة مطلوبة',
    'pl': 'Uwaga jest wymagana',
  }, 'Remark is required');

  String get vehicleAndTiresApproved => _t({
    'es': 'El vehículo y sus ${tyresName().toLowerCase()} han sido aprobados.',
    'de': 'Das Fahrzeug und seine ${tyresName()} wurden genehmigt.',
    'fr': 'Le véhicule et ses ${tyresName().toLowerCase()} ont été approuvés.',
    'it': 'Il veicolo e i suoi ${tyresName().toLowerCase()} sono stati approvati.',
    'pt': 'O veículo e seus ${tyresName().toLowerCase()} foram aprovados.',
    'ru': 'Автомобиль и его шины одобрены.',
    'zh': '车辆及其${tyresName()}已获批准。',
    'ar': 'تمت الموافقة على المركبة و${tyresName()}ها.',
    'pl': 'Pojazd i jego ${tyresName().toLowerCase()} zostały zatwierdzone.',
  }, 'Vehicle and its ${tyresName().toLowerCase()} have been approved.');

  String get vehicleAndTiresRejected => _t({
    'es': 'El vehículo y sus ${tyresName().toLowerCase()} han sido rechazados.',
    'de': 'Das Fahrzeug und seine ${tyresName()} wurden abgelehnt.',
    'fr': 'Le véhicule et ses ${tyresName().toLowerCase()} ont été rejetés.',
    'it': 'Il veicolo e i suoi ${tyresName().toLowerCase()} sono stati rifiutati.',
    'pt': 'O veículo e seus ${tyresName().toLowerCase()} foram rejeitados.',
    'ru': 'Автомобиль и его шины отклонены.',
    'zh': '车辆及其${tyresName()}已被驳回。',
    'ar': 'تم رفض المركبة و${tyresName()}ها.',
    'pl': 'Pojazd i jego ${tyresName().toLowerCase()} zostały odrzucone.',
  }, 'Vehicle and its ${tyresName().toLowerCase()} have been rejected.');

  String get remarkLabel => _t({
    'es': 'Comentario:',
    'de': 'Bemerkung:',
    'fr': 'Remarque :',
    'it': 'Nota:',
    'pt': 'Observação:',
    'ru': 'Примечание:',
    'zh': '备注：',
    'ar': 'ملاحظة:',
    'pl': 'Uwaga:',
  }, 'Remark:');

  String get notAllowedPermission => _t({
    'es': 'No tiene permiso para aprobar o rechazar esta inspección.',
    'de': 'Sie haben keine Berechtigung, diese Inspektion zu genehmigen oder abzulehnen.',
    'fr': 'Vous n\'avez pas l\'autorisation d\'approuver ou de rejeter cette inspection.',
    'it': 'Non hai i permessi per approvare o rifiutare questa ispezione.',
    'pt': 'Você não tem permissão para aprovar ou rejeitar esta inspeção.',
    'ru': 'У вас нет разрешения на одобрение или отклонение этой инспекции.',
    'zh': '您无权批准或驳回此检查。',
    'ar': 'ليس لديك إذن للموافقة على هذا الفحص أو رفضه.',
    'pl': 'Nie masz uprawnień do zatwierdzenia lub odrzucenia tej inspekcji.',
  }, 'You do not have permission to approve or reject this inspection.');

  String get invalidInspectionId => _t({
    'es': 'No se encontró un ID de estado de inspección válido. Vuelva a seleccionar de la lista pendiente.',
    'de': 'Gültige Inspektionsstatus-ID nicht gefunden. Bitte erneut aus der Liste auswählen.',
    'fr': 'ID de statut d\'inspection valide introuvable. Veuillez sélectionner à nouveau dans la liste.',
    'it': 'ID stato ispezione valido non trovato. Seleziona nuovamente dall\'elenco in sospeso.',
    'pt': 'ID de status de inspeção válido não encontrado. Selecione novamente na lista pendente.',
    'ru': 'Не найден действительный ID инспекции. Выберите заново из списка.',
    'zh': '未找到有效的检查状态ID。请从待处理列表中重新选择。',
    'ar': 'لم يتم العثور على معرف صالح لحالة الفحص. يرجى إعادة التحديد من القائمة المعلقة.',
    'pl': 'Nie znaleziono prawidłowego identyfikatora inspekcji. Wybierz ponownie z listy oczekujących.',
  }, 'Valid Inspection Status ID not found. Please re-select from the pending list.');

  String get failedToApprove => _t({
    'es': 'Error al aprobar la inspección',
    'de': 'Inspektion konnte nicht genehmigt werden',
    'fr': 'Échec de l\'approbation de l\'inspection',
    'it': 'Impossibile approvare l\'ispezione',
    'pt': 'Falha ao aprovar a inspeção',
    'ru': 'Не удалось одобрить инспекцию',
    'zh': '批准检查失败',
    'ar': 'فشل في الموافقة على الفحص',
    'pl': 'Nie udało się zatwierdzić inspekcji',
  }, 'Failed to approve inspection');

  String get failedToReject => _t({
    'es': 'Error al rechazar la inspección',
    'de': 'Inspektion konnte nicht abgelehnt werden',
    'fr': 'Échec du rejet de l\'inspection',
    'it': 'Impossibile rifiutare l\'ispezione',
    'pt': 'Falha ao rejeitar a inspeção',
    'ru': 'Не удалось отклонить инспекцию',
    'zh': '驳回检查失败',
    'ar': 'فشل في رفض الفحص',
    'pl': 'Nie udało się odrzucić inspekcji',
  }, 'Failed to reject inspection');

  String get notAllowed => _t({
    'es': 'No permitido',
    'de': 'Nicht erlaubt',
    'fr': 'Non autorisé',
    'it': 'Non consentito',
    'pt': 'Não permitido',
    'ru': 'Не разрешено',
    'zh': '不允许',
    'ar': 'غير مسموح',
    'pl': 'Niedozwolone',
  }, 'Not Allowed');

  String get error => _t({
    'es': 'Error',
    'de': 'Fehler',
    'fr': 'Erreur',
    'it': 'Errore',
    'pt': 'Erro',
    'ru': 'Ошибка',
    'zh': '错误',
    'ar': 'خطأ',
    'pl': 'Błąd',
  }, 'Error');

  String get cancel => _t({
    'es': 'Cancelar',
    'de': 'Abbrechen',
    'fr': 'Annuler',
    'it': 'Annulla',
    'pt': 'Cancelar',
    'ru': 'Отмена',
    'zh': '取消',
    'ar': 'إلغاء',
    'pl': 'Anuluj',
  }, 'Cancel');

  // ══════════════════════════════════════════════════════════
  // HOME SCREEN (home_view.dart)
  // ══════════════════════════════════════════════════════════

  String get vehiclesTiresInspections => _t({
    'es': 'Inspecciones de Vehículos / ${tyresName()}',
    'de': 'Fahrzeug- / ${tyresName()}inspektionen',
    'fr': 'Inspections Véhicules / ${tyresName()}',
    'it': 'Ispezioni Veicoli / ${tyresName()}',
    'pt': 'Inspeções de Veículos / ${tyresName()}',
    'ru': 'Инспекции ТС / ${tyresName()}',
    'zh': '车辆 / ${tyresName()}检查',
    'ar': 'فحوصات المركبات / ${tyresName()}',
    'pl': 'Inspekcje Pojazdów / ${tyresName()}',
  }, 'Vehicles / ${tyresName()} Inspections');

  String get vehicleInspection => _t({
    'es': 'Inspección de vehículo',
    'de': 'Fahrzeuginspektion',
    'fr': 'Inspection de véhicule',
    'it': 'Ispezione veicolo',
    'pt': 'Inspeção de veículo',
    'ru': 'Инспекция ТС',
    'zh': '车辆检查',
    'ar': 'فحص المركبة',
    'pl': 'Inspekcja pojazdu',
  }, 'Vehicle Inspection');

  String get tireInspection => _t({
    'es': 'Inspección de ${tyreName().toLowerCase()}',
    'de': '${tyreName()}inspektion',
    'fr': 'Inspection de ${tyreName().toLowerCase()}',
    'it': 'Ispezione ${tyreName().toLowerCase()}',
    'pt': 'Inspeção de ${tyreName().toLowerCase()}',
    'ru': 'Инспекция шины',
    'zh': '${tyreName()}检查',
    'ar': 'فحص ${tyreName()}',
    'pl': 'Inspekcja ${tyreName().toLowerCase()}',
  }, '${tyreName()} Inspection');

  String get viewAction => _t({
    'es': 'ver >',
    'de': 'anzeigen >',
    'fr': 'voir >',
    'it': 'visualizza >',
    'pt': 'ver >',
    'ru': 'просмотр >',
    'zh': '查看 >',
    'ar': 'عرض >',
    'pl': 'zobacz >',
  }, 'view >');
}


