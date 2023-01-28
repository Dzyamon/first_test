-- https://sql-academy.org/ru/guide/multi-table-request-join
-- SELECT поля_таблицы_1 FROM (подзапрос) [AS] псевдоним_производной_таблицы/ Обратите внимание на то, что для производной таблицы обязательно должен указываться её псевдоним, 
-- Создать отчет затрат семьи Quincey за 3 квартал 2005 года. Отсортировать по возрастанию member_name, затем по убыванию поля costs. Последней строкой вывести итог по всей семье. Для этого необходимо под колонкой good_name вывести слово "Total:", а под costs - общую сумму всех затрат, оставив первые два поля пустыми. https://sql-academy.org/ru/guide/combining-queries

WITH report 
    AS (SELECT  
			member_name, 
            status, 
            good_name, 
            SUM(amount * unit_price) AS costs 
        FROM FamilyMembers
            JOIN Payments ON member_id = family_member
            JOIN Goods ON good = good_id
        WHERE member_name LIKE '%Quincey' AND 
            date BETWEEN '2005-07-01' AND '2005-09-30'
        GROUP BY member_name, status, good_name)
        -- ORDER BY member_name, costs DESC)
SELECT * FROM report 
UNION 
SELECT 
    member_name = NULL,
    status = NULL,
    "Total:", 
    (SELECT SUM(costs) FROM report)
FROM report
ORDER BY
    CASE
        WHEN member_name IS NULL THEN 1 ELSE 0
    END, 
    member_name ASC,
    costs DESC

-- Вывести пассажиров с самым длинным именем
SELECT name
FROM Passenger
WHERE LENGTH(name) = (
    SELECT MAX(LENGTH(name))
    FROM Passenger
  )
  
-- Узнать, кто старше всех в семьe
SELECT member_name
FROM FamilyMembers
WHERE birthday = (
    SELECT MIN(birthday)
    FROM FamilyMembers
  )
  
-- Определить товары, которые покупали более 1 раза
SELECT DISTINCT good_name
FROM Goods
  JOIN Payments ON Goods.good_id = Payments.good
GROUP BY good
HAVING COUNT(good) > 1

-- Найдите самый дорогой деликатес (delicacies) и выведите его стоимость
WITH United AS (
  SELECT *
  FROM Goods
    JOIN Payments ON Payments.good = Goods.good_id
    JOIN GoodTypes ON Goods.type = GoodTypes.good_type_id
)
SELECT good_name, unit_price
FROM United
WHERE unit_price = (
	SELECT MAX(unit_price)
    FROM United
    WHERE good_type_name = "delicacies"
)

-- Узнать, сколько потрачено на каждую из групп товаров в 2005 году. Вывести название группы и сумму
SELECT good_type_name,
  SUM(amount * unit_price) AS costs
FROM GoodTypes gt
  JOIN Goods g ON gt.good_type_id = g.type
  JOIN Payments p ON g.good_id = p.good
WHERE YEAR(date) = 2005
GROUP BY good_type_name

-- Вывести средний возраст людей (в годах), хранящихся в базе данных. Результат округлите до целого в меньшую сторону.
SELECT FLOOR(AVG(YEAR(CURDATE()) - YEAR(birthday) - 1)) AS age
FROM FamilyMembers

-- Найдите среднюю стоимость икры. В базе данных хранятся данные о покупках красной (red caviar) и черной икры (black caviar).
SELECT AVG(unit_price) AS cost
FROM Payments
WHERE good IN (
    SELECT good_id
    FROM Goods
    WHERE good_name LIKE "%caviar"
  )
  
-- Сколько лет самому молодому обучающемуся ?
SELECT MIN(TIMESTAMPDIFF(YEAR, birthday, CURRENT_DATE)) as year
FROM Student

-- Сколько времени обучающийся будет находиться в школе, учась со 2-го по 4-ый уч. предмет ?
SELECT DISTINCT TIMEDIFF(
    (
      SELECT end_pair
      FROM Timepair
      WHERE id = 4
    ),
    (
      SELECT start_pair
      FROM Timepair
      WHERE id = 2
    )
  ) AS time
FROM Timepair

-- Какой(ие) кабинет(ы) пользуются самым большим спросом?
SELECT classroom
FROM Schedule
GROUP BY classroom
HAVING COUNT(classroom) = (
    SELECT COUNT(classroom)
    FROM Schedule
    GROUP BY classroom
    ORDER BY COUNT(classroom) DESC
    LIMIT 1
  )

