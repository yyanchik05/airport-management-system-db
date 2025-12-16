-- Тема: Функції та Збережені процедури (Business Logic)

-- ФУНКЦІЇ (FUNCTIONS) - Для обчислень

-- Функція: Розрахунок повної вартості обслуговування рейсу
CREATE OR REPLACE FUNCTION fn_calculate_total_cost(p_flight_id INT)
RETURNS DECIMAL(10, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_cost DECIMAL(10, 2);
BEGIN
    -- Рахуємо суму цін всіх послуг для цього рейсу
    SELECT COALESCE(SUM(SC.price_per_unit), 0)
    INTO total_cost
    FROM Service_Tasks ST
    JOIN Service_Catalog SC ON ST.service_type_id = SC.service_type_id
    WHERE ST.flight_id = p_flight_id;

    RETURN total_cost;
END;
$$;

-- Функція: Отримання тривалості затримки у зрозумілому форматі
CREATE OR REPLACE FUNCTION fn_get_delay_text(p_flight_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    delay_min INT;
    result_text TEXT;
BEGIN
    -- Шукаємо сумарну затримку
    SELECT SUM(duration_minutes) INTO delay_min
    FROM Flight_Delays
    WHERE flight_id = p_flight_id;

    IF delay_min IS NULL OR delay_min = 0 THEN
        RETURN 'No Delay';
    ELSE
        -- Форматуємо хвилини у години та хвилини
        RETURN (delay_min / 60) || ' hr ' || (delay_min % 60) || ' min';
    END IF;
END;
$$;

-- Функція: Перевірка, чи вільний Гейт
CREATE OR REPLACE FUNCTION fn_is_gate_available(p_gate_id INT, p_check_time TIMESTAMP)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    flight_count INT;
BEGIN
    -- Рахуємо, скільки літаків стоїть на цьому гейті у вказаний час
    -- (Перевіряємо перетин часових проміжків Arrival та Departure)
    SELECT COUNT(*) INTO flight_count
    FROM Flights
    WHERE gate_id = p_gate_id
      AND p_check_time BETWEEN arrival_time AND departure_time;

    IF flight_count > 0 THEN
        RETURN FALSE; -- Зайнято
    ELSE
        RETURN TRUE;  -- Вільно
    END IF;
END;
$$;


-- ПРОЦЕДУРИ (PROCEDURES) - SELECT & INSERT

-- Процедура: Реєстрація нового рейсу (INSERT)
CREATE OR REPLACE PROCEDURE sp_register_new_flight(
    p_flight_number VARCHAR,
    p_aircraft_id INT,
    p_gate_id INT,
    p_arrival TIMESTAMP,
    p_departure TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Перевірка на дублікат (Error Handling)
    IF EXISTS (SELECT 1 FROM Flights WHERE flight_number = p_flight_number AND DATE(arrival_time) = DATE(p_arrival)) THEN
        RAISE EXCEPTION 'Flight % already exists for this date!', p_flight_number;
    END IF;

    -- Вставка
    INSERT INTO Flights (flight_number, aircraft_id, gate_id, arrival_time, departure_time, status)
    VALUES (p_flight_number, p_aircraft_id, p_gate_id, p_arrival, p_departure, 'Scheduled');
    
    RAISE NOTICE 'Flight % created successfully.', p_flight_number;
END;
$$;

-- Процедура: Призначення послуги (INSERT)
CREATE OR REPLACE PROCEDURE sp_assign_service(
    p_flight_id INT,
    p_service_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Service_Tasks (flight_id, service_type_id, start_time, status)
    VALUES (p_flight_id, p_service_id, NOW(), 'Pending');
END;
$$;


-- ПРОЦЕДУРИ (PROCEDURES) - UPDATE

-- Процедура: Оновлення статусу рейсу (UPDATE)
-- Логіка: Змінює статус. Якщо статус 'Landed', автоматично оновлює час прибуття.
CREATE OR REPLACE PROCEDURE sp_update_flight_status(
    p_flight_id INT,
    p_new_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Валідація: перевіряємо, чи рейс існує
    IF NOT EXISTS (SELECT 1 FROM Flights WHERE flight_id = p_flight_id) THEN
        RAISE EXCEPTION 'Flight ID % not found', p_flight_id;
    END IF;

    -- Оновлення
    UPDATE Flights
    SET status = p_new_status,
        arrival_time = CASE WHEN p_new_status = 'Landed' THEN NOW() ELSE arrival_time END
    WHERE flight_id = p_flight_id;
    
    RAISE NOTICE 'Flight ID % status updated to %', p_flight_id, p_new_status;
END;
$$;

-- Процедура: Завершення задачі (UPDATE)
-- Логіка: Ставить статус 'Completed' і записує час завершення
CREATE OR REPLACE PROCEDURE sp_complete_service_task(
    p_task_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Service_Tasks
    SET status = 'Completed',
        end_time = NOW()
    WHERE task_id = p_task_id;
END;
$$;



SELECT fn_calculate_total_cost(5);
SELECT fn_get_delay_text(5); 
SELECT fn_is_gate_available(1, NOW()::timestamp);

CALL sp_register_new_flight('TEST-999', 1, 1, NOW()::timestamp + INTERVAL '1 day', NOW()::timestamp + INTERVAL '1 day 2 hours');
CALL sp_assign_service(5, 2); -- Призначити прибирання (ID 2) для рейсу ID 5

CALL sp_update_flight_status(5, 'De-boarding');
CALL sp_complete_service_task(5);