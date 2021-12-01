# Домашняя работа "3.4. Операционные системы, лекция 2"

1. На лекции мы познакомились с [node_exporter](https://github.com/prometheus/node_exporter/releases). В демонстрации его исполняемый файл запускался в background. Этого достаточно для демо, но не для настоящей production-системы, где процессы должны находиться под внешним управлением. Используя знания из лекции по systemd, создайте самостоятельно простой [unit-файл](https://www.freedesktop.org/software/systemd/man/systemd.service.html) для node_exporter:
    * поместите его в автозагрузку,
    * предусмотрите возможность добавления опций к запускаемому процессу через внешний файл (посмотрите, например, на `systemctl cat cron`),
    * удостоверьтесь, что с помощью systemctl процесс корректно стартует, завершается, а после перезагрузки автоматически поднимается.

	>Создадим unit-файл для node_exporter:  

   >$ cd /etc/systemd/system  
	 $ sudo vim node_exporter.service  
	[Unit]  
		Description=Node Exporter  
		After=network-online.target  
	[Service]  
		User=node_exporter  
		Group=node_exporter  
		Type=simple  
		ExecStart=/usr/local/bin/node_exporter  
		EnvironmentFile=/etc/default/node_exporter  
	[Install]  
		WantedBy=multi-user.target  
	
	>Добавим севрис в автозагрузку:
	$ sudo systemctl enable node_exporter
	
	>Перезагрузим демон и запустим node_exporter:  
	$ sudo systemctl daemon-reload  
	$ sudo systemctl start node_exporter  
	
	>Выполним ребут и посмотрим статус службы после загрузки системы:  
	$ sudo reboot  
	...  
	$ sudo systemctl status node_exporter.service  
	● node_exporter.service - Node Exporter  
     Loaded: loaded (/etc/systemd/system/node_exporter.service; enabled; vendor preset: enabled)  
     Active: active (running) since Fri 2021-11-26 05:37:36 UTC; 4h 10min ago  
   Main PID: 690 (node_exporter)  
      Tasks: 5 (limit: 4616)  
     Memory: 14.7M  
     CGroup: /system.slice/node_exporter.service  
             └─690 /usr/local/bin/node_exporter  
			 
	>Служба активна - значит автозагрузка работает.

	
2. Ознакомьтесь с опциями node_exporter и выводом `/metrics` по-умолчанию. Приведите несколько опций, которые вы бы выбрали для базового мониторинга хоста по CPU, памяти, диску и сети.

 >Чтобы активировать дополнительные опции для базового мониторинга хоста по CPU, памяти, диску и сети, добавим флаг –collector. <name> в node_exporter.service при запуске экспортера узлов:

	>ExecStart=/usr/local/bin/node_exporter  --collector.disable-defaults --collector.netstat --collector.meminfo --collector.cpu --collector.filesystem


3. Установите в свою виртуальную машину [Netdata](https://github.com/netdata/netdata). Воспользуйтесь [готовыми пакетами](https://packagecloud.io/netdata/netdata/install) для установки (`sudo apt install -y netdata`). После успешной установки:
    * в конфигурационном файле `/etc/netdata/netdata.conf` в секции [web] замените значение с localhost на `bind to = 0.0.0.0`,
    * добавьте в Vagrantfile проброс порта Netdata на свой локальный компьютер и сделайте `vagrant reload`:
    ```bash
    config.vm.network "forwarded_port", guest: 19999, host: 19999
    ```
    После успешной перезагрузки в браузере *на своем ПК* (не в виртуальной машине) вы должны суметь зайти на `localhost:19999`. Ознакомьтесь с метриками, которые по умолчанию собираются Netdata и с комментариями, которые даны к этим метрикам.


	>Установили на виртуальную машину netdata согласно документации. Изменили значение 127.0.0.1 на 0.0.0.0 в конфигурационном файле `/etc/netdata/netdata.conf`. Добавили в Vagrantfile проброс порта Netdata на свой локальный компьютер и сделали `vagrant reload`. При переходе в браузере на `localhost:19999` увидили графический интерфейс с метриками CPU, load, disk, ram, swap, network, processes, idlejitter, interrupts и т.д. У каждой метрики есть описание и информативный дисплей.
![image](https://user-images.githubusercontent.com/87534423/144200386-ac11d687-0be2-417d-8355-0c32ead77d80.png)


4. Можно ли по выводу `dmesg` понять, осознает ли ОС, что загружена не на настоящем оборудовании, а на системе виртуализации?  

>Чтобы проверить, является ли система Linux физической или виртуальной, запустим:  

>$ dmesg | grep "Hypervisor detected"  

>Если система физическая, мы не увидим никаких выходных данных.  
>Если система – виртуальная машина, мы увидим такой результат:  

>[ 0.000000] Hypervisor detected: KVM  

5. Как настроен sysctl `fs.nr_open` на системе по-умолчанию? Узнайте, что означает этот параметр. Какой другой существующий лимит не позволит достичь такого числа (`ulimit --help`)?  

>vagrant@vagrant:~$ sysctl fs.nr_open  
>fs.nr_open = 1048576  

>Параметр означает максимальное количество дескрипторов файлов, которое может выделить процесс. Значение по умолчанию - 1024х1024 (1048576), чего должно хватить для большинства машин. Фактический лимит зависит от лимита ресурсов RLIMIT_NOFILE.

>RLIMIT_NOFILE — указывает значение, которое больше максимального номера дескриптора файла, который может быть открыт этим процессом.

>Также максимальное количество открытых файлов для процесса мы можем увидеть через ulimit. Есть жесткий и мягкий лимиты максимально открытых дескрипторов. Мягкий лимит:   

>	$ ulimit -Sn
>	1024
>"жесткий" лимит, устанавливается администратором. Пользователь имеет право увеличить "мягкий" лимит до значения "жесткого":

>	$ ulimit -Hn
	1048576

6. Запустите любой долгоживущий процесс (не `ls`, который отработает мгновенно, а, например, `sleep 1h`) в отдельном неймспейсе процессов; покажите, что ваш процесс работает под PID 1 через `nsenter`. Для простоты работайте в данном задании под root (`sudo -i`). Под обычным пользователем требуются дополнительные опции (`--map-root-user`) и т.д.

>Запущенные экземпляры bash

>vagrant@vagrant:~$ ps au -H | fgrep '/bin/bash'| grep -v grep  
vagrant     1681  0.0  0.4   9968  4136 pts/2    Ss   19:26   0:00 /bin/bash  
root        1707  0.0  0.0   8080   592 pts/2    S    19:27   0:00       unshare -f --pid --mount-proc /bin/bash  
root        1708  0.0  0.4   9836  4264 pts/2    S    19:27   0:00         /bin/bash  
С unshare запущен bash PID = 1708. Если зайти в неймспейс по этому пиду, ps aux -H покажет, что PID bash = 1.  

>vagrant@vagrant:~$ sudo nsenter --target 1708 --pid --mount  
root@vagrant:/# ps aux -H  
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND  
root          24  0.0  0.3   9836  3976 pts/1    S    19:30   0:00 -bash  
root          33  0.0  0.3  11492  3396 pts/1    R+   19:30   0:00   ps aux -H  
root           1  0.0  0.4   9836  4264 pts/2    S    19:27   0:00 /bin/bash  
root          12  0.0  0.0   8076   592 pts/2    S+   19:28   0:00   sleep 1h  

7. Найдите информацию о том, что такое `:(){ :|:& };:`. Запустите эту команду в своей виртуальной машине Vagrant с Ubuntu 20.04 (**это важно, поведение в других ОС не проверялось**). Некоторое время все будет "плохо", после чего (минуты) – ОС должна стабилизироваться. Вызов `dmesg` расскажет, какой механизм помог автоматической стабилизации. Как настроен этот механизм по-умолчанию, и как изменить число процессов, которое можно создать в сессии?

>Логическая бомба (известная также как fork bomb), забивающая память системы, что в итоге приводит к её зависанию.    
 $ :(){ :|:& };:  
 [..]  
 $ dmesg  
 cgroup: fork rejected by pids controller in /user.slice/user-1000.slice/session-1.scope  
 
>Ограничить количество запущенных процессов для пользователя можно с помощью ulimit -u. 

