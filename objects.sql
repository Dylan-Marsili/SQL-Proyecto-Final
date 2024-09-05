-- DROP DATABASE tourup;
CREATE DATABASE tourup;
USE tourup;

-- ------------------------------------------------------- Tables' Creation Scripts ----------------------------------------------------------------------

-- Table Group: Ubicación y Entidades Relacionadas
DROP TABLE IF EXISTS ubicacion;
CREATE TABLE ubicacion(
    id_location INT NOT NULL AUTO_INCREMENT,
    city_name VARCHAR(30) NOT NULL,
    city_zipcode INT NOT NULL,
    state VARCHAR(30) NOT NULL,
    country VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_location),
    UNIQUE (city_name)
);

-- Table Group: Departamentos y Puestos
DROP TABLE IF EXISTS departamentos;           
CREATE TABLE departamentos(
    id_department INT NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(30)NOT NULL,
    department_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (id_department)
);

DROP TABLE IF EXISTS rangos;
CREATE TABLE rangos(
    id_rank INT NOT NULL AUTO_INCREMENT,
    rank_name_hierarchy VARCHAR(30) NOT NULL,
    salary_floor DECIMAL NOT NULL,
    salary_ceiling DECIMAL NOT NULL,
    PRIMARY KEY (id_rank)
);

DROP TABLE IF EXISTS puestos;   
CREATE TABLE puestos(
    id_position INT NOT NULL AUTO_INCREMENT,
    position_name VARCHAR(30) NOT NULL,
    id_rank INT NOT NULL,
    id_department INT NOT NULL,
    PRIMARY KEY (id_position),
    FOREIGN KEY (id_rank) REFERENCES rangos(id_rank),
    FOREIGN KEY (id_department) REFERENCES departamentos(id_department)
);

-- Table Group: Empleados
DROP TABLE IF EXISTS empleados;
CREATE TABLE empleados(
    id_employee INT NOT NULL AUTO_INCREMENT,
    employee_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(50) NOT NULL,
    address VARCHAR(150) NOT NULL,
    rfc_employee VARCHAR(50) NOT NULL UNIQUE,
    salary DECIMAL NOT NULL,
    employee_bank_name VARCHAR(70) NOT NULL,
    employee_bank_account VARCHAR(12) NOT NULL,
    hiring_date DATE NOT NULL,
    id_location INT,
    id_position INT,
    PRIMARY KEY (id_employee),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location),
    FOREIGN KEY (id_position) REFERENCES puestos(id_position),
    UNIQUE (rfc_employee)
);

-- Table Group: Categorías y Experiencias
DROP TABLE IF EXISTS categoria_actividades;
CREATE TABLE categoria_actividades(
    id_category INT NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_category)
);

DROP TABLE IF EXISTS proveedores_experiencias;
CREATE TABLE proveedores_experiencias(
    id_supplier INT NOT NULL AUTO_INCREMENT,
    company_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(50) NOT NULL,
    main_contact_name VARCHAR(150) NOT NULL,
    payment_method VARCHAR(70) NOT NULL,
    bank_name VARCHAR(150) NOT NULL,
    bank_account VARCHAR(12) NOT NULL,
    supplier_rfc VARCHAR(50) NOT NULL,
    id_location INT NOT NULL,
    PRIMARY KEY (id_supplier),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location),
    UNIQUE (supplier_rfc)
);

DROP TABLE IF EXISTS experiencias_tours;
CREATE TABLE experiencias_tours(
    id_experience INT NOT NULL AUTO_INCREMENT,
    experience_name VARCHAR(150) NOT NULL,
    id_category INT NOT NULL,
    experience_description VARCHAR(255) NOT NULL,
    duration INT NOT NULL,
    requirements_restrictions VARCHAR(255) NOT NULL,
    price_per_person DECIMAL NOT NULL,
    payment_agreement_percent DECIMAL NOT NULL,
    id_location INT NOT NULL,
    id_supplier INT NOT NULL,
    PRIMARY KEY (id_experience),
    FOREIGN KEY (id_category) REFERENCES categoria_actividades(id_category),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location),
    FOREIGN KEY (id_supplier) REFERENCES proveedores_experiencias(id_supplier)
);

-- Table Group: Clientes y Ventas
DROP TABLE IF EXISTS clientes;
CREATE TABLE clientes(
    id_customer INT NOT NULL AUTO_INCREMENT,
    customer_name VARCHAR(150) NOT NULL,
    email VARCHAR(50) NOT NULL,
    phone VARCHAR(70) NOT NULL,
    rfc_customer VARCHAR(50) NOT NULL UNIQUE,
    id_location INT NOT NULL,
    PRIMARY KEY (id_customer),
    FOREIGN KEY (id_location) REFERENCES ubicacion(id_location)
);

DROP TABLE IF EXISTS ventas;
CREATE TABLE ventas(
    id_sale_transaction INT NOT NULL AUTO_INCREMENT,
    id_customer INT NOT NULL,
    id_experience INT NOT NULL,
    sale_date DATE NOT NULL,
    experience_date DATE NOT NULL,
    group_size INT NOT NULL,
    amount_total DECIMAL, 
    id_employee_sale INT NOT NULL,
    notes VARCHAR(255),
    PRIMARY KEY (id_sale_transaction),
    FOREIGN KEY (id_customer) REFERENCES clientes(id_customer),
    FOREIGN KEY (id_experience) REFERENCES experiencias_tours(id_experience),
    FOREIGN KEY (id_employee_sale) REFERENCES empleados(id_employee)
);

