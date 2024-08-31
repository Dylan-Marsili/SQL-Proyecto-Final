-- DROP DATABASE tourup;
CREATE DATABASE tourup;
USE tourup;
-- SHOW TABLES;
-- ------------------------------------------------------- Tables' Creation Scripts ----------------------------------------------------------------------

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

DROP TABLE IF EXISTS departamentos;           
CREATE TABLE departamentos(
	id_department INT NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(30)NOT NULL,
    department_description VARCHAR(300) NOT NULL,
    PRIMARY KEY (id_department)
);

DROP TABLE  IF EXISTS rangos;
CREATE TABLE rangos(
	id_rank INT NOT NULL AUTO_INCREMENT,
    rank_name_hierarchy VARCHAR(30) NOT NULL,
    salary_floor DECIMAL NOT NULL,
    salary_ceiling DECIMAL NOT NULL,
    PRIMARY KEY (id_rank)
);

DROP TABLE  IF EXISTS puestos;   
CREATE TABLE puestos(
	id_position INT NOT NULL AUTO_INCREMENT,
    position_name VARCHAR(30) NOT NULL,
    id_rank INT NOT NULL,
    id_department INT NOT NULL,
    PRIMARY KEY (id_position),
    FOREIGN KEY (id_rank) REFERENCES rangos(id_rank),
    FOREIGN KEY (id_department) REFERENCES departamentos(id_department)
);

DROP TABLE  IF EXISTS empleados;
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

DROP TABLE  IF EXISTS categoria_actividades;
CREATE TABLE categoria_actividades(
	id_category INT NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_category)
);        

DROP TABLE  IF EXISTS proveedores_experiencias;
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

DROP TABLE  IF EXISTS experiencias_tours;
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

DROP TABLE  IF EXISTS clientes;
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

DROP TABLE  IF EXISTS ventas;
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

DROP TABLE  IF EXISTS pago_proveedores;
CREATE TABLE pago_proveedores(
	id_payment_transaction INT NOT NULL AUTO_INCREMENT,
    id_sale_transaction INT NOT NULL,
    sale_trx_value DECIMAL(10,2), -- value added via trigger
    commission_agreed DECIMAL(10,2), -- value added via trigger
    total_payment DECIMAL(10,2), -- value added via trigger
    PRIMARY KEY (id_payment_transaction),
    FOREIGN KEY (id_sale_transaction) REFERENCES ventas(id_sale_transaction)
);
 
DROP TABLE  IF EXISTS FEEDBACK;
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

DROP TABLE IF EXISTS experiencias_tours_log;
CREATE TABLE experiencias_tours_log (
		  id_experience int NOT NULL,
		  experience_name varchar(150) NOT NULL,
		  id_category int NOT NULL,
		  experience_description varchar(255) NOT NULL,
		  duration int NOT NULL,
		  requirements_restrictions varchar(255) NOT NULL,
		  price_per_person decimal(10,0) NOT NULL,
		  payment_agreement_percent decimal(10,0) NOT NULL,
		  id_location int NOT NULL,
		  id_supplier int NOT NULL,
		  date_audit datetime NOT NULL,
		  type varchar(50) NOT NULL    
	);


-- ------------------------------------------------------- Trigger Scripts ----------------------------------------------------------------------

  -- ---------  TRIGGER PRE- VENTAS --------------------------
DROP TRIGGER IF EXISTS tr_insertar_ventas_totales;
DELIMITER //
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
//

-- --------- TRIGGER PRE- PAGO A PROVEEDORES ------------------
DROP TRIGGER IF EXISTS tr_detalles_pago_proveedores
DELIMITER //
CREATE TRIGGER tr_detalles_pago_proveedores
BEFORE INSERT ON pago_proveedores
FOR EACH ROW
BEGIN
   
    DECLARE total_sale DECIMAL (10,2);
	DECLARE runat_commission_base DECIMAL(10,2);
    DECLARE total_payment DECIMAL(10,2);
    
    SELECT amount_total
    INTO total_sale
    FROM ventas AS v
    WHERE v.id_sale_transaction = NEW.id_sale_transaction;
    
    SET NEW.sale_trx_value = total_sale;

    SELECT payment_agreement_percent
	INTO runat_commission_base
	FROM experiencias_tours AS ex
		INNER JOIN ventas AS v ON (v.id_experience = ex.id_experience)
    WHERE v.id_sale_transaction = NEW.id_sale_transaction;
    
    SET NEW.commission_agreed = runat_commission_base;
    
    SET total_payment = total_sale - ((runat_commission_base/100) * total_sale);
    
    SET NEW.total_payment = total_payment;    
