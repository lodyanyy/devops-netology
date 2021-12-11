# Домашнее задание к занятию "3.7. Компьютерные сети, лекция 2"

#### 1. Проверьте список доступных сетевых интерфейсов на вашем компьютере. Какие команды есть для этого в Linux и в Windows?  
- Linux  
```bash
lodyanyy@lodyanyy:~$ ip -c -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
enp3s0           UP             c8:60:00:2a:55:97 <BROADCAST,MULTICAST,UP,LOWER_UP> 
wlp4s6           DOWN           48:5b:39:bd:c5:79 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
```  

- Windows  
```bash
PS Z:\> ipconfig

Настройка протокола IP для Windows


Адаптер Ethernet Ethernet 4:

   Состояние среды. . . . . . . . : Среда передачи недоступна.
   DNS-суффикс подключения . . . . . :

Адаптер Ethernet VirtualBox Host-Only Network:

   DNS-суффикс подключения . . . . . :
   Локальный IPv6-адрес канала . . . : fe80::446d:57f9:77f:ee06%9
   IPv4-адрес. . . . . . . . . . . . : 192.168.56.1
   Маска подсети . . . . . . . . . . : 255.255.255.0
   Основной шлюз. . . . . . . . . :

Адаптер Ethernet Ethernet 5:

   DNS-суффикс подключения . . . . . :
   Локальный IPv6-адрес канала . . . : fe80::5c70:e0f6:d95f:9f4e%10
   IPv4-адрес. . . . . . . . . . . . : 10.78.1.14
   Маска подсети . . . . . . . . . . : 255.255.255.0
   Основной шлюз. . . . . . . . . : 10.78.1.1

Адаптер Ethernet Ethernet 3:

   Состояние среды. . . . . . . . : Среда передачи недоступна.
   DNS-суффикс подключения . . . . . :
```

#### 2. Какой протокол используется для распознавания соседа по сетевому интерфейсу? Какой пакет и команды есть в Linux для этого?  

Используются протоколы LLDP и CDP  
В linux существует пакет lldpd. Командой lldpctl можем увидеть соседствующее оборудование.

#### 3. Какая технология используется для разделения L2 коммутатора на несколько виртуальных сетей? Какой пакет и команды есть в Linux для этого? Приведите пример конфига.  

Используется технология VLAN. В linux используется пакеты vlan или iproute2.  
```bash
lodyanyy@lodyanyy:~$ sudo /sbin/vconfig add enp3s0 100  
lodyanyy@lodyanyy:~$ sudo /sbin/ifconfig enp3s0.100 10.78.1.14 netmask 255.255.255.0 up  
lodyanyy@lodyanyy:~$ ifconfig
enp3s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.31.43  netmask 255.255.255.0  broadcast 192.168.31.255
        inet6 fe80::14b4:f193:77e3:f6f6  prefixlen 64  scopeid 0x20<link>
        ether c8:60:00:2a:55:97  txqueuelen 1000  (Ethernet)
        RX packets 3021895  bytes 3293032191 (3.2 GB)
        RX errors 0  dropped 467  overruns 0  frame 0
        TX packets 1495398  bytes 364178861 (364.1 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

enp3s0.100: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.78.1.14  netmask 255.255.255.0  broadcast 10.78.1.255
        inet6 fe80::ca60:ff:fe2a:5597  prefixlen 64  scopeid 0x20<link>
        ether c8:60:00:2a:55:97  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 47  bytes 5684 (5.6 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Локальная петля (Loopback))
        RX packets 17045  bytes 1469302 (1.4 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 17045  bytes 1469302 (1.4 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

wlp4s6: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        ether 48:5b:39:bd:c5:79  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
или  
```bash
lodyanyy@lodyanyy:~$ sudo ip link add link enp3s0 name enp3s0.100 type vlan id 100  
```

#### 4. Какие типы агрегации интерфейсов есть в Linux? Какие опции есть для балансировки нагрузки? Приведите пример конфига.  

В Linux есть типы агрегации интерфейсов teaming и bonding. Пример конфигурации bonding для интерфейсов eth0 и eth1:  
```bash
auto bond0
iface bond0 inet dhcp
   bond-slaves none
   bond-mode active-backup
   bond-miimon 100

