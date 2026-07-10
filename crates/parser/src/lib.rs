use ast::{Expression, InfixOperator, PrefixOperator, Program, Statement};
use errors::IplError;
use lexer::token::{SpannedToken, Token};

#[derive(PartialEq, PartialOrd)]
enum Precedence {
    Lowest,
    AndOr,       // dan, atau
    Equals,      // sama dengan, tidak sama dengan
    LessGreater, // lebih dari, kurang dari
    Sum,         // +, -
    Product,     // *, /, %
    Prefix,      // -X, bukan X
    Call,        // fungsi(X)
}

fn token_precedence(token: &Token) -> Precedence {
    match token {
        Token::Dan | Token::Atau => Precedence::AndOr,
        Token::SamaDengan | Token::TidakSamaDengan => Precedence::Equals,
        Token::LebihDari | Token::KurangDari | Token::Minimal | Token::Maksimal => Precedence::LessGreater,
        Token::Tambah | Token::Kurang => Precedence::Sum,
        Token::Kali | Token::Bagi | Token::Mod => Precedence::Product,
        Token::KurungBuka => Precedence::Call,
        _ => Precedence::Lowest,
    }
}

pub struct Parser {
    tokens: Vec<SpannedToken>,
    posisi: usize,
}

impl Parser {
    pub fn new(tokens: Vec<SpannedToken>) -> Self {
        Self { tokens, posisi: 0 }
    }

    fn current(&self) -> &SpannedToken {
        &self.tokens[self.posisi]
    }

    fn peek(&self) -> &SpannedToken {
        if self.posisi + 1 < self.tokens.len() {
            &self.tokens[self.posisi + 1]
        } else {
            &self.tokens[self.tokens.len() - 1]
        }
    }

    fn advance(&mut self) {
        if self.posisi < self.tokens.len() - 1 {
            self.posisi += 1;
        }
    }

    fn expect(&mut self, expected: Token) -> Result<(), IplError> {
        if self.current().token == expected {
            self.advance();
            Ok(())
        } else {
            Err(IplError::Sintaks {
                pesan: format!("Diharapkan token {:?}, tapi mendapat {:?}", expected, self.current().token),
                lokasi: self.current().lokasi.clone(),
                saran: None,
            })
        }
    }

    pub fn parse_program(&mut self) -> Result<Program, IplError> {
        let mut statements = Vec::new();

        while self.current().token != Token::EOF {
            let stmt = self.parse_statement()?;
            statements.push(stmt);
        }

        Ok(Program { statements })
    }

    fn parse_statement(&mut self) -> Result<Statement, IplError> {
        match self.current().token {
            Token::Buat => self.parse_deklarasi_variabel(),
            Token::Jika => self.parse_jika(),
            Token::Selama => self.parse_selama(),
            Token::Fungsi => self.parse_fungsi(),
            Token::Kembalikan => self.parse_kembalikan(),
            Token::Tampilkan => self.parse_tampilkan(),
            Token::Identifier(_) => {
                if self.peek().token == Token::Assign {
                    self.parse_assignment()
                } else {
                    self.parse_expression_statement()
                }
            }
            _ => self.parse_expression_statement(),
        }
    }

    fn parse_deklarasi_variabel(&mut self) -> Result<Statement, IplError> {
        let lokasi = self.current().lokasi.clone();
        self.advance();

        let nama = match &self.current().token {
            Token::Identifier(n) => n.clone(),
            _ => return Err(IplError::Sintaks {
                pesan: "Diharapkan nama variabel setelah 'buat'.".to_string(),
                lokasi: self.current().lokasi.clone(),
                saran: Some("Contoh: buat nama = 10".to_string()),
            }),
        };
        self.advance();

        self.expect(Token::Assign)?;

        let nilai = self.parse_expression(Precedence::Lowest)?;

        Ok(Statement::DeklarasiVariabel { nama, nilai, lokasi })
    }

    fn parse_assignment(&mut self) -> Result<Statement, IplError> {
        let lokasi = self.current().lokasi.clone();
        let nama = match &self.current().token {
            Token::Identifier(n) => n.clone(),
            _ => unreachable!(),
        };
        self.advance();
        self.expect(Token::Assign)?;

        let nilai = self.parse_expression(Precedence::Lowest)?;

        Ok(Statement::Assignment { nama, nilai, lokasi })
    }

    fn parse_kembalikan(&mut self) -> Result<Statement, IplError> {
        let lokasi = self.current().lokasi.clone();
        self.advance();

        let nilai = if self.current().token == Token::EOF || self.current().token == Token::KurawalTutup {
            None
        } else {
            Some(self.parse_expression(Precedence::Lowest)?)
        };

        Ok(Statement::Kembalikan { nilai, lokasi })
    }

