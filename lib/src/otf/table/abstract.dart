import '../../common/codable/binary.dart';
import 'table_record_entry.dart';

abstract class FontTable implements BinaryCodable {
  FontTable.fromTableRecordEntry(this.entry);

  TableRecordEntry? entry;
}
