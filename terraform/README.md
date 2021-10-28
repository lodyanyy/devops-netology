 # Local .terraform directories
**/.terraform/*         #Исключить все файлы в любой скрытой папке с названием terraform
*.tfstate               #Исключить все файлы с расширением .tfstate
*.tfstate.*             #Исключить все файлы содержащие в названии .tfstate.
crash.log               #Исключить файл crash.log
*.tfvars                #Исключить все файлы с расширением .tfvars
override.tf             #Исключить файл override.tf
override.tf.json        #Исключить файл override.tf.json
*_override.tf           #Исключить все файлы содержащие в названии _override.tf
*_override.tf.json      #Исключить все файлы содержащие в названии _override.tf.json
.terraformrc            #Исключить все файлы в скрытой папке с названием terraformrc
terraform.rc            #Исключить файл terraform.rc