END;
//

-- --------- TRIGGER PRE- UPDATE DE PRECIOS EXPERIENCIAS_TOURS ------------------
DROP TRIGGER IF EXISTS tr_experiencias_tours_update_log
DELIMITER //
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
		type
	)
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
		SYSDATE(),
		'UPDATE_OLD_SP_REESTR_PRECIOS_LAUNCHED'
	);
END;
//

-- ------------------------------------------------------- Function Creation Scripts ----------------------------------------------------------------------
-- --------- FUNCIÓN PARA CALCULAR PRECIO DE VENTA POR GRUPO--------------
DROP FUNCTION IF EXISTS f_precio_venta_grupo
DELIMITER && 
CREATE FUNCTION f_precio_venta_grupo(param_number_of_people INT, param_id_experience INT)
RETURNS DECIMAL (10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE individual_price DECIMAL(10);
    DECLARE total_price DECIMAL(10);
    
    SELECT price_per_person INTO individual_price
    FROM experiencias_tours
    WHERE id_experience = param_id_experience;
    
    SET total_price = individual_price * param_number_of_people;
    
    RETURN total_price;
    
END;
&& 
-- SELECT f_precio_venta_grupo(8,72);


-- --FUNCIÓN PARA CALCULAR VENTAS LOGRADAS POR EMPLEADO (EXCLUSIVO AREA DE VENTAS--
DROP FUNCTION IF EXISTS f_ventas_por_empleado;
DELIMITER %%
CREATE FUNCTION  `f_ventas_por_empleado` (param_id_employee INT)
RETURNS INTEGER DETERMINISTIC
BEGIN
RETURN
	(SELECT count(*)
     FROM ventas AS v
     WHERE v.id_employee_sale = param_id_employee);   
END;
%%
-- SELECT * FROM analisis_salarios
-- WHERE position_name LIKE '%ven%';
-- SELECT f_ventas_por_empleado(16);


-- ------FUNCIÓN PARA CALCULAR % DE BONO SOBRE VENTAS POR EMPLEADO ------
DROP FUNCTION IF EXISTS f_definir_bono;
DELIMITER $$
CREATE FUNCTION `f_definir_bono`(param_total_sales DECIMAL(10))
RETURNS DECIMAL (10,2)
DETERMINISTIC
BEGIN
	DECLARE bonus DECIMAL (10,2);    
    IF param_total_sales > 400000 THEN
		SET bonus = 0.03;
	ELSEIF param_total_sales BETWEEN 200000 AND 399000 THEN
		SET bonus = 0.02;
	ELSE 
		SET bonus = 0.005;
	END IF;
    
    RETURN bonus;
END;
$$
-- SELECT f_definir_bono(500000); 


-- --FUNCIÓN PARA ASIGNAR EL % DE VARIACIÓN(DELTA) DE PRECIOS A CADA TOUR A PARTIR DE SUS VENTAS ANUALES --
DROP FUNCTION IF EXISTS f_definir_delta_precios;
DELIMITER //
CREATE FUNCTION `f_definir_delta_precios`(param_units_sold DECIMAL(10),param_price_per_person DECIMAL(10))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
	DECLARE price_delta DECIMAL(10,2);
    
    SET price_delta = CASE
		WHEN param_units_sold < 10 THEN 1/1.20
        WHEN param_units_sold BETWEEN 11 AND 20 AND  param_price_per_person < 1600 THEN 1/1.05
        WHEN param_units_sold  BETWEEN 11 AND 20 AND param_price_per_person >= 1600 THEN 1/1.10
        WHEN param_units_sold > 21 THEN 1.10
        ELSE 1
	END;
    
    RETURN price_delta;        
END;
//
-- f_definir_delta_precios(param_units_sold, param_price_per_person)


-- ------------------------------------------------------- Stored Procedure Scripts ----------------------------------------------------------------------

-- ----RUTINA PARA ASIGNAR BONOS ANUALES A EMPLEADOS DE VENTAS----
DROP PROCEDURE IF EXISTS sp_asignar_bono
DELIMITER ??
CREATE PROCEDURE `sp_asignar_bono`()
BEGIN	
    DROP VIEW IF EXISTS v_ventas_por_empleado;
    CREATE VIEW v_ventas_por_empleado AS
    SELECT 
	v.id_employee_sale,
    e.employee_name,
    p.position_name,
	sum(v.group_size * ex.price_per_person) AS sale_per_employee
FROM ventas AS v
	INNER JOIN experiencias_tours AS ex ON (v.id_experience = ex.id_experience)
    INNER JOIN empleados AS e ON (e.id_employee = v.id_employee_sale)
    INNER JOIN puestos AS p ON (p.id_position = e.id_position)
GROUP BY 
	v.id_employee_sale
ORDER BY 
	sale_per_employee DESC;    
    
DROP VIEW IF EXISTS v_bono_por_empleado;
CREATE VIEW v_bono_por_empleado AS
SELECT 
	spe.id_employee_sale,
    spe.employee_name,
    spe.position_name,
	spe.sale_per_employee,
	e.salary * 12 AS yearly_salary,
    f_definir_bono(spe.sale_per_employee) AS bonus_percentage,
    f_definir_bono(spe.sale_per_employee) * spe.sale_per_employee AS total_bonus,
    (e.salary*12) + (spe.sale_per_employee * f_definir_bono(spe.sale_per_employee)) AS total_payment
FROM v_ventas_por_empleado AS spe
	INNER JOIN empleados AS e ON (e.id_employee = spe.id_employee_sale);

SELECT * FROM v_bono_por_empleado;
END;
??
-- CALL sp_asignar_bono()


-- ----RUTINA PARA VERIFICAR QUÉ CLIENTES COMPRARON UN TOUR ESPECÍFICO----
DROP PROCEDURE IF EXISTS sp_clientes_por_experiencia;
DELIMITER **
CREATE PROCEDURE `sp_clientes_por_experiencia`(IN param_id_experience INT)
BEGIN
    SELECT 
		ex.experience_name,
		c.customer_name,
        c.email,
        cloc.state AS customer_residing_state,
        loc.state AS tour_experience_state,
        v.group_size,
        v.amount_total
    FROM VENTAS AS v
		INNER JOIN experiencias_tours AS ex ON (ex.id_experience = v.id_experience)
		INNER JOIN clientes AS c ON(v.id_customer = c.id_customer)
        INNER JOIN ubicacion AS loc ON (ex.id_location = loc.id_location)
        INNER JOIN ubicacion AS cloc ON (c.id_location = cloc.id_location)
	WHERE v.id_experience = param_id_experience;
END;
**
-- CALL sp_clientes_por_experiencia(25)


-- ----RUTINA PARA EJECUTAR LA ACTUALIZACIÓN ANUAL DE PRECIOS----
DROP PROCEDURE IF EXISTS sp_reestructuracion_anual_precios;
DELIMITER $$
CREATE PROCEDURE `sp_reestructuracion_anual_precios`()
BEGIN 
	-- declaración de variables requeridas
	DECLARE transition_table_name VARCHAR(255);
    SET transition_table_name = CONCAT('transition_prices_template_', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'));           
    
    -- creación de vista con nuevos precios
	DROP VIEW IF EXISTS v_new_price_definition;
	CREATE VIEW v_new_price_definition AS
    SELECT 
        ex.id_experience,
        ex.experience_name,
        ex.price_per_person,
        SUM(v.amount_total) AS total_sales,
        SUM(v.amount_total) / price_per_person AS unit_tours_sold,
        F_DEFINIR_DELTA_PRECIOS(SUM(v.amount_total) / price_per_person, ex.price_per_person) AS price_delta,
        ex.price_per_person * F_DEFINIR_DELTA_PRECIOS(SUM(v.amount_total) / price_per_person, ex.price_per_person) AS new_price
    FROM experiencias_tours AS ex
		INNER JOIN ventas AS v ON (v.id_experience = ex.id_experience)
    GROUP BY ex.id_experience , ex.experience_name
    ORDER BY unit_tours_sold DESC;		    

    -- creación de tabla de transición con precios viejos y nuevos
    DROP TABLE IF EXISTS transition_prices_template;
	CREATE TABLE transition_prices_template LIKE experiencias_tours;
	INSERT INTO transition_prices_template SELECT * FROM experiencias_tours;
	ALTER TABLE transition_prices_template	
		ADD COLUMN old_price DECIMAL(10,2) DEFAULT NULL;
	UPDATE transition_prices_template AS np 
		SET np.old_price = np.price_per_person;
	UPDATE transition_prices_template AS ex
        INNER JOIN v_new_price_definition AS np ON (ex.id_experience = np.id_experience) 
		SET ex.price_per_person = np.new_price;		
    
	-- creación de tabla con nombre dinámico como backup de los datos históricos pre update
     SET @consulta_create = CONCAT('CREATE TABLE ', transition_table_name, ' LIKE transition_prices_template');
	 PREPARE statement FROM @consulta_create;
	 EXECUTE statement;
	 DEALLOCATE PREPARE statement;  
     -- inserción de datos en la tabla con nombre dinámico como backup de los datos históricos pre update
     SET @consulta_insert = CONCAT('INSERT INTO ', transition_table_name, ' SELECT * FROM transition_prices_template');
     PREPARE statement FROM @consulta_insert;
	 EXECUTE statement;
	 DEALLOCATE PREPARE statement;   
   
	-- actualización/alteración de la tabla base con los nuevos precios
	UPDATE experiencias_tours AS ex
        INNER JOIN transition_prices_template AS tpt ON (tpt.id_experience = ex.id_experience) 
	SET 
		ex.experience_name = tpt.experience_name,
		ex.id_category = tpt.id_category,
		ex.experience_description = tpt.experience_description,
		ex.duration = tpt.duration,
		ex.requirements_restrictions = tpt.requirements_restrictions,
		ex.price_per_person = tpt.price_per_person,
		ex.payment_agreement_percent = tpt.payment_agreement_percent,
		ex.id_location = tpt.id_location,
		ex.id_supplier = tpt.id_supplier;
	
    -- llamado a las tablas de resultados principales y secundarias del proceso
	SELECT * FROM v_new_price_definition AS new_prices;
	SELECT * FROM transition_prices_template AS transition_template;
	SELECT * FROM experiencias_tours AS experiencias_tours;
	SET @consulta_select = CONCAT('SELECT * FROM ', transition_table_name);
	PREPARE statement FROM @consulta_select;
	EXECUTE statement;
	DEALLOCATE PREPARE statement; 
        
END;
$$
-- call sp_reestructuracion_anual_precios();


-- ----RUTINA PARA SELECCIONAR TABLAS PARA EL DIRECTOR DE VENTAS (USO DEL CÓDIGO DE ERROR)----
DROP PROCEDURE sp_seleccionar_tabla
DELIMITER !!
CREATE PROCEDURE sp_seleccionar_tabla(param_tabla VARCHAR(20))
BEGIN 
	IF param_tabla = 'ventas' THEN
		SELECT * FROM ventas;
	ELSEIF param_tabla = 'experiencias_tours' THEN
		SELECT * FROM experiencias_tours;
	ELSEIF param_tabla = 'feedback' THEN
		SELECT * FROM feedback;
	ELSE
		SIGNAL sqlstate VALUE '99900'
			SET MESSAGE_TEXT = 'ERROR: No tiene permisos para ver la tabla seleccionada';
	END IF;
END;
!!
-- CALL sp_seleccionar_tabla('ventas')


-- ----RUTINA PARA SELECCIONAR CUALQUIER TABLA DEL SISTEMA (USO AISLADO DE CONSULTAS DINÁMICAS)----
DROP PROCEDURE sp_seleccionar_tabla_dir
DELIMITER ¡¡
CREATE PROCEDURE sp_seleccionar_tabla_dir(param_tabla_dir VARCHAR(20))
BEGIN 
	SET @table_requested_dir = CONCAT('SELECT * FROM ', param_tabla_dir);
	
    PREPARE cursor_sql FROM @table_requested_dir;
    EXECUTE cursor_sql;
    DEALLOCATE PREPARE cursor_sql;    
END;
¡¡
-- CALL sp_seleccionar_tabla_dir('puestos')


-- ------------------------------------------------------- View Creation Scripts ----------------------------------------------------------------------
    
-- ----VISTA DE PAGO A PROVEEDORES----
-- DROP VIEW IF EXISTS v_pagos_proveedores;
CREATE VIEW v_pagos_proveedores AS
SELECT 
	v.id_sale_transaction,
    v.sale_date, 
    v.group_size, 
    ex.price_per_person, 
    ex.payment_agreement_percent, 
    v.group_size * ex.price_per_person AS sale_value,
    (v.group_size * ex.price_per_person) - ((v.group_size * ex.price_per_person) * (ex.payment_agreement_percent / 100)) AS supplier_payment,
    DATE_ADD(v.sale_date, INTERVAL 20 DAY) AS payment_date
FROM  ventas as V	
INNER JOIN experiencias_tours as ex ON (v.id_experience = ex.id_experience)
ORDER BY payment_date;
-- SELECT * FROM v_pagos_proveedores;


-- ----VISTA DE RESULTADOS DE TRANSACCIONES POR PROVEEDOR----
-- DROP VIEW IF EXISTS v_transacciones_por_proveedor;
CREATE VIEW v_transacciones_por_proveedor AS
SELECT 
	ex.id_supplier, 
	p.company_name,
    COUNT(v.id_sale_transaction) as total_transactions,
	SUM(v.group_size * ex.price_per_person) AS total_sales
FROM ventas AS v
	INNER JOIN experiencias_tours AS ex ON (v.id_experience = ex.id_experience)
    INNER JOIN proveedores_experiencias AS p ON (p.id_supplier = ex.id_supplier)
GROUP BY 
	ex.id_supplier,
    p.company_name
ORDER BY total_sales DESC;
-- SELECT * FROM v_transacciones_por_proveedor;


-- ----------------VISTA DE VENTAS POR ESTADO -----------------
-- DROP VIEW IF EXISTS v_ventas_por_estado;
CREATE VIEW v_ventas_por_estado AS
SELECT 
	ex.id_location, 
    loc.state, 
    COUNT(v.id_sale_transaction) AS transactions_per_state,
    SUM(v.group_size * ex.price_per_person) AS sales_per_state
FROM ventas AS v
	INNER JOIN experiencias_tours AS ex ON (v.id_experience = ex.id_experience)
	INNER JOIN ubicacion AS loc ON (ex.id_location = loc.id_location)
GROUP BY
	ex.id_location, 
    loc.state
ORDER BY
	sales_per_state DESC;
-- SELECT * FROM v_ventas_por_estado;

-- ----------VISTA DEL TOP 10 DE EXPERIENCIAS VENDIDAS ---------
-- DROP VIEW IF EXISTS v_top_sellers_experiencias;
CREATE VIEW v_top_sellers_experiencias AS
SELECT 
	ex.id_experience,
    ex.experience_name, 
    SUM(v.amount_total) AS total_sales
FROM experiencias_tours AS ex
	INNER JOIN ventas AS v ON (v.id_experience = ex.id_experience)
GROUP BY
	ex.id_experience,
    ex.experience_name
ORDER BY
	total_sales DESC
LIMIT 10;
-- SELECT * FROM v_top_sellers_experiencias;

-- ----VISTA DE ANÁLISIS DE NÓMINA Y EQUIDAD SALARIAL----
-- DROP VIEW IF EXISTS v_analisis_salarios;
CREATE VIEW v_analisis_salarios AS
SELECT 
	e.id_employee,
    e.employee_name,
    p.position_name,
    d.department_name,
    r.id_rank,
    r.rank_name_hierarchy,
    e.salary,
    r.salary_floor,
    r.salary_ceiling
FROM empleados AS e
	INNER JOIN puestos as p ON (p.id_position = e.id_position)
    INNER JOIN rangos as r ON (r.id_rank = p.id_rank)
    INNER JOIN departamentos as d ON(p.id_department=d.id_department)
ORDER BY
	salary DESC;
-- SELECT * FROM v_analisis_salarios;
