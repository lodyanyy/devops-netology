## 1. Регистрация доменного имени  
Зарегистрировали доменное имя lodyanyy.ru на reg.ru. Соответственно, получили доступ к личному кабинету на сйте регистратора и можем управлять доменом.  

## 2. Создание инфраструктуры  

\* Для получения ключа KEY.JSON делаем следующее:
 - создаем сервисный аккаунт в yandex cloud с ролью editor
 - генерируем ключ yc iam key create --service-account-name service-bot --output key.json
```
lodyanyy@lodyanyy:~/netology/diplom/terraform$ yc iam key create --service-account-name service-bot --output key.json
id: ajehd95r9n4lgtbt1qv7
service_account_id: ajea94q719pq7rsv223j
created_at: "2022-08-23T14:56:28.675381249Z"
key_algorithm: RSA_2048
```
