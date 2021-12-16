# Домашнее задание к занятию "3.8. Компьютерные сети, лекция 2"
#### 1. Подключитесь к публичному маршрутизатору в интернет. Найдите маршрут к вашему публичному IP  
```bash
lodyanyy@lodyanyy:~$ telnet route-views.routeviews.org
Trying 128.223.51.103...
Connected to route-views.routeviews.org.
Escape character is '^]'.
C
**********************************************************************

                    RouteViews BGP Route Viewer
                    route-views.routeviews.org

 route views data is archived on http://archive.routeviews.org

 This hardware is part of a grant by the NSF.
 Please contact help@routeviews.org if you have questions, or
 if you wish to contribute your view.

 This router has views of full routing tables from several ASes.
 The list of peers is located at http://www.routeviews.org/peers
 in route-views.oregon-ix.net.txt

 NOTE: The hardware was upgraded in August 2014.  If you are seeing
 the error message, "no default Kerberos realm", you may want to
 in Mac OS X add "default unset autologin" to your ~/.telnetrc

 To login, use the username "rviews".

 **********************************************************************


User Access Verification

Username: rviews
route-views>show ip route 2.92.6.215   
Routing entry for 2.92.4.0/22
  Known via "bgp 6447", distance 20, metric 0
  Tag 6939, type external
  Last update from 64.71.137.241 6d17h ago
  Routing Descriptor Blocks:
  * 64.71.137.241, from 64.71.137.241, 6d17h ago
      Route metric is 0, traffic share count is 1
      AS Hops 3
      Route tag 6939
      MPLS label: none
      
route-views>show bgp 2.92.6.215     
BGP routing table entry for 2.92.4.0/22, version 1400906837
Paths: (23 available, best #11, table default)
  Not advertised to any peer
  Refresh Epoch 1
  20912 3257 3356 3216 8402
    212.66.96.126 from 212.66.96.126 (212.66.96.126)
      Origin IGP, localpref 100, valid, external
      Community: 3257:8070 3257:30515 3257:50001 3257:53900 3257:53902 20912:65004
      path 7FE003DDB328 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  3333 1103 3216 8402
    193.0.0.56 from 193.0.0.56 (193.0.0.56)
      Origin incomplete, localpref 100, valid, external
      Community: 3216:2001 3216:4464 8402:1093 8402:1143 65000:52254
      path 7FE0CDDC0570 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  8283 3216 8402
    94.142.247.3 from 94.142.247.3 (94.142.247.3)
      Origin incomplete, metric 0, localpref 100, valid, external
      Community: 3216:2001 3216:4464 8283:1 8283:101 8402:1093 8402:1143 65000:52254
      unknown transitive attribute: flag 0xE0 type 0x20 length 0x18
        value 0000 205B 0000 0000 0000 0001 0000 205B
              0000 0005 0000 0001 
      path 7FE167A4DCB0 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  3356 3216 8402
    4.68.4.46 from 4.68.4.46 (4.69.184.201)
      Origin IGP, metric 0, localpref 100, valid, external
      Community: 3216:2001 3216:4464 3356:2 3356:22 3356:100 3356:123 3356:503 3356:903 3356:2067 8402:1093 8402:1143
      path 7FE09376F1F8 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  3549 3356 3216 8402
    208.51.134.254 from 208.51.134.254 (67.16.168.191)
      Origin IGP, metric 0, localpref 100, valid, external
      Community: 3216:2001 3216:4464 3356:2 3356:22 3356:100 3356:123 3356:503 3356:903 3356:2067 3549:2581 3549:30840 8402:1093 8402:1143
      path 7FE0DAF8CFF0 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  53767 14315 6453 6453 3356 3216 8402
    162.251.163.2 from 162.251.163.2 (162.251.162.3)
      Origin IGP, localpref 100, valid, external
      Community: 14315:5000 53767:5000
      path 7FE0BC8AC878 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  20130 6939 3216 8402
    140.192.8.16 from 140.192.8.16 (140.192.8.16)
      Origin IGP, localpref 100, valid, external
      path 7FE0EC3922F8 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  57866 3356 3216 8402
    37.139.139.17 from 37.139.139.17 (37.139.139.17)
      Origin IGP, metric 0, localpref 100, valid, external
      Community: 3216:2001 3216:4464 3356:2 3356:22 3356:100 3356:123 3356:503 3356:903 3356:2067 8402:1093 8402:1143
      path 7FE18068BC48 RPKI State not found
      rx pathid: 0, tx pathid: 0
  Refresh Epoch 1
  101 3356 3216 8402
    209.124.176.223 from 209.124.176.223 (209.124.176.223)
      Origin IGP, localpref 100, valid, external
      Community: 101:20100 101:20110 101:22100 3216:2001 3216:4464 3356:2 3356:22 3356:100 3356:123 3356:503 3356:903 3356:2067 8402:1093 8402:1143

```  

