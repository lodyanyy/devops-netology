# Домашнее задание к занятию "3.3. Операционные системы, лекция 1"

1. Какой системный вызов делает команда `cd`? В прошлом ДЗ мы выяснили, что `cd` не является самостоятельной  программой, это `shell builtin`, поэтому запустить `strace` непосредственно на `cd` не получится. Тем не менее, вы можете запустить `strace` на `/bin/bash -c 'cd /tmp'`. В этом случае вы увидите полный список системных вызовов, которые делает сам `bash` при старте. Вам нужно найти тот единственный, который относится именно к `cd`. Обратите внимание, что `strace` выдаёт результат своей работы в поток stderr, а не в stdout.
К команде cd отноится системный вызов chdir("/tmp")


1. Попробуйте использовать команду `file` на объекты разных типов на файловой системе. Например:
    ```bash
    vagrant@netology1:~$ file /dev/tty
    /dev/tty: character special (5/0)
    vagrant@netology1:~$ file /dev/sda
    /dev/sda: block special (8/0)
    vagrant@netology1:~$ file /bin/bash
    /bin/bash: ELF 64-bit LSB shared object, x86-64
    ```
    Используя `strace` выясните, где находится база данных `file` на основании которой она делает свои догадки.
    
    stat("/home/vagrant/.magic.mgc", 0x7ffff270ba50) = -1 ENOENT (No such file or directory)
    stat("/home/vagrant/.magic", 0x7ffff270ba50) = -1 ENOENT (No such file or directory)
    openat(AT_FDCWD, "/etc/magic.mgc", O_RDONLY) = -1 ENOENT (No such file or directory)
    stat("/etc/magic", {st_mode=S_IFREG|0644, st_size=111, ...}) = 0
    openat(AT_FDCWD, "/etc/magic", O_RDONLY) = 3
    ...
    openat(AT_FDCWD, "/usr/share/misc/magic.mgc", O_RDONLY) = 3

Базы данных для file могут находится в следующих файлах: /home/vagrant/.magic.mgc, /home/vagrant/.magic, /etc/magic.mgc. Но находятся в /etc/magic и в /usr/share/misc/magic.mgc


1. Предположим, приложение пишет лог в текстовый файл. Этот файл оказался удален (deleted в lsof), однако возможности сигналом сказать приложению переоткрыть файлы или просто перезапустить приложение – нет. Так как приложение продолжает писать в удаленный файл, место на диске постепенно заканчивается. Основываясь на знаниях о перенаправлении потоков предложите способ обнуления открытого удаленного файла (чтобы освободить место на файловой системе).

    Сымитруем запись лога приложения в текстовый файл. Командой cat прочитаем ввод и перенаправим его в файл some_log
        $ cat > some_log
        1kdhfj;nbrgov;m,dSPIrcg,GSCPKRg,ckprsgBMSkjonascrmcuToavnaiigbmndfib
    Затем, не завершая запись в файл, в другом теминале находим PID зпущенного процесса
        $ ps u
        USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        vagrant     7189  0.0  0.0   8220   520 pts/0    S+   07:06   0:00 cat
    Смотрим, сколько места занимает процесс:
		$ lsof -p 7189
		COMMAND  PID    USER   FD   TYPE DEVICE SIZE/OFF    NODE NAME
		cat     7189 vagrant    1w   REG  253,0       69 3670032 /tmp/some_log
	В данном случае 69 байт, файловый дескриптор 1
	Далее используем перенаправление вывода:
		$ > some_log
	И проверяем теперь место, занимаемое процессом 7189:
		COMMAND  PID    USER   FD   TYPE DEVICE SIZE/OFF    NODE NAME
		cat     7189 vagrant    1w   REG  253,0        0 3670032 /tmp/some_log
	Размер файла стал равен 0.
	
	
1. Занимают ли зомби-процессы какие-то ресурсы в ОС (CPU, RAM, IO)?

	"Зомби" процессы не занимают ресурсы в ОС, но не освобождают запись в таблице процессов. 
запись освободиться при вызове wait() родительским процессом. 


1. В iovisor BCC есть утилита `opensnoop`:
    ```bash
    root@vagrant:~# dpkg -L bpfcc-tools | grep sbin/opensnoop
    /usr/sbin/opensnoop-bpfcc
    ```
    На какие файлы вы увидели вызовы группы `open` за первую секунду работы утилиты? Воспользуйтесь пакетом `bpfcc-tools` для Ubuntu 20.04. Дополнительные [сведения по установке](https://github.com/iovisor/bcc/blob/master/INSTALL.md).
	
		root@vagrant/usr/sbin/opensnoop-bpfcc -d 1
		PID    COMM               FD ERR PATH
		799    vminfo              4   0 /var/run/utmp

1. Какой системный вызов использует `uname -a`? Приведите цитату из man по этому системному вызову, где описывается альтернативное местоположение в `/proc`, где можно узнать версию ядра и релиз ОС.
	
	Используется системный вызов uname()
	65 и 66 строчка в man:
	Part of the utsname information is  also  accessible  via  /proc/sys/kernel/{ostype, hostname, osrelease, version, domainname}.
	
	
1. Чем отличается последовательность команд через `;` и через `&&` в bash? Например:
    ```bash
    root@netology1:~# test -d /tmp/some_dir; echo Hi
    Hi
    root@netology1:~# test -d /tmp/some_dir && echo Hi
    root@netology1:~#
    ```
    Есть ли смысл использовать в bash `&&`, если применить `set -e`?
	
	Последовательность команд через `;` выполняется по порядку вне зависимости от их результата, а последовательность команд через `&&` выполняется сначала слева от  `&&`, а затем, при удачном выполнении левой части, справа от `&&`.
	При set -e командная оболочка завершит свою работу, если список исполняемых команд завершится с ненулевым результатом, кроме случая, когда с ненулевым результатом выполнения завершится непоследняя команда.
	То есть смысл использовать `&&` есть, так как при использовании `set -e` команда с `&&` и неудачным выполнением левой части командная оболочка не завершит свою работу.

	
1. Из каких опций состоит режим bash `set -euxo pipefail` и почему его хорошо было бы использовать в сценариях?

	-e прерывает выполнение исполнения при ошибке любой команды кроме последней в последовательности 
	-x вывод трейса простых команд 
	-u неустановленные/не заданные параметры и переменные считаются как ошибки, с выводом в stderr текста ошибки и выполнит завершение неинтерактивного вызова
	-o pipefail возвращает код возврата набора/последовательности команд, ненулевой при последней команды или 0 для успешного выполнения команд.
	Данный режим будет полезен при отладке, либо для большего информирования при наличии ошибок.
	
	
1. Используя `-o stat` для `ps`, определите, какой наиболее часто встречающийся статус у процессов в системе. В `man ps` ознакомьтесь (`/PROCESS STATE CODES`) что значат дополнительные к основной заглавной буквы статуса процессов. Его можно не учитывать при расчете (считать S, Ss или Ssl равнозначными).

		D    uninterruptible sleep (usually IO)
        I    Idle kernel thread
        R    running or runnable (on run queue)
        S    interruptible sleep (waiting for an event to complete)
        T    stopped by job control signal
        t    stopped by debugger during the tracing
        W    paging (not valid since the 2.6.xx kernel)
        X    dead (should never be seen)
        Z    defunct ("zombie") process, terminated but not reaped by its parent
		
	При выполнении ps -Ao stat больше всего в системе видим процессы в состоянии прерываемого сна. 
