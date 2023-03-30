List<int> toUCS2byteList(String str) {
  return [
    for (final code in str.codeUnits) ...[code >> 8, code & 0xFF]
  ];
}

String fromUCS2byteList(List<int> byteList) {
  return String.fromCharCodes([
    for (var i = 0; i < byteList.length; i += 2)
      byteList[i] << 8 | byteList[i + 1]
  ]);
}
