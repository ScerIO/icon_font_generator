import '../utils/logger.dart';

void _debug(String message) => logger.w(message);

void debugUnsupportedTable(String tableName) =>
    _debug('Unsupported table: $tableName');

void debugUnsupportedTableVersion(String tableName, int version) =>
    _debug('Unsupported $tableName table version: $version');

void debugUnsupportedTableFormat(String tableName, int format) =>
    _debug('Unsupported $tableName table format: $format');

void debugUnsupportedFeature(String featureDescription) =>
    _debug('Unsupported feature: $featureDescription');
