# Домашняя работа к занятию "4.2. Использование Python для решения типовых DevOps задач"

## Обязательная задача 1

Есть скрипт:
```python
#!/usr/bin/env python3
a = 1
b = '2'
c = a + b
```

### Вопросы:
| Вопрос  | Ответ |
| ------------- | ------------- |
| Какое значение будет присвоено переменной `c`?  | возникнет ошибка при сложении разных типов данных int и str  |
| Как получить для переменной `c` значение 12?  | нужно смнить тип переменной a на string c = str(a) + b чтобы складывались строки |
| Как получить для переменной `c` значение 3?  | нужно смнить тип переменной b на integer c = a + int(b) чтобы складывлись числа |

## Обязательная задача 2
Мы устроились на работу в компанию, где раньше уже был DevOps Engineer. Он написал скрипт, позволяющий узнать, какие файлы модифицированы в репозитории, относительно локальных изменений. Этим скриптом недовольно начальство, потому что в его выводе есть не все изменённые файлы, а также непонятен полный путь к директории, где они находятся. Как можно доработать скрипт ниже, чтобы он исполнял требования вашего руководителя?

```python
#!/usr/bin/env python3
import os
bash_command = ["cd ~/netology/sysadm-homeworks", "git status"]
result_os = os.popen(' && '.join(bash_command)).read()
is_change = False
for result in result_os.split('\n'):
    if result.find('modified') != -1:
        prepare_result = result.replace('\tmodified:   ', '')
        print(prepare_result)
        break
```

### Ваш скрипт:  
убрали лишнюю переменную is_change и команду break, прерывающую выполнение программы после первого успешно найденного значения. Добавили функцию os.getcwd(), возвращающую текущую директорию поиска. 
```python
#!/usr/bin/env python3
import os
bash_command = ["cd ~/netology/sysadm-homeworks", "git status"]
result_os = os.popen(' && '.join(bash_command)).read()
#is_change = False
for result in result_os.split('\n'):
    if result.find('изменено') != -1:
        prepare_result = result.replace('\tизменено:      ', '')
        print(os.getcwd() ,'/' , prepare_result, sep='')
        #break
```

### Вывод скрипта при запуске при тестировании:
```bash
lodyanyy@lodyanyy:~$ /home/lodyanyy/123.py
/home/lodyanyy/README.md
/home/lodyanyy/new/123456.md
/home/lodyanyy/test1.sh
```

## Обязательная задача 3
1. Доработать скрипт выше так, чтобы он мог проверять не только локальный репозиторий в текущей директории, а также умел воспринимать путь к репозиторию, который мы передаём как входной параметр. Мы точно знаем, что начальство коварное и будет проверять работу этого скрипта в директориях, которые не являются локальными репозиториями.

### Ваш скрипт:
```python
#!/usr/bin/env python3
import os
import sys
path=os.getcwd()
if len(sys.argv)!=1:
    path=sys.argv[1]
bash_command = [f'cd {path}', 'git status 2>&1']
result_os = os.popen(' && '.join(bash_command)).read()
for result in result_os.split('\n'):
    if result.find('fatal') != -1:
        print('Каталог не является GIT репозиторием')
    if result.find('изменено') != -1:
        prepare_result = result.replace('\tизменено:      ', '')
        print(os.getcwd() ,'/' , prepare_result, sep='')
```
### Вывод скрипта при запуске при тестировании:

```
lodyanyy@lodyanyy:~/netology/sysadm-homeworks$ ./123.py
/home/lodyanyy/netology/sysadm-homeworks/README.md
/home/lodyanyy/netology/sysadm-homeworks/new/123456.md
/home/lodyanyy/netology/sysadm-homeworks/test1.sh
lodyanyy@lodyanyy:~/netology/sysadm-homeworks$ ./123.py /media/lodyanyy/Soft/devops-netology
/home/lodyanyy/netology/sysadm-homeworks/test1.sh
/home/lodyanyy/netology/sysadm-homeworks/test133.md
lodyanyy@lodyanyy:~/netology/sysadm-homeworks$ ./123.py /media/lodyanyy/Soft
Каталог не является GIT репозиторием
```

## Обязательная задача 4
1. Наша команда разрабатывает несколько веб-сервисов, доступных по http. Мы точно знаем, что на их стенде нет никакой балансировки, кластеризации, за DNS прячется конкретный IP сервера, где установлен сервис. Проблема в том, что отдел, занимающийся нашей инфраструктурой очень часто меняет нам сервера, поэтому IP меняются примерно раз в неделю, при этом сервисы сохраняют за собой DNS имена. Это бы совсем никого не беспокоило, если бы несколько раз сервера не уезжали в такой сегмент сети нашей компании, который недоступен для разработчиков. Мы хотим написать скрипт, который опрашивает веб-сервисы, получает их IP, выводит информацию в стандартный вывод в виде: <URL сервиса> - <его IP>. Также, должна быть реализована возможность проверки текущего IP сервиса c его IP из предыдущей проверки. Если проверка будет провалена - оповестить об этом в стандартный вывод сообщением: [ERROR] <URL сервиса> IP mismatch: <старый IP> <Новый IP>. Будем считать, что наша разработка реализовала сервисы: `drive.google.com`, `mail.google.com`, `google.com`.

### Ваш скрипт:
```python
#!/usr/bin/env python3

import socket
import time

hosts = {'drive.google.com':'0.0.0.0', 'mail.google.com':'0.0.0.0', 'google.com':'0.0.0.0'}
while 1 == 1 :
  for host in hosts :
    ip = socket.gethostbyname(host)
    if ip != hosts[host] :
      print(' [ERROR] ' + str(host) +' IP mistmatch: '+hosts[host]+' '+ip)
      hosts[host]=ip
    else :
        print(str(host) + ' ' + ip)
    time.sleep(2)
```

### Вывод скрипта при запуске при тестировании:
```bash
lodyanyy@lodyanyy:~/netology/sysadm-homeworks$ /home/lodyanyy/netology/sysadm-homeworks/456.py
 [ERROR] drive.google.com IP mistmatch: 0.0.0.0 74.125.131.194
 [ERROR] mail.google.com IP mistmatch: 0.0.0.0 64.233.165.19
 [ERROR] google.com IP mistmatch: 0.0.0.0 173.194.222.102
drive.google.com 74.125.131.194
mail.google.com 64.233.165.19
google.com 173.194.222.102
drive.google.com 74.125.131.194
mail.google.com 64.233.165.19
google.com 173.194.222.102
...
```
