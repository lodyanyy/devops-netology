## 1. Регистрация доменного имени  
Зарегистрировали доменное имя lodyanyy.ru на reg.ru. Соответственно, получили доступ к личному кабинету на сйте регистратора и можем управлять доменом.  

## 2. Создание инфраструктуры  

Для реализации IaaC подхода при организации (эксплуатации) инфраструктуры написан bash-скрипт, который создаёт каталог в указанном YC облаке, сервисный аккаунт для дальнейшей работы с терраформом, сохраняет чувствительные данные в отдельный файл rivate.auto.tfvars вне репозитария, а также собирает и передает идентификаторы яндекс облака и каталога в конфигурационные файлы терраформа, а также автоматически создает S3 bucket в YC.
Изначально в файл rivate.auto.tfvars требуется сохранить только значения OAuth-токена и ID облака, в котором будем работать.

```bash
#!/usr/bin/env bash

# создадим пустой профиль main-profile
yc config profile create main-profile

#присвоим переменной YC_TOKEN соответствующее значение из файла private.auto.tfvars
YC_TOKEN=$(sed 's/"//g' /home/lodyanyy/netology/diplom/private.auto.tfvars | sed -n '1,1 s/YC_TOKEN = //p')

#задаем OAth-токен профилю main-profile
yc config set token $YC_TOKEN --profile main-profile

#присвоим переменной YC_CLOUD_ID соответствующее значение из файла private.auto.tfvars
YC_CLOUD_ID=$(sed 's/"//g' /home/lodyanyy/netology/diplom/private.auto.tfvars | sed -n '2,2 s/YC_CLOUD_ID = //p')

#задаем ID облака профилю main-profile
yc config set cloud-id $YC_CLOUD_ID

# создадим каталог с именем main-folder
yc resource-manager folder create --name main-folder --profile main-profile

# передадим ID каталога в переменную YC_FOLDER_ID
YC_FOLDER_ID=$(yc resource-manager folder get main-folder | sed -n '1,1 s/id: //p')
echo $YC_FOLDER_ID

#передадим значение переменной YC_FOLDER_ID в файл variables.tf для 
sed -i "6c\  default = \"${YC_FOLDER_ID}\"" /home/lodyanyy/netology/diplom/terraform_S3/variables.tf
sed -i "6c\  default = \"${YC_FOLDER_ID}\"" /home/lodyanyy/netology/diplom/terraform/variables.tf

#передадим значение переменной YC_CLOUD_ID в файл variables.tf для 
sed -i "2c\  default = \"${YC_CLOUD_ID}\"" /home/lodyanyy/netology/diplom/terraform_S3/variables.tf
sed -i "2c\  default = \"${YC_CLOUD_ID}\"" /home/lodyanyy/netology/diplom/terraform/variables.tf

# создадим сервисный аккаунт с именем service-bot в каталоге main-folder
array1=($(yc iam service-account create --folder-name main-folder --name service-bot | cut -d: -f 2 | cut -c 2-))
YC_SERVICE_ACCOUNT_ID=${array1[0]}
echo $YC_SERVICE_ACCOUNT_ID

# Создадим статический ключ доступа для сервисного аккаунта service-bot. И передадим его ключи в private.auto.tfvars
array2=($(yc iam access-key create --service-account-name service-bot --folder-id $YC_FOLDER_ID | cut -d: -f 2 | cut -c 2-))

YC_ACCESS_KEY=${array2[3]}
echo $YC_ACCESS_KEY
sed -i "3c\YC_ACCESS_KEY = \"${YC_ACCESS_KEY}\"" /home/lodyanyy/netology/diplom/private.auto.tfvars


YC_SECRET_KEY=${array2[4]}
echo $YC_SECRET_KEY
sed -i "4c\YC_SECRET_KEY = \"${YC_SECRET_KEY}\"" /home/lodyanyy/netology/diplom/private.auto.tfvars

# назначим сервисному аккаунту роль editor
yc resource-manager folder add-access-binding $YC_FOLDER_ID --role editor --subject serviceAccount:$YC_SERVICE_ACCOUNT_ID

# создание S3 bucket в YC развернем через terraform
cd /home/lodyanyy/netology/diplom/terraform_S3
terraform workspace new stage
terraform init
terraform plan -var-file /home/lodyanyy/netology/diplom/private.auto.tfvars
terraform apply --auto-approve -var-file /home/lodyanyy/netology/diplom/private.auto.tfvars
```
