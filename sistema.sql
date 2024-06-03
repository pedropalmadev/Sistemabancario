CREATE DATABASE SistemaBancario;
USE SistemaBancario;

-- Tabela de Clientes
CREATE TABLE Cliente (
    CPF BIGINT PRIMARY KEY,
    Nome VARCHAR(255),
    DataNasc DATE,
    Email VARCHAR(255),
    Telefone VARCHAR(250),
    Endereco VARCHAR(255)
);

-- Tabela de Contas Bancárias
CREATE TABLE Conta (
    NumeroConta INT PRIMARY KEY,
    TipoConta VARCHAR(20),
    Saldo DECIMAL(10, 2),
    CPFCliente BIGINT,
    FOREIGN KEY (CPFCliente) REFERENCES Cliente(CPF)
);

-- Tabela de Transações
CREATE TABLE Transacao (
    IdTransacao INT PRIMARY KEY,
    TipoTransacao VARCHAR(20),
    Valor DECIMAL(10, 2),
    DataHora DATE,
    NumeroConta INT NOT NULL,
    FOREIGN KEY (NumeroConta) REFERENCES Conta(NumeroConta)
);

-- Tabela de Histórico de Transações
CREATE TABLE HistoricoTransacoes (
    IdHistorico INT PRIMARY KEY,
    IdTransacao INT,
    Descricao VARCHAR(255),
    FOREIGN KEY(IdTransacao) REFERENCES Transacao(IdTransacao)
);

-- Inserting into Cliente table
INSERT INTO Cliente (CPF, Nome, DataNasc, Email, Telefone, Endereco)
VALUES
    (12345678901, 'João Silva', '1990-01-01', 'joao@example.com', '123-456789', 'Rua A, 123'),
    (98765432102, 'Maria Oliveira', '1985-12-15', 'maria@example.com', '987-654321', 'Rua C, 789'),
    (98765432103, 'José Oliveira', '1990-02-14', 'jose@example.com', '987-654322', 'Rua D, 890'),
    (98765432104, 'Pedro Santos', '1988-05-18', 'pedro@example.com', '987-654323', 'Rua E, 901'),
    (98765432105, 'Ana Silva', '1992-10-11', 'ana@example.com', '987-654324', 'Rua F, 1002'),
    (98765432106, 'Luiz Pereira', '1995-06-16', 'luiz@example.com', '987-654325', 'Rua G, 1013');

-- Inserindo na tabela Conta
INSERT INTO Conta (NumeroConta, TipoConta, Saldo, CPFCliente)
VALUES (1001, 'Conta Corrente', 1000.00, 12345678901),
       (1002, 'Cartão de Crédito', 5000.00, 12345678901),
       (1003, 'Conta Corrente', 1500.00, 98765432102),
       (1004, 'Poupança', 2500.00, 98765432102);

INSERT INTO Transacao (IdTransacao, TipoTransacao, Valor, DataHora, NumeroConta)
VALUES (1, 'Débito', 1000.00, '2023-11-17 08:00:00', 1001),
       (2, 'Crédito', 2000.00, '2023-11-17 12:00:00', 1002),
       (3, 'Débito', 500.00, '2023-11-17 20:00:00', 1001),
       (4, 'Débito', 3100.00, '2023-11-18 10:00:00', 1003),
       (5, 'Crédito', 2500.00, '2023-11-18 15:00:00', 1004);

INSERT INTO HistoricoTransacoes (IdHistorico, IdTransacao, Descricao)
VALUES (1, 1, 'Compra de mercadorias'),
       (2, 2, 'Depósito na poupança'),
       (3, 3, 'Pagamento de conta'),
       (4, 4, 'Compra de roupas'),
       (5, 5, 'Depósito da folha de pagamento');

-- Procedure para encontrar as transações com valor maior que 1500
CREATE PROCEDURE Valoracimade1500
AS
BEGIN
    SELECT
        t.IdTransacao,
        t.TipoTransacao,
        t.Valor,
        t.DataHora,
        cl.Nome,
        cl.CPF
    FROM
        Transacao t
    INNER JOIN
        Conta c ON t.NumeroConta = c.NumeroConta
    INNER JOIN
        Cliente cl ON c.CPFCliente = cl.CPF
    WHERE
        t.Valor > 1500;
END;

-- Seleciona apenas transições em credito
CREATE PROCEDURE ApenasCredito
AS
BEGIN
    SELECT *
    FROM Transacao, Cliente
    WHERE TipoTransacao = 'Crédito';
END;

-- Seleciona transições apenas em debito
CREATE PROCEDURE ApenasDebito
AS
BEGIN
    SELECT *
    FROM Transacao, Cliente
    WHERE TipoTransacao = 'Débito';
END;

-- Seleciona apenas contas correntes
CREATE PROCEDURE ApenasContaCorrente
AS
BEGIN
    SELECT * FROM Conta, Cliente WHERE TipoConta = 'Conta Corrente';
END;

-- Seleciona apenas conta poupança
CREATE PROCEDURE ApenasContaPoupanca
AS
BEGIN
    SELECT * FROM Conta, Cliente WHERE TipoConta = 'Poupança';
END;

-- Executando as procedures
EXEC Valoracimade1500;
EXEC ApenasCredito;
EXEC ApenasDebito;
EXEC ApenasContaCorrente;
EXEC ApenasContaPoupanca;

-- Triggers
CREATE TRIGGER trg_PrevenirSaldoNegativo
BEFORE UPDATE ON Conta
FOR EACH ROW
BEGIN
    IF NEW.Saldo < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo não pode ser negativo.';
    END IF;
END;

CREATE TRIGGER trg_LogarTransacao
AFTER INSERT ON Transacao
FOR EACH ROW
BEGIN
    INSERT INTO HistoricoTransacoes (IdTransacao, Descricao)
    VALUES (NEW.IdTransacao, CONCAT('Transação de tipo ', NEW.TipoTransacao, ' na conta ', NEW.NumeroConta));
END;

CREATE TRIGGER trg_AtualizarSaldo
AFTER INSERT ON Transacao
FOR EACH ROW
BEGIN
    IF NEW.TipoTransacao = 'Crédito' THEN
        UPDATE Conta SET Saldo = Saldo + NEW.Valor WHERE NumeroConta = NEW.NumeroConta;
    ELSE
        UPDATE Conta SET Saldo = Saldo - NEW.Valor WHERE NumeroConta = NEW.NumeroConta;
    END IF;
END;

CREATE TRIGGER trg_PrevenirTransacoesEmContasInativas
BEFORE INSERT ON Transacao
FOR EACH ROW
BEGIN
    IF (SELECT TipoConta FROM Conta WHERE NumeroConta = NEW.NumeroConta) IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conta inativa.';
    END IF;
END;

CREATE TRIGGER trg_AtualizarInformacoesDoCliente
AFTER UPDATE ON Conta
FOR EACH ROW
BEGIN
    UPDATE Cliente SET Nome = NEW.Nome, Email = NEW.Email, Telefone = NEW.Telefone, Endereco = NEW.Endereco
    WHERE CPF = NEW.CPFCliente;
END;


-- Selecionando todas as informações das tabelas Cliente, Transacao e HistoricoTransacoes
SELECT * FROM Cliente, Transacao, HistoricoTransacoes;

-- Selecionando as informações da tabela Transacao
SELECT * FROM Transacao;

-- Selecionando as informações da tabela HistoricoTransacoes
SELECT * FROM HistoricoTransacoes;
