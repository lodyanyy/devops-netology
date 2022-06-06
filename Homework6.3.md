# Домашняя работа к занятию "6.3. MySQL"

## Введение

Перед выполнением задания вы можете ознакомиться с 
[дополнительными материалами](https://github.com/netology-code/virt-homeworks/tree/master/additional/README.md).

## Задача 1

Используя docker поднимите инстанс MySQL (версию 8). Данные БД сохраните в volume.

Изучите [бэкап БД](https://github.com/netology-code/virt-homeworks/tree/master/06-db-03-mysql/test_data) и 
восстановитесь из него.

Перейдите в управляющую консоль `mysql` внутри контейнера.

Используя команду `\h` получите список управляющих команд.

Найдите команду для выдачи статуса БД и **приведите в ответе** из ее вывода версию сервера БД.

Подключитесь к восстановленной БД и получите список таблиц из этой БД.

**Приведите в ответе** количество записей с `price` > 300.

В следующих заданиях мы будем продолжать работу с данным контейнером.

## Решение  

Создадим .yml файл:  

```
version: '3.7'
services:
  db:
    image: mysql:8
    restart: always
    environment:
      MYSQL_DATABASE: 'lodyanyy_db'
      MYSQL_USER: 'lodyanyy'
      MYSQL_PASSWORD: 'qaz123'
      MYSQL_ROOT_PASSWORD: 'qaz1234'
    volumes:
      - my-db:/var/lib/mysql
volumes:
  my-db:
```

Запустим проект  

```
$ docker-compose up -d
Creating network "06-db-03-mysql_default" with the default driver
Creating volume "06-db-03-mysql_my-db" with default driver
Pulling db (mysql:8)...
8: Pulling from library/mysql
Digest: sha256:548da4c67fd8a71908f17c308b8ddb098acf5191d3d7694e56801c6a8b2072cc
Status: Downloaded newer image for mysql:8
Creating 06-db-03-mysql_db_1 ... done
```
Копируем бэкап в запущенный контейнер
```
$ docker cp test_dump.sql 06-db-03-mysql_db_1:/var/tmp/test_dump.sql
```
Запускаем командную строку в контейнере и восстановим дамп
```
$ sudo docker exec -it 06-db-03-mysql_db_1 bash
/# mysql -u lodyanyy -p lodyanyy_db < /var/tmp/test_dump.sql
```
Версия сервера БД
```
mysql> \s
--------------
mysql  Ver 8.0.29 for Linux on x86_64 (MySQL Community Server - GPL)

Connection id:          11
Current database:       lodyanyy_db
Current user:           lodyanyy@localhost
SSL:                    Not in use
Current pager:          stdout
Using outfile:          ''
Using delimiter:        ;
Server version:         8.0.29 MySQL Community Server - GPL
Protocol version:       10
Connection:             Localhost via UNIX socket
Server characterset:    utf8mb4
Db     characterset:    utf8mb4
Client characterset:    latin1
Conn.  characterset:    latin1
UNIX socket:            /var/run/mysqld/mysqld.sock
Binary data as:         Hexadecimal
Uptime:                 48 min 34 sec

Threads: 2  Questions: 38  Slow queries: 0  Opens: 160  Flush tables: 3  Open tables: 78  Queries per second avg: 0.013
--------------
```
Список таблиц БД
```
mysql> SHOW TABLES;
+-----------------------+
| Tables_in_lodyanyy_db |
+-----------------------+
| orders                |
+-----------------------+
1 row in set (0.00 sec)
```
Приведем в ответе количество записей с price > 300
```
mysql> select count(*) from orders where price > 300;
+----------+
| count(*) |
+----------+
|        1 |
+----------+
1 row in set (0.01 sec)
```

## Задача 2

Создайте пользователя test в БД c паролем test-pass, используя:
- плагин авторизации mysql_native_password
- срок истечения пароля - 180 дней 
- количество попыток авторизации - 3 
- максимальное количество запросов в час - 100
- аттрибуты пользователя:
    - Фамилия "Pretty"
    - Имя "James"

Предоставьте привелегии пользователю `test` на операции SELECT базы `test_db`.
    
Используя таблицу INFORMATION_SCHEMA.USER_ATTRIBUTES получите данные по пользователю `test` и 
**приведите в ответе к задаче**.  

## Решение

Создадим пользователя с требуемыми параметрами:  
```
CREATE USER 'test'@'localhost' 
    IDENTIFIED WITH mysql_native_password BY 'test-pass'
    WITH MAX_CONNECTIONS_PER_HOUR 100
    PASSWORD EXPIRE INTERVAL 180 DAY
    FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 2
    ATTRIBUTE '{"first_name":"James", "last_name":"Pretty"}';
```
Предоставим привелегии пользователю test на операции SELECT базы lodyanyy_db:  
```
GRANT SELECT ON lodyanyy_db.* to 'test'@'localhost';
```  
Используя таблицу INFORMATION_SCHEMA.USER_ATTRIBUTES получим данные по пользователю test:
```
SELECT * from INFORMATION_SCHEMA.USER_ATTRIBUTES where USER = 'test';
+------+-----------+------------------------------------------------+
| USER | HOST      | ATTRIBUTE                                      |
+------+-----------+------------------------------------------------+
| test | localhost | {"last_name": "Pretty", "first_name": "James"} |
+------+-----------+------------------------------------------------+
1 row in set (0.00 sec)
```

## Задача 3

Установите профилирование `SET profiling = 1`.
Изучите вывод профилирования команд `SHOW PROFILES;`.

Исследуйте, какой `engine` используется в таблице БД `test_db` и **приведите в ответе**.

Измените `engine` и **приведите время выполнения и запрос на изменения из профайлера в ответе**:
- на `MyISAM`
- на `InnoDB`  

## Решение

Установим профилирование и изучим вывод профилирования команд:
```
SET profiling = 1
SHOW PROFILES;
+----------+------------+----------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                |
+----------+------------+----------------------------------------------------------------------+
|        1 | 0.00094600 | SELECT * from INFORMATION_SCHEMA.USER_ATTRIBUTES where USER = 'test' |
|        2 | 0.00175075 | show databases                                                       |
|        3 | 0.00036200 | SHOW GRANTS                                                          |
+----------+------------+----------------------------------------------------------------------+
3 rows in set, 1 warning (0.00 sec)
```  
В  таблице БД `lodyanyy_db` используется engine InnoDB:
```
SELECT TABLE_NAME, ENGINE FROM information_schema.TABLES where TABLE_SCHEMA = 'lodyanyy_db';
+------------+--------+
| TABLE_NAME | ENGINE |
+------------+--------+
| orders     | InnoDB |
+------------+--------+
1 row in set (0.01 sec)
```
Измените engine и **приведите время выполнения и запрос на изменения из профайлера в ответе**:
```
SHOW PROFILES;
+----------+------------+----------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                            |
+----------+------------+----------------------------------------------------------------------------------+
|       11 | 0.47458650 | ALTER TABLE lodyanyy_db.orders ENGINE = MyIsam                                   |
|       12 | 1.79490775 | ALTER TABLE lodyanyy_db.orders ENGINE = InnoDB                                   |
+----------+------------+----------------------------------------------------------------------------------+
12 rows in set, 1 warning (0.00 sec)
```  

## Задача 4 

Изучите файл `my.cnf` в директории /etc/mysql.

Измените его согласно ТЗ (движок InnoDB):
- Скорость IO важнее сохранности данных
- Нужна компрессия таблиц для экономии места на диске
- Размер буффера с незакомиченными транзакциями 1 Мб
- Буффер кеширования 30% от ОЗУ
- Размер файла логов операций 100 Мб

Приведите в ответе измененный файл `my.cnf`.

## Решение 

Изучим файл my.cnf:
```
root@2d148ee02bf1:/# cat /etc/mysql/my.cnf
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
secure-file-priv= NULL

# Custom config should go here
!includedir /etc/mysql/conf.d/
```
Изменим его согласно ТЗ (движок InnoDB):
```
root@2d148ee02bf1:/# cat /etc/mysql/my.cnf
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL  Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
secure-file-priv= NULL

# Custom config should go here
!includedir /etc/mysql/conf.d/
innodb_flush_log_at_trx_commit = 0
innodb_file_format=Barracuda
innodb_log_buffer_size= 1M
key_buffer_size = 300M
max_binlog_size= 100M
```
