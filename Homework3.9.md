# Домашнее задание к занятию "3.9. Элементы безопасности информационных систем"

#### 1. Установите Bitwarden плагин для браузера. Зарегестрируйтесь и сохраните несколько паролей.



#### 2. Установите Google authenticator на мобильный телефон. Настройте вход в Bitwarden акаунт через Google authenticator OTP.



#### 3. Установите apache2, сгенерируйте самоподписанный сертификат, настройте тестовый сайт для работы по HTTPS.

```bash
lodyanyy@lodyanyy:~$ sudo apt install apache2
lodyanyy@lodyanyy:~$ sudo a2enmod ssl
lodyanyy@lodyanyy:~$ sudo systemctl restart apache2
lodyanyy@lodyanyy:~$ sudo ufw allow "Apache"
lodyanyy@lodyanyy:~$ sudo openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/ssl/private/test.key -out /etc/ssl/certs/test.cert -subj "/C=RU/ST=Saratovskaya/L=Saratov/O=example/OU=COM/CN=www.example.com"
lodyanyy@lodyanyy:~$ sudo vim /etc/apache2/sites-available/www.example.com.conf
<VirtualHost *:443>
ServerName example.com
DocumentRoot /var/www/example.com
SSLEngine on
SSLCertificateFile /etc/ssl/certs/test.cert
SSLCertificateKeyFile /etc/ssl/private/test.key
</VirtualHost>

lodyanyy@lodyanyy:~$ sudo mkdir /var/www/example.com
lodyanyy@lodyanyy:~$ sudo vim /var/www/example.com/index.html
<h1>This is a test site</h1>

lodyanyy@lodyanyy:~$ sudo a2ensite www.example.com
```

#### 4. Проверьте на TLS уязвимости произвольный сайт в интернете (кроме сайтов МВД, ФСБ, МинОбр, НацБанк, РосКосмос, РосАтом, РосНАНО и любых госкомпаний, объектов КИИ, ВПК ... и тому подобное).  

```bash
$ git clone --depth 1 https://github.com/drwetter/testssl.sh.git  
$ ./testssl.sh -U --sneaky https://www.ruchoco.ru/
Testing all IPv4 addresses (port 443): 96.16.49.198 96.16.49.212
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Start 2021-12-28 14:27:51        -->> 96.16.49.198:443 (www.ruchoco.ru) <<--

 Further IP addresses:   96.16.49.212 2a02:26f0:41::216:1fca 2a02:26f0:41::216:1fc3 2a02:26f0:41::216:1fd1 
 rDNS (96.16.49.198):    a96-16-49-198.deploy.static.akamaitechnologies.com.
 Service detected:       HTTP


 Testing vulnerabilities 

 Heartbleed (CVE-2014-0160)                not vulnerable (OK), no heartbeat extension
 CCS (CVE-2014-0224)                       not vulnerable (OK)
 Ticketbleed (CVE-2016-9244), experiment.  not vulnerable (OK), no session tickets
 ROBOT                                     Server does not support any cipher suites that use RSA key transport
 Secure Renegotiation (RFC 5746)           OpenSSL handshake didn't succeed
 Secure Client-Initiated Renegotiation     not vulnerable (OK)
 CRIME, TLS (CVE-2012-4929)                not vulnerable (OK)
 BREACH (CVE-2013-3587)                    potentially NOT ok, "gzip" HTTP compression detected. - only supplied "/" tested
                                           Can be ignored for static pages or if no secrets in the page
 POODLE, SSL (CVE-2014-3566)               not vulnerable (OK)
 TLS_FALLBACK_SCSV (RFC 7507)              No fallback possible (OK), no protocol below TLS 1.2 offered
 SWEET32 (CVE-2016-2183, CVE-2016-6329)    not vulnerable (OK)
 FREAK (CVE-2015-0204)                     not vulnerable (OK)
 DROWN (CVE-2016-0800, CVE-2016-0703)      not vulnerable on this host and port (OK)
                                           make sure you don't use this certificate elsewhere with SSLv2 enabled services
                                           https://censys.io/ipv4?q=6D3AC8B076F639DB0F514F5ADD0100DED0CFDBE53DC287D46F08825E1C51E64E could help you to find out
 LOGJAM (CVE-2015-4000), experimental      not vulnerable (OK): no DH EXPORT ciphers, no DH key detected with <= TLS 1.2
 BEAST (CVE-2011-3389)                     not vulnerable (OK), no SSL3 or TLS1
 LUCKY13 (CVE-2013-0169), experimental     not vulnerable (OK)
 Winshock (CVE-2014-6321), experimental    not vulnerable (OK)
 RC4 (CVE-2013-2566, CVE-2015-2808)        no RC4 ciphers detected (OK)

 Done 2021-12-28 14:28:15 [  29s] -->> 96.16.49.198:443 (www.ruchoco.ru) <<--
```

#### 5. Установите на Ubuntu ssh сервер, сгенерируйте новый приватный ключ. Скопируйте свой публичный ключ на другой сервер. Подключитесь к серверу по SSH-ключу.  

```bash
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/lodyanyy/.ssh/id_rsa): /home/lodyanyy/.ssh/somekey_rsa       
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/lodyanyy/.ssh/somekey_rsa
Your public key has been saved in /home/lodyanyy/.ssh/somekey_rsa.pub

lodyanyy@lodyanyy:~$ ssh-copy-id -i .ssh/somekey_rsa -p 2200 vagrant@127.0.0.1
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: ".ssh/somekey_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -p '2200' 'vagrant@127.0.0.1'"
and check to make sure that only the key(s) you wanted were added.

lodyanyy@lodyanyy:~$ ssh -p '2200' 'vagrant@127.0.0.1'
vagrant@127.0.0.1's password: 
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.4.0-91-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Thu 30 Dec 2021 09:04:57 AM UTC

  System load:  0.0                Processes:             117
  Usage of /:   11.6% of 30.88GB   Users logged in:       0
  Memory usage: 18%                IPv4 address for eth0: 10.0.2.15
  Swap usage:   0%


This system is built by the Bento project by Chef Software
More information can be found at https://github.com/chef/bento
Last login: Wed Dec 29 13:54:32 2021 from 10.0.2.2
```
 
#### 6. Переименуйте файлы ключей из задания 5. Настройте файл конфигурации SSH клиента, так чтобы вход на удаленный сервер осуществлялся по имени сервера.

```bash
lodyanyy@lodyanyy:~$ mv .ssh/somekey_rsa .ssh/somenewkey_rsa
lodyanyy@lodyanyy:~$ mv .ssh/somekey_rsa.pub .ssh/somenewkey_rsa.pub
lodyanyy@lodyanyy:~$ vi .ssh/config
	Host somevagrant
	HostName 127.0.0.1
	IdentityFile ~/.ssh/somenewkey_rsa
	User vagrant
	Port 2200

lodyanyy@lodyanyy:~$ ssh somevagrant
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.4.0-91-generic x86_64)
...
```

#### 7. Соберите дамп трафика утилитой tcpdump в формате pcap, 100 пакетов. Откройте файл pcap в Wireshark.

```bash
lodyanyy@lodyanyy:~$ sudo tcpdump -c 100 -w dump.pcap
[sudo] пароль для lodyanyy: 
tcpdump: listening on enp3s0, link-type EN10MB (Ethernet), capture size 262144 bytes
100 packets captured
143 packets received by filter
0 packets dropped by kernel
```



