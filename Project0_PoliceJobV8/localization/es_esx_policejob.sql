USE `es_extended`;

INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('police', 'Guardia Civil')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('police',0,'recruit','Guardia Alumno',900,'{}','{}'),
	('police',1,'GC_Primera','Guardia Civil De Primera',1200,'{}','{}'),
	('police',2,'Cabo','Cabo',1200,'{}','{}'),
	('police',3,'Cabo_Mayor','Cabo Mayor',1200,'{}','{}'),
	('police',4,'Sargento','Sargento',1500,'{}','{}'),
	('police',5,'Sargento_Primero','Sargento Primero',1500,'{}','{}'),
	('police',6,'Brigada','Brigada',1500,'{}','{}'),
	('police',7,'Sub-Teniente','Sub-Teniente',1800,'{}','{}'),
	('police',8,'Sub-Oficial_Mayor','Sub-Oficial Mayor',1800,'{}','{}'),
	('police',9,'Alférez','Alférez',1800,'{}','{}'),
	('police',10,'Teniente','Teniente',1800,'{}','{}'),
	('police',11,'Capitan','Capitan',1800,'{}','{}'),
	('police',12,'Comandante','Comandante',2100,'{}','{}'),
	('police',12,'Teniente_Coronel','Teniente Coronel',2100,'{}','{}'),
	('police',13,'Coronel','Coronel',2100,'{}','{}'),
	('police',14,'General_Brigada','General De Brigada',2500,'{}','{}'),
	('police',15,'General_Division','General De Division',2500,'{}','{}'),
	('police',16,'Teniente_General','Teniente General',2700,'{}','{}')
;

INSERT INTO `fine_types` (label, amount, category) VALUES
	('Mal uso del claxon', 200, 0),
	('Cruzar ilegalmente una línea continua', 400, 0),
	('Conducir por el lado equivocado de la carretera', 2500, 0),
	('Cambio de sentido ilegal', 2500, 0),
	('Conducir ilegalmente fuera de la carretera', 1700, 0),
	('Rechazar un mandato legal', 300, 0),
	('Detención ilegal de un vehículo', 1500, 0),
	('Estacionamiento ilegal', 700, 0),
	('No ceder a la derecha', 700, 0),
	('Incumplimiento de la información del vehículo', 900, 0),
	('No detenerse en una señal de pare ', 1050, 0),
	('No detenerse en un semáforo en rojo', 1300, 0),
	('Paso ilegal', 1000, 0),
	('Conducir un vehículo ilegal', 1000, 0),
	('Conducir sin licencia', 1500, 0),
	('Pegar y corre', 8000, 0),
	('Exceder velocidades superiores a <5 mph', 900, 0),
	('Exceder velocidades superiores a 5-15 mph', 1200, 0),
	('Exceder velocidades superiores a 15-30 mph', 1800, 0),
	('Exceder velocidades superiores a 30 mph', 1800, 0),
	('Impedir el flujo de tráfico', 1100, 1),
	('Intoxicación pública', 900, 1),
	('Conducta desordenada', 900, 1),
	('Obstrucción a la justicia', 1300, 1),
	('Insultos hacia civiles', 750, 1),
	('Faltar el respeto a un official', 1100, 1),
	('Amenaza verbal hacia un civil', 900, 1),
	('Amenaza verbal hacia un official', 1500, 1),
	('Proporcionar información falsa', 2500, 1),
	('Intento de corrupción', 1500, 1),
	('Blandiendo un arma en los límites de la ciudad', 1200, 2),
	('Blandiendo un arma letal en los límites de la ciudad', 3000, 2),
	('Sin licencia de armas de fuego', 6000, 2),
	('Posesión de un arma ilegal', 7000, 2),
	('Posesión de herramientas de robo', 3000, 2),
	('Grand Theft Auto', 1800, 2),
	('Intención de vender / distribuir una sustancia ilegal', 1500, 2),
	('Fabricación de una sustancia ilegal', 1500, 2),
	('Posesión de una sustancia ilegal ', 2000, 2),
	('Secuestro a un civil', 2000, 2),
	('Secuestro a un official', 4000, 2),
	('Robo', 6500, 2),
	('Robo a mano armada de una tienda', 7500, 2),
	('Robo a mano armada de un banco', 20000, 2),
	('Asalto a un civil', 2000, 3),
	('Asalto a un official', 2500, 3),
	('Intento de asesinato de un civil', 3000, 3),
	('Intento de asesinato de un official', 5000, 3),
	('Asesinato de un civil', 10000, 3),
	('Asesinato de un official (Federal)', 30000, 3),
	('Homicidio involuntario', 1800, 3),
	('Fraude', 2000, 2);
;
