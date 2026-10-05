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
      'Não foi possível salvar a área. Selecione novamente na próxima vez.';

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
      'Calendários, áreas e locais são fictícios, com base em 5 de outubro de 2026. Não use para descartar lixo de verdade.\n\nNotificações, widgets e configurações de localização ainda não foram implementados. Este protótipo não envia notificações.\n\nSomente a área de exemplo e o idioma escolhidos são salvos. Não coletamos fotos nem localização.';

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
}
