import 'package:bpclpos/features/home/domain/entities/home_entities.dart';

enum PrinterCommandSet {
  escPos,
  cpcl,
  tspl,
  zpl,
}

class SalesReportPrinter {
  SalesReportPrinter({
    this.lineWidth = 32,
    this.maxItems = 50,
  });

  final int lineWidth;
  final int maxItems;

  List<int> buildReport({
    required PrinterCommandSet commandSet,
    required List<SaleRecord> salesRecords,
    required double totalSales,
    required int totalUnits,
    required double totalProfit,
    required String printedAt,
    required String Function(DateTime) formatDateTime,
  }) {
    final lines = _buildLines(
      salesRecords: salesRecords,
      totalSales: totalSales,
      totalUnits: totalUnits,
      totalProfit: totalProfit,
      printedAt: printedAt,
      formatDateTime: formatDateTime,
      includeFooterSpacing: commandSet == PrinterCommandSet.escPos,
    );

    return _buildForCommandSet(commandSet, lines);
  }

  List<int> buildTestLabel({required PrinterCommandSet commandSet}) {
    final lines = _buildTestLines(
      includeFooterSpacing: commandSet == PrinterCommandSet.escPos,
    );
    return _buildForCommandSet(commandSet, lines);
  }

  List<int> _buildForCommandSet(
    PrinterCommandSet commandSet,
    List<String> lines,
  ) {
    switch (commandSet) {
      case PrinterCommandSet.cpcl:
        return _buildCpclFromLines(lines);
      case PrinterCommandSet.tspl:
        return _buildTsplFromLines(lines);
      case PrinterCommandSet.zpl:
        return _buildZplFromLines(lines);
      case PrinterCommandSet.escPos:
        return _buildEscPosFromLines(lines);
    }
  }

  List<int> _buildEscPosFromLines(List<String> lines) {
    final buffer = StringBuffer();
    for (final line in lines) {
      buffer.writeln(line);
    }

    final bytes = <int>[];
    bytes.addAll(_escPosInit());
    bytes.addAll(_encodeAscii(buffer.toString()));
    return bytes;
  }

  List<int> _buildCpclFromLines(List<String> lines) {
    const lineHeight = 24;
    const leftMargin = 20;
    final height = _cpclHeight(lines.length, lineHeight);

    final buffer = StringBuffer();
    buffer.writeln('! 0 200 200 $height 1');
    buffer.writeln('PW 576');
    buffer.writeln('DENSITY 8');
    buffer.writeln('SPEED 4');

    var y = 20;
    for (final line in lines) {
      if (line.isEmpty) {
        y += lineHeight;
        continue;
      }
      buffer.writeln('TEXT 0 0 $leftMargin $y ${line.trimRight()}');
      y += lineHeight;
    }
    buffer.writeln('FORM');
    buffer.writeln('PRINT');

    final bytes = <int>[];
    bytes.addAll(_encodeAscii(buffer.toString().replaceAll('\n', '\r\n')));
    return bytes;
  }

  List<int> _buildTsplFromLines(List<String> lines) {
    const dotsPerMm = 8;
    const lineHeight = 24;
    const leftMargin = 20;
    final heightDots = _cpclHeight(lines.length, lineHeight);
    final heightMm = (heightDots / dotsPerMm).ceil();

    final buffer = StringBuffer();
    buffer.writeln('SIZE 58 mm, ${heightMm} mm');
    buffer.writeln('GAP 2 mm, 0 mm');
    buffer.writeln('DENSITY 8');
    buffer.writeln('SPEED 4');
    buffer.writeln('CLS');

    var y = 20;
    for (final line in lines) {
      if (line.trim().isEmpty) {
        y += lineHeight;
        continue;
      }
      final safeLine = _escapeTspl(line);
      buffer.writeln('TEXT $leftMargin,$y,"0",0,1,1,"$safeLine"');
      y += lineHeight;
    }

    buffer.writeln('PRINT 1,1');

    final bytes = <int>[];
    bytes.addAll(_encodeAscii(buffer.toString().replaceAll('\n', '\r\n')));
    return bytes;
  }

  List<int> _buildZplFromLines(List<String> lines) {
    const lineHeight = 28;
    const leftMargin = 20;
    const printWidth = 464;
    final heightDots = _cpclHeight(lines.length, lineHeight);

    final buffer = StringBuffer();
    buffer.writeln('^XA');
    buffer.writeln('^PW$printWidth');
    buffer.writeln('^LL$heightDots');

    var y = 20;
    for (final line in lines) {
      if (line.trim().isEmpty) {
        y += lineHeight;
        continue;
      }
      final safeLine = _escapeZpl(line);
      buffer.writeln('^FO$leftMargin,$y^A0N,24,24^FD$safeLine^FS');
      y += lineHeight;
    }
    buffer.writeln('^XZ');

    final bytes = <int>[];
    bytes.addAll(_encodeAscii(buffer.toString().replaceAll('\n', '\r\n')));
    return bytes;
  }

  List<int> _escPosInit() => [0x1B, 0x40];

  String _center(String text) {
    final trimmed = text.trim();
    if (trimmed.length >= lineWidth) return trimmed;
    final padding = ((lineWidth - trimmed.length) / 2).floor();
    return (' ' * padding) + trimmed;
  }

  String _hr(String ch) => ch * lineWidth;

  String _row(String item, String qty, String amt) {
    const qtyWidth = 4;
    const amtWidth = 10;
    final itemWidth = lineWidth - qtyWidth - amtWidth;
    final left = _fit(item, itemWidth, padRight: true);
    final mid = _fit(qty, qtyWidth, padRight: false);
    final right = _fit(amt, amtWidth, padRight: false);
    return '$left$mid$right';
  }

  String _fit(String value, int width, {required bool padRight}) {
    final trimmed = value.trim();
    if (trimmed.length >= width) {
      return trimmed.substring(0, width);
    }
    return padRight ? trimmed.padRight(width) : trimmed.padLeft(width);
  }

  List<String> _buildLines({
    required List<SaleRecord> salesRecords,
    required double totalSales,
    required int totalUnits,
    required double totalProfit,
    required String printedAt,
    required String Function(DateTime) formatDateTime,
    required bool includeFooterSpacing,
  }) {
    final lines = <String>[];

    lines.add(_center('BPCL Fuel POS'));
    lines.add(_center('Sales Report'));
    lines.add(_center('Printed: $printedAt'));
    lines.add(_hr('='));

    _addWrapped(lines, 'Total Sales: Rs ${totalSales.toStringAsFixed(2)}');
    _addWrapped(lines, 'Total Units: $totalUnits');
    _addWrapped(lines, 'Total Profit: Rs ${totalProfit.toStringAsFixed(2)}');

    lines.add(_hr('-'));
    lines.add(_row('Item', 'Qty', 'Amt'));
    lines.add(_hr('-'));

    final items = salesRecords.take(maxItems).toList();
    for (final record in items) {
      lines.add(
        _row(
          record.product,
          record.units.toString(),
          record.amount.toStringAsFixed(2),
        ),
      );
      _addWrapped(lines, 'Cust: ${record.customer}');
      _addWrapped(lines, 'Date: ${formatDateTime(record.date)}');
      lines.add(_hr('-'));
    }

    if (salesRecords.length > items.length) {
      _addWrapped(
        lines,
        'Showing ${items.length} of ${salesRecords.length} sales.',
      );
    }

    if (includeFooterSpacing) {
      lines.add('');
      lines.add('');
      lines.add('');
    }

    return lines;
  }

  List<String> _buildTestLines({required bool includeFooterSpacing}) {
    final lines = <String>[];
    lines.add(_center('BPCL Fuel POS'));
    lines.add(_center('Test Print'));
    lines.add(_hr('-'));
    _addWrapped(lines, 'If you can read this,');
    _addWrapped(lines, 'printer mode is OK.');
    lines.add(_hr('-'));

    if (includeFooterSpacing) {
      lines.add('');
      lines.add('');
      lines.add('');
    }

    return lines;
  }

  void _addWrapped(List<String> lines, String line) {
    var text = line.trim();
    if (text.isEmpty) {
      lines.add('');
      return;
    }
    while (text.length > lineWidth) {
      lines.add(text.substring(0, lineWidth));
      text = text.substring(lineWidth);
    }
    lines.add(text);
  }

  List<int> _encodeAscii(String text) {
    final bytes = <int>[];
    for (final codeUnit in text.codeUnits) {
      bytes.add(codeUnit <= 0x7F ? codeUnit : 0x3F);
    }
    return bytes;
  }

  String _escapeTspl(String text) {
    return text.replaceAll('"', '\'').trimRight();
  }

  String _escapeZpl(String text) {
    return text
        .replaceAll('^', ' ')
        .replaceAll('~', ' ')
        .trimRight();
  }

  int _cpclHeight(int lineCount, int lineHeight) {
    final height = 40 + (lineCount * lineHeight) + 40;
    return height < 200 ? 200 : height;
  }
}
