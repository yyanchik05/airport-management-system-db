-- --- ОЧИЩЕННЯ (Видаляємо старе перед створенням нового) ---
DROP TABLE IF EXISTS Flight_Delays CASCADE;
DROP TABLE IF EXISTS Delay_Codes CASCADE;
DROP TABLE IF EXISTS Service_Tasks CASCADE;
DROP TABLE IF EXISTS Flights CASCADE;
DROP TABLE IF EXISTS Service_Catalog CASCADE;
DROP TABLE IF EXISTS Infrastructure CASCADE;
DROP TABLE IF EXISTS Aircrafts CASCADE;

-- --- КРОК 1: БУДУЄМО ТАБЛИЦІ ---

CREATE TABLE Aircrafts (
    aircraft_id SERIAL PRIMARY KEY,
    registration_number VARCHAR(10) UNIQUE,
    model VARCHAR(50),
    airline_name VARCHAR(50)
);

CREATE TABLE Infrastructure (
    gate_id SERIAL PRIMARY KEY,
    gate_code VARCHAR(10),
    gate_type VARCHAR(20), 
    is_operational BOOLEAN
);

CREATE TABLE Service_Catalog (
    service_type_id SERIAL PRIMARY KEY,
    service_name VARCHAR(50),
    price_per_unit DECIMAL(10,2),
    estimated_duration_min INT
);

CREATE TABLE Flights (
    flight_id SERIAL PRIMARY KEY,
    flight_number VARCHAR(10),
    aircraft_id INT REFERENCES Aircrafts(aircraft_id),
    gate_id INT REFERENCES Infrastructure(gate_id),
    arrival_time TIMESTAMP,
    departure_time TIMESTAMP,
    status VARCHAR(20)
);

CREATE TABLE Service_Tasks (
    task_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES Flights(flight_id),
    service_type_id INT REFERENCES Service_Catalog(service_type_id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20)
);

-- --- КРОК 2: ЗАПОВНЮЄМО ДАНИМИ ---

INSERT INTO Aircrafts (registration_number, model, airline_name) VALUES 
('UR-PSQ', 'Boeing 737-800', 'Ukraine Intl Airlines'),
('SP-RSM', 'Boeing 737-800', 'Ryanair'),
('D-AINA', 'Airbus A320', 'Lufthansa');

INSERT INTO Infrastructure (gate_code, gate_type, is_operational) VALUES 
('A1', 'Terminal', TRUE),
('A2', 'Terminal', TRUE),
('R5', 'Remote', TRUE);

INSERT INTO Service_Catalog (service_name, price_per_unit, estimated_duration_min) VALUES 
('Refueling', 1200.00, 30),
('Cabin Cleaning', 150.00, 20),
('Catering Loading', 500.00, 25);

INSERT INTO Flights (flight_number, aircraft_id, gate_id, arrival_time, departure_time, status) VALUES 
('PS55', 1, 1, '2023-10-25 14:00:00', '2023-10-25 15:30:00', 'Boarding');

INSERT INTO Service_Tasks (flight_id, service_type_id, start_time, status) VALUES 
(1, 1, '2023-10-25 14:10:00', 'In Progress'),
(1, 2, '2023-10-25 14:15:00', 'Completed');

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
SET status = 'Landed', arrival_time = NOW() 
WHERE flight_number = 'PS55';

SELECT * FROM Flights WHERE flight_number = 'PS55';

DELETE FROM Service_Tasks 
WHERE task_id = 1;



-- --- ВАРІАНТ "NATURAL KEY" (Як ти хотіла) ---

-- 1. Довідник кодів
-- Тепер iata_code - це головний ключ (Primary Key)
CREATE TABLE Delay_Codes (
    iata_code VARCHAR(3) PRIMARY KEY, -- Головний ключ тепер текст ("93", "71")
    description VARCHAR(100),
    responsible_party VARCHAR(50)
);

-- 2. Журнал затримок
-- Тепер ми посилаємось на iata_code
CREATE TABLE Flight_Delays (
    delay_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES Flights(flight_id),
    delay_code VARCHAR(3) REFERENCES Delay_Codes(iata_code), -- Зв'язок по тексту!
    duration_minutes INT,
    comments VARCHAR(200)
);

-- 3. Наповнюємо кодами (ID більше не пишемо!)
INSERT INTO Delay_Codes (iata_code, description, responsible_party) VALUES 
('93', 'Late Arrival of Aircraft', 'Airline'),
('34', 'Cleaning and Loading', 'Airport'),
('71', 'Weather conditions', 'Nature'),
('81', 'ATFM Restrictions', 'ATC'),
('11', 'Passenger / Baggage', 'Airline');

-- 4. Фіксуємо затримку
-- Дивись, як зручно тепер писати INSERT! Ми одразу пишемо код '71'
INSERT INTO Flight_Delays (flight_id, delay_code, duration_minutes, comments) VALUES 
(1, '71', 30, 'Strong wind'),          -- Одразу ясно, що код 71
(1, '34', 15, 'Cleaning team late');    -- Одразу ясно, що код 34


SELECT * FROM Flight_Delays;


-- 1. Перевірка ЦІНИ (в Service_Catalog)
-- Ціна не може бути менше 0
ALTER TABLE Service_Catalog 
ADD CONSTRAINT check_price_positive 
CHECK (price_per_unit >= 0);

-- 2. Перевірка ЧАСУ (в Flights)
-- Час вильоту має бути ПІЗНІШЕ за час прильоту (якщо обидва вказані)
ALTER TABLE Flights 
ADD CONSTRAINT check_departure_after_arrival 
CHECK (departure_time > arrival_time);

-- 3. Перевірка ЧАСУ ЗАДАЧ (в Service_Tasks)
-- Кінець задачі має бути пізніше початку
ALTER TABLE Service_Tasks 
ADD CONSTRAINT check_task_end_time 
CHECK (end_time > start_time);

-- 4. Перевірка СТАТУСУ (в Flights)
-- Дозволяємо вводити тільки конкретні слова
ALTER TABLE Flights 
ADD CONSTRAINT check_flight_status 
CHECK (status IN ('Scheduled', 'Landed', 'Boarding', 'Departer', 'Cancelled', 'Delayed', 'De-boarding'));

-- 5. Перевірка ТИПУ ГЕЙТА (в Infrastructure)
-- Тільки 'Terminal' або 'Remote'
ALTER TABLE Infrastructure 
ADD CONSTRAINT check_gate_type 
CHECK (gate_type IN ('Terminal', 'Remote'));

-- 6. Перевірка тривалості затримки
ALTER TABLE Flight_Delays 
ADD CONSTRAINT check_delay_duration 
CHECK (duration_minutes > 0);


-- 7. Унікальність назви гейту
ALTER TABLE Infrastructure 
ADD CONSTRAINT unique_gate_code UNIQUE (gate_code);