-- Удалить компании, совершившие наименьшее количество рейсов.
DELETE FROM Company
WHERE Company.id IN (
    SELECT company
    FROM Trip
    GROUP BY company
    HAVING COUNT(company) = (
        SELECT MIN(cnt)
        FROM (
            SELECT COUNT(company) AS cnt
            FROM Trip
            GROUP BY company
          ) AS c
      )
  )

-- Добавьте в список типов товаров (GoodTypes) новый тип "auto".
INSERT INTO GoodTypes
SELECT COUNT(*) + 1,
  'auto'
FROM GoodTypes

-- Удалить всех членов семьи с фамилией "Quincey".
DELETE FROM FamilyMembers
WHERE member_name LIKE "%Quincey"

-- Перенести расписание всех занятий на 30 мин. вперед.
UPDATE Timepair
SET start_pair = start_pair + INTERVAL 30 MINUTE,
  end_pair = end_pair + INTERVAL 30 MINUTE
  
-- Добавить отзыв с рейтингом 5 на жилье, находящиеся по адресу "11218, Friel Place, New York", от имени "George Clooney"
/*
INSERT INTO Reviews (id, reservation_id, rating)
SELECT 
	COUNT(*) + 1,
	(SELECT rsv.id
 	 FROM Reservations rsv
		JOIN Rooms r ON rsv.room_id = r.id
		JOIN Users u ON rsv.user_id = u.id
	 WHERE address = "11218, Friel Place, New York" 
	   AND name = "George Clooney"
	),
	5 
FROM Reviews
 */
INSERT INTO Reviews (id, reservation_id, rating)
VALUES (
    (
      SELECT COUNT(*) + 1
      FROM Reviews AS a
    ),
    (
      SELECT rsv.id
      FROM Reservations rsv
        JOIN Rooms ON rsv.room_id = Rooms.id
        JOIN Users ON rsv.user_id = Users.id
      WHERE address = "11218, Friel Place, New York" 
	    AND name = "George Clooney"
    ),
    5
  )
  
-- Выведите идентификаторы преподавателей, которые хотя бы один раз за всё время преподавали в каждом из одиннадцатых классов.
SELECT teacher
FROM Schedule
  JOIN Class ON Class.id = Schedule.class
WHERE name LIKE "11%"
GROUP BY teacher
HAVING COUNT(DISTINCT name) > 1
ORDER BY teacher

-- Выведите список комнат, которые были зарезервированы в течение 12 недели 2020 года.
SELECT DISTINCT Rooms.*
FROM Rooms
  JOIN Reservations ON Rooms.id = Reservations.room_id
WHERE WEEK(start_date, 1) = 12
  AND YEAR(start_date) = 2020
  
-- Вывести в порядке убывания популярности доменные имена 2-го уровня, используемые пользователями для электронной почты. Полученный результат необходимо дополнительно отсортировать по возрастанию названий доменных имён.
SELECT RIGHT(email, LENGTH(email) - LOCATE("@", email)) AS domain,
	COUNT(email) AS count
-- SELECT SUBSTRING_INDEX(email, "@", -1) AS domain,
--	  COUNT(email) AS count
FROM Users
GROUP BY domain
ORDER BY count DESC,
  domain
  
-- Выведите отсортированный список (по возрастанию) имен студентов в виде Фамилия.И.О.
SELECT CONCAT(
    last_name,
    ".",
    LEFT(first_name, 1),
    ".",
    LEFT(middle_name, 1),
    "."
  ) AS name
FROM Student
ORDER BY name

--Вывести количество бронирований по каждому месяцу каждого года, в которых было хотя бы 1 бронирование. Результат отсортируйте в порядке возрастания даты бронирования.
SELECT YEAR(start_date) AS year,
  MONTH(start_date) AS month,
  COUNT(id) AS amount
FROM Reservations
GROUP BY year,
  month
HAVING amount > 0
ORDER BY year

-- Вывести список комнат со всеми удобствами (наличие ТВ, интернета, кухни и кондиционера), а также общее количество дней и сумму за все дни аренды каждой из таких комнат. Если комната не сдавалась, то количество дней и сумму вывести как 0.
SELECT home_type,
  address,
  IFNULL(SUM(DATEDIFF(end_date, start_date)), 0) AS days,
  IFNULL(SUM(total), 0) AS total_fee
FROM Rooms
  LEFT JOIN Reservations ON Rooms.id = Reservations.room_id
