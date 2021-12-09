# Домашняя работа к занятию "3.6. Компьютерные сети, лекция 1"

#### 1. Работа c HTTP через телнет.
- Подключились утилитой телнет к сайту stackoverflow.com
`telnet stackoverflow.com 80`
- отправили HTTP запрос
```bash
GET /questions HTTP/1.0
HOST: stackoverflow.com
[press enter]
[press enter]
HTTP/1.1 301 Moved Permanently
cache-control: no-cache, no-store, must-revalidate
location: https://stackoverflow.com/questions
x-request-guid: 8e309f21-f777-4562-a826-bb8345fd9422
feature-policy: microphone 'none'; speaker 'none'
content-security-policy: upgrade-insecure-requests; frame-ancestors 'self' https://stackexchange.com
Accept-Ranges: bytes
Date: Thu, 09 Dec 2021 10:11:20 GMT
Via: 1.1 varnish
Connection: close
X-Served-By: cache-bma1660-BMA
X-Cache: MISS
X-Cache-Hits: 0
X-Timer: S1639044681.569083,VS0,VE101
Vary: Fastly-SSL
X-DNS-Prefetch-Control: off
Set-Cookie: prov=37b0bd96-8723-097c-6a71-56f2d4ff0b25; domain=.stackoverflow.com; expires=Fri, 01-Jan-2055 00:00:00 GMT; path=/; HttpOnly
Connection closed by foreign host
```
   Получили 301 код HTTP, который относится к группе redirection, которая сообщает нам, что запрашиваемый ресурс перемещен навсегда. Адрес нового месторасположения ресурса указывается в поле Location. В данном случае https://stackoverflow.com/questions

#### 2. Повторите задание 1 в браузере, используя консоль разработчика F12.
- откройте вкладку `Network`
- отправьте запрос http://stackoverflow.com
- найдите первый ответ HTTP сервера, откройте вкладку `Headers`  
- укажите в ответе полученный HTTP код.  
 Первый ответ сервера вернул код 200 ОК. Видим, что был изменен запрос с http на https.
- проверьте время загрузки страницы, какой запрос обрабатывался дольше всего?  
 Время загрузки страницы 2,60 секунды. Самый долгий запрос - первый, обрабатывался 379 мс.