    fn parse_tampilkan(&mut self) -> Result<Statement, IplError> {
        let lokasi = self.current().lokasi.clone();
        self.advance(); 
        
        let mut nilai = Vec::new();

        if self.current().token != Token::EOF && self.current().token != Token::KurawalTutup {
            loop {
                nilai.push(self.parse_expression(Precedence::Lowest)?);
                if self.current().token == Token::Koma {
                    self.advance();
                } else {
                    break;
                }
            }
        }

        Ok(Statement::Tampilkan { nilai, lokasi })
    }

    fn parse_expression_statement(&mut self) -> Result<Statement, IplError> {
        let expr = self.parse_expression(Precedence::Lowest)?;
        Ok(Statement::Expression(expr))
    }

    fn parse_block(&mut self) -> Result<Vec<Statement>, IplError> {
        let is_maka = self.current().token == Token::Maka;
        let is_kurawal = self.current().token == Token::KurawalBuka;

        if !is_maka && !is_kurawal {
            return Err(IplError::Sintaks {
                pesan: "Diharapkan '{' atau 'maka' untuk membuka blok.".to_string(),
                lokasi: self.current().lokasi.clone(),
                saran: None,
            });
        }
        self.advance();

        let mut statements = Vec::new();
        while self.current().token != Token::KurawalTutup 
            && self.current().token != Token::Selesai 
            && self.current().token != Token::EOF 
        {
            statements.push(self.parse_statement()?);
        }

        if is_kurawal {
            self.expect(Token::KurawalTutup)?;
        } else {
            self.expect(Token::Selesai)?;
        }

        Ok(statements)
    }

    fn parse_jika(&mut self) -> Result<Statement, IplError> {
        let lokasi = self.current().lokasi.clone();
        self.advance();

        let kondisi = self.parse_expression(Precedence::Lowest)?;
        let konsekuensi = self.parse_block()?;

        let alternatif = if self.current().token == Token::JikaTidak {
            self.advance();
            if self.current().token == Token::Jika {
                Some(vec![self.parse_jika()?])
            } else {
                Some(self.parse_block()?)
            }
        } else {
            None
        };

        Ok(Statement::Jika { kondisi, konsekuensi, alternatif, lokasi })
    }

    fn parse_selama(&mut self) -> Result<Statement, IplError> {
        let lokasi = self.current().lokasi.clone();
        self.advance();

        let kondisi = self.parse_expression(Precedence::Lowest)?;
        let body = self.parse_block()?;

        Ok(Statement::Selama { kondisi, body, lokasi })
    }

    fn parse_fungsi(&mut self) -> Result<Statement, IplError> {
        let lokasi = self.current().lokasi.clone();
        self.advance();

        let nama = match &self.current().token {
            Token::Identifier(n) => n.clone(),
            _ => return Err(IplError::Sintaks {
                pesan: "Diharapkan nama fungsi.".to_string(),
                lokasi: self.current().lokasi.clone(),
                saran: None,
            }),
        };
        self.advance();

        self.expect(Token::KurungBuka)?;
        let mut parameter = Vec::new();
        if self.current().token != Token::KurungTutup {
            loop {
                match &self.current().token {
                    Token::Identifier(p) => {
                        parameter.push(p.clone());
                        self.advance();
                    }
                    _ => return Err(IplError::Sintaks {
                        pesan: "Diharapkan identifier untuk parameter.".to_string(),
                        lokasi: self.current().lokasi.clone(),
                        saran: None,
                    }),
                }

                if self.current().token == Token::Koma {
                    self.advance();
                } else {
                    break;
                }
            }
        }
        self.expect(Token::KurungTutup)?;

        let body = self.parse_block()?;

        Ok(Statement::DeklarasiFungsi { nama, parameter, body, lokasi })
    }

    fn parse_expression(&mut self, precedence: Precedence) -> Result<Expression, IplError> {
        let mut left = self.parse_prefix()?;

        while self.current().token != Token::EOF && precedence < token_precedence(&self.current().token) {
            left = self.parse_infix(left)?;
        }

        Ok(left)
    }

