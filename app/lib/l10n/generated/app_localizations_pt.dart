// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => 'Idioma / Language';

  @override
  String get languageSaveError =>
      'Não foi possível salvar o idioma. Selecione novamente na próxima vez.';

  @override
  String get about => 'Sobre este protótipo';

  @override
  String get sampleBanner =>
      'Dados de teste · Não use para descartar lixo de verdade';

  @override
  String get today => 'Hoje';

  @override
  String get tomorrow => 'Amanhã';

  @override
  String get searchTab => 'Separação';

  @override
  String get placesTab => 'Pontos de reciclagem';

  @override
  String get chooseArea => 'Selecionar área';

  @override
  String get fictionalAreas => 'Áreas fictícias para testes.';

  @override
  String areaName(String area) {
    return 'Toshima · Área de exemplo $area';
  }

  @override
  String get areaSaveError =>
      'Não foi possível guardar. A definição não mudou. Tente novamente.';

  @override
  String sourceOpenError(String url) {
    return 'Não foi possível abrir a página oficial.\n$url';
  }

  @override
  String demoDate(String date) {
    return 'Exemplo para $date';
  }

  @override
  String get upcoming => 'Próximas coletas';

  @override
  String get officialToshima => 'Informações oficiais de Toshima (japonês)';

  @override
  String get official => 'Informações oficiais (japonês)';

  @override
  String get checkTime =>
      'Confira as instruções e os horários oficiais de descarte';

  @override
  String get noCollection => 'Sem coleta';

  @override
  String get uncertain => 'É preciso confirmar o calendário de coleta';

  @override
  String get burnable => 'Lixo incinerável';

  @override
  String get recyclables => 'Recicláveis';

  @override
  String get metals => 'Metal, cerâmica e vidro';

  @override
  String get searchTitle => 'Como descartar este item?';

  @override
  String get searchSubtitle => 'Pesquise pelo nome do item.';

  @override
  String get itemName => 'Nome do item';

  @override
  String get searchHint => 'Ex.: pilha, garrafa plástica';

  @override
  String get noResults =>
      'Nenhum resultado. Tente outro nome ou consulte as informações oficiais.';

  @override
  String get disposal => 'Instruções de descarte';

  @override
  String get disposalAndPlaces => 'Descarte e pontos de coleta';

  @override
  String get sampleSorting => 'Exemplo de orientação de separação';

  @override
  String get findPlaces => 'Encontrar pontos de coleta';

  @override
  String get officialDisposal => 'Instruções oficiais de descarte (japonês)';

  @override
  String get placesSubtitle =>
      'Pontos de entrega de pilhas, pequenos eletrônicos e lâmpadas fluorescentes.\nPara o lixo comum, veja Hoje.';

  @override
  String get damageQuestion => 'Está inchada ou danificada?';

  @override
  String get noDamage => 'Não';

  @override
  String get damagedOrUnknown => 'Sim / Não sei';

  @override
  String get damageWarning =>
      'Não coloque em uma caixa de coleta comum. Verifique o estado e consulte a orientação oficial do distrito para encontrar o contato responsável.';

  @override
  String get officialBattery =>
      'Orientações e contatos para pilhas e baterias (japonês)';

  @override
  String placesCount(int count) {
    return 'Pontos de exemplo ($count)';
  }

  @override
  String get fictionalPoints => 'Estes locais são fictícios. Não vá até eles.';

  @override
  String get noPoints =>
      'Ainda não há pontos verificados para este item. Consulte a orientação oficial do distrito.';

  @override
  String get conditions => 'Ver condições de recebimento';

  @override
  String samplePoint(String point) {
    return 'Ponto de coleta de exemplo $point';
  }

  @override
  String get samplePointDetail => 'Local fictício de coleta para testes';

  @override
  String acceptedItems(String items) {
    return 'Exemplos de itens aceitos: $items';
  }

  @override
  String get pointConditions =>
      'Horários e condições: não cadastrados.\nEste não é um ponto de entrega real. Rotas indisponíveis.';

  @override
  String get mapTitle => 'Mapa de coleta';

  @override
  String get mapUnavailable =>
      'O mapa ainda não está conectado.\nUse a lista abaixo para testar o protótipo.';

  @override
  String get aboutBody =>
      'Esta amostra de desenvolvimento usa calendários, áreas e pontos de coleta fictícios. Não a use para descartar lixo de verdade.\n\nÁrea, idioma e configurações de lembretes são salvos no dispositivo. Fotos e localização não são coletadas.';

  @override
  String get dryBattery => 'Pilhas secas';

  @override
  String get rechargeable => 'Baterias recarregáveis';

  @override
  String get appliance => 'Pequenos eletrônicos';

  @override
  String get lamp => 'Lâmpadas fluorescentes';

  @override
  String get dryBatteryHint =>
      'Verifique o tipo e o estado da pilha ou bateria antes de escolher um local.';

  @override
  String get rechargeableHint =>
      'Não coloque em caixas de coleta de pilhas secas. Confira o método adequado ao tipo e estado da bateria.';

  @override
  String get applianceHint =>
      'Confira os itens aceitos, o tamanho da abertura e as regras para baterias embutidas.';

  @override
  String get lampHint =>
      'Tubos quebrados e lâmpadas LED têm regras diferentes. Consulte a orientação oficial.';

  @override
  String get food => 'Restos de alimentos';

  @override
  String get pet => 'Garrafas PET';

  @override
  String get cans => 'Latas e garrafas de vidro';

  @override
  String get bulky => 'Móveis e lixo volumoso';

  @override
  String get foodGuidance =>
      'Exemplo para lixo incinerável: escorra os líquidos antes do descarte.';

  @override
  String get recyclingGuidance =>
      'Exemplo para recicláveis: confira os dias de coleta e as regras de preparação.';

  @override
  String get dryBatteryGuidance =>
      'Confira o método de coleta para o tipo de pilha ou bateria.';

  @override
  String get rechargeableGuidance =>
      'As regras variam conforme o tipo e a presença de inchaço ou danos.';

  @override
  String get applianceGuidance =>
      'Confira os limites de tamanho e as regras para baterias embutidas.';

  @override
  String get lampGuidance =>
      'Confira separadamente as regras para fluorescentes e lâmpadas LED.';

  @override
  String get bulkyGuidance =>
      'As regras de lixo volumoso dependem das dimensões e do tipo de item. Consulte o guia e as informações de agendamento do distrito.';

  @override
  String collectionArea(String area) {
    return 'Área de coleta: $area';
  }

  @override
  String get setupAreaTitle => 'Definir uma área de exemplo';

  @override
  String get confirmAreaTitle => 'Usar esta área?';

  @override
  String candidateArea(String area) {
    return 'Área a guardar: $area';
  }

  @override
  String currentArea(String area) {
    return 'Definição atual: $area';
  }

  @override
  String get confirmAreaAction => 'Guardar esta área';

  @override
  String get chooseAgain => 'Escolher novamente';

  @override
  String get savingArea => 'A guardar…';

  @override
  String get setupRecovery =>
      'Não foi possível ler a área definida. Escolha-a novamente.';

  @override
  String get cancel => 'Cancelar';

  @override
  String collectionDeadline(String time) {
    return 'Colocar o lixo até às $time';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item: colocar até às $time';
  }

  @override
  String get chooseCollectionItem =>
      'Escolha o tipo de objeto que quer entregar.';

  @override
  String backToItem(String item) {
    return 'Voltar às instruções de $item';
  }

  @override
  String get close => 'Fechar';

  @override
  String get widgetLabel => 'Coleta de lixo';

  @override
  String get widgetSample => 'Exemplo de desenvolvimento';

  @override
  String get widgetNext => 'Próxima previsão';

  @override
  String get widgetOfferTitle => 'Mostrar a coleta de lixo na tela inicial';

  @override
  String get widgetOfferBody =>
      'Veja a data e o tipo de lixo sem abrir o aplicativo.';

  @override
  String get widgetAdd => 'Adicionar';

  @override
  String get widgetSkip => 'Pular';

  @override
  String get widgetSettings => 'Widget da tela inicial';

  @override
  String get widgetAdded => 'Adicionado à tela inicial';

  @override
  String get widgetRequested =>
      'Adição solicitada. Confirme na janela do sistema.';

  @override
  String get widgetUnsupported =>
      'Toque e segure a tela inicial, escolha Widgets e adicione Gomimap.';

  @override
  String get widgetFailure =>
      'Não foi possível solicitar. Tente novamente ou adicione pela tela inicial.';

  @override
  String get widgetSaveError =>
      'Não foi possível salvar a escolha. Tente novamente.';

  @override
  String get disposalDeadlinePassed => 'O prazo para colocar o lixo terminou';

  @override
  String get notifications => 'Lembretes de coleta';

  @override
  String get notificationIntro => 'Receba um lembrete nas manhãs de coleta.';

  @override
  String get notificationEnabled => 'Lembrete de manhã';

  @override
  String get notificationEvening => 'Lembrar também na noite anterior';

  @override
  String get notificationSave => 'Salvar';

  @override
  String get notificationLater => 'Depois';

  @override
  String get notificationPermission =>
      'As notificações não estão permitidas neste dispositivo';

  @override
  String get notificationOsSettings => 'Abrir as configurações de notificações';

  @override
  String get notificationNone => 'Não há datas de coleta para agendar';

  @override
  String get notificationFixture =>
      'O aplicativo normal não agenda lembretes de exemplo';

  @override
  String notificationReserved(int count) {
    return 'Agendados: $count';
  }

  @override
  String notificationPreview(int count) {
    return 'Relógio de teste: prévia de $count lembretes';
  }

  @override
  String notificationNext(String when) {
    return 'Próximo lembrete: $when';
  }

  @override
  String get notificationError =>
      'Não foi possível salvar ou aplicar. Confira as configurações e os lembretes.';

  @override
  String get notificationRetry => 'Tentar novamente';

  @override
  String get notificationTest => 'Mostrar notificação de teste';

  @override
  String notificationMorningTitle(String date) {
    return 'Lixo de hoje, $date';
  }

  @override
  String notificationEveningTitle(String date) {
    return 'Preparar para amanhã, $date';
  }

  @override
  String notificationTestTitle(String title) {
    return 'Teste: $title';
  }

  @override
  String get notificationChangedArea =>
      'Este lembrete é de outra área. Exibindo a área atual.';

  @override
  String get notificationUpdated => 'O calendário mudou após este lembrete.';

  @override
  String get notificationOfferTitle => 'Lembrar nos dias de coleta';
}