- приложите скриншот консоли браузера в ответ.
![screenHTTP200](https://user-images.githubusercontent.com/87534423/145390699-e6ab7b2d-c6cd-4f65-945c-b6ce68cbaf10.jpg)


#### 3. Какой IP адрес у вас в интернете?

	Воспользовавшись сервисом whoer.net узнали IP адрес:  2.92.6.215  
	
#### 4. Какому провайдеру принадлежит ваш IP адрес? Какой автономной системе AS? Воспользуйтесь утилитой `whois`  

```bash
lodyanyy@lodyanyy:~$ whois 2.92.6.215
% This is the RIPE Database query service.
% The objects are in RPSL format.
%
% The RIPE Database is subject to Terms and Conditions.
% See http://www.ripe.net/db/support/db-terms-conditions.pdf

% Note: this output has been filtered.
%       To receive output for a database update, use the "-B" flag.

% Information related to '2.92.0.0 - 2.93.255.255'

% Abuse contact for '2.92.0.0 - 2.93.255.255' is 'abuse-b2b@beeline.ru'

inetnum:        2.92.0.0 - 2.93.255.255
netname:        BEELINE-BROADBAND
descr:          Dynamic IP Pool for Broadband Customers
country:        RU
admin-c:        CORB1-RIPE
tech-c:         CORB1-RIPE
status:         ASSIGNED PA
mnt-by:         RU-CORBINA-MNT
created:        2011-01-26T20:23:16Z
last-modified:  2011-10-24T07:14:47Z
source:         RIPE

role:           CORBINA TELECOM Network Operations
address:        PAO Vimpelcom - CORBINA TELECOM/Internet Network Operations
address:        111250 Russia Moscow Krasnokazarmennaya, 12
phone:          +7 495 755 5648
fax-no:         +7 495 787 1990
remarks:        -----------------------------------------------------------
remarks:        Feel free to contact Corbina Telecom NOC to
remarks:        resolve networking problems related to Corbina
remarks:        -----------------------------------------------------------
remarks:        User support, general questions: support@corbina.net
remarks:        Routing, peering, security: ipnoc@corbina.net
remarks:        Report spam and abuse: abuse@beeline.ru
remarks:        Mail and news: postmaster@corbina.net
remarks:        DNS: hostmaster@corbina.net
remarks:        Engineering Support ES@beeline.ru
remarks:        -----------------------------------------------------------
admin-c:        SVNT1-RIPE
tech-c:         SVNT2-RIPE
nic-hdl:        CORB1-RIPE
mnt-by:         RU-CORBINA-MNT
abuse-mailbox:  abuse-b2b@beeline.ru
created:        1970-01-01T00:00:00Z
last-modified:  2021-04-12T10:52:26Z
source:         RIPE # Filtered

% Information related to '2.92.6.0/24AS3216'

route:          2.92.6.0/24
descr:          RU-CORBINA-BROADBAND-POOL2
origin:         AS3216
mnt-by:         RU-CORBINA-MNT
created:        2011-09-19T10:34:00Z
last-modified:  2011-09-19T10:34:00Z
source:         RIPE # Filtered

% Information related to '2.92.6.0/24AS8402'

route:          2.92.6.0/24
descr:          RU-CORBINA-BROADBAND-POOL2
origin:         AS8402
mnt-by:         RU-CORBINA-MNT
created:        2011-09-21T13:46:03Z
last-modified:  2011-09-21T13:46:03Z
source:         RIPE # Filtered

% This query was served by the RIPE Database Query Service version 1.102 (ANGUS)
```  
   IP-адрес относится к провайдеру Билайн к системе AS8402

#### 5. Через какие сети проходит пакет, отправленный с вашего компьютера на адрес 8.8.8.8? Через какие AS? Воспользуйтесь утилитой `traceroute`

```bash
lodyanyy@lodyanyy:~$ traceroute -An 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  192.168.31.1 [*]  0.379 ms  0.410 ms  0.477 ms
 2  95.24.56.1 [AS8402]  1.127 ms  1.161 ms  1.187 ms
 3  78.107.138.162 [AS8402]  1.542 ms  1.620 ms  1.038 ms
 4  194.186.255.80 [AS3216/AS23649]  1.375 ms  1.337 ms  1.458 ms
 5  79.104.235.207 [AS3216]  20.235 ms 79.104.235.205 [AS3216]  20.408 ms 79.104.235.207 [AS3216]  20.698 ms
 6  195.68.176.50 [AS3216]  17.924 ms  17.101 ms 72.14.198.48 [AS15169]  25.077 ms
 7  * * *
 8  108.170.227.70 [AS15169]  25.098 ms 108.170.250.33 [AS15169]  25.631 ms  25.577 ms
 9  108.170.250.99 [AS15169]  21.144 ms 108.170.250.113 [AS15169]  20.515 ms 108.170.250.83 [AS15169]  20.764 ms
10  216.239.51.32 [AS15169]  34.719 ms 142.250.239.64 [AS15169]  31.942 ms 209.85.255.136 [AS15169]  35.043 ms
11  216.239.43.20 [AS15169]  44.180 ms 172.253.66.110 [AS15169]  39.541 ms 72.14.238.168 [AS15169]  27.691 ms
12  216.239.48.85 [AS15169]  37.768 ms 142.250.56.215 [AS15169]  36.522 ms 216.239.58.65 [AS15169]  41.966 ms
13  * * *
14  * * *
15  * * *
16  * * *
17  * * *
18  * * *
19  * * *
20  * * *
21  * * *
22  * 8.8.8.8 [AS15169]  36.700 ms  40.617 ms
```  

#### 6. Повторите задание 5 в утилите `mtr`. На каком участке наибольшая задержка - delay?

![screenMTR](https://user-images.githubusercontent.com/87534423/145390812-b4662bf6-0b62-4746-9592-27a1a30b2193.jpg)

   Наибольшая задержка происходит на участке до хоста 209.85.249.158

#### 7. Какие DNS сервера отвечают за доменное имя dns.google? Какие A записи? воспользуйтесь утилитой `dig`

```bash
lodyanyy@lodyanyy:~$ dig dns.google

; <<>> DiG 9.16.1-Ubuntu <<>> dns.google
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41945
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;dns.google.                    IN      A

;; ANSWER SECTION:
dns.google.             1577    IN      A       8.8.4.4
dns.google.             1577    IN      A       8.8.8.8

;; Query time: 23 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Чт дек 09 15:18:20 +04 2021
;; MSG SIZE  rcvd: 71
```  
   Ответ: 8.8.4.4, 8.8.8.8

#### 8. Проверьте PTR записи для IP адресов из задания 7. Какое доменное имя привязано к IP? воспользуйтесь утилитой `dig`

```bash
lodyanyy@lodyanyy:~$ dig -x 8.8.4.4

; <<>> DiG 9.16.1-Ubuntu <<>> -x 8.8.4.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 7262
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   85039   IN      PTR     dns.google.

;; Query time: 23 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Чт дек 09 15:37:23 +04 2021
;; MSG SIZE  rcvd: 73

lodyanyy@lodyanyy:~$ dig -x 8.8.8.8

; <<>> DiG 9.16.1-Ubuntu <<>> -x 8.8.8.8
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19974
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;8.8.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
8.8.8.8.in-addr.arpa.   50476   IN      PTR     dns.google.

;; Query time: 19 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Чт дек 09 15:37:42 +04 2021
;; MSG SIZE  rcvd: 73
```
   Ответ: dns.google.
