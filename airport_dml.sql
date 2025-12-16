TRUNCATE Flight_Delays, Service_Tasks, Flights, Service_Catalog, Infrastructure, Aircrafts, Delay_Codes RESTART IDENTITY CASCADE;

-- ЛІТАКИ 
INSERT INTO Aircrafts (registration_number, model, airline_name) VALUES 
('UR-PSQ', 'Boeing 737-800', 'Ukraine Intl Airlines'), 
('SP-RSM', 'Boeing 737-800', 'Ryanair'),               
('D-AINA', 'Airbus A320neo', 'Lufthansa'),             
('W6-WZZ', 'Airbus A321', 'Wizz Air'),                 
('TC-JNC', 'Airbus A330', 'Turkish Airlines'),         
('G-XLEA', 'Airbus A380', 'British Airways'),          
('F-GZNP', 'Boeing 777', 'Air France'),               
('SP-LVA', 'Embraer 195', 'LOT Polish Airlines'),     
('YL-CSK', 'Airbus A220', 'Air Baltic'),              
('UR-SQE', 'Boeing 737-700', 'SkyUp Airlines'),      
('PH-BXO', 'Boeing 737-900', 'KLM'),                  
('A6-EOQ', 'Airbus A380', 'Emirates');                

-- ІНФРАСТРУКТУРА / ГЕЙТИ 
INSERT INTO Infrastructure (gate_code, gate_type, is_operational) VALUES 
('A1', 'Terminal', TRUE),  
('A2', 'Terminal', TRUE),  
('A3', 'Terminal', FALSE), -- Ремонт
('A4', 'Terminal', TRUE),  
('B1', 'Terminal', TRUE),
('B2', 'Terminal', TRUE),  
('B3', 'Terminal', TRUE), 
('R1', 'Remote', TRUE),   
('R2', 'Remote', TRUE),    
('R3', 'Remote', FALSE);   

-- КАТАЛОГ ПОСЛУГ 
INSERT INTO Service_Catalog (service_name, price_per_unit, estimated_duration_min) VALUES 
('Refueling', 1200.00, 40),         
('Cabin Cleaning', 150.00, 25),      
('Catering Loading', 500.00, 30),    
('De-icing', 800.00, 20),            -- Проти обледеніння
('Bus Transfer', 100.00, 15),        
('Potable Water Service', 50.00, 10),-- Питна вода
('Lavatory Service', 70.00, 15),     -- Туалет
('Baggage Handling', 300.00, 45),    -- 
('Pushback', 120.00, 10),            -- Виштовхування літака
('GPU Power Supply', 40.00, 60);     -- Наземне живлення

-- КОДИ ЗАТРИМОК (IATA) 
INSERT INTO Delay_Codes (iata_code, description, responsible_party) VALUES 
('93', 'Late Arrival of Incoming Aircraft', 'Airline'),
('34', 'Cleaning and Loading', 'Airport'),
('71', 'Weather conditions', 'Nature'),
('81', 'ATFM Restrictions', 'ATC'),
('11', 'Passenger / Baggage', 'Airline'),
('89', 'Ground Handling', 'Airport'),
('41', 'Technical Defect of Aircraft', 'Airline'),
('85', 'Mandatory Security', 'Government'),
('75', 'De-icing of Aircraft', 'Airport'),
('99', 'Other / Undefined', 'Airline');

