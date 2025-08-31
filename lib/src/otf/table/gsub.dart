import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/otf.dart';
import '../debugger.dart';
import 'abstract.dart';
import 'feature_list.dart';
import 'lookup.dart';
import 'script_list.dart';
import 'table_record_entry.dart';

class GlyphSubstitutionTableHeader implements BinaryCodable {
  GlyphSubstitutionTableHeader(
      this.majorVersion,
      this.minorVersion,
      this.scriptListOffset,
      this.featureListOffset,
      this.lookupListOffset,
      this.featureVariationsOffset);

  factory GlyphSubstitutionTableHeader.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    final major = byteData.getUint16(entry.offset);
    final minor = byteData.getUint16(entry.offset + 2);
    final version = Revision(major, minor);

    final isV10 = version == const Revision(1, 0);

    if (!isV10) {
      debugUnsupportedTableVersion(kGSUBTag, version.int32value);
    }

    return GlyphSubstitutionTableHeader(
      major,
      minor,
      byteData.getUint16(entry.offset + 4),
      byteData.getUint16(entry.offset + 6),
      byteData.getUint16(entry.offset + 8),
      isV10 ? null : byteData.getUint32(entry.offset + 10),
    );
  }

  factory GlyphSubstitutionTableHeader.create() {
    return GlyphSubstitutionTableHeader(1, 0, null, null, null, null);
  }

  final int majorVersion;
  final int minorVersion;
  int? scriptListOffset;
  int? featureListOffset;
  int? lookupListOffset;
  int? featureVariationsOffset;

  bool get isV10 => majorVersion == 1 && minorVersion == 0;

  @override
  int get size => isV10 ? 10 : 12;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint16(0, majorVersion)
      ..setUint16(2, minorVersion)
      ..setUint16(4, scriptListOffset!)
      ..setUint16(6, featureListOffset!)
      ..setUint16(8, lookupListOffset!);

    if (!isV10) {
      byteData.getUint32(10);
    }
  }
}

class GlyphSubstitutionTable extends FontTable {
  GlyphSubstitutionTable(super.entry, this.header,
      this.scriptListTable, this.featureListTable, this.lookupListTable)
      : super.fromTableRecordEntry();

  factory GlyphSubstitutionTable.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    final header = GlyphSubstitutionTableHeader.fromByteData(byteData, entry);

    final scriptListTable = ScriptListTable.fromByteData(
        byteData, entry.offset + header.scriptListOffset!);
    final featureListTable = FeatureListTable.fromByteData(
        byteData, entry.offset + header.featureListOffset!);
    final lookupListTable = LookupListTable.fromByteData(
        byteData, entry.offset + header.lookupListOffset!);

    return GlyphSubstitutionTable(
      entry,
      header,
      scriptListTable,
      featureListTable,
      lookupListTable,
    );
  }

  factory GlyphSubstitutionTable.create() {
    final header = GlyphSubstitutionTableHeader.create();

    final scriptListTable = ScriptListTable.create();
    final featureListTable = FeatureListTable.create();
    final lookupListTable = LookupListTable.create();

    return GlyphSubstitutionTable(
      null,
      header,
      scriptListTable,
      featureListTable,
      lookupListTable,
    );
  }

  final GlyphSubstitutionTableHeader header;

  final ScriptListTable scriptListTable;
  final FeatureListTable featureListTable;
  final LookupListTable lookupListTable;

  @override
  void encodeToBinary(ByteData byteData) {
    var relativeOffset = header.size;

    scriptListTable.encodeToBinary(
        byteData.sublistView(relativeOffset, scriptListTable.size));
    header.scriptListOffset = relativeOffset;
    relativeOffset += scriptListTable.size;

    featureListTable.encodeToBinary(
        byteData.sublistView(relativeOffset, featureListTable.size));
    header.featureListOffset = relativeOffset;
    relativeOffset += featureListTable.size;

    lookupListTable.encodeToBinary(
        byteData.sublistView(relativeOffset, lookupListTable.size));
    header.lookupListOffset = relativeOffset;
    relativeOffset += lookupListTable.size;

    header.encodeToBinary(byteData.sublistView(0, header.size));
  }

  @override
  int get size =>
      header.size +
      scriptListTable.size +
      featureListTable.size +
      lookupListTable.size;
}
