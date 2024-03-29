
# Домашняя работа "5.1. Введение в виртуализацию. Типы и функции гипервизоров. Обзор рынка вендоров и областей применения."


## Задача 1

Опишите кратко, как вы поняли: в чем основное отличие полной (аппаратной) виртуализации, паравиртуализации и виртуализации на основе ОС.  

>  Полная (аппаратная) виртуализация не использует операционную систему на хосте, управление виртуальными машинами осуществляется аппаратно. Паравиртуализация
  использует операционную систему для доступа гипервизора к ресурсам хоста. Виртуализация на основе ОС запускает виртуальные машины внутри ОС хоста, что накладывает ограничения
  на выбор ядра ОС виртуальных машин - ядро ВМ и ядро хоста не должны отличаться.
## Доработка
>  Паравиртуализация в отличие от аппаратной виртуализации модифицирует ядро гостевой ОС для разделения доступа к аппаратным ресурсам физической машины, на которой установлена.

## Задача 2

Выберите один из вариантов использования организации физических серверов, в зависимости от условий использования.

Организация серверов:
- физические сервера,
- паравиртуализация,
- виртуализация уровня ОС.

Условия использования:
- Высоконагруженная база данных, чувствительная к отказу.
- Различные web-приложения.
- Windows системы для использования бухгалтерским отделом.
- Системы, выполняющие высокопроизводительные расчеты на GPU.

Опишите, почему вы выбрали к каждому целевому использованию такую организацию.  
> - Высоконагруженная база данных, чувствительная к отказу.
В данном случае лучше всего использовать отдельные физические сервера. Так как в случае виртуализации - высокая нагрузка на аппаратные ресурсы хостовой машины может отрицательно сказаться на других виртуальных машинах, что может привезти к отказу.
> - Различные web-приложения.
Здесь можно применить виртуализацию уровня ОС. Web-приложения обычно не требовательны к ресурсам машины, и удобнее, легче и дешевле использовать виртуализацию уровня ОС для управления и тестирования web-приложений в различных средах.
> - Windows системы для использования бухгалтерским отделом.
Паравиртуализация в данном случае может быть решением поставленной задачи. Конкретно использование Microsoft Hyper-V поможет решить вопрос совместного использования пользовательских ОС на Windows, 1С, MS office, а также интеграции с AD.
> - Системы, выполняющие высокопроизводительные расчеты на GPU.
Подходящий вариант решения - физические сервера. В данном случае требуется максимальная производительность, а в случае виртуализации будут затрачиваться дополнительные ресурсы на работу самого гипервизора.

## Задача 3

Выберите подходящую систему управления виртуализацией для предложенного сценария. Детально опишите ваш выбор.

Сценарии:

1. 100 виртуальных машин на базе Linux и Windows, общие задачи, нет особых требований. Преимущественно Windows based инфраструктура, требуется реализация программных балансировщиков нагрузки, репликации данных и автоматизированного механизма создания резервных копий.  
> VMWare. Нет ограничений по выбору операционной системы, есть реализация программных балансировщиков нагрузки, репликации данных и автоматизированного механизма создания резервных копий. Высокий уровень безопасности. 
2. Требуется наиболее производительное бесплатное open source решение для виртуализации небольшой (20-30 серверов) инфраструктуры на базе Linux и Windows виртуальных машин.  
> XEN. Это бесплатное, стабильное и универсальное программное решение, которое может работать и с linux и с windows гостевыми операционными системами.  
3. Необходимо бесплатное, максимально совместимое и производительное решение для виртуализации Windows инфраструктуры.  
> Hyper-V. Имеет максимальную совместимость с windows системами, хорошую производительность, обладает 
4. Необходимо рабочее окружение для тестирования программного продукта на нескольких дистрибутивах Linux.  
> KVM. Активно развивающееся программное решение, из-за этого обладает всеми современными функциями, которые будут необходимы при тестировании программных продуктов. Имеет хорошую поддержку.

## Задача 4

Опишите возможные проблемы и недостатки гетерогенной среды виртуализации (использования нескольких систем управления виртуализацией одновременно) и что необходимо сделать для минимизации этих рисков и проблем. Если бы у вас был выбор, то создавали бы вы гетерогенную среду или нет? Мотивируйте ваш ответ примерами.  

> Проблемы гетерогенной среды виртуализации - это во-первых цена на как минимум две системы виртуализации, если это коммерческие продукты, во-вторых нужны специалисты, которые одновременно хорошо разбираются в выбранных системах, либо нужны специалисты кратно количеству используемых систем, то есть цена обслуживания гетерогенной среды будет больше, чем моногенной. В-третьих, усложняется управление ресурсами среды, появляется риск возникновения конфликтов между системами управления виртуализации.  
Минимизировать эти проблемы можно, если максимально разделить системы по сферам использования, либо использовать разные типы виртуализации в среде. Допустим использовать VMware в качестве гипервизора аппаратной виртуализации и на одной из виртуальных машин использовать виртуализацию уровня ОС (контейниризация), либо использовать windows server с hyper-v на гостевой ОС для работы сотрудников бухгалтерии в терминальной сессии.  
Для выбора использовать гетерогенную среду или нет, нужно убедиться, что ни одна из систем виртуализации полностью не решает поставленные задачи. Использование нескольких гипервизоров аппаратной виртуализации скорее всего нецелесообразно, гораздо логичнее использовать вложенную структуру, совмещая полную, пара-виртуализацию и виртуализацию уровня ОС.