WHERE (has_tv, has_internet, has_kitchen, has_air_con) = (1, 1, 1, 1)
GROUP BY home_type,
  address 
-- GROUP BY Rooms.id
  
-- Вывести время отлета и время прилета для каждого перелета в формате "ЧЧ:ММ, ДД.ММ - ЧЧ:ММ, ДД.ММ", где часы и минуты с ведущим нулем, а день и месяц без.
SELECT CONCAT(
    DATE_FORMAT(time_out, "%H:%i, %e.%c"),
    " - ",
    DATE_FORMAT(time_in, "%H:%i, %e.%c")
  ) AS flight_time
FROM Trip

-- Для каждой комнаты, которую снимали как минимум 1 раз, найдите имя человека, снимавшего ее последний раз, и дату, когда он выехал
SELECT a.room_id,
  name,
  a.end_date
FROM (
    SELECT room_id,
      MAX(end_date) AS end_date
    FROM Reservations
    GROUP BY room_id
  ) AS a
  JOIN Reservations ON a.end_date = Reservations.end_date
  JOIN Users ON Users.id = Reservations.user_id

-- Вывести идентификаторы всех владельцев комнат, что размещены на сервисе бронирования жилья и сумму, которую они заработали
SELECT owner_id,
  IFNULL(SUM(total), 0) AS total_earn
FROM Rooms
  LEFT JOIN Reservations ON Rooms.id = Reservations.room_id
GROUP BY owner_id
ORDER BY total_earn DESC

-- Необходимо категоризовать жилье на economy, comfort, premium по цене соответственно <= 100, 100 < цена < 200, >= 200. В качестве результата вывести таблицу с названием категории и количеством жилья, попадающего в данную категорию
SELECT (
    CASE
      WHEN price <= 100 THEN 'economy'
      WHEN price >= 200 THEN 'premium'
      ELSE 'comfort'
    END
  ) AS category,
  COUNT(id) as count
FROM Rooms
GROUP BY category
ORDER BY CASE
    category
    WHEN 'comfort' THEN 1
    WHEN 'premium' THEN 2
    ELSE 0
  END

-- Найдите какой процент пользователей, зарегистрированных на сервисе бронирования, хоть раз арендовали или сдавали в аренду жилье. Результат округлите до сотых.
WITH active AS (
  SELECT DISTINCT user_id
  FROM Reservations
  UNION
  SELECT DISTINCT owner_id
  FROM Rooms,
    Reservations
  WHERE Reservations.room_id = Rooms.id
)
SELECT ROUND(
    100 * (
      SELECT COUNT(*)
      FROM active
    ) / COUNT(Users.id),
    2
  ) as percent
FROM Users

-- Выведите названия товаров из таблицы Goods (поле good_name), которые ещё ни разу не покупались ни одним из членов семьи (таблица Payments).
SELECT good_name
FROM Goods
WHERE good_id NOT IN (SELECT good FROM Payments)
/*
SELECT good_name
FROM 
    Goods 
    JOIN Payments ON Goods.good_id = Payments.good
WHERE amount IS NULL
*/  

