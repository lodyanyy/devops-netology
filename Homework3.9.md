# Домашнее задание к занятию "3.9. Элементы безопасности информационных систем"

#### 1. Установите Bitwarden плагин для браузера. Зарегестрируйтесь и сохраните несколько паролей.

![bitwarden1](https://user-images.githubusercontent.com/87534423/147741864-8b113989-289c-476e-8821-b9d4a3d626c4.jpg)

#### 2. Установите Google authenticator на мобильный телефон. Настройте вход в Bitwarden акаунт через Google authenticator OTP.

![bitwarden2](https://user-images.githubusercontent.com/87534423/147741892-93ea21bb-5722-4492-a9b6-c261850b430d.jpg)

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
![example](https://user-images.githubusercontent.com/87534423/147741928-3e35ff99-8b89-4689-847d-d06a80a524bd.jpg)

#### 4. Проверьте на TLS уязвимости произвольный сайт в интернете (кроме сайтов МВД, ФСБ, МинОбр, НацБанк, РосКосмос, РосАтом, РосНАНО и любых госкомпаний, объектов КИИ, ВПК ... и тому подобное).  

Устанавливаем инструмент для тестирования testssl.sh 

```bash
$ git clone --depth 1 https://github.com/drwetter/testssl.sh.git  
```
Запускаем проверку  

![ruchoco](https://user-images.githubusercontent.com/87534423/147742001-489c02a3-ab4f-44af-8136-4aa2bd3a1345.jpg)

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
```
Теперь зайдем на сервер по имени somevagrant
```bash
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
Открываем дамп трафика в wireshark:

![wireshark](https://user-images.githubusercontent.com/87534423/147742427-53551890-0ece-4195-8c0a-e8290606ada9.jpg)
