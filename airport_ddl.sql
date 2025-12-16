-- Очищення (видаляємо старе, якщо є)
DROP TABLE IF EXISTS Flight_Delays CASCADE;
DROP TABLE IF EXISTS Service_Tasks CASCADE;
DROP TABLE IF EXISTS Flights CASCADE;
DROP TABLE IF EXISTS Service_Catalog CASCADE;
DROP TABLE IF EXISTS Infrastructure CASCADE;
DROP TABLE IF EXISTS Aircrafts CASCADE;
DROP TABLE IF EXISTS Delay_Codes CASCADE;

-- СТВОРЕННЯ ТАБЛИЦЬ (TABLES & KEYS)

-- Довідник: Літаки
CREATE TABLE Aircrafts (
    aircraft_id SERIAL PRIMARY KEY,
    registration_number VARCHAR(10) UNIQUE NOT NULL,
    model VARCHAR(50) NOT NULL,
    airline_name VARCHAR(50)
);

-- Довідник: Інфраструктура (Гейти)
CREATE TABLE Infrastructure (
    gate_id SERIAL PRIMARY KEY,
    gate_code VARCHAR(10) UNIQUE NOT NULL, -- Унікальна назва гейту
    gate_type VARCHAR(20) CHECK (gate_type IN ('Terminal', 'Remote')), -- Перевірка типу
    is_operational BOOLEAN DEFAULT TRUE
);

-- Довідник: Послуги
CREATE TABLE Service_Catalog (
    service_type_id SERIAL PRIMARY KEY,
    service_name VARCHAR(50) NOT NULL,
    price_per_unit DECIMAL(10,2) CHECK (price_per_unit >= 0), -- Ціна не може бути мінусовою
    estimated_duration_min INT
);

-- Довідник: Коди затримок (IATA)
CREATE TABLE Delay_Codes (
    iata_code VARCHAR(3) PRIMARY KEY, -- Використовуємо код як ключ (Natural Key)
    description VARCHAR(100),
    responsible_party VARCHAR(50)
);

-- Головна таблиця: Рейси
CREATE TABLE Flights (
    flight_id SERIAL PRIMARY KEY,
    flight_number VARCHAR(10) NOT NULL,
    aircraft_id INT REFERENCES Aircrafts(aircraft_id),
    gate_id INT REFERENCES Infrastructure(gate_id),
    arrival_time TIMESTAMP,
    departure_time TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('Scheduled', 'Landed', 'Boarding', 'Departer', 'Cancelled', 'Delayed', 'De-boarding')),
    -- Перевірка: виліт має бути пізніше прильоту
    CONSTRAINT check_time_logic CHECK (departure_time > arrival_time)
);

-- Таблиця: Задачі обслуговування
CREATE TABLE Service_Tasks (
    task_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES Flights(flight_id) ON DELETE CASCADE, -- Якщо рейс видалять, задачі теж зникнуть
    service_type_id INT REFERENCES Service_Catalog(service_type_id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')),
    -- Перевірка: кінець задачі пізніше початку
    CONSTRAINT check_task_time CHECK (end_time > start_time)
);

-- Таблиця: Журнал затримок
CREATE TABLE Flight_Delays (
    delay_id SERIAL PRIMARY KEY,
    flight_id INT REFERENCES Flights(flight_id) ON DELETE CASCADE,
    delay_code VARCHAR(3) REFERENCES Delay_Codes(iata_code),
    duration_minutes INT CHECK (duration_minutes > 0), -- Затримка > 0 хвилин
    comments VARCHAR(200)
);



-- Перевірка ЦІНИ (в Service_Catalog)
-- Ціна не може бути менше 0
ALTER TABLE Service_Catalog 
ADD CONSTRAINT check_price_positive 
CHECK (price_per_unit >= 0);

-- Перевірка ЧАСУ (в Flights)
-- Час вильоту має бути ПІЗНІШЕ за час прильоту (якщо обидва вказані)
ALTER TABLE Flights 
ADD CONSTRAINT check_departure_after_arrival 
CHECK (departure_time > arrival_time);

-- Перевірка ЧАСУ ЗАДАЧ (в Service_Tasks)
-- Кінець задачі має бути пізніше початку
ALTER TABLE Service_Tasks 
ADD CONSTRAINT check_task_end_time 
CHECK (end_time > start_time);

-- Перевірка СТАТУСУ (в Flights)
-- Дозволяємо вводити тільки конкретні слова
ALTER TABLE Flights 
ADD CONSTRAINT check_flight_status 
CHECK (status IN ('Scheduled', 'Landed', 'Boarding', 'Departer', 'Cancelled', 'Delayed', 'De-boarding'));

-- Перевірка ТИПУ ГЕЙТА (в Infrastructure)
-- Тільки 'Terminal' або 'Remote'
ALTER TABLE Infrastructure 
ADD CONSTRAINT check_gate_type 
CHECK (gate_type IN ('Terminal', 'Remote'));

-- Перевірка тривалості затримки
ALTER TABLE Flight_Delays 
ADD CONSTRAINT check_delay_duration 
CHECK (duration_minutes > 0);


-- Унікальність назви гейту
ALTER TABLE Infrastructure 
ADD CONSTRAINT unique_gate_code UNIQUE (gate_code);




-- ІНДЕКСИ - для швидкодії

-- Індекс для швидкого пошуку рейсу за номером (бо ми часто шукаємо 'PS55')
CREATE INDEX idx_flights_number ON Flights(flight_number);

-- Індекс для пошуку рейсів за датою (для розкладу)
CREATE INDEX idx_flights_arrival ON Flights(arrival_time);

-- Індекс для швидкого пошуку задач конкретного рейсу
CREATE INDEX idx_tasks_flight ON Service_Tasks(flight_id);

