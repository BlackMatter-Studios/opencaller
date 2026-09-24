// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'OpenCaller';

  @override
  String get appSubtitle =>
      'O Identificador de Chamadas 100% Livre, Privado e Comunitário';

  @override
  String get statusOnline => 'ONLINE';

  @override
  String get statusOffline => 'MODO DESCONECTADO';

  @override
  String get statusSyncing => 'SINCRONIZANDO';

  @override
  String get close => 'Fechar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get error => 'Erro';

  @override
  String get success => 'Sucesso';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navLookup => 'Busca';

  @override
  String get navShield => 'Escudo';

  @override
  String get navPrivacy => 'Privacidade';

  @override
  String get historyTitle => 'Atividade de Chamadas';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterSpam => 'Spam';

  @override
  String get filterBlocked => 'Bloqueadas';

  @override
  String get filterUnknown => 'Desconhecidas';

  @override
  String get emptyHistoryTitle => 'Nenhuma chamada registrada';

  @override
  String get emptyHistorySubtitle =>
      'Suas chamadas recebidas e filtradas aparecerão aqui em tempo real.';

  @override
  String get incomingCall => 'Chamada Recebida';

  @override
  String get outgoingCall => 'Chamada Efetuada';

  @override
  String get missedCall => 'Chamada Perdida';

  @override
  String get blockedCall => 'Bloqueada Automaticamente';

  @override
  String get blockNumber => 'Bloquear Número';

  @override
  String get reportSpam => 'Denunciar Spam';

  @override
  String get lookupTitle => 'Busca Reversa de Telefones';

  @override
  String get searchHint => 'Buscar número telefônico E.164...';

  @override
  String get searchButton => 'Buscar';

  @override
  String get searching => 'Buscando...';

  @override
  String couldBeHint(String name) {
    return 'Pode ser: $name';
  }

  @override
  String probableMatch(String name) {
    return 'Provável: $name';
  }

  @override
  String get verifiedBusiness => 'Empresa Verificada';

  @override
  String get communityVerified => 'Consenso Comunitário';

  @override
  String get badgeCommunityHint => 'DICA COMUNITÁRIA (1 SUGESTÃO) 35% conf.';

  @override
  String get badgeProbableMatch => 'IDENTIFICADOR PROVÁVEL 65% conf.';

  @override
  String get badgeConsensusVerified => 'CONSENSO VERIFICADO 90% conf.';

  @override
  String get badgeVerifiedBusiness => 'EMPRESA VERIFICADA 100% conf.';

  @override
  String get spamSevere => 'SPAM SEVERO DETECTADO';

  @override
  String get spamSuspicious => 'NÚMERO SUSPEITO';

  @override
  String get spamClean => 'NÚMERO LIMPO';

  @override
  String spamScore(int score) {
    return 'Pontuação de Spam: $score%';
  }

  @override
  String reportsCount(int count) {
    return '$count denúncias';
  }

  @override
  String reportSheetTitle(String number) {
    return 'Denunciar Número: $number';
  }

  @override
  String get reportReason => 'Motivo / Categoria';

  @override
  String get categoryScam => 'Fraude / Golpe';

  @override
  String get categoryTelemarketing => 'Telemarketing / Vendas';

  @override
  String get categoryDebtCollector => 'Cobrança Excessiva';

  @override
  String get categoryRobocall => 'Robocall Automatizado';

  @override
  String get submitReport => 'Enviar Denúncia';

  @override
  String get reportSubmitted =>
      'Denúncia registrada com sucesso! Obrigado por proteger a comunidade.';

  @override
  String get shieldTitle => 'Escudo de Defesa Telefônica';

  @override
  String get protectionActive => 'Proteção em Tempo Real Ativa';

  @override
  String get protectionInactive => 'Proteção Desativada';

  @override
  String get screeningRole => 'Filtragem Nativa de Chamadas';

  @override
  String get screeningRoleGranted =>
      'Função CallScreening do Android concedida';

  @override
  String get screeningRoleNeeded => 'Toque para ativar interceptação nativa';

  @override
  String get grantRoleButton => 'Conceder Permissão Nativa';

  @override
  String get spamThreshold => 'Limite de Bloqueio Automático';

  @override
  String spamThresholdDesc(int threshold) {
    return 'Chamadas com pontuação de spam igual ou superior a $threshold% serão silenciadas e rejeitadas sem tocar.';
  }

  @override
  String get localDatabase => 'Banco de Dados Local Offline';

  @override
  String localNumbersCount(int count) {
    return '$count números conhecidos no dispositivo';
  }

  @override
  String get syncButton => 'Sincronizar Agora';

  @override
  String get syncInProgress =>
      'Sincronizando atualizações delta com nó federado...';

  @override
  String get syncSuccess => 'Banco de dados sincronizado com sucesso!';

  @override
  String get privacyTitle => 'Centro de Soberania e Privacidade';

  @override
  String get privacyManifesto => 'Garantia de Zero Rastreamento';

  @override
  String get privacyManifestoDesc =>
      'O OpenCaller nunca vende nem compartilha seus contatos ou chamadas. Seus dados permanecem no seu dispositivo ou no seu próprio servidor.';

  @override
  String get sovereigntyTierTitle => 'Nível de Soberania Atual';

  @override
  String get tier0Name => 'Nível 0 — Escudo Local Desconectado';

  @override
  String get tier0Desc =>
      'Zero chamadas à rede. Consulta SQLite local em <10ms.';

  @override
  String get tier1Name => 'Nivel 1 — Inteligência na Nuvem';

  @override
  String get tier1Desc =>
      'Consulta banco comunitário para números desconhecidos.';

  @override
  String get tier2Name => 'Nível 2 — Colaborador Comunitário Híbrido';

  @override
  String get tier2Desc =>
      'Contribui voluntariamente com contatos não favoritos ao diretório aberto.';

  @override
  String get changeTier => 'Alterar Nível de Soberania';

  @override
  String get reopenOnboarding => 'Revisitar Assistente Inicial';

  @override
  String get reopenOnboardingDesc =>
      'Execute novamente o assistente de configuração a qualquer momento.';

  @override
  String get reopenOnboardingButton => 'Iniciar Assistente';

  @override
  String get languageTitle => 'Idioma do Aplicativo';

  @override
  String get languageSystem => 'Padrão do Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get delistTitle => 'Direito ao Esquecimento (Delist)';

  @override
  String get delistDesc =>
      'Exclua permanentemente seu número da base global do OpenCaller e bloqueie reimportações.';

  @override
  String get delistNumberHint => 'Número E.164 para remover...';

  @override
  String get delistReasonHint => 'Motivo (ex: Titular solicitou remoção)';

  @override
  String get delistButton => 'Solicitar Remoção Permanente';

  @override
  String get delistSuccess => 'Número purgado e bloqueado com sucesso.';

  @override
  String get onboardingWelcomeTitle => 'OpenCaller';

  @override
  String get onboardingWelcomeSubtitle =>
      'O Identificador de Chamadas 100% Livre, Privado e Comunitário';

  @override
  String get onboardingFeature1Title => 'Detecção Local Instantânea (<10ms)';

  @override
  String get onboardingFeature1Desc =>
      'Seu dispositivo consulta um banco SQLite local antes de o telefone tocar. Zero latência e zero chamadas à nuvem.';

  @override
  String get onboardingFeature2Title => 'Zero Rastreamento Comercial';

  @override
  String get onboardingFeature2Desc =>
      'Sem SDKs do Facebook ou Google Ads. Seu histórico e contatos nunca são vendidos. Código 100% aberto sob licença MIT.';

  @override
  String get onboardingFeature3Title => 'Poder Comunitário Federado';

  @override
  String get onboardingFeature3Desc =>
      'Uma rede descentralizada onde usuários colaboram e verificam números com consenso gradual e democrático.';

  @override
  String get onboardingStartButton => 'Iniciar Configuração';

  @override
  String get onboardingTierHeader => 'Escolha seu Nível de Privacidade';

  @override
  String get onboardingTierNotice =>
      'Você pode alterar essa preferência a qualquer momento em Ajustes. Nunca compartilharemos seus contatos sem sua permissão.';

  @override
  String get onboardingVerifyHeader => 'Verificação de Conta';

  @override
  String get onboardingVerifyDesc =>
      'O OpenCaller é 100% comunitário e gratuito. Para evitar bots e abusos, verifique sua conta a custo zero com seu método favorito:';

  @override
  String get onboardingVerifyOptionTelegram =>
      'Bot do Telegram (@OpenCallerVerifyBot)';

  @override
  String get onboardingVerifyOptionTelegramDesc =>
      'Contato verificado por SIM. 100% gratuito e imune a números virtuais.';

  @override
  String get onboardingVerifyOptionWhatsApp =>
      'WhatsApp (Baileys Auto-hospedado)';

  @override
  String get onboardingVerifyOptionWhatsAppDesc =>
      'Receba um código OTP de 6 dígitos diretamente no seu WhatsApp.';

  @override
  String get onboardingVerifyOptionAndroid => 'Gateway Android Auto-hospedado';

  @override
  String get onboardingVerifyOptionAndroidDesc =>
      'Flash call sem toque ou SMS local a partir de um aparelho Android próprio.';

  @override
  String get onboardingVerifyOptionPoW =>
      'Prova de Trabalho Anônima (Sem Telefone)';

  @override
  String get onboardingVerifyOptionPoWDesc =>
      'Atestação de hardware + desafio criptográfico. Anonimato total.';

  @override
  String get onboardingPhoneNumber => 'Número de Telefone (E.164)';

  @override
  String get onboardingSendCode => 'Solicitar Código';

  @override
  String get onboardingEnterCode => 'Digitar código OTP de 6 dígitos';

  @override
  String get onboardingVerifyCode => 'Validar Código OTP';

  @override
  String get onboardingRunPoW => 'Executar Desafio Criptográfico';

  @override
  String onboardingVerifiedStatus(String label) {
    return 'Verificado: $label';
  }

  @override
  String get onboardingTelephonyHeader => 'Proteção Telefônica Nativa';

  @override
  String get onboardingTelephonyDesc =>
      'Para interceptar chamadas fraudulentas antes de o telefone tocar, o OpenCaller precisa da função CallScreening do Android.';

  @override
  String get onboardingGrantRole => 'Ativar Defesa de Chamadas';

  @override
  String get onboardingSkip => 'Pular por Enquanto';

  @override
  String get onboardingReadyHeader => 'Tudo Pronto!';

  @override
  String get onboardingReadyDesc =>
      'O OpenCaller está configurado e pronto para proteger suas chamadas com total soberania e privacidade.';

  @override
  String get onboardingEnterApp => 'Entrar no OpenCaller';

  @override
  String get crowdsourcingControls => 'CONTROLES DE COLABORAÇÃO COMUNITÁRIA';

  @override
  String get shareContactsTitle =>
      'Compartilhar Contatos com o Diretório Comunitário';

  @override
  String get shareContactsDesc =>
      'Ajude a identificar comércios locais e entregadores. É necessário consenso estrito de 3 votos antes da publicação.';

  @override
  String get excludeStarredTitle => 'Excluir Contatos Favoritos / Família';

  @override
  String get excludeStarredDesc =>
      'Amigos pessoais e favoritos nunca são transmitidos sob nenhuma circunstância.';

  @override
  String get stripMetadataTitle => 'Remover Metadatos Privados';

  @override
  String get stripMetadataDesc =>
      'E-mails, endereços, aniversários e anotações pessoais permanecem estritamente no dispositivo.';

  @override
  String get consentModalTitle =>
      'Termo de Privacidade de Colaboração Comunitária';

  @override
  String get consentModalDesc =>
      '• Consenso Estrito: Um nome só se torna visível após confirmação independente de 3 ou mais usuários.\n• Zero Dados Pessoais: E-mails, fotos e endereços físicos NUNCA são acessados ou transmitidos.\n• Direito ao Esquecimento: Qualquer pessoa pode remover seu número a qualquer momento.';

  @override
  String get consentModalAgree => 'Compreendo e Consinto';

  @override
  String get consentModalFeedback =>
      'Colaboração comunitária ativada com garantias de privacidade.';

  @override
  String get shieldHeaderTitle => 'Escudo de Chamadas Nativo';

  @override
  String get shieldHeaderDesc =>
      'O OpenCaller funciona localmente para filtrar chamadas recebidas com latência zero e sem vazamento de dados.';

  @override
  String get shieldAndroidRoleTitle =>
      'Permissão de Filtragem de Chamadas Android';

  @override
  String get shieldStatusActive => 'ATIVO';

  @override
  String get shieldStatusActionRequired => 'AÇÃO NECESSÁRIA';

  @override
  String get shieldStatusPending => 'PENDENTE';

  @override
  String get shieldAndroidRoleDesc =>
      'O Android exige a permissão de Filtragem de Chamadas para permitir que o OpenCaller consulte o banco de dados local SQLite de forma síncrona (<150ms) e silencie ou bloqueie chamadas de spam antes de o telefone tocar.';

  @override
  String get shieldSetRoleButton => 'Definir como App de Filtragem';

  @override
  String get shieldActiveOnDevice =>
      'Filtragem em tempo real ativa neste dispositivo';

  @override
  String get shieldIOSRoleTitle => 'Extensão Call Directory do iOS';

  @override
  String get shieldIOSEnabled => 'ATIVADO';

  @override
  String get shieldIOSSetupNeeded => 'CONFIGURAÇÃO NECESSÁRIA';

  @override
  String get shieldIOSDesc =>
      'No iOS, o OpenCaller carrega números de spam e comunitários no banco telefônico do iOS via CallKit. A Apple exige ativar esta extensão uma vez nos Ajustes do Sistema.';

  @override
  String get shieldIOSInstructions =>
      'Instruções:\n1. Toque em \"Abrir Ajustes do iPhone\" abaixo.\n2. Vá para Telefone > Bloqueio e ID de Chamada.\n3. Ative o \"OpenCaller\".';

  @override
  String get shieldIOSOpenSettings => 'Abrir Ajustes do iPhone';

  @override
  String get shieldIOSRefresh => 'Atualizar Status / Recarregar Extensão';

  @override
  String get shieldDeviceRequirement =>
      'A filtragem de chamadas requer um dispositivo físico Android ou iOS.';

  @override
  String get unidentifiedCaller => 'Número Não Identificado';

  @override
  String get noRecords => 'SEM REGISTRO';

  @override
  String get protectedDelisted => 'PROTEGIDO';

  @override
  String get privateDelistedNumber => 'Número Privado / Removido';

  @override
  String get delistedNote => 'Este número exerceu seu direito ao esquecimento.';

  @override
  String get communityHintNote =>
      'Sugerido por 1 colaborador comunitário. Use com cuidado.';

  @override
  String get probableMatchNote =>
      'Confirmado por 2 colaboradores independentes.';

  @override
  String get consensusVerifiedNote =>
      'Consenso comunitário de 3+ colaboradores atingido.';

  @override
  String get metricCategory => 'Categoria';

  @override
  String get metricReports => 'Denúncias';

  @override
  String get statusCleanBadge => 'LIMPO';

  @override
  String get statusBlocked => 'BLOQUEADO';

  @override
  String get unknownCaller => 'Chamada Desconhecida';

  @override
  String syncCompleted(int count) {
    return 'Sincronização concluída! $count números atualizados.';
  }

  @override
  String syncFailed(String error) {
    return 'Erro na sincronização: $error';
  }

  @override
  String get syncTooltip => 'Sincronizar Banco Local de Spam';

  @override
  String get cryptoChallengeTitle => 'Verificação Criptográfica Local';

  @override
  String get cryptoChallengeDesc =>
      'Não requer número de telefone. Resolve um desafio Proof-of-Work SHA-256 em ~50ms no seu dispositivo para comprovar que você é um usuário autêntico.';

  @override
  String get generateAnonymousCredential => 'Gerar Credencial Anônima';

  @override
  String get enterPhoneNumber => 'Digite seu Número de Telefone';

  @override
  String get requestOtpButton => 'Solicitar Código OTP';

  @override
  String get otpSixDigits => 'Código de 6 Dígitos:';

  @override
  String get verifyCodeButton => 'Validar Código';

  @override
  String get nextStepButton => 'Próximo Passo';

  @override
  String get androidCallScreeningServiceDesc =>
      'Permite que o serviço Android CallScreeningService intercepte chamadas em tempo real com zero latência.';

  @override
  String get callScreeningActive => 'Filtro ativo e pronto neste dispositivo';

  @override
  String get summaryTierLabel => 'Nível de Privacidade';

  @override
  String get summaryShieldLabel => 'Status do Escudo';

  @override
  String get summaryVerifyLabel => 'Verificação';

  @override
  String get summaryConfigurable => 'Configurável em Ajustes';

  @override
  String get summaryGuestMode => 'Modo Convidado';

  @override
  String get summaryVerified => 'Verificado';
}
