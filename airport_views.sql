-- HORIZONTAL VIEW (Горизонтальна)
-- Табло для пасажирів (їм не треба знати ID літака чи ID гейту).
CREATE OR REPLACE VIEW View_Passenger_Board AS
SELECT 
    flight_number, 
    arrival_time, 
    departure_time, 
    status
FROM Flights;

-- VERTICAL VIEW (Вертикальна)
-- Список тільки проблемних рейсів для менеджера.
CREATE OR REPLACE VIEW View_Problem_Flights AS
SELECT * FROM Flights 
WHERE status IN ('Delayed', 'Cancelled');

-- MIXED VIEW (Змішана)
-- Прайс-лист лише на дешеві послуги (до 500 грн).
CREATE OR REPLACE VIEW View_Cheap_Services AS
SELECT 
    service_name, 
    price_per_unit
FROM Service_Catalog
WHERE price_per_unit < 500.00;

-- JOINED VIEW (Об'єднана з кількох таблиць)
-- Головне табло диспетчера (повна інформація про рейс, літак і гейт).
CREATE OR REPLACE VIEW View_Master_Control AS
SELECT 
    F.flight_number,
    A.model AS aircraft_model,
    A.airline_name,
    I.gate_code,
    F.status,
    F.arrival_time
FROM Flights F
JOIN Aircrafts A ON F.aircraft_id = A.aircraft_id
JOIN Infrastructure I ON F.gate_id = I.gate_id;

-- SUBQUERY VIEW (З підзапитом)
-- Рейси, які обслуговують найдорожчі літаки.
-- (Припустимо для прикладу, що ми шукаємо послуги дорожчі за середню ціну)
CREATE OR REPLACE VIEW View_Expensive_Services AS
SELECT *
FROM Service_Catalog
WHERE price_per_unit > (SELECT AVG(price_per_unit) FROM Service_Catalog);

-- UNION VIEW (Об'єднання результатів)
-- Єдиний список "Увага!". Об'єднуємо затримки і скасування в один звіт.
CREATE OR REPLACE VIEW View_Attention_Required AS
SELECT flight_number, status, 'Bad Weather/Tech' as reason FROM Flights WHERE status = 'Cancelled'
UNION
SELECT flight_number, status, 'Delay Occurred' as reason FROM Flights WHERE status = 'Delayed';

-- VIEW ON VIEW (В'юшка на основі іншої в'юшки)
-- Беремо "Головне табло" (пункт 4) і фільтруємо тільки Wizz Air.
CREATE OR REPLACE VIEW View_WizzAir_Flights AS
SELECT *
FROM View_Master_Control
WHERE airline_name = 'Wizz Air';

-- VIEW WITH CHECK OPTION
-- В'юшка для роботи тільки з гейтами терміналу.
-- CHECK OPTION заборонить через цю в'юшку перетворити гейт на 'Remote'.
CREATE OR REPLACE VIEW View_Terminal_Gates AS
SELECT *
FROM Infrastructure
WHERE gate_type = 'Terminal'
WITH CHECK OPTION;



SELECT * FROM View_Passenger_Board;
SELECT * FROM View_Problem_Flights;
SELECT * FROM View_Cheap_Services;
SELECT * FROM View_Master_Control;
SELECT * FROM View_Expensive_Services;
SELECT * FROM View_Attention_Required;
SELECT * FROM View_WizzAir_Flights;
SELECT * FROM View_Terminal_Gates;