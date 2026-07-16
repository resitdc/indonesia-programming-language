import 'package:highlight/highlight.dart';
import 'package:highlight/languages/xml.dart';

// Custom syntax highlighting mode for RPL language
final rpl = Mode(
  refs: {},
  aliases: ["rpl"],
  keywords: {
    "keyword":
        "jika tidak maka selama ulangi dalam selesai coba tangkap lempar impor gabung pakai buat fungsi kembalikan adalah bukan",
    "literal": "benar salah kosong",
    "built_in": "cetak tampilkan baca"
  },
  contains: [
    Mode(
      className: "comment",
      begin: "//",
      end: "\$",
    ),
    Mode(
      className: "string",
      begin: "\"",
      end: "\"",
      contains: [
        Mode(
          className: "escape",
          begin: "\\\\.",
        )
      ],
    ),
    Mode(
      className: "string",
      begin: "`",
      end: "`",
      contains: [
        Mode(
          className: "escape",
          begin: "\\\\.",
        )
      ],
    ),
    Mode(
      className: "number",
      begin: "\\b\\d+(\\.\\d+)?\\b",
      relevance: 0,
    ),
  ],
);

// Custom XML/HTML mode that embeds RPL syntax inside <?rpl ... ?> and {{ ... }}
final rplHtml = Mode(
  refs: xml.refs,
  aliases: ["rpl-html", "rpl.html"],
  case_insensitive: true,
  contains: [
    Mode(
      begin: "<\\?rpl",
      end: "\\?>",
      subLanguage: ["rpl"],
    ),
    Mode(
      begin: "\\{\\{",
      end: "\\}\\}",
      subLanguage: ["rpl"],
    ),
    ...?xml.contains,
  ],
);

void registerRplLanguages() {
  highlight.registerLanguage('rpl', rpl);
  highlight.registerLanguage('rpl-html', rplHtml);
}