#### 2. Создайте dummy0 интерфейс в Ubuntu. Добавьте несколько статических маршрутов. Проверьте таблицу маршрутизации.  

```bash
lodyanyy@lodyanyy:~$ sudo ip link add dummy0 type dummy
lodyanyy@lodyanyy:~$ sudo ip addr add 10.0.10.1/24 dev dummy0
lodyanyy@lodyanyy:~$ sudo ip link set dummy0 up
lodyanyy@lodyanyy:~$ sudo ip route add to 10.10.0.0/16 via 10.0.10.1
lodyanyy@lodyanyy:~$ sudo ip route add to 10.12.0.0/16 via 10.0.10.1
lodyanyy@lodyanyy:~$ ip route
default via 192.168.31.1 dev enp3s0 proto dhcp metric 100 
10.0.10.0/24 dev dummy0 proto kernel scope link src 10.0.10.1 
10.10.0.0/16 via 10.0.10.1 dev dummy0 
10.12.0.0/16 via 10.0.10.1 dev dummy0 
10.78.1.0/24 dev enp3s0.100 proto kernel scope link src 10.78.1.14 
169.254.0.0/16 dev enp3s0 scope link metric 1000 
192.168.31.0/24 dev enp3s0 proto kernel scope link src 192.168.31.43 metric 100 
```

#### 3. Проверьте открытые TCP порты в Ubuntu, какие протоколы и приложения используют эти порты? Приведите несколько примеров.  

```bash
lodyanyy@lodyanyy:~$ sudo netstat -ntlp | grep LISTEN
tcp        0      0 0.0.0.0:7071            0.0.0.0:*               LISTEN      1276/anydesk        
tcp        0      0 0.0.0.0:40783           0.0.0.0:*               LISTEN      1276/anydesk        
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN      650/systemd-resolve 
tcp        0      0 127.0.0.1:631           0.0.0.0:*               LISTEN      163202/cupsd        
tcp6       0      0 :::1716                 :::*                    LISTEN      1662/kdeconnectd    
tcp6       0      0 ::1:631                 :::*                    LISTEN      163202/cupsd 
```  
53 порт TCP использует systemd  
7071 порт TCP использует anydesk  

#### 4. Проверьте используемые UDP сокеты в Ubuntu, какие протоколы и приложения используют эти порты?  

```bash
lodyanyy@lodyanyy:~$ ss -lupn
State			Recv-Q			Send-Q			Local Address:Port			Peer Address:Port			Process                                                  
UNCONN			0				0				127.0.0.53%lo:53			0.0.0.0:*                                                                                
UNCONN          0               0               0.0.0.0:631                 0.0.0.0:*                                                                                
UNCONN          0               0               0.0.0.0:54095				0.0.0.0:*                                                                                
UNCONN          0               0               0.0.0.0:50002               0.0.0.0:*                   users:(("anydesk",pid=160142,fd=23))                    
UNCONN          0               0               0.0.0.0:5353                0.0.0.0:*                                                                                
UNCONN          0               0               [::]:36251					[::]:*                                                                                
UNCONN          0               0               [::]:5353                   [::]:*                                                                                
UNCONN          0               0               *:1716                      *:*                         users:(("kdeconnectd",pid=1662,fd=11))  
```bash  
50002 порт UDP использует anydesk  
1716 порт UDP использует kdeconnectd  

#### 5. Используя diagrams.net, создайте L3 диаграмму вашей домашней сети или любой другой сети, с которой вы работали.  