auto eth0
   iface eth0 inet manual
   bond-master bond0
   bond-primary eth0 eth1

auto eth1
iface eth1 inet manual
   bond-master bond0
   bond-primary eth0 eth1
```

#### 5. Сколько IP адресов в сети с маской /29 ? Сколько /29 подсетей можно получить из сети с маской /24. Приведите несколько примеров /29 подсетей внутри сети 10.10.10.0/24.  

С маской /29 будет 8 адресов, 6 из которых может использоваться. Из сети с маской /24 можно получить 32 подсети с маской /29.
```bash
lodyanyy@lodyanyy:~$ ipcalc 10.10.10.0/29
Address:   10.10.10.0           00001010.00001010.00001010.00000 001
Netmask:   255.255.255.248 = 29 11111111.11111111.11111111.11111 000
Wildcard:  0.0.0.7              00000000.00000000.00000000.00000 111
=>
Network:   10.10.10.0/29        00001010.00001010.00001010.00000 000
HostMin:   10.10.10.1           00001010.00001010.00001010.00000 001
HostMax:   10.10.10.6           00001010.00001010.00001010.00000 110
Broadcast: 10.10.10.7           00001010.00001010.00001010.00000 111
Hosts/Net: 6                     Class A, Private Internet

lodyanyy@lodyanyy:~$ ipcalc 10.10.10.16/29
Address:   10.10.10.16          00001010.00001010.00001010.00010 100
Netmask:   255.255.255.248 = 29 11111111.11111111.11111111.11111 000
Wildcard:  0.0.0.7              00000000.00000000.00000000.00000 111
=>
Network:   10.10.10.16/29       00001010.00001010.00001010.00010 000
HostMin:   10.10.10.17          00001010.00001010.00001010.00010 001
HostMax:   10.10.10.22          00001010.00001010.00001010.00010 110
Broadcast: 10.10.10.23          00001010.00001010.00001010.00010 111
Hosts/Net: 6                     Class A, Private Internet

lodyanyy@lodyanyy:~$ ipcalc 10.10.10.96/29
Address:   10.10.10.96          00001010.00001010.00001010.01100 100
Netmask:   255.255.255.248 = 29 11111111.11111111.11111111.11111 000
Wildcard:  0.0.0.7              00000000.00000000.00000000.00000 111
=>
Network:   10.10.10.96/29       00001010.00001010.00001010.01100 000
HostMin:   10.10.10.97          00001010.00001010.00001010.01100 001
HostMax:   10.10.10.102         00001010.00001010.00001010.01100 110
Broadcast: 10.10.10.103         00001010.00001010.00001010.01100 111
Hosts/Net: 6                     Class A, Private Internet
```

#### 6. Задача: вас попросили организовать стык между 2-мя организациями. Диапазоны 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 уже заняты. Из какой подсети допустимо взять частные IP адреса? Маску выберите из расчета максимум 40-50 хостов внутри подсети.  

Остается свободный частный диапазон 100.64.0.0/10. Для использования 40-50 хостов достаточно /26 маски с емкостью до 62ух рабочих хостов.

#### 7. Как проверить ARP таблицу в Linux, Windows? Как очистить ARP кеш полностью? Как из ARP таблицы удалить только один нужный IP?  

Linux:  

проверить ARP таблицу: arp -n  
очитстить ARP кеш: sudo ip -s -s neigh flush all  
удалить один IP: sudo arp -d 192.168.1.64  

Windows:  

проверить ARP таблицу: arp -a  
очитстить ARP кеш: netsh interface ip delete arpcache  
удалить один IP: arp -d 192.168.1.64  

