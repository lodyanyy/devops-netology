# Домашняя работа к занятию "6.2. SQL"

## Задача 1

Используя docker поднимите инстанс PostgreSQL (версию 12) c 2 volume, 
в который будут складываться данные БД и бэкапы.

Приведите получившуюся команду или docker-compose манифест.

## Решение
lodyanyy@lodyanyy:~$ docker pull postgres:12  
docker-compose.yaml
>
 ```
 version: '3'
services:
  db:
    container_name: pg12
    image: postgres:12
    environment:
      POSTGRES_USER: lodyanyy
      POSTGRES_PASSWORD: 123456
      POSTGRES_DB: start_db
    ports:
      - "5432:5432"
    volumes:      
      - database_volume:/home/database/
      - backup_volume:/home/backup/

volumes:
  database_volume:
  backup_volume:
 ```  
 Поднимаем docker-compose и запускаем bash внутри контейнера pg12:  
 ```
 $ docker-compose up -d
 $ sudo docker exec -it pg12 bash
 ```

## Задача 2

В БД из задачи 1: 
- создайте пользователя test-admin-user и БД test_db
- в БД test_db создайте таблицу orders и clients (спeцификация таблиц ниже)
- предоставьте привилегии на все операции пользователю test-admin-user на таблицы БД test_db
- создайте пользователя test-simple-user  
- предоставьте пользователю test-simple-user права на SELECT/INSERT/UPDATE/DELETE данных таблиц БД test_db

Таблица orders:
- id (serial primary key)
- наименование (string)
- цена (integer)

Таблица clients:
- id (serial primary key)
- фамилия (string)
- страна проживания (string, index)
- заказ (foreign key orders)

Приведите:
- итоговый список БД после выполнения пунктов выше,
- описание таблиц (describe)
- SQL-запрос для выдачи списка пользователей с правами над таблицами test_db
- список пользователей с правами над таблицами test_db  

## Решение

