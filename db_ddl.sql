-- =====================================================
-- ESQUEMA OTIMIZADO: E-COMMERCE
-- =====================================================
-- Otimizações:
-- - Nomes de colunas sem espaços (ex: `first_name` ao invés de `first name`).
-- - Tipos de dados corrigidos (DECIMAL para dinheiro, INT para quantidades).
-- - Chaves primárias e estrangeiras simplificadas e mais robustas.
-- - Nomes de tabelas de junção mais concisos (ex: `ProductSupplier`).
-- =====================================================

CREATE SCHEMA IF NOT EXISTS `ecommerce_dio_v2` DEFAULT CHARACTER SET utf8mb4 ;
USE `ecommerce_dio_v2` ;

-- -----------------------------------------------------
-- Tabela `Client`
-- - Adicionado `client_type` para diferenciar Pessoa Física de Jurídica.
-- - Colunas renomeadas para o padrão `snake_case`.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`Client` (
  `idClient` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(45) NOT NULL,
  `surname` VARCHAR(45) NOT NULL,
  `client_type` ENUM('PF', 'PJ') NOT NULL,
  `document` VARCHAR(14) NOT NULL, -- Armazena CPF ou CNPJ sem formatação
  `address` VARCHAR(255) NULL,
  `birthdate` DATE NOT NULL,
  PRIMARY KEY (`idClient`),
  UNIQUE INDEX `document_UNIQUE` (`document` ASC) VISIBLE
);

-- -----------------------------------------------------
-- Tabela `Product`
-- - `value` alterado para DECIMAL(10,2) para precisão monetária.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`Product` (
  `idProduct` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(45) NOT NULL,
  `description` VARCHAR(255) NULL,
  `value` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`idProduct`)
);

-- -----------------------------------------------------
-- Tabela `PaymentMethod`
-- - Tabela renomeada de `Payments` para refletir que são métodos de pagamento do cliente.
-- - `limitAvailable` alterado para DECIMAL.
-- - Adicionada Foreign Key para `idClient`.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`PaymentMethod` (
  `idPaymentMethod` INT NOT NULL AUTO_INCREMENT,
  `idClient` INT NOT NULL,
  `type` ENUM('Boleto', 'Cartão', 'Dois Cartões', 'Pix') NOT NULL,
  `limitAvailable` DECIMAL(10,2) NULL DEFAULT 0,
  PRIMARY KEY (`idPaymentMethod`),
  CONSTRAINT `fk_Payment_Client`
    FOREIGN KEY (`idClient`)
    REFERENCES `ecommerce_dio_v2`.`Client` (`idClient`)
);

-- -----------------------------------------------------
-- Tabela `Order`
-- - Colunas de FK renomeadas para clareza (`idClient`, `idPaymentMethod`).
-- - Foreign Key para `PaymentMethod` simplificada.
-- - `deliveryCost` alterado para DECIMAL.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`Order` (
  `idOrder` INT NOT NULL AUTO_INCREMENT,
  `idClient` INT NOT NULL,
  `idPaymentMethod` INT NOT NULL,
  `status` ENUM('Em Andamento', 'Processando', 'Enviado', 'Entregue', 'Cancelado') NOT NULL DEFAULT 'Processando',
  `description` VARCHAR(255) NULL,
  `deliveryCost` DECIMAL(10,2) NULL DEFAULT 0.00,
  `order_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idOrder`),
  CONSTRAINT `fk_Order_Client`
    FOREIGN KEY (`idClient`)
    REFERENCES `ecommerce_dio_v2`.`Client` (`idClient`),
  CONSTRAINT `fk_Order_PaymentMethod`
    FOREIGN KEY (`idPaymentMethod`)
    REFERENCES `ecommerce_dio_v2`.`PaymentMethod` (`idPaymentMethod`)
);

-- -----------------------------------------------------
-- Tabela `ProductOrder` (antiga `Product_has_Order`)
-- - `amount` alterado para INT.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`ProductOrder` (
  `idProduct` INT NOT NULL,
  `idOrder` INT NOT NULL,
  `amount` INT NOT NULL DEFAULT 1,
  `status` ENUM('Disponível', 'Sem estoque') NOT NULL DEFAULT 'Disponível',
  PRIMARY KEY (`idProduct`, `idOrder`),
  CONSTRAINT `fk_ProductOrder_Product`
    FOREIGN KEY (`idProduct`)
    REFERENCES `ecommerce_dio_v2`.`Product` (`idProduct`),
  CONSTRAINT `fk_ProductOrder_Order`
    FOREIGN KEY (`idOrder`)
    REFERENCES `ecommerce_dio_v2`.`Order` (`idOrder`)
);

-- -----------------------------------------------------
-- Tabela `Tracker`
-- - `idTracker` agora é a única chave primária.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`Tracker` (
  `idTracker` INT NOT NULL AUTO_INCREMENT,
  `idOrder` INT NOT NULL,
  `place` VARCHAR(100) NOT NULL,
  `tracker_time` DATETIME NOT NULL,
  `tracker_code` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`idTracker`),
  INDEX `idx_tracker_code` (`tracker_code`), -- Índice para buscas por código de rastreio
  CONSTRAINT `fk_Tracker_Order`
    FOREIGN KEY (`idOrder`)
    REFERENCES `ecommerce_dio_v2`.`Order` (`idOrder`)
);

