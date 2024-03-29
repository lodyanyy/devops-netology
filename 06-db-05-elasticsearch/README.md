# Домашняя работа к занятию "6.5. Elasticsearch"

## Задача 1

В этом задании вы потренируетесь в:
- установке elasticsearch
- первоначальном конфигурировании elastcisearch
- запуске elasticsearch в docker

Используя докер образ [centos:7](https://hub.docker.com/_/centos) как базовый и 
[документацию по установке и запуску Elastcisearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/targz.html):

- составьте Dockerfile-манифест для elasticsearch
- соберите docker-образ и сделайте `push` в ваш docker.io репозиторий
- запустите контейнер из получившегося образа и выполните запрос пути `/` c хост-машины

Требования к `elasticsearch.yml`:
- данные `path` должны сохраняться в `/var/lib`
- имя ноды должно быть `netology_test`

В ответе приведите:
- текст Dockerfile манифеста
- ссылку на образ в репозитории dockerhub
- ответ `elasticsearch` на запрос пути `/` в json виде

Подсказки:
- возможно вам понадобится установка пакета perl-Digest-SHA для корректной работы пакета shasum
- при сетевых проблемах внимательно изучите кластерные и сетевые настройки в elasticsearch.yml
- при некоторых проблемах вам поможет docker директива ulimit
- elasticsearch в логах обычно описывает проблему и пути ее решения

Далее мы будем работать с данным экземпляром elasticsearch.

## Решение
Текст Dockerfile:  
```yaml
FROM centos:7

ENV PATH=/usr/lib:/elasticsearch-8.3.3/jdk/bin:/elasticsearch-8.3.3/bin:$PATH

RUN yum install -y perl-Digest-SHA && \
    yum -y install wget && \
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.3.3-linux-x86_64.tar.gz && \
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.3.3-linux-x86_64.tar.gz.sha512 && \
    shasum -a 512 elasticsearch-8.3.3-linux-x86_64.tar.gz.sha512 && \
    tar -xzf elasticsearch-8.3.3-linux-x86_64.tar.gz && \
    rm elasticsearch-8.3.3-linux-x86_64.tar.gz && \
    rm elasticsearch-8.3.3-linux-x86_64.tar.gz.sha512

ENV ES_HOME=/elasticsearch-8.3.3

RUN groupadd -g 1000 elasticsearch && useradd elasticsearch -u 1000 -g 1000 && \
    mkdir /var/lib/elasticsearch

WORKDIR /var/lib/elasticsearch

RUN set -ex && for path in data logs config config/scripts; do \
        mkdir -p "$path"; \
        chown -R elasticsearch:elasticsearch "$path"; \
    done

RUN mkdir /elasticsearch-8.3.3/snapshots && \
    chown -R elasticsearch:elasticsearch /elasticsearch-8.3.3

COPY logging.yml /elasticsearch-8.3.3/config/
COPY elasticsearch.yml /elasticsearch-8.3.3/config/

USER elasticsearch

CMD ["elasticsearch"]

EXPOSE 9200 9300
```  

```bash
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ sudo sysctl -w vm.max_map_count=262144
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ docker run --rm -d --name elastic -p 9200:9200 -p 9300:9300 bd97566be65d
deb6abc1e22c58cacf04b175f7e3251f2a21f2a74eacc7ce27749d0504717132
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ docker ps -a
CONTAINER ID   IMAGE          COMMAND           CREATED          STATUS          PORTS                                                                                  NAMES
deb6abc1e22c   bd97566be65d   "elasticsearch"   40 seconds ago   Up 18 seconds   0.0.0.0:9200->9200/tcp, :::9200->9200/tcp, 0.0.0.0:9300->9300/tcp, :::9300->9300/tcp   elastic
```  
Ответ elasticsearch на запрос пути / в json виде:
```json
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -u elastic:changeme localhost:9200
{
  "name" : "netology_test",
  "cluster_name" : "netology",
  "cluster_uuid" : "d19yspLkQ6-3qTxWC38nyw",
  "version" : {
    "number" : "8.3.3",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "801fed82df74dbe537f89b71b098ccaff88d2c56",
    "build_date" : "2022-07-23T19:30:09.227964828Z",
    "build_snapshot" : false,
    "lucene_version" : "9.2.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```
```bash
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ docker tag bd97566be65d lodyanyy/netology:6.5
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ docker login docker.io
Authenticating with existing credentials...
Login Succeeded
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ docker push lodyanyy/netology:6.5
```
[Ссылка на образ в репозитарии dockerhub](https://hub.docker.com/r/lodyanyy/netology)

## Задача 2

В этом задании вы научитесь:
- создавать и удалять индексы
- изучать состояние кластера
- обосновывать причину деградации доступности данных

Ознакомтесь с [документацией](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html) 
и добавьте в `elasticsearch` 3 индекса, в соответствии со таблицей:

| Имя | Количество реплик | Количество шард |
|-----|-------------------|-----------------|
| ind-1| 0 | 1 |
| ind-2 | 1 | 2 |
| ind-3 | 2 | 4 |

Получите список индексов и их статусов, используя API и **приведите в ответе** на задание.

Получите состояние кластера `elasticsearch`, используя API.

Как вы думаете, почему часть индексов и кластер находится в состоянии yellow?

Удалите все индексы.

**Важно**

При проектировании кластера elasticsearch нужно корректно рассчитывать количество реплик и шард,
иначе возможна потеря данных индексов, вплоть до полной, при деградации системы.

## Решение  
Создадим три индекса, согласно заданию:
```bash
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -ku elastic -X PUT "localhost:9200/index1" -H 'Content-Type: application/json' -d'
>  {
>    "settings": {
>      "index": {
>        "number_of_shards": 1,
>        "number_of_replicas": 0
>      }
>    }
>  }
>  '
Enter host password for user 'elastic':
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -ku elastic -X PUT "localhost:9200/index2" -H 'Content-Type: application/json' -d'
 {
   "settings": {
     "index": {
       "number_of_shards": 2,
       "number_of_replicas": 1
     }
   }
 }
 '
Enter host password for user 'elastic':
{"acknowledged":true,"shards_acknowledged":true,"index":"index2"}
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -ku elastic -X PUT "localhost:9200/index3" -H 'Content-Type: application/json' -d'
 {
   "settings": {
     "index": {
       "number_of_shards": 4,
       "number_of_replicas": 2
     }
   }
 }
 '
Enter host password for user 'elastic':
{"acknowledged":true,"shards_acknowledged":true,"index":"index3"}
```
Получим список индексов и их статусов, используя API
```bash
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -ku elastic  localhost:9200/_cat/indices
Enter host password for user 'elastic':
yellow open index2 79Onhys3QMSWFh929Azb4Q 2 1 0 0 450b 450b
green  open index1 sJ_hKeG3RGOoFTndHeRa-A 1 0 0 0 225b 225b
yellow open index3 lTgxc4X5RGmDMqOkfgCU6w 4 2 0 0 900b 900b
``` 
Получим состояние кластера elasticsearch, используя API:
```bash
{
  "cluster_name" : "elasticsearch",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 10,
  "active_shards" : 10,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 10,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 50.0
}
```
У индексов в состоянии Yellow должны быть реплики, но так как в кластере только одна нода, разместиться этим репликам негде.

Удалим все индексы:
```bash
$ curl -ku elastic  -X DELETE localhost:9200/index1
$ curl -ku elastic  -X DELETE localhost:9200/index2
$ curl -ku elastic  -X DELETE localhost:9200/index3
```

## Задача 3

В данном задании вы научитесь:
- создавать бэкапы данных
- восстанавливать индексы из бэкапов

Создайте директорию `{путь до корневой директории с elasticsearch в образе}/snapshots`.

Используя API [зарегистрируйте](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-register-repository.html#snapshots-register-repository) 
данную директорию как `snapshot repository` c именем `netology_backup`.

**Приведите в ответе** запрос API и результат вызова API для создания репозитория.

Создайте индекс `test` с 0 реплик и 1 шардом и **приведите в ответе** список индексов.

[Создайте `snapshot`](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-take-snapshot.html) 
состояния кластера `elasticsearch`.

**Приведите в ответе** список файлов в директории со `snapshot`ами.

Удалите индекс `test` и создайте индекс `test-2`. **Приведите в ответе** список индексов.

[Восстановите](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshots-restore-snapshot.html) состояние
кластера `elasticsearch` из `snapshot`, созданного ранее. 

**Приведите в ответе** запрос к API восстановления и итоговый список индексов.

Подсказки:
- возможно вам понадобится доработать `elasticsearch.yml` в части директивы `path.repo` и перезапустить `elasticsearch`

## Решение  
Запрос API выглядит следующим образом:
```
curl -X PUT "localhost:9200/_snapshot/netology_backup?pretty" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/elasticsearch-8.3.3/snapshots"
  }
}'
```
Результат вызова:
```
{
  "acknowledged" : true
}
```
Создадим индекс test с 0 реплик и 1 шардом, создадим snapshot состояния кластера elasticsearch и приведем в ответе список индексов:
```bash
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -X PUT "localhost:9200/_snapshot/netology_backup/my_snapshot?pretty"
{
  "accepted" : true
}
```
```
health status index uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test  7JLvEJfLTvekGBj7lPQlZA   1   0          0            0       225b           225b
```

Приведём в ответе список файлов в директории со snapshotами:
```bash
[elasticsearch@deb6abc1e22c elasticsearch]$ ll -a /elasticsearch-8.3.3/snapshots
total 48
drwxr-xr-x 1 elasticsearch elasticsearch  4096 Aug 15 14:49 .
drwxr-xr-x 1 elasticsearch elasticsearch  4096 Aug 15 11:02 ..
-rw-r--r-- 1 elasticsearch elasticsearch   844 Aug 15 14:49 index-0
-rw-r--r-- 1 elasticsearch elasticsearch     8 Aug 15 14:49 index.latest
drwxr-xr-x 4 elasticsearch elasticsearch  4096 Aug 15 14:49 indices
-rw-r--r-- 1 elasticsearch elasticsearch 18331 Aug 15 14:49 meta-FPBQWtDQSP-F0IfgTcxO-g.dat
-rw-r--r-- 1 elasticsearch elasticsearch   352 Aug 15 14:49 snap-FPBQWtDQSP-F0IfgTcxO-g.dat
```
Удалите индекс test и создайте индекс test-2. Приведите в ответе список индексов:
```bash
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -X GET 'localhost:9200/_cat/indices?v'
health status index  uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test-2 832VCx6FQ7uD_t3uanlDQg   1   0          0            0       225b           225b
```
Восстановим состояние кластера elasticsearch из snapshot, созданного ранее:
```bash
lodyanyy@lodyanyy:~/netology/06-db-05-elasticsearch$ curl -X POST "localhost:9200/_snapshot/netology_backup/my_snapshot/_restore?pretty" -H 'Content-Type: application/json' -d'
> {
>   "indices": "*",
>   "include_global_state": false
> }'
{
  "accepted" : true
}
```
Итоговый список индексов:
```
health status index  uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   test   Gel4KavgRsWZNkHar0gqhg   1   0          0            0       225b           225b
green  open   test-2 832VCx6FQ7uD_t3uanlDQg   1   0          0            0       225b           225b
```