- создадим БД test_db и выполним подключение к созданной базе:
```
root@e8848a61a50f:/# createdb test_db -U lodyanyy
root@e8848a61a50f:/# psql -d test_db -U lodyanyy
psql (12.10 (Debian 12.10-1.pgdg110+1))
Type "help" for help.
```  
- создадим пользователя test-admin-user:
```
test_db=# CREATE USER test_admin_user;
CREATE ROLE
```  
- в БД test_db создадим таблицы orders и clients:
```
test_db=# CREATE TABLE orders
(
   id SERIAL PRIMARY KEY,
   наименование TEXT,
   цена INTEGER
);
CREATE TABLE

test_db=# CREATE TABLE clients
(
    id SERIAL PRIMARY KEY,
    фамилия TEXT,
    "страна проживания" TEXT,
    заказ INTEGER,
    FOREIGN KEY (заказ) REFERENCES orders(id)
);
CREATE TABLE
test_db=# CREATE INDEX country_index ON clients ("страна проживания");
CREATE INDEX
```
-предоставим привилегии на все операции пользователю test-admin-user на таблицы БД test_db:
```
test_db=# GRANT ALL ON TABLE orders TO test_admin_user;
GRANT
test_db=# GRANT ALL ON TABLE clients TO test_admin_user;
GRANT
```
- создадим пользователя test-simple-user:
```
test_db=# CREATE USER test_simple_user;
CREATE ROLE
```
- предоставим пользователю test-simple-user права на SELECT/INSERT/UPDATE/DELETE данных таблиц БД test_db:
```
test_db=# GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE orders TO test_simple_user;
GRANT
test_db=# GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE clients TO test_simple_user;
GRANT
```
- итоговый список БД после выполнения пунктов выше:
![image](https://user-images.githubusercontent.com/87534423/166143911-7cf835c8-ecd0-4af0-8386-a0a53bdfa5fa.png)

- описание таблиц (describe):  
![image](https://user-images.githubusercontent.com/87534423/166144225-2f663f63-463d-4c0e-9941-4099ffbf8b2c.png)

- SQL-запрос для выдачи списка пользователей с правами над таблицами test_db:
```
test_db=# SELECT grantee, table_catalog, table_name, privilege_type FROM information_schema.table_privileges WHERE table_name IN ('orders','clients');
```

- список пользователей с правами над таблицами test_db: 
![image](https://user-images.githubusercontent.com/87534423/166144639-fcdb6c17-487c-45bb-aadd-33b52842cce4.png)


## Задача 3

Используя SQL синтаксис - наполните таблицы следующими тестовыми данными:

Таблица orders

|Наименование|цена|
|------------|----|
|Шоколад| 10 |
|Принтер| 3000 |
|Книга| 500 |
|Монитор| 7000|
|Гитара| 4000|

Таблица clients

|ФИО|Страна проживания|
|------------|----|
|Иванов Иван Иванович| USA |
|Петров Петр Петрович| Canada |
|Иоганн Себастьян Бах| Japan |
|Ронни Джеймс Дио| Russia|
|Ritchie Blackmore| Russia|

Используя SQL синтаксис:
- вычислите количество записей для каждой таблицы 
- приведите в ответе:
    - запросы 
    - результаты их выполнения.

## Решение

- наполним таблицы требуемыми тестовыми данными:  
```
test_db=# INSERT INTO orders VALUES (1, 'Шоколад', 10), (2, 'Принтер', 3000), (3, 'Книга', 500), (4, 'Монитор', 7000), (5, 'Гитара', 4000);
INSERT 0 5
test_db=# INSERT INTO clients VALUES (1, 'Иванов Иван Иванович', 'USA'), (2, 'Петров Петр Петрович', 'Canada'), (3, 'Иоганн Себастьян Бах', 'Japan'), (4, 'Ронни Джеймс Дио', 'Russia'), (5, 'Ritchie Blackmore', 'Russia');
INSERT 0 5
```
- SQL-запросы для вычисления количества записей в таблицах:
```
SELECT COUNT (*) FROM orders;
SELECT COUNT (*) FROM clients;
```
- результаты:  
![image](https://user-images.githubusercontent.com/87534423/166145347-7a4af5b6-72ea-47c3-8e6b-36dda9e3e050.png)


## Задача 4

Часть пользователей из таблицы clients решили оформить заказы из таблицы orders.

Используя foreign keys свяжите записи из таблиц, согласно таблице:

|ФИО|Заказ|
|------------|----|
|Иванов Иван Иванович| Книга |
|Петров Петр Петрович| Монитор |
|Иоганн Себастьян Бах| Гитара |

Приведите SQL-запросы для выполнения данных операций.

Приведите SQL-запрос для выдачи всех пользователей, которые совершили заказ, а также вывод данного запроса.
 
Подсказка - используйте директиву `UPDATE`.

## Решение 
- свяжем записи из таблиц следующими запросами:  
```
test_db=# UPDATE clients SET заказ=(select id from orders where наименование='Книга') WHERE фамилия='Иванов Иван Иванович';
UPDATE 1
test_db=# UPDATE clients SET заказ=(select id from orders where наименование='Монитор') WHERE фамилия='Петров Петр Петрович';
UPDATE 1
test_db=# UPDATE clients SET заказ=(select id from orders where наименование='Гитара') WHERE фамилия='Иоганн Себастьян Бах';
UPDATE 1
```
- с помощью запроса ```SELECT* FROM clients WHERE заказ IS NOT NULL;``` выведем пользователей, которые совершили заказ:  
![image](https://user-images.githubusercontent.com/87534423/166145922-29cdb02b-1357-4f54-a2cb-c5cc3206e51b.png)


## Задача 5

Получите полную информацию по выполнению запроса выдачи всех пользователей из задачи 4 
(используя директиву EXPLAIN).

Приведите получившийся результат и объясните что значат полученные значения.

## Решение 
![image](https://user-images.githubusercontent.com/87534423/166146110-7847a1b3-802f-4b76-bec9-ce41a3fea35b.png)  
Чтение данных из таблицы clients происходит с использованием метода Seq Scan — последовательного чтения данных. Значение 0.00 — ожидаемые затраты на получение первой строки. Второе — 18.10 — ожидаемые затраты на получение всех строк. rows - ожидаемое число строк, которое должен вывести этот узел плана. При этом так же предполагается, что узел выполняется до конца. width - ожидаемый средний размер строк, выводимых этим узлом плана (в байтах). Каждая запись сравнивается с условием "заказ" IS NOT NULL. Если условие выполняется, запись вводится в результат. Иначе — отбрасывается.

Посмотрим, как обработается запрос в реальных условиях, применим директиву ANALYZE:  
![image](https://user-images.githubusercontent.com/87534423/166147175-4dc4df7c-a1b8-41c5-be30-648527f67749.png)  
Здесь уже видны реальные затраты на обработку первой и всех строк, количество выведенных строк (3), удовлетворяющих фильру "заказ" IS NOT NULL, количество проходов (1), количество строк, которые были удалены из запроса по фильтру (2), планируемое и затраченное время, а также общее количество строк, по которым производилась выборка.

## Задача 6

Создайте бэкап БД test_db и поместите его в volume, предназначенный для бэкапов (см. Задачу 1).

Остановите контейнер с PostgreSQL (но не удаляйте volumes).

Поднимите новый пустой контейнер с PostgreSQL.

Восстановите БД test_db в новом контейнере.

Приведите список операций, который вы применяли для бэкапа данных и восстановления. 