-- -----------------------------------------------------
-- Outras Tabelas (Supplier, Vendor, Stock) com melhorias
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`Supplier` (
  `idSupplier` INT NOT NULL AUTO_INCREMENT,
  `corporate_name` VARCHAR(100) NOT NULL,
  `cnpj` CHAR(14) NOT NULL,
  PRIMARY KEY (`idSupplier`),
  UNIQUE INDEX `cnpj_UNIQUE` (`cnpj` ASC) VISIBLE
);

CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`Vendor` (
  `idVendor` INT NOT NULL AUTO_INCREMENT,
  `corporate_name` VARCHAR(100) NOT NULL,
  `fantasy_name` VARCHAR(100) NULL,
  `seller_name` VARCHAR(100) NOT NULL,
  `address` VARCHAR(255) NULL,
  PRIMARY KEY (`idVendor`),
  UNIQUE INDEX `corporate_name_UNIQUE` (`corporate_name` ASC) VISIBLE
);

CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`Stock` (
  `idStock` INT NOT NULL AUTO_INCREMENT,
  `place` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`idStock`)
);

-- -----------------------------------------------------
-- Tabelas de Junção com Nomes Simplificados
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`ProductVendor` (
  `idVendor` INT NOT NULL,
  `idProduct` INT NOT NULL,
  `amount` INT NOT NULL,
  PRIMARY KEY (`idVendor`, `idProduct`),
  CONSTRAINT `fk_ProductVendor_Vendor` FOREIGN KEY (`idVendor`) REFERENCES `Vendor` (`idVendor`),
  CONSTRAINT `fk_ProductVendor_Product` FOREIGN KEY (`idProduct`) REFERENCES `Product` (`idProduct`)
);

CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`ProductSupplier` (
  `idSupplier` INT NOT NULL,
  `idProduct` INT NOT NULL,
  PRIMARY KEY (`idSupplier`, `idProduct`),
  CONSTRAINT `fk_ProductSupplier_Supplier` FOREIGN KEY (`idSupplier`) REFERENCES `Supplier` (`idSupplier`),
  CONSTRAINT `fk_ProductSupplier_Product` FOREIGN KEY (`idProduct`) REFERENCES `Product` (`idProduct`)
);

CREATE TABLE IF NOT EXISTS `ecommerce_dio_v2`.`ProductStock` (
  `idProduct` INT NOT NULL,
  `idStock` INT NOT NULL,
  `quantity` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`idProduct`, `idStock`),
  CONSTRAINT `fk_ProductStock_Product` FOREIGN KEY (`idProduct`) REFERENCES `Product` (`idProduct`),
  CONSTRAINT `fk_ProductStock_Stock` FOREIGN KEY (`idStock`) REFERENCES `Stock` (`idStock`)
);


-- =====================================================
-- CONSULTAS OTIMIZADAS
-- - Uso de aliases (ex: `p` para `Product`) para tornar o código mais limpo.
-- - Remoção de nomes de schema (`ecommerce_dio_v2`) que são desnecessários após `USE`.
-- - Consultas reestruturadas para melhor performance e legibilidade.
-- =====================================================

-- -----------------------------------------------------
-- Pergunta: Quais são os pedidos do usuário de ID = 2?
-- -----------------------------------------------------
SELECT
    p.name AS product_name,
    p.value,
    p.category,
    o.description AS order_description,
    o.status,
    o.deliveryCost
FROM ProductOrder AS po
INNER JOIN `Order` AS o ON po.idOrder = o.idOrder
INNER JOIN Product AS p ON po.idProduct = p.idProduct
WHERE o.idClient = 2;

-- -----------------------------------------------------
-- Pergunta: Quais fornecedores (suppliers) vendem 'Alface crespa'?
-- - A condição foi movida para a cláusula WHERE, que é mais otimizada
--   para filtros do que HAVING.
-- -----------------------------------------------------
SELECT
    p.name,
    GROUP_CONCAT(s.corporate_name SEPARATOR ', ') AS suppliers
FROM ProductSupplier AS ps
INNER JOIN Supplier AS s ON ps.idSupplier = s.idSupplier
INNER JOIN Product AS p ON ps.idProduct = p.idProduct
WHERE p.name = 'Alface crespa'
GROUP BY p.name;

-- -----------------------------------------------------
-- Pergunta: Quais os produtos disponíveis ordenados por categoria?
-- -----------------------------------------------------
SELECT
    name,
    category,
    value
FROM Product
ORDER BY category, name;

-- -----------------------------------------------------
-- Pergunta: Qual é o detalhamento de entrega do pedido com o código de rastreio '20230801CX95PI021'?
-- - A consulta foi simplificada, removendo a subconsulta desnecessária
--   e usando JOINs diretos, o que é mais eficiente e legível.
-- -----------------------------------------------------
SELECT
    p.name AS product_name,
    t.tracker_code,
    t.tracker_time,
    t.place
FROM Tracker AS t
INNER JOIN ProductOrder AS po ON t.idOrder = po.idOrder
INNER JOIN Product AS p ON po.idProduct = p.idProduct
WHERE t.tracker_code = '20230801CX95PI021'
ORDER BY t.tracker_time DESC;