-- РЕЙСИ (Прилетіли, Вилітають, Затримані)
INSERT INTO Flights (flight_number, aircraft_id, gate_id, arrival_time, departure_time, status) VALUES 
-- Вже прилетіли (Минулий час)
('PS55', 1, 1, NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours', 'Landed'),
('LH145', 3, 2, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours', 'Landed'),
('TK458', 5, 5, NOW() - INTERVAL '1 hour', NOW() + INTERVAL '1 hour', 'Boarding'), 
-- Зараз обслуговуються
('FR303', 2, 8, NOW(), NOW() + INTERVAL '45 minutes', 'De-boarding'), 
('W6500', 4, 9, NOW(), NOW() + INTERVAL '2 hours', 'Delayed'),        -- Затримка
('BA990', 6, 6, NOW() + INTERVAL '10 minutes', NOW() + INTERVAL '2 hours', 'Scheduled'),
('LO770', 8, 4, NOW() + INTERVAL '30 minutes', NOW() + INTERVAL '1.5 hours', 'Scheduled'),
-- Скасовані та майбутні
('AF112', 7, 7, NULL, NULL, 'Cancelled'), 
('BT402', 9, 2, NOW() + INTERVAL '5 hours', NOW() + INTERVAL '6 hours', 'Scheduled'),
('PQ881', 10, 1, NOW() + INTERVAL '6 hours', NOW() + INTERVAL '8 hours', 'Scheduled'),
('KL110', 11, 5, NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day 2 hours', 'Scheduled'),
('EK220', 12, 6, NOW() + INTERVAL '2 days', NOW() + INTERVAL '2 days 4 hours', 'Scheduled');

select * from Flights;

-- ЗАДАЧІ ОБСЛУГОВУВАННЯ 
-- Для рейсу PS55 (вже полетів) - все виконано
INSERT INTO Service_Tasks (flight_id, service_type_id, start_time, end_time, status) VALUES 
(1, 1, NOW() - INTERVAL '4 hours 50 min', NOW() - INTERVAL '4 hours 20 min', 'Completed'), -- Заправка
(1, 2, NOW() - INTERVAL '4 hours 40 min', NOW() - INTERVAL '4 hours 10 min', 'Completed'), -- Прибирання
(1, 8, NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 30 min', 'Completed');        -- Багаж

-- Для рейсу FR303 (на віддаленій стоянці) - потрібен автобус
INSERT INTO Service_Tasks (flight_id, service_type_id, start_time, end_time, status) VALUES 
(4, 5, NOW(), NOW() + INTERVAL '15 minutes', 'In Progress'), -- Автобус
(4, 8, NOW(), NULL, 'In Progress');                          -- Вивантаження багажу

-- Для затриманого Wizz Air (W6500)
INSERT INTO Service_Tasks (flight_id, service_type_id, start_time, end_time, status) VALUES 
(5, 1, NULL, NULL, 'Pending'), -- Заправка чекає
(5, 4, NULL, NULL, 'Pending'); -- Проти обледеніння

-- Для Turkish Airlines (TK458) - посадка пасажирів
INSERT INTO Service_Tasks (flight_id, service_type_id, start_time, end_time, status) VALUES 
(3, 3, NOW(), NOW() + INTERVAL '20 minutes', 'In Progress'), -- Їжа
(3, 1, NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '10 minutes', 'Completed'); -- Заправка

INSERT INTO Service_Tasks (flight_id, service_type_id, start_time, status) VALUES 
(2, 2, NOW() - INTERVAL '2.5 hours', 'Completed'),
(6, 9, NULL, 'Pending'),
(7, 10, NULL, 'Pending');

SELECT * FROM Service_Tasks;

select * from Service_Tasks
where status = 'In Progress';


-- ЖУРНАЛ ЗАТРИМОК (Фіксація проблем)
INSERT INTO Flight_Delays (flight_id, delay_code, duration_minutes, comments) VALUES 
(5, '71', 60, 'Heavy snowfall, waiting for de-icing'), -- Wizz Air (Погода)
(5, '89', 20, 'Truck breakdown'),                      -- Wizz Air (Зламалась машина)
(8, '41', 120, 'Engine inspection required'),          -- Air France (Технічна)
(3, '11', 15, 'Late passenger from connecting flight');-- Turkish (Пасажир)

SELECT * FROM Flight_Delays;

SELECT 
    Flights.flight_number AS "Рейс",
    Aircrafts.model AS "Літак",
    Infrastructure.gate_code AS "Гейт",
    Service_Catalog.service_name AS "Послуга",
    Service_Tasks.status AS "Статус задачі"
FROM Service_Tasks
JOIN Flights ON Service_Tasks.flight_id = Flights.flight_id
JOIN Aircrafts ON Flights.aircraft_id = Aircrafts.aircraft_id
JOIN Infrastructure ON Flights.gate_id = Infrastructure.gate_id
JOIN Service_Catalog ON Service_Tasks.service_type_id = Service_Catalog.service_type_id;

UPDATE Flights 
SET status = 'Landed', arrival_time = '2023-10-25 14:10:00'
WHERE flight_number = 'PS55';

SELECT * FROM Flights WHERE flight_number = 'PS55';

DELETE FROM Service_Tasks 
WHERE task_id = 1;





