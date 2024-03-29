# Домашняя работа к занятию "6.4. PostgreSQL"

## Задача 1

Используя docker поднимите инстанс PostgreSQL (версию 13). Данные БД сохраните в volume.

Подключитесь к БД PostgreSQL используя `psql`.

Воспользуйтесь командой `\?` для вывода подсказки по имеющимся в `psql` управляющим командам.

**Найдите и приведите** управляющие команды для:
- вывода списка БД
- подключения к БД
- вывода списка таблиц
- вывода описания содержимого таблиц
- выхода из psql

## Решение  
- вывод списка БД

```
postgres=# \l
                                  List of databases
    Name     |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
-------------+----------+----------+------------+------------+-----------------------
 lodyanyy_db | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres    | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0   | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | =c/lodyanyy          +
             |          |          |            |            | lodyanyy=CTc/lodyanyy
 template1   | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | =c/lodyanyy          +
             |          |          |            |            | lodyanyy=CTc/lodyanyy
  (4 rows)
```  
- подключение к БД  

```
postgres=# \c postgres
You are now connected to database "postgres" as user "lodyanyy".
```  
- вывод списка таблиц  

```
  postgres=# \dtS
                    List of relations
   Schema   |          Name           | Type  |  Owner   
------------+-------------------------+-------+----------
 pg_catalog | pg_aggregate            | table | lodyanyy
 pg_catalog | pg_am                   | table | lodyanyy
 pg_catalog | pg_amop                 | table | lodyanyy
 pg_catalog | pg_amproc               | table | lodyanyy
 pg_catalog | pg_attrdef              | table | lodyanyy
 pg_catalog | pg_attribute            | table | lodyanyy
 pg_catalog | pg_auth_members         | table | lodyanyy
 ...
```  
- вывод описания содержимого таблиц  

```
postgres=# \dS+ pg_aggregate
                                   Table "pg_catalog.pg_aggregate"
      Column      |   Type   | Collation | Nullable | Default | Storage  | Stats target | Description 
------------------+----------+-----------+----------+---------+----------+--------------+-------------
 aggfnoid         | regproc  |           | not null |         | plain    |              | 
 aggkind          | "char"   |           | not null |         | plain    |              | 
 aggnumdirectargs | smallint |           | not null |         | plain    |              | 
 aggtransfn       | regproc  |           | not null |         | plain    |              | 
 aggfinalfn       | regproc  |           | not null |         | plain    |              | 
 aggcombinefn     | regproc  |           | not null |         | plain    |              | 
 ...
```
- выход из psql
```
postgres=# \q
```

## Задача 2

Используя `psql` создайте БД `test_database`.

