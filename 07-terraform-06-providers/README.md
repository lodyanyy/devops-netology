# Домашняя работа к занятию "7.6. Написание собственных провайдеров для Terraform."

Бывает, что 
* общедоступная документация по терраформ ресурсам не всегда достоверна,
* в документации не хватает каких-нибудь правил валидации или неточно описаны параметры,
* понадобиться использовать провайдер без официальной документации,
* может возникнуть необходимость написать свой провайдер для системы используемой в ваших проектах.   

## Задача 1. 
Давайте потренируемся читать исходный код AWS провайдера, который можно склонировать от сюда: 
[https://github.com/hashicorp/terraform-provider-aws.git](https://github.com/hashicorp/terraform-provider-aws.git).
Просто найдите нужные ресурсы в исходном коде и ответы на вопросы станут понятны.  


1. Найдите, где перечислены все доступные `resource` и `data_source`, приложите ссылку на эти строки в коде на 
гитхабе. 

## Решение  

`resource` находятся в файле /main/internal/provider/provider.go в строках 913-2108 по ссылке 
> https://github.com/hashicorp/terraform-provider-aws/blob/1bc96e19dbfa95a1e426f8e89c11e42928438eb0/internal/provider/provider.go#L913  

`data_source`находятся в файле /main/internal/provider/provider.go в строках 415-911 по ссылке
> https://github.com/hashicorp/terraform-provider-aws/blob/1bc96e19dbfa95a1e426f8e89c11e42928438eb0/internal/provider/provider.go#L415  

2. Для создания очереди сообщений SQS используется ресурс `aws_sqs_queue` у которого есть параметр `name`. 
    * С каким другим параметром конфликтует `name`? Приложите строчку кода, в которой это указано.
    * Какая максимальная длина имени? 
    * Какому регулярному выражению должно подчиняться имя? 

## Решение 
`name` конфликтует с параметром `name_prefix`. Видим [здесь](https://github.com/hashicorp/terraform-provider-aws/blob/1bc96e19dbfa95a1e426f8e89c11e42928438eb0/internal/service/sqs/queue.go#L87):
```
"name": {
			Type:          schema.TypeString,
			Optional:      true,
			Computed:      true,
			ForceNew:      true,
			ConflictsWith: []string{"name_prefix"},
		},
```

Максимальная длина имени составляет 80 символов, это видно из регулярного выражения которому должно подчиняться имя. Видим [здесь](https://github.com/hashicorp/terraform-provider-aws/blob/1bc96e19dbfa95a1e426f8e89c11e42928438eb0/internal/service/sqs/queue.go#L424):  
```
if fifoQueue {
			re = regexp.MustCompile(`^[a-zA-Z0-9_-]{1,75}\.fifo$`)
		} else {
			re = regexp.MustCompile(`^[a-zA-Z0-9_-]{1,80}$`)
		}
```
Здесь видим, что имя может состоять из маленьких и больших латинских букв, цифр, нижнего подчеркивания и дефиса, а также должно быть от 1 до 75 символов, заканчивающееся расширением `.fifo` (+5 символов), либо без указания расширения от 1 до 80 символов.
