// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'OpenCaller';

  @override
  String get appSubtitle =>
      'El Identificador de Llamadas 100% Libre, Privado y Comunitario';

  @override
  String get statusOnline => 'EN LÍNEA';

  @override
  String get statusOffline => 'MODO DESCONECTADO';

  @override
  String get statusSyncing => 'SINCRONIZANDO';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get navHistory => 'Historial';

  @override
  String get navLookup => 'Búsqueda';

  @override
  String get navShield => 'Escudo';

  @override
  String get navPrivacy => 'Privacidad';

  @override
  String get historyTitle => 'Actividad de Llamadas';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterSpam => 'Spam';

  @override
  String get filterBlocked => 'Bloqueadas';

  @override
  String get filterUnknown => 'Desconocidas';

  @override
  String get emptyHistoryTitle => 'Sin llamadas registradas';

  @override
  String get emptyHistorySubtitle =>
      'Tus llamadas entrantes e interceptadas aparecerán aquí en tiempo real.';

  @override
  String get incomingCall => 'Llamada Entrante';

  @override
  String get outgoingCall => 'Llamada Saliente';

  @override
  String get missedCall => 'Llamada Perdida';

  @override
  String get blockedCall => 'Bloqueada Automáticamente';

  @override
  String get blockNumber => 'Bloquear Número';

  @override
  String get reportSpam => 'Reportar Spam';

  @override
  String get lookupTitle => 'Búsqueda Inversa de Teléfonos';

  @override
  String get searchHint => 'Buscar número telefónico E.164...';

  @override
  String get searchButton => 'Buscar';

  @override
  String get searching => 'Buscando...';

  @override
  String couldBeHint(String name) {
    return 'Podría ser: $name';
  }

  @override
  String probableMatch(String name) {
    return 'Probable: $name';
  }

  @override
  String get verifiedBusiness => 'Negocio Verificado';

  @override
  String get communityVerified => 'Consenso Comunitario';

  @override
  String get badgeCommunityHint => 'HINT COMUNITARIO (1 SUGERENCIA) 35% conf.';

  @override
  String get badgeProbableMatch => 'IDENTIFICADOR PROBABLE 65% conf.';

  @override
  String get badgeConsensusVerified => 'CONSENSO VERIFICADO 90% conf.';

  @override
  String get badgeVerifiedBusiness => 'NEGOCIO VERIFICADO 100% conf.';

  @override
  String get spamSevere => 'SPAM SEVERO DETECTADO';

  @override
  String get spamSuspicious => 'NÚMERO SOSPECHOSO';

  @override
  String get spamClean => 'NÚMERO LIMPIO';

  @override
  String spamScore(int score) {
    return 'Puntaje Spam: $score%';
  }

  @override
  String reportsCount(int count) {
    return '$count reportes';
  }

  @override
  String reportSheetTitle(String number) {
    return 'Reportar Número: $number';
  }

  @override
  String get reportReason => 'Motivo / Categoría';

  @override
  String get categoryScam => 'Fraude / Extorsión';

  @override
  String get categoryTelemarketing => 'Telemarketing / Ventas';

  @override
  String get categoryDebtCollector => 'Cobro Judicial / Agresivo';

  @override
  String get categoryRobocall => 'Robocall Automatizado';

  @override
  String get submitReport => 'Enviar Reporte';

  @override
  String get reportSubmitted =>
      '¡Reporte registrado con éxito! Gracias por proteger a la comunidad.';

  @override
  String get shieldTitle => 'Escudo de Defensa Telefónica';

  @override
  String get protectionActive => 'Protección en Tiempo Real Activa';

  @override
  String get protectionInactive => 'Protección Desactivada';

  @override
  String get screeningRole => 'Intercepción Nativa de Llamadas';

  @override
  String get screeningRoleGranted => 'Rol CallScreening de Android concedido';

  @override
  String get screeningRoleNeeded => 'Toca para activar intercepción nativa';

  @override
  String get grantRoleButton => 'Conceder Permiso Nativo';

  @override
  String get spamThreshold => 'Umbral de Auto-Bloqueo';

  @override
  String spamThresholdDesc(int threshold) {
    return 'Las llamadas con puntaje spam igual o superior al $threshold% se silenciarán y rechazarán automáticamente sin sonar.';
  }

  @override
  String get localDatabase => 'Base de Datos Local Offline';

  @override
  String localNumbersCount(int count) {
    return '$count números conocidos en el dispositivo';
  }

  @override
  String get syncButton => 'Sincronizar Ahora';

  @override
  String get syncInProgress =>
      'Sincronizando actualizaciones delta con nodo federado...';

  @override
  String get syncSuccess => '¡Base de datos sincronizada exitosamente!';

  @override
  String get privacyTitle => 'Centro de Soberanía y Privacidad';

  @override
  String get privacyManifesto => 'Garantía de Cero Rastreo';

  @override
  String get privacyManifestoDesc =>
      'OpenCaller jamás vende, comercializa ni comparte tus contactos o llamadas. Tus datos residen en tu dispositivo o en tu propio servidor.';

  @override
  String get sovereigntyTierTitle => 'Nivel de Soberanía Actual';

  @override
  String get tier0Name => 'Nivel 0 — Escudo Local Desconectado';

  @override
  String get tier0Desc =>
      'Cero llamadas a la red. Consulta SQLite local en <10ms.';

  @override
  String get tier1Name => 'Nivel 1 — Inteligencia en la Nube';

  @override
  String get tier1Desc =>
      'Consulta base de datos comunitaria para números desconocidos.';

  @override
  String get tier2Name => 'Nivel 2 — Colaborador Comunitario Híbrido';

  @override
  String get tier2Desc =>
      'Aporta voluntariamente contactos no favoritos al directorio libre.';

  @override
  String get changeTier => 'Cambiar Nivel de Soberanía';

  @override
  String get reopenOnboarding => 'Revisitar Asistente de Inicio';

  @override
  String get reopenOnboardingDesc =>
      'Vuelve a ejecutar el asistente de configuración guiada cuando lo desees.';

  @override
  String get reopenOnboardingButton => 'Lanzar Asistente';

  @override
  String get languageTitle => 'Idioma de la Aplicación';

  @override
  String get languageSystem => 'Predeterminado del Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get delistTitle => 'Derecho al Olvido (Delist)';

  @override
  String get delistDesc =>
      'Elimina permanentemente tu número de la base global de OpenCaller y bloquéalo de futuras ingestiones.';

  @override
  String get delistNumberHint => 'Número E.164 a eliminar...';

  @override
  String get delistReasonHint => 'Motivo (ej. El titular solicita remoción)';

  @override
  String get delistButton => 'Solicitar Delist Permanente';

  @override
  String get delistSuccess => 'Número purgado y bloqueado exitosamente.';

  @override
  String get onboardingWelcomeTitle => 'OpenCaller';

  @override
  String get onboardingWelcomeSubtitle =>
      'El Identificador de Llamadas 100% Libre, Privado y Comunitario';

  @override
  String get onboardingFeature1Title => 'Detección Local Instantánea (<10ms)';

  @override
  String get onboardingFeature1Desc =>
      'Tu dispositivo consulta una base de datos local SQLite antes de que suene el teléfono. Cero latencia y cero llamadas a la nube para números conocidos.';

  @override
  String get onboardingFeature2Title => 'Cero Rastreo Comercial';

  @override
  String get onboardingFeature2Desc =>
      'Sin SDKs de Facebook ni Google Ads. Tu historial y libreta jamás se venden. 100% código abierto bajo licencia MIT.';

  @override
  String get onboardingFeature3Title => 'Poder Comunitario Federado';

  @override
  String get onboardingFeature3Desc =>
      'Una red descentralizada donde los usuarios colaboran y verifican números con consenso democrático y gradual.';

  @override
  String get onboardingStartButton => 'Comenzar Configuración';

  @override
  String get onboardingTierHeader => 'Elige tu Nivel de Privacidad';

  @override
  String get onboardingTierNotice =>
      'Puedes modificar esta preferencia en cualquier momento desde Ajustes. Nunca compartiremos tus contactos sin tu consentimiento explícito.';

  @override
  String get onboardingVerifyHeader => 'Verificación de Cuenta';

  @override
  String get onboardingVerifyDesc =>
      'OpenCaller es 100% libre y comunitario. Para evitar bots y abusos, verifica tu cuenta sin costo utilizando tu método preferido:';

  @override
  String get onboardingVerifyOptionTelegram =>
      'Bot de Telegram (@OpenCallerVerifyBot)';

  @override
  String get onboardingVerifyOptionTelegramDesc =>
      'Contacto respaldado por SIM. 100% gratuito e inmune a números virtuales.';

  @override
  String get onboardingVerifyOptionWhatsApp =>
      'WhatsApp (Baileys Auto-alojado)';

  @override
  String get onboardingVerifyOptionWhatsAppDesc =>
      'Recibe un código OTP de 6 dígitos directamente en tu chat de WhatsApp.';

  @override
  String get onboardingVerifyOptionAndroid => 'Gateway Android Auto-alojado';

  @override
  String get onboardingVerifyOptionAndroidDesc =>
      'Llamada flash de cero timbres o SMS local desde un nodo Android propio.';

  @override
  String get onboardingVerifyOptionPoW =>
      'Prueba de Trabajo Anónima (Sin Teléfono)';

  @override
  String get onboardingVerifyOptionPoWDesc =>
      'Atestación de hardware del dispositivo + desafío criptográfico. Anonimato total.';

  @override
  String get onboardingPhoneNumber => 'Número de Teléfono (E.164)';

  @override
  String get onboardingSendCode => 'Solicitar Código';

  @override
  String get onboardingEnterCode => 'Ingresar código OTP de 6 dígitos';

  @override
  String get onboardingVerifyCode => 'Validar Código OTP';

  @override
  String get onboardingRunPoW => 'Ejecutar Desafío Criptográfico';

  @override
  String onboardingVerifiedStatus(String label) {
    return 'Verificado: $label';
  }

  @override
  String get onboardingTelephonyHeader => 'Blindaje de Telefonía Nativa';

  @override
  String get onboardingTelephonyDesc =>
      'Para interceptar y silenciar llamadas fraudulentas antes de que suene tu teléfono, OpenCaller requiere el rol CallScreening del sistema Android.';

  @override
  String get onboardingGrantRole => 'Activar Defensa Telefónica';

  @override
  String get onboardingSkip => 'Omitir por Ahora';

  @override
  String get onboardingReadyHeader => '¡Todo Listo para Defenderte!';

  @override
  String get onboardingReadyDesc =>
      'OpenCaller está configurado y protegiendo tus llamadas entrantes con total soberanía y privacidad.';

  @override
  String get onboardingEnterApp => 'Ingresar a OpenCaller';

  @override
  String get crowdsourcingControls => 'CONTROLES DE APORTE COMUNITARIO';

  @override
  String get shareContactsTitle =>
      'Compartir Contactos con el Directorio Comunitario';

  @override
  String get shareContactsDesc =>
      'Ayuda a identificar negocios locales y repartidores. Se requiere consenso estricto de 3 votos antes de publicar.';

  @override
  String get excludeStarredTitle => 'Excluir Contactos Destacados / Familiares';

  @override
  String get excludeStarredDesc =>
      'Amigos cercanos y favoritos nunca se transmiten bajo ninguna circunstancia.';

  @override
  String get stripMetadataTitle => 'Eliminar Metadatos Privados';

  @override
  String get stripMetadataDesc =>
      'Correos electrónicos, direcciones físicas, cumpleaños y notas personales se mantienen exclusivamente en tu dispositivo.';

  @override
  String get consentModalTitle => 'Acuerdo de Privacidad de Aporte Comunitario';

  @override
  String get consentModalDesc =>
      '• Consenso Estricto: Un nombre solo se hace visible cuando 3 o más usuarios independientes coinciden.\n• Cero Datos Personales: Correos, fotos y direcciones físicas NUNCA se acceden ni se transmiten.\n• Derecho al Olvido: Cualquiera puede dar de baja su número en cualquier momento.';

  @override
  String get consentModalAgree => 'Entiendo y Doy mi Consentimiento';

  @override
  String get consentModalFeedback =>
      'Aporte comunitario habilitado con salvaguardas de privacidad.';

  @override
  String get shieldHeaderTitle => 'Escudo de Llamadas Nativo';

  @override
  String get shieldHeaderDesc =>
      'OpenCaller se ejecuta localmente para filtrar llamadas entrantes con latencia cero y sin fuga de datos.';

  @override
  String get shieldAndroidRoleTitle => 'Rol de Filtrado de Llamadas Android';

  @override
  String get shieldStatusActive => 'ACTIVO';

  @override
  String get shieldStatusActionRequired => 'ACCIÓN REQUERIDA';

  @override
  String get shieldStatusPending => 'PENDIENTE';

  @override
  String get shieldAndroidRoleDesc =>
      'Android requiere otorgar el rol de Filtrado de Llamadas para permitir a OpenCaller consultar la base de datos local SQLite de forma síncrona (<150ms) y silenciar o bloquear llamadas de spam antes de que suene tu teléfono.';

  @override
  String get shieldSetRoleButton => 'Configurar como App de Filtrado';

  @override
  String get shieldActiveOnDevice =>
      'Filtrado en tiempo real activo en este dispositivo';

  @override
  String get shieldIOSRoleTitle => 'Extensión Call Directory de iOS';

  @override
  String get shieldIOSEnabled => 'HABILITADO';

  @override
  String get shieldIOSSetupNeeded => 'CONFIGURACIÓN NECESARIA';

  @override
  String get shieldIOSDesc =>
      'En iOS, OpenCaller carga números de spam y comunitarios en la base telefónica de iOS mediante CallKit. Apple requiere activar esta extensión una vez en los Ajustes del Sistema.';

  @override
  String get shieldIOSInstructions =>
      'Instrucciones:\n1. Toca \"Abrir Ajustes de iPhone\" abajo.\n2. Ve a Teléfono > Bloqueo e ID de llamadas.\n3. Activa \"OpenCaller\".';

  @override
  String get shieldIOSOpenSettings => 'Abrir Ajustes de iPhone';

  @override
  String get shieldIOSRefresh => 'Actualizar Estado / Recargar Extensión';

  @override
  String get shieldDeviceRequirement =>
      'El filtrado telefónico requiere un dispositivo físico Android o iOS.';

  @override
  String get unidentifiedCaller => 'Número No Identificado';

  @override
  String get noRecords => 'SIN REGISTRO';

  @override
  String get protectedDelisted => 'PROTEGIDO';

  @override
  String get privateDelistedNumber => 'Número Privado / Retirado';

  @override
  String get delistedNote => 'Este número ejerció su derecho a ser olvidado.';

  @override
  String get communityHintNote =>
      'Sugerido por 1 colaborador comunitario. Usar con precaución.';

  @override
  String get probableMatchNote => 'Confirmado por 2 usuarios independientes.';

  @override
  String get consensusVerifiedNote =>
      'Consenso comunitario de 3+ colaboradores alcanzado.';

  @override
  String get metricCategory => 'Categoría';

  @override
  String get metricReports => 'Reportes';

  @override
  String get statusCleanBadge => 'LIMPIO';

  @override
  String get statusBlocked => 'BLOQUEADO';

  @override
  String get unknownCaller => 'Llamada Desconocida';

  @override
  String syncCompleted(int count) {
    return '¡Sincronización completada! Se actualizaron $count números.';
  }

  @override
  String syncFailed(String error) {
    return 'Error en sincronización: $error';
  }

  @override
  String get syncTooltip => 'Sincronizar Base Local de Spam';

  @override
  String get cryptoChallengeTitle => 'Verificación Criptográfica Local';

  @override
  String get cryptoChallengeDesc =>
      'No requiere número de teléfono. Resuelve un Proof-of-Work SHA-256 en ~50ms en tu teléfono para probar que eres un dispositivo real y no un bot.';

  @override
  String get generateAnonymousCredential => 'Generar Credencial Anónima';

  @override
  String get enterPhoneNumber => 'Ingresa tu Número Telefónico';

  @override
  String get requestOtpButton => 'Solicitar Código OTP';

  @override
  String get otpSixDigits => 'Código de 6 Dígitos:';

  @override
  String get verifyCodeButton => 'Verificar Código';

  @override
  String get nextStepButton => 'Siguiente Paso';

  @override
  String get androidCallScreeningServiceDesc =>
      'Permite que el servicio Android CallScreeningService intercepte llamadas entrantes en tiempo real con cero latencia.';

  @override
  String get callScreeningActive => 'Filtro activo y listo en este dispositivo';

  @override
  String get summaryTierLabel => 'Nivel de Privacidad';

  @override
  String get summaryShieldLabel => 'Estado del Blindaje';

  @override
  String get summaryVerifyLabel => 'Verificación';

  @override
  String get summaryConfigurable => 'Configurable en Ajustes';

  @override
  String get summaryGuestMode => 'Modo Invitado';

  @override
  String get summaryVerified => 'Verificado';
}
