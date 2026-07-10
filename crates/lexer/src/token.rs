use errors::Lokasi;
// ini penting gaes, ini kamusnya

#[derive(Debug, PartialEq, Clone)]
pub enum Token {
    Buat,       // buat
    Tampilkan,  // tampilkan
    Masukkan,   // masukkan
    Jika,       // jika
    JikaTidak,  // jika tidak
    Fungsi,     // fungsi
    Kembalikan, // kembalikan
    Selama,     // selama
    Ulangi,     // ulangi
    Berhenti,   // berhenti
    Lanjut,     // lanjut
    Benar,      // benar
    Salah,      // salah
    Kosong,     // kosong

    LebihDari,       // lebih dari
    KurangDari,      // kurang dari
    Minimal,         // minimal
    Maksimal,        // maksimal
    SamaDengan,      // sama dengan
    TidakSamaDengan, // tidak sama dengan
    Dan,             // dan
    Atau,            // atau
    Bukan,           // bukan

    Tambah, // +
    Kurang, // -
    Kali,   // *
    Bagi,   // /
    Mod,    // %

    Assign,      // =
    TitikKoma,   // ;
    Koma,        // ,
    TitikDua,    // :
    KurungBuka,  // (
    KurungTutup, // )
    KurungSikuBuka, // [
    KurungSikuTutup, // ]
    KurawalBuka, // {
    KurawalTutup,// }

    Identifier(String),
    String(String),
    Angka(f64),

    EOF,
}

impl Token {
    pub fn dari_keyword(k: &str) -> Option<Token> {
        match k {
            "buat" => Some(Token::Buat),
            "tampilkan" => Some(Token::Tampilkan),
            "masukkan" => Some(Token::Masukkan),
            "jika" => Some(Token::Jika),
            "fungsi" => Some(Token::Fungsi),
            "kembalikan" => Some(Token::Kembalikan),
            "selama" => Some(Token::Selama),
            "ulangi" => Some(Token::Ulangi),
            "berhenti" => Some(Token::Berhenti),
            "lanjut" => Some(Token::Lanjut),
            "benar" => Some(Token::Benar),
            "salah" => Some(Token::Salah),
            "kosong" => Some(Token::Kosong),
            "minimal" => Some(Token::Minimal),
            "maksimal" => Some(Token::Maksimal),
            "dan" => Some(Token::Dan),
            "atau" => Some(Token::Atau),
            "bukan" => Some(Token::Bukan),
            _ => None,
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub struct SpannedToken {
    pub token: Token,
    pub lokasi: Lokasi,
}