-- Первичный ключ при добавлении новой записи MySQL
CREATE TABLE Goods (
	good_id INT NOT NULL AUTO_INCREMENT

-- Добавление данных, оператор INSERT	
INSERT INTO имя_таблицы [(поле_таблицы, ...)]
VALUES (значение_поля_таблицы, ...)
| SELECT поле_таблицы, ... FROM имя_таблицы ...

-- Обновление данных, оператор UPDATE
UPDATE имя_таблицы
SET поле_таблицы1 = значение_поля_таблицы1,
    поле_таблицыN = значение_поля_таблицыN
[WHERE условие_выборки]

-- Удаление данных, оператор DELETE
DELETE FROM имя_таблицы
[WHERE условие_отбора_записей];
TRUNCATE TABLE имя_таблицы;

-- Удаление записей при многотабличных запросах
DELETE имя_таблицы_1 [, имя_таблицы_2] FROM 
имя_таблицы_1 JOIN имя_таблицы_2 
ON имя_таблицы_1.поле = имя_таблицы_2.поле
[WHERE условие_отбора_записей];

-- Удалить запись из таблицы Goods, у которой поле good_name равно "milk"
DELETE FROM Goods
WHERE good_name = "milk"

-- Измените запрос так, чтобы удалить товары (Goods), имеющие тип деликатесов (delicacies).
DELETE Goods FROM Goods 
    JOIN GoodTypes ON type = good_type_id
WHERE good_type_name = "delicacies"

CREATE DATABASE IF NOT EXIST
SHOW DATABASE
USE DATABASE

CREATE TABLE Users (
    id INT,
    name VARCHAR(255) NOT NULL,
    age INT NOT NULL DEFAULT 18,
    company INT,
    PRIMARY KEY (id),
    FOREIGN KEY (company) REFERENCES Companies (id) 
        ON DELETE RESTRICT ON UPDATE CASCADE
		-- ON DELETE SET NULL);
DESCRIBE Users;
DROP TABLE [IF EXIST] имя_таблицы;

-- Строковый тип данных
CHAR
CONCAT
INSERT
INSTR
LENGTH
LEFT, RIGHT
LOCATE
LOWER, UPPER
LPAD, RPAD
LTRIM, RTRIM, TRIM
REPEAT
REPLACE
REVERSE
SUBSTRING

-- Выведите идентификаторы (поле good_id) всех товаров, дополнив идентификаторы незначащими нолями слева до 2-х знаков.
SELECT LPAD(good_id,2,"00") as ids 
FROM Goods

-- Числовой тип данных
GREATEST
LEAST
INTERVAL
BIT_COUNT
ABS
MOD
CEILING
FLOOR
ROUND
TRUNCATE
EXP
LOG
POW
SQRT
PI
RAND
SIGN

-- Выведите id тех комнат, которые арендовали нечетное количество раз.
SELECT room_id, COUNT(*) AS count
FROM Reservations
GROUP BY room_id
HAVING MOD(COUNT(*),2) = 1

-- Работа с датами и временем
NOW
CURDATE
CURTIME
TIMESTAMPADD
TIMESTAMPDIFF
DATE
DATEDIFF
TIMEDIFF
ADDDATE
SUBDATE
DATE_FORMAT
YEAR
MONTH
MONTHNAME
DAY
DAYNAME
DAYOFWEEK
DAYOFYEAR
HOUR
MINUTE

DATE_FORMAT(datetime, format) форматирует дату и время в соответствии со строкой format.
\
%a	Сокращенное наименование дня недели (Sun...Sat)
%b	Сокращенное наименование месяца (Jan...Dec)
%c	Месяц в числовой форме (1...12)
%D	День месяца с английским суффиксом (1st, 2nd, 3rd и т. д.)
%d	День месяца в числовой форме с ведущим нулем (01..31)
%e	День месяца в числовой форме (1..31)
%f	Микросекунды (000000..999999)
%H	Час с ведущим нулем (00..23)
%h	Час с ведущим нулем (01..12)
%I	Час с ведущим нулем (01..12)
%i	Минуты с ведущим нулем (00..59)
%j	День года (001..366)
%k	Час с ведущим нулем (0..23)
%l	Час без ведущего нуля (1..12)
%M	Название месяца (January...December)
%m	Месяц в числовой форме с ведущим нулем (01..12)
%p	AM или PM (для 12-часового формата)
%r	Время, 12-часовой формат (hh:mm:ss AM|hh:mm:ss PM)
%S	Секунды (00..59)
%s	Секунды (00..59)
%T	Время, 24-часовой формат (hh:mm:ss)
%U	Неделя (00..52), где воскресенье считается первым днем недели
%u	Неделя (00..52), где понедельник считается первым днем недели
%W	Название дня недели (Sunday...Saturday)
%w	День недели (0...6), 0 — Воскресенье, 6 — Суббота
%Y	Год в 4 разряда ГГГГ
%y	Год в 2 разряда ГГ

CREATE TABLE date_table (datetime TIMESTAMP);
INSERT INTO date_table VALUES("2022-06-16 16:37:23");
INSERT INTO date_table VALUES("22.05.31 8+15+04");
INSERT INTO date_table VALUES("2014/02/22 16*37*22");
INSERT INTO date_table VALUES("20220616163723");
INSERT INTO date_table VALUES("2021-02-12");
SELECT * FROM date_table;

-- Вывести текущую дату и время в формате "ЧЧ:ММ, ДД.ММ.ГГГГ", где часы и минуты с ведущим нулем, а день и месяц без. Для вывода используйте псевдоним date.
SELECT DATE_FORMAT(NOW(), "%H:%i, %d.%c.%Y") AS date
-- SELECT DATE_FORMAT(TIMESTAMPADD(HOUR, 3, NOW()), "%H:%i, %d.%c.%Y") AS date
