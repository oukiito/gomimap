// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gomimap';

  @override
  String get language => 'Idioma / Language';

  @override
  String get languageSaveError =>
      'No se pudo guardar el idioma. Vuelve a seleccionarlo la próxima vez.';

  @override
  String get about => 'Acerca de este prototipo';

  @override
  String get sampleBanner => 'Datos de prueba · No usar para tirar basura real';

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get searchTab => 'Separación';

  @override
  String get placesTab => 'Puntos de reciclaje';

  @override
  String get chooseArea => 'Seleccionar zona';

  @override
  String get fictionalAreas => 'Zonas ficticias para pruebas.';

  @override
  String areaName(String area) {
    return 'Toshima · Zona de ejemplo $area';
  }

  @override
  String get areaSaveError =>
      'No se pudo guardar. La configuración no cambió. Inténtalo de nuevo.';

  @override
  String sourceOpenError(String url) {
    return 'No se pudo abrir la página oficial.\n$url';
  }

  @override
  String demoDate(String date) {
    return 'Ejemplo del $date';
  }

  @override
  String get upcoming => 'Próximas recogidas';

  @override
  String get officialToshima => 'Información oficial de Toshima (japonés)';

  @override
  String get official => 'Información oficial (japonés)';

  @override
  String get checkTime => 'Consulta las instrucciones y los horarios oficiales';

  @override
  String get noCollection => 'Sin recogida';

  @override
  String get uncertain => 'Es necesario confirmar el calendario de recogida';

  @override
  String get burnable => 'Basura combustible';

  @override
  String get recyclables => 'Reciclables';

  @override
  String get metals => 'Metal, cerámica y vidrio';

  @override
  String get searchTitle => '¿Cómo se desecha esto?';

  @override
  String get searchSubtitle => 'Busca por el nombre del objeto.';

  @override
  String get itemName => 'Nombre del objeto';

  @override
  String get searchHint => 'Ej.: pila, botella de plástico';

  @override
  String get noResults =>
      'No se encontraron resultados. Prueba otro nombre o consulta la información oficial.';

  @override
  String get disposal => 'Instrucciones de eliminación';

  @override
  String get disposalAndPlaces => 'Eliminación y puntos de recogida';

  @override
  String get sampleSorting => 'Instrucciones de separación de ejemplo';

  @override
  String get findPlaces => 'Buscar puntos de recogida';

  @override
  String get officialDisposal =>
      'Instrucciones oficiales de eliminación (japonés)';

  @override
  String get placesSubtitle =>
      'Puntos para pilas, aparatos pequeños y tubos fluorescentes.\nPara la basura habitual, consulta Hoy.';

  @override
  String get damageQuestion => '¿Está hinchada o dañada?';

  @override
  String get noDamage => 'No';

  @override
  String get damagedOrUnknown => 'Sí / No lo sé';

  @override
  String get damageWarning =>
      'No la deposites en una caja de recogida normal. Comprueba su estado y consulta la guía oficial del distrito para encontrar el contacto adecuado.';

  @override
  String get officialBattery =>
      'Guía y contactos oficiales para pilas y baterías (japonés)';

  @override
  String placesCount(int count) {
    return 'Puntos de ejemplo ($count)';
  }

  @override
  String get fictionalPoints =>
      'Estos lugares son ficticios. No acudas a ellos.';

  @override
  String get noPoints =>
      'Aún no hay puntos verificados para este objeto. Consulta la guía oficial del distrito.';

  @override
  String get conditions => 'Ver condiciones de recepción';

  @override
  String samplePoint(String point) {
    return 'Punto de recogida de ejemplo $point';
  }

  @override
  String get samplePointDetail => 'Lugar de recogida ficticio para pruebas';

  @override
  String acceptedItems(String items) {
    return 'Ejemplos de objetos aceptados: $items';
  }

  @override
  String get pointConditions =>
      'Horarios y condiciones: sin registrar.\nNo es un punto de entrega real. No se ofrecen rutas.';

  @override
  String get mapTitle => 'Mapa de recogida';

  @override
  String get mapUnavailable =>
      'El mapa aún no está conectado.\nPuedes probar el prototipo con la lista de abajo.';

  @override
  String get aboutBody =>
      'Esta muestra de desarrollo usa calendarios, zonas y puntos de recogida ficticios. No la uses para sacar basura de verdad.\n\nLa zona, el idioma y los ajustes de avisos se guardan en el dispositivo. No se recopilan fotos ni ubicación.';

  @override
  String get dryBattery => 'Pilas secas';

  @override
  String get rechargeable => 'Baterías recargables';

  @override
  String get appliance => 'Aparatos pequeños';

  @override
  String get lamp => 'Tubos fluorescentes';

  @override
  String get dryBatteryHint =>
      'Comprueba el tipo y el estado de la pila o batería antes de elegir un lugar.';

  @override
  String get rechargeableHint =>
      'No las pongas en cajas de pilas secas. Comprueba el método adecuado para su tipo y estado.';

  @override
  String get applianceHint =>
      'Comprueba los objetos aceptados, el tamaño de la abertura y las normas para baterías integradas.';

  @override
  String get lampHint =>
      'Los tubos rotos y las bombillas LED tienen normas diferentes. Consulta la guía oficial.';

  @override
  String get food => 'Restos de comida';

  @override
  String get pet => 'Botellas PET';

  @override
  String get cans => 'Latas y botellas de vidrio';

  @override
  String get bulky => 'Muebles y basura voluminosa';

  @override
  String get foodGuidance =>
      'Ejemplo para basura combustible: escurre los líquidos antes de desecharla.';

  @override
  String get recyclingGuidance =>
      'Ejemplo para reciclables: comprueba los días de recogida y la preparación necesaria.';

  @override
  String get dryBatteryGuidance =>
      'Comprueba el método de recogida para el tipo de pila o batería.';

  @override
  String get rechargeableGuidance =>
      'Las normas varían según el tipo y si está hinchada o dañada.';

  @override
  String get applianceGuidance =>
      'Comprueba los límites de tamaño y las normas para baterías integradas.';

  @override
  String get lampGuidance =>
      'Consulta por separado las normas para tubos fluorescentes y bombillas LED.';

  @override
  String get bulkyGuidance =>
      'Las normas para basura voluminosa dependen del tamaño y del objeto. Consulta el catálogo y la información de reserva del distrito.';

  @override
  String collectionArea(String area) {
    return 'Zona de recogida: $area';
  }

  @override
  String get setupAreaTitle => 'Configurar una zona de ejemplo';

  @override
  String get confirmAreaTitle => '¿Usar esta zona?';

  @override
  String candidateArea(String area) {
    return 'Zona que se guardará: $area';
  }

  @override
  String currentArea(String area) {
    return 'Configuración actual: $area';
  }

  @override
  String get confirmAreaAction => 'Guardar esta zona';

  @override
  String get chooseAgain => 'Elegir de nuevo';

  @override
  String get savingArea => 'Guardando…';

  @override
  String get setupRecovery =>
      'No se pudo leer la zona configurada. Elígela de nuevo.';

  @override
  String get cancel => 'Cancelar';

  @override
  String collectionDeadline(String time) {
    return 'Sacar la basura antes de las $time';
  }

  @override
  String itemDeadline(String item, String time) {
    return '$item: sacar antes de las $time';
  }

  @override
  String get chooseCollectionItem =>
      'Elige el tipo de objeto que quieres llevar al punto de recogida.';

  @override
  String backToItem(String item) {
    return 'Volver a las instrucciones de $item';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get widgetLabel => 'Recogida de basura';

  @override
  String get widgetSample => 'Ejemplo de desarrollo';

  @override
  String get widgetNext => 'Próxima previsión';

  @override
  String get widgetOfferTitle =>
      'Mostrar el calendario de recogida en la pantalla de inicio';

  @override
  String get widgetOfferBody =>
      'Consulta la fecha y el tipo de basura sin abrir la aplicación.';

  @override
  String get widgetAdd => 'Añadir';

  @override
  String get widgetSkip => 'Omitir';

  @override
  String get widgetSettings => 'Widget de la pantalla de inicio';

  @override
  String get widgetAdded => 'Añadido a la pantalla de inicio';

  @override
  String get widgetRequested =>
      'Se solicitó añadirlo. Confirma en el diálogo del sistema.';

  @override
  String get widgetUnsupported =>
      'Mantén pulsada la pantalla de inicio, elige Widgets y añade Gomimap.';

  @override
  String get widgetFailure =>
      'No se pudo solicitar. Reintenta o añádelo desde la pantalla de inicio.';

  @override
  String get widgetSaveError => 'No se pudo guardar la elección. Reintenta.';

  @override
  String get disposalDeadlinePassed =>
      'El plazo para sacar la basura ha pasado';

  @override
  String get notifications => 'Recordatorios de recogida';

  @override
  String get notificationIntro => 'Recibe un aviso las mañanas de recogida.';

  @override
  String get notificationEnabled => 'Aviso por la mañana';

  @override
  String get notificationEvening => 'Avisar también la noche anterior';

  @override
  String get notificationSave => 'Guardar';

  @override
  String get notificationLater => 'Más tarde';

  @override
  String get notificationPermission =>
      'Este dispositivo no permite las notificaciones';

  @override
  String get notificationOsSettings => 'Abrir los ajustes de notificaciones';

  @override
  String get notificationNone => 'No hay fechas de recogida para programar';

  @override
  String get notificationFixture =>
      'La aplicación normal no programa avisos de ejemplo';

  @override
  String notificationReserved(int count) {
    return 'Programados: $count';
  }

  @override
  String notificationPreview(int count) {
    return 'Reloj de prueba: vista previa de $count avisos';
  }

  @override
  String notificationNext(String when) {
    return 'Próximo aviso: $when';
  }

  @override
  String get notificationError =>
      'No se pudo guardar o aplicar. Revisa los ajustes y los avisos programados.';

  @override
  String get notificationRetry => 'Reintentar';

  @override
  String get notificationTest => 'Mostrar notificación de prueba';

  @override
  String notificationMorningTitle(String date) {
    return 'Basura de hoy, $date';
  }

  @override
  String notificationEveningTitle(String date) {
    return 'Preparar para mañana, $date';
  }

  @override
  String notificationTestTitle(String title) {
    return 'Prueba: $title';
  }

  @override
  String get notificationChangedArea =>
      'Este aviso es de otra zona. Se muestra la zona actual.';

  @override
  String get notificationUpdated =>
      'El calendario cambió después de este aviso.';

  @override
  String get notificationOfferTitle => 'Avisarme los días de recogida';

  @override
  String get mapLoadError => 'No se pudo cargar el mapa';

  @override
  String get mapRetry => 'Reintentar';

  @override
  String get mapShowList => 'Ver lista';
}