    fn parse_prefix(&mut self) -> Result<Expression, IplError> {
        let token = self.current().clone();
        match token.token {
            Token::Identifier(name) => {
                self.advance();
                Ok(Expression::Identifier(name, token.lokasi))
            }
            Token::Angka(val) => {
                self.advance();
                Ok(Expression::Angka(val, token.lokasi))
            }
            Token::String(s) => {
                self.advance();
                Ok(Expression::String(s, token.lokasi))
            }
            Token::Benar => {
                self.advance();
                Ok(Expression::Boolean(true, token.lokasi))
            }
            Token::Salah => {
                self.advance();
                Ok(Expression::Boolean(false, token.lokasi))
            }
            Token::Kosong => {
                self.advance();
                Ok(Expression::Kosong(token.lokasi))
            }
            Token::Bukan | Token::Kurang => {
                self.advance();
                let op = if token.token == Token::Bukan { PrefixOperator::Bukan } else { PrefixOperator::Minus };
                let kanan = self.parse_expression(Precedence::Prefix)?;
                Ok(Expression::Prefix { operator: op, kanan: Box::new(kanan), lokasi: token.lokasi })
            }
            Token::KurungBuka => {
                self.advance();
                let expr = self.parse_expression(Precedence::Lowest)?;
                self.expect(Token::KurungTutup)?;
                Ok(expr)
            }
            _ => Err(IplError::Sintaks {
                pesan: format!("Token tidak valid untuk permulaan ekspresi: {:?}", token.token),
                lokasi: token.lokasi,
                saran: None,
            }),
        }
    }

    fn parse_infix(&mut self, left: Expression) -> Result<Expression, IplError> {
        let token = self.current().clone();
        
        if token.token == Token::KurungBuka {
            return self.parse_call_arguments(left);
        }

        let op = match token.token {
            Token::Tambah => InfixOperator::Tambah,
            Token::Kurang => InfixOperator::Kurang,
            Token::Kali => InfixOperator::Kali,
            Token::Bagi => InfixOperator::Bagi,
            Token::Mod => InfixOperator::Mod,
            Token::LebihDari => InfixOperator::LebihDari,
            Token::KurangDari => InfixOperator::KurangDari,
            Token::Minimal => InfixOperator::Minimal,
            Token::Maksimal => InfixOperator::Maksimal,
            Token::SamaDengan => InfixOperator::SamaDengan,
            Token::TidakSamaDengan => InfixOperator::TidakSamaDengan,
            Token::Dan => InfixOperator::Dan,
            Token::Atau => InfixOperator::Atau,
            _ => unreachable!(),
        };

        let precedence = token_precedence(&token.token);
        self.advance();
        let kanan = self.parse_expression(precedence)?;

        Ok(Expression::Infix {
            kiri: Box::new(left),
            operator: op,
            kanan: Box::new(kanan),
            lokasi: token.lokasi,
        })
    }

    fn parse_call_arguments(&mut self, fungsi: Expression) -> Result<Expression, IplError> {
        let lokasi = self.current().lokasi.clone();
        self.advance();
        
        let mut argumen = Vec::new();
        if self.current().token != Token::KurungTutup {
            loop {
                argumen.push(self.parse_expression(Precedence::Lowest)?);
                if self.current().token == Token::Koma {
                    self.advance();
                } else {
                    break;
                }
            }
        }
        self.expect(Token::KurungTutup)?;

        Ok(Expression::Call { fungsi: Box::new(fungsi), argumen, lokasi })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use lexer::Lexer;

    fn test_parse(input: &str) -> Program {
        let mut lexer = Lexer::new(input);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens);
        parser.parse_program().unwrap()
    }

    #[test]
    fn test_parse_deklarasi() {
        let program = test_parse("buat x = 10");
        assert_eq!(program.statements.len(), 1);
        match &program.statements[0] {
            Statement::DeklarasiVariabel { nama, nilai, .. } => {
                assert_eq!(nama, "x");
                if let Expression::Angka(v, _) = nilai {
                    assert_eq!(*v, 10.0);
                } else {
                    panic!("Bukan angka");
                }
            }
            _ => panic!("Bukan deklarasi variabel"),
        }
    }

    #[test]
    fn test_parse_precedence() {
        let program = test_parse("buat x = 10 + 5 * 2");
        match &program.statements[0] {
            Statement::DeklarasiVariabel { nilai, .. } => {
                if let Expression::Infix { operator, kanan, .. } = nilai {
                    assert_eq!(*operator, InfixOperator::Tambah);
                    if let Expression::Infix { operator: op_kanan, .. } = &**kanan {
                        assert_eq!(*op_kanan, InfixOperator::Kali);
                    } else {
                        panic!("Kanan harusnya infix (*)");
                    }
                }
            }
            _ => panic!("Bukan deklarasi variabel"),
        }
    }
}