Изучите [бэкап БД](https://github.com/netology-code/virt-homeworks/tree/master/06-db-04-postgresql/test_data).

Восстановите бэкап БД в `test_database`.

Перейдите в управляющую консоль `psql` внутри контейнера.

Подключитесь к восстановленной БД и проведите операцию ANALYZE для сбора статистики по таблице.

Используя таблицу [pg_stats](https://postgrespro.ru/docs/postgresql/12/view-pg-stats), найдите столбец таблицы `orders` 
с наибольшим средним значением размера элементов в байтах.

**Приведите в ответе** команду, которую вы использовали для вычисления и полученный результат.

## Решение

Создадим БД test_database:
```
lodyanyy_db=# CREATE DATABASE test_database;
CREATE DATABASE
lodyanyy_db-# \l
                                   List of databases
     Name      |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges   
---------------+----------+----------+------------+------------+-----------------------
 lodyanyy_db   | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | 
 postgres      | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | 
 template0     | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | =c/lodyanyy          +
               |          |          |            |            | lodyanyy=CTc/lodyanyy
 template1     | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | =c/lodyanyy          +
               |          |          |            |            | lodyanyy=CTc/lodyanyy
 test_database | lodyanyy | UTF8     | en_US.utf8 | en_US.utf8 | 
(5 rows)
```
Восстановим бэкап:
```
root@5a070ae8235e:/# psql -U lodyanyy -d test_database < /var/tmp/test_dump.sql
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 row)

SET
SET
SET
SET
SET
SET
ERROR:  relation "orders" already exists
ERROR:  role "postgres" does not exist
ERROR:  relation "orders_id_seq" already exists
ERROR:  role "postgres" does not exist
ALTER SEQUENCE
ALTER TABLE
ERROR:  duplicate key value violates unique constraint "orders_pkey"
DETAIL:  Key (id)=(1) already exists.
CONTEXT:  COPY orders, line 1
 setval 
--------
      8
(1 row)

ERROR:  multiple primary keys for table "orders" are not allowed
```
Подключимся к БД test_database, посмотрим список существующих таблиц и соберем статистику с помощью ANALYZE:
```
test_database=# root@5a070ae8235e:/# psql -U lodyanyy -d test_database
psql (13.7 (Debian 13.7-1.pgdg110+1))
Type "help" for help.

test_database=# \dt
         List of relations
 Schema |  Name  | Type  |  Owner   
--------+--------+-------+----------
 public | orders | table | lodyanyy
(1 row)

test_database=# ^C
test_database=# ANALYZE verbose orders;
INFO:  analyzing "public.orders"
INFO:  "orders": scanned 1 of 1 pages, containing 8 live rows and 16 dead rows; 8 rows in sample, 8 estimated total rows
ANALYZE
```
Найдем столбец таблицы orders с наибольшим средним значением размера элементов в байтах (это title):
```
test_database=# select attname, avg_width from pg_stats where tablename='orders';
 attname | avg_width 
---------+-----------
 id      |         4
 title   |        16
 price   |         4
(3 rows)
```


## Задача 3

Архитектор и администратор БД выяснили, что ваша таблица orders разрослась до невиданных размеров и
поиск по ней занимает долгое время. Вам, как успешному выпускнику курсов DevOps в нетологии предложили
провести разбиение таблицы на 2 (шардировать на orders_1 - price>499 и orders_2 - price<=499).

Предложите SQL-транзакцию для проведения данной операции.

Можно ли было изначально исключить "ручное" разбиение при проектировании таблицы orders?

## Решение

SQL-транзакция:

```
BEGIN;
CREATE TABLE orders_1 (LIKE orders);
INSERT INTO orders_1 SELECT * FROM orders WHERE price >499;
DELETE FROM orders WHERE price >499;
CREATE TABLE orders_2 (LIKE orders);
INSERT INTO orders_2 SELECT * FROM orders WHERE price <=499;
DELETE FROM orders WHERE price <=499;
COMMIT;
```
```
test_database=# SELECT * FROM public.orders;
 id | title | price 
----+-------+-------
(0 rows)

test_database=# SELECT * FROM public.orders_1;
 id |       title        | price 
----+--------------------+-------
  2 | My little database |   500
  6 | WAL never lies     |   900
  8 | Dbiezdmin          |   501
(3 rows)

test_database=# SELECT * FROM public.orders_2;
 id |        title         | price 
----+----------------------+-------
  1 | War and peace        |   100
  3 | Adventure psql time  |   300
  4 | Server gravity falls |   300
  5 | Log gossips          |   123
  7 | Me and my bash-pet   |   499
(5 rows)
```
Можно изначально исключить "ручное" разбиение при проектировании таблицы orders, если использовать декларативное секционирование с предложением PARTITION BY.  

## Задача 4

Используя утилиту `pg_dump` создайте бекап БД `test_database`.

Как бы вы доработали бэкап-файл, чтобы добавить уникальность значения столбца `title` для таблиц `test_database`?

## Решение  

Создадим бэкап:
```
pg_dump -U lodyanyy -d test_database >test_database_dump.sql
```  
Уникальность столбца title можно выполнить следующим образом:
```
test_database=# CREATE unique INDEX title_un ON public.orders(title);
CREATE INDEX
```
