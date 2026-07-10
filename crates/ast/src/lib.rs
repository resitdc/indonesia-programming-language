use errors::Lokasi;

#[derive(Debug, PartialEq, Clone)]
pub struct Program {
    pub statements: Vec<Statement>,
}

#[derive(Debug, PartialEq, Clone)]
pub enum Statement {
    DeklarasiVariabel {
        nama: String,
        nilai: Expression,
        lokasi: Lokasi,
    },
    Jika {
        kondisi: Expression,
        konsekuensi: Vec<Statement>,
        alternatif: Option<Vec<Statement>>,
        lokasi: Lokasi,
    },
    Selama {
        kondisi: Expression,
        body: Vec<Statement>,
        lokasi: Lokasi,
    },
    Kembalikan {
        nilai: Option<Expression>,
        lokasi: Lokasi,
    },
    DeklarasiFungsi {
        nama: String,
        parameter: Vec<String>,
        body: Vec<Statement>,
        lokasi: Lokasi,
    },
    Assignment {
        nama: String,
        nilai: Expression,
        lokasi: Lokasi,
    },
    Tampilkan {
        nilai: Vec<Expression>,
        lokasi: Lokasi,
    },
    Expression(Expression),
}

#[derive(Debug, PartialEq, Clone)]
pub enum Expression {
    Identifier(String, Lokasi),
    Angka(f64, Lokasi),
    String(String, Lokasi),
    Boolean(bool, Lokasi),
    Kosong(Lokasi),
    
    Prefix {
        operator: PrefixOperator,
        kanan: Box<Expression>,
        lokasi: Lokasi,
    },
    Infix {
        kiri: Box<Expression>,
        operator: InfixOperator,
        kanan: Box<Expression>,
        lokasi: Lokasi,
    },
    Call {
        fungsi: Box<Expression>,
        argumen: Vec<Expression>,
        lokasi: Lokasi,
    },
}

#[derive(Debug, PartialEq, Clone)]
pub enum PrefixOperator {
    Minus,
    Bukan,
}

#[derive(Debug, PartialEq, Clone)]
pub enum InfixOperator {
    Tambah,
    Kurang,
    Kali,
    Bagi,
    Mod,
    LebihDari,
    KurangDari,
    Minimal,
    Maksimal,
    SamaDengan,
    TidakSamaDengan,
    Dan,
    Atau,
}

impl Expression {
    pub fn lokasi(&self) -> &Lokasi {
        match self {
            Expression::Identifier(_, l) => l,
            Expression::Angka(_, l) => l,
            Expression::String(_, l) => l,
            Expression::Boolean(_, l) => l,
            Expression::Kosong(l) => l,
            Expression::Prefix { lokasi, .. } => lokasi,
            Expression::Infix { lokasi, .. } => lokasi,
            Expression::Call { lokasi, .. } => lokasi,
        }
    }
}
