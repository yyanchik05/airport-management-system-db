-- Адміністрування доступу (Roles & Users)

-- СТВОРЕННЯ РОЛЕЙ (Групи прав)

-- "Менеджер" (Read-Write)
-- Ця роль для диспетчерів. Вони можуть робити все: читати, писати, видаляти.
CREATE ROLE airport_manager_role;

-- "Глядач" (Read-Only)
-- Ця роль для аналітиків або інфо-табло. Вони можуть ТІЛЬКИ читати.
CREATE ROLE airport_viewer_role;


-- НАДАННЯ ПРАВ (GRANT)

-- Налаштовуємо "Менеджера":
-- Дозволяємо підключатися до бази
GRANT CONNECT ON DATABASE postgres TO airport_manager_role;
-- Дозволяємо робити ВСЕ (SELECT, INSERT, UPDATE, DELETE) у схемі public
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airport_manager_role;
-- !ВАЖЛИВО! Дозволяємо користуватися лічильниками (SERIAL), щоб створювати нові ID
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO airport_manager_role;

-- Налаштовуємо "Глядача":
-- Дозволяємо підключатися
GRANT CONNECT ON DATABASE postgres TO airport_viewer_role;
-- Дозволяємо ТІЛЬКИ ЧИТАТИ (SELECT)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO airport_viewer_role;
-- (Ми НЕ даємо прав INSERT/UPDATE/DELETE, тому база захищена від змін цією роллю)


-- СТВОРЕННЯ КОРИСТУВАЧІВ (Users)

-- Користувач 1: Головний Диспетчер Макс
CREATE USER dispatcher_max WITH PASSWORD 'admin123';

-- Користувач 2: Стажер Анна (або Аналітик)
CREATE USER analyst_anna WITH PASSWORD 'securePass2025';


-- ПРИЗНАЧЕННЯ РОЛЕЙ (Assignment)

-- Макс стає Менеджером (отримує всі права ролі)
GRANT airport_manager_role TO dispatcher_max;

-- Анна стає Глядачем (отримує тільки права на читання)
GRANT airport_viewer_role TO analyst_anna;



