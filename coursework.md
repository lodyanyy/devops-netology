# Курсовая работа по итогам модуля "DevOps и системное администрирование"

Курсовая работа необходима для проверки практических навыков, полученных в ходе прохождения курса "DevOps и системное администрирование".

Мы создадим и настроим виртуальное рабочее место. Позже вы сможете использовать эту систему для выполнения домашних заданий по курсу

## Задание

1. Создайте виртуальную машину Linux.
2. Установите ufw и разрешите к этой машине сессии на порты 22 и 443, при этом трафик на интерфейсе localhost (lo) должен ходить свободно на все порты.
3. Установите hashicorp vault ([инструкция по ссылке](https://learn.hashicorp.com/tutorials/vault/getting-started-install?in=vault/getting-started#install-vault)).
4. Cоздайте центр сертификации по инструкции ([ссылка](https://learn.hashicorp.com/tutorials/vault/pki-engine?in=vault/secrets-management)) и выпустите сертификат для использования его в настройке веб-сервера nginx (срок жизни сертификата - месяц).
5. Установите корневой сертификат созданного центра сертификации в доверенные в хостовой системе.
6. Установите nginx.
7. По инструкции ([ссылка](https://nginx.org/en/docs/http/configuring_https_servers.html)) настройте nginx на https, используя ранее подготовленный сертификат:
  - можно использовать стандартную стартовую страницу nginx для демонстрации работы сервера;
  - можно использовать и другой html файл, сделанный вами;
8. Откройте в браузере на хосте https адрес страницы, которую обслуживает сервер nginx.
9. Создайте скрипт, который будет генерировать новый сертификат в vault:
  - генерируем новый сертификат так, чтобы не переписывать конфиг nginx;
  - перезапускаем nginx для применения нового сертификата.
10. Поместите скрипт в crontab, чтобы сертификат обновлялся какого-то числа каждого месяца в удобное для вас время.

## Результат

Результатом курсовой работы должны быть снимки экрана или текст:

- Процесс установки и настройки ufw
```bash
$ sudo apt-get install ufw              #установка
  Reading package lists... Done
  Building dependency tree       
  Reading state information... Done
  ufw is already the newest version (0.36-6).
  0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
$ sudo ufw status
  Status: inactive
$ sudo ufw enable
  Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
  Firewall is active and enabled on system startup
$ sudo ufw status
  Status: active
  
$ sudo ufw default allow outgoing           #изменяем значения по умолчанию для исходящих соединений на "разрешено"
Default outgoing policy changed to 'allow'
(be sure to update your rules accordingly)
$ sudo ufw allow in on lo from 0.0.0.0/0    #разрешаем входящие подключения на localhost
$ sudo ufw allow 22                         #разрешаем входящие подключения по любому порту 22
$ sudo ufw allow 443                        #разрешаем входящие подключения по любому порту 443
$ sudo ufw status
  Status: active

  To                         Action      From
  --                         ------      ----
  22                         ALLOW       Anywhere                  
  443                        ALLOW       Anywhere                  
  Anywhere on lo             ALLOW       Anywhere                  
  22 (v6)                    ALLOW       Anywhere (v6)             
  443 (v6)                   ALLOW       Anywhere (v6)  
```
- Процесс установки и выпуска сертификата с помощью hashicorp vault
```bash
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -                                  #устанавливаем hashicorp vault
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install vault

$ vault server -dev -dev-root-token-id root                     #запускаем сервер vault в отдельной сессии

$ export VAULT_ADDR=http://127.0.0.1:8200                       #экспортируем переменные сред для адреса севрера хранилища и для проверки подлинности
$ export VAULT_TOKEN=root
$ vault secrets enable pki                                      #включем механизм pki
Success! Enabled the pki secrets engine at: pki/
$ vault secrets tune -max-lease-ttl=720h pki                    #устаналиваем максимальное время выдачи сертификатов месяц
Success! Tuned the secrets engine at: pki/
$ vault write -field=certificate pki/root/generate/internal \   #создаем корневой сертификат, сохраняем как CA_cert.crt
> common_name="example.com" \
> ttl=720h > CA_cert.crt

$ vault write pki/config/urls \                                 #настраиваем URL-адреса центра сертификации и CRL
> issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
> crl_distribution_points="$VAULT_ADDR/v1/pki/crl"
Success! Data written to: pki/config/urls

$ vagrant scp default:~/CA_cert.crt ~/certs                     #копируем сертификат на хостовую машину
```
устанавливаем сертификат в доверенные  
![add_cert](https://user-images.githubusercontent.com/87534423/149737701-31db6f33-4be7-40fd-bfbe-9e8a4e2fb79a.jpg)

- Процесс установки и настройки сервера nginx
```bash
$ sudo apt install nginx
$ sudo mkdir /var/www/coursework.com
$ sudo vim /var/www/coursework.com/index.html
$ sudo vi /etc/nginx/sites-available/default

server {
        listen 80 default_server;
        listen [::]:80 default_server;
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        server_name coursework.com;
        ssl_certificate     /home/vagrant/ssl/coursework.com.crt;
        ssl_certificate_key /home/vagrant/ssl/coursework.com.key;
        ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers         HIGH:!aNULL:!MD5;**
}


```

- Страница сервера nginx в браузере хоста не содержит предупреждений 
- Скрипт генерации нового сертификата работает (сертификат сервера ngnix должен быть "зеленым")
- Crontab работает (выберите число и время так, чтобы показать что crontab запускается и делает что надо)