-- Table Group: Pagos a Proveedores y Feedback
DROP TABLE IF EXISTS pago_proveedores;
CREATE TABLE pago_proveedores(
    id_payment_transaction INT NOT NULL AUTO_INCREMENT,
    id_sale_transaction INT NOT NULL,
    sale_trx_value DECIMAL(10,2), -- value added via trigger
    commission_agreed DECIMAL(10,2), -- value added via trigger
    total_payment DECIMAL(10,2), -- value added via trigger
    PRIMARY KEY (id_payment_transaction),
    FOREIGN KEY (id_sale_transaction) REFERENCES ventas(id_sale_transaction)
);

DROP TABLE IF EXISTS feedback;
CREATE TABLE feedback(
    id_feedback INT NOT NULL AUTO_INCREMENT,
    id_customer INT NOT NULL,
    id_experience INT NOT NULL, 
    feedback_received VARCHAR(300) NOT NULL,
    feedback_status INT NOT NULL,
    resolution VARCHAR(300),
    PRIMARY KEY (id_feedback),
    FOREIGN KEY (id_customer) REFERENCES clientes(id_customer),
    FOREIGN KEY (id_experience) REFERENCES experiencias_tours(id_experience)
);

-- Table Group: Logs
DROP TABLE IF EXISTS experiencias_tours_log;
CREATE TABLE experiencias_tours_log (
    id_experience INT NOT NULL,
    experience_name VARCHAR(150) NOT NULL,
    id_category INT NOT NULL,
    experience_description VARCHAR(255) NOT NULL,
    duration INT NOT NULL,
    requirements_restrictions VARCHAR(255) NOT NULL,
    price_per_person DECIMAL(10,0) NOT NULL,
    payment_agreement_percent DECIMAL(10,0) NOT NULL,
    id_location INT NOT NULL,
    id_supplier INT NOT NULL,
    date_audit DATETIME NOT NULL,
    type VARCHAR(50) NOT NULL
);

-- ------------------------------------------------------- Trigger Scripts ----------------------------------------------------------------------

-- ---------  TRIGGER PRE- VENTAS --------------------------
DROP TRIGGER IF EXISTS tr_insertar_ventas_totales;
DELIMITER $$
CREATE TRIGGER tr_insertar_ventas_totales
BEFORE INSERT ON ventas
FOR EACH ROW
BEGIN   
    DECLARE exp_price_per_person DECIMAL (10,2);
    
    SELECT price_per_person 
    INTO exp_price_per_person
    FROM experiencias_tours AS e
    WHERE e.id_experience = NEW.id_experience;
    
    SET NEW.amount_total = NEW.group_size * exp_price_per_person;
END;
$$

-- --------- TRIGGER PRE- PAGO A PROVEEDORES ------------------
DROP TRIGGER IF EXISTS tr_detalles_pago_proveedores;
DELIMITER $$
CREATE TRIGGER tr_detalles_pago_proveedores
BEFORE INSERT ON pago_proveedores
FOR EACH ROW
BEGIN
    DECLARE total_sale DECIMAL (10,2);
    DECLARE runat_commission_base DECIMAL(10,2);
    DECLARE total_payment DECIMAL(10,2);
    
    SELECT amount_total INTO total_sale
    FROM ventas AS v
    WHERE v.id_sale_transaction = NEW.id_sale_transaction;
    
    SET NEW.sale_trx_value = total_sale;

    SELECT payment_agreement_percent INTO runat_commission_base
    FROM experiencias_tours AS ex
    INNER JOIN ventas AS v ON (v.id_experience = ex.id_experience)
    WHERE v.id_sale_transaction = NEW.id_sale_transaction;
    
    SET NEW.commission_agreed = runat_commission_base;
    SET total_payment = total_sale - ((runat_commission_base / 100) * total_sale);
    
    SET NEW.total_payment = total_payment;    
END;
$$

-- --------- TRIGGER PRE- UPDATE DE PRECIOS EXPERIENCIAS_TOURS ------------------
DROP TRIGGER IF EXISTS tr_experiencias_tours_update_log;
DELIMITER $$
CREATE TRIGGER tr_experiencias_tours_update_log 
BEFORE UPDATE ON experiencias_tours FOR EACH ROW
BEGIN
    INSERT INTO experiencias_tours_log(
        id_experience, 
        experience_name,
        id_category,
        experience_description,
        duration,
        requirements_restrictions,
        price_per_person,
        payment_agreement_percent,
        id_location,
        id_supplier,
        date_audit,
        type)
    VALUES(
        OLD.id_experience,
        OLD.experience_name,
        OLD.id_category,
        OLD.experience_description,
        OLD.duration,
        OLD.requirements_restrictions,
        OLD.price_per_person,
        OLD.payment_agreement_percent,
        OLD.id_location,
        OLD.id_supplier,
        NOW(),
        'UPDATE'
    );
END;
$$
