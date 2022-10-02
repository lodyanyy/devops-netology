## 1. Регистрация доменного имени  
Зарегистрировали доменное имя lodyanyy.ru на reg.ru. Соответственно, получили доступ к личному кабинету на сйте регистратора и можем управлять доменом.  

## 2. Создание инфраструктуры  

Для реализации IaaC подхода при организации (эксплуатации) инфраструктуры написан bash-скрипт, который создаёт каталог в указанном YC облаке, сервисный аккаунт для дальнейшей работы с терраформом, сохраняет чувствительные данные в отдельный файл private.auto.tfvars вне репозитария, а также собирает и передает идентификаторы яндекс облака и каталога в конфигурационные файлы терраформа, а также автоматически создает S3 bucket в YC.
Изначально в файл private.auto.tfvars требуется сохранить только значения OAuth-токена и ID облака, в котором будем работать.

```bash
#!/usr/bin/env bash

echo "создание профиля main-profile"
yc config profile create main-profile

echo "присвоение переменной YC_TOKEN соответствующеего значения из файла private.auto.tfvars"
YC_TOKEN=$(sed 's/"//g' ~/netology/diplom/terraform/private.auto.tfvars | sed -n '1,1 s/YC_TOKEN = //p')

echo "назначение OAth-токена профилю main-profile"
yc config set token $YC_TOKEN --profile main-profile

echo "присвоение переменной YC_CLOUD_ID соответствующего значения из файла private.auto.tfvars"
YC_CLOUD_ID=$(sed 's/"//g' ~/netology/diplom/terraform/private.auto.tfvars | sed -n '2,2 s/YC_CLOUD_ID = //p')

echo "назначение ID облака профилю main-profile"
yc config set cloud-id $YC_CLOUD_ID

echo "создание каталога с именем main-folder"
yc resource-manager folder create --name main-folder --profile main-profile

echo "передача ID каталога в переменную YC_FOLDER_ID"
YC_FOLDER_ID=$(yc resource-manager folder get main-folder | sed -n '1,1 s/id: //p')
echo $YC_FOLDER_ID

echo "передадча значения переменной YC_FOLDER_ID в файл variables.tf" 
sed -i "6c\  default = \"${YC_FOLDER_ID}\"" ~/netology/diplom/terraform_S3/variables.tf
sed -i "6c\  default = \"${YC_FOLDER_ID}\"" ~/netology/diplom/terraform/variables.tf

echo "передача значения переменной YC_CLOUD_ID в файл variables.tf"
sed -i "2c\  default = \"${YC_CLOUD_ID}\"" ~/netology/diplom/terraform_S3/variables.tf
sed -i "2c\  default = \"${YC_CLOUD_ID}\"" ~/netology/diplom/terraform/variables.tf

echo "создание сервисного аккаунта с именем service-bot в каталоге main-folder"
array1=($(yc iam service-account create --folder-name main-folder --name service-bot | cut -d: -f 2 | cut -c 2-))
YC_SERVICE_ACCOUNT_ID=${array1[0]}
echo $YC_SERVICE_ACCOUNT_ID

echo "создание статического ключа доступа для сервисного аккаунта service-bot и передача его в private.auto.tfvars"
array2=($(yc iam access-key create --service-account-name service-bot --folder-id $YC_FOLDER_ID | cut -d: -f 2 | cut -c 2-))

YC_ACCESS_KEY=${array2[3]}
echo $YC_ACCESS_KEY
sed -i "3c\YC_ACCESS_KEY = \"${YC_ACCESS_KEY}\"" ~/netology/diplom/terraform/private.auto.tfvars
sed -i "1c\access_key = \"${YC_ACCESS_KEY}\"" ~/netology/diplom/terraform/backend.tfvars

YC_SECRET_KEY=${array2[4]}
echo $YC_SECRET_KEY
sed -i "4c\YC_SECRET_KEY = \"${YC_SECRET_KEY}\"" ~/netology/diplom/terraform/private.auto.tfvars
sed -i "2c\secret_key = \"${YC_SECRET_KEY}\"" ~/netology/diplom/terraform/backend.tfvars

echo "назначение сервисному аккаунту роли editor"
yc resource-manager folder add-access-binding $YC_FOLDER_ID --role editor --subject serviceAccount:$YC_SERVICE_ACCOUNT_ID

echo "создание S3 bucket в YC через terraform"
cd ~/netology/diplom/terraform_S3
terraform init
terraform workspace new stage
terraform plan -var-file ~/netology/diplom/terraform/private.auto.tfvars
terraform apply --auto-approve -var-file ~/netology/diplom/terraform/private.auto.tfvars
echo "переход в основной каталог"
cd ~/netology/diplom/terraform
terraform init -backend-config=backend.tfvars
terraform workspace new stage
terraform plan -var-file ~/netology/diplom/terraform/private.auto.tfvars
terraform apply --auto-approve -var-file ~/netology/diplom/terraform/private.auto.tfvars
```
В результате настроен workspace stage, созданы VPC в разных зонах доступности, и имеем возможность быстро создавать, а также удалять виртуальные машины и сети, выполняя лишь команды terraform apply и terraform destroy.
