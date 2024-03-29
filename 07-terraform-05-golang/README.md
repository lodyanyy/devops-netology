# Домашняя работа к занятию "7.5. Основы golang"

С `golang` в рамках курса, мы будем работать не много, поэтому можно использовать любой IDE. 
Но рекомендуем ознакомиться с [GoLand](https://www.jetbrains.com/ru-ru/go/).  

## Задача 1. Установите golang.
1. Воспользуйтесь инструкций с официального сайта: [https://golang.org/](https://golang.org/).
2. Так же для тестирования кода можно использовать песочницу: [https://play.golang.org/](https://play.golang.org/).

## Решение
1. Установлен golang:
```
lodyanyy@lodyanyy:~/Загрузки$ go version
go version go1.18.4 linux/amd64
```
2. Протестирована песочница.

## Задача 2. Знакомство с gotour.
У Golang есть обучающая интерактивная консоль [https://tour.golang.org/](https://tour.golang.org/). 
Рекомендуется изучить максимальное количество примеров. В консоли уже написан необходимый код, 
осталось только с ним ознакомиться и поэкспериментировать как написано в инструкции в левой части экрана. 

## Решение

Изучены обучающие примеры golang 

## Задача 3. Написание кода. 
Цель этого задания закрепить знания о базовом синтаксисе языка. Можно использовать редактор кода 
на своем компьютере, либо использовать песочницу: [https://play.golang.org/](https://play.golang.org/).

1. Напишите программу для перевода метров в футы (1 фут = 0.3048 метр). Можно запросить исходные данные 
у пользователя, а можно статически задать в коде.
    Для взаимодействия с пользователем можно использовать функцию `Scanf`:
    ```
    package main
    
    import "fmt"
    
    func main() {
        fmt.Print("Enter a number: ")
        var input float64
        fmt.Scanf("%f", &input)
    
        output := input * 2
    
        fmt.Println(output)    
    }
    ```
    
#### Решение 3.1

[Программа](https://github.com/lodyanyy/devops-netology/blob/main/07-terraform-05-golang/convers.go) для перевода метров в футы:

```
    package main
    
    import "fmt"
    
    const Foot = 0.3048
    
    func main() {
        fmt.Print("Введите длину в метрах: ")
        var input float64
        fmt.Scanf("%f", &input)
    
        output := input / Foot
    
        fmt.Println(output)    
    }
```
Результат:  
![image](https://user-images.githubusercontent.com/87534423/180663338-078b69a1-268d-45e9-b26f-ad22bfca249c.png)


2. Напишите программу, которая найдет наименьший элемент в любом заданном списке, например:
    ```
    x := []int{48,96,86,68,57,82,63,70,37,34,83,27,19,97,9,17,}
    ```
    
#### Решение 3.2
[minimal.go](https://github.com/lodyanyy/devops-netology/blob/main/07-terraform-05-golang/minimal.go)
```
package main
import "fmt"

func main() {
    x := []int{48,96,86,68,57,82,63,70,37,34,83,27,19,97,9,17}
    min := x[0]
    for _, value := range x {
            if (value < min) {
                    min = value
            }
    }
    fmt.Println(min)
}
```
![image](https://user-images.githubusercontent.com/87534423/180664149-c5d4a739-a208-46a8-86d5-98c75c25173a.png)


3. Напишите программу, которая выводит числа от 1 до 100, которые делятся на 3. То есть `(3, 6, 9, …)`.

В виде решения ссылку на код или сам код. 

#### Решение 3.3  
[dev3.go](https://github.com/lodyanyy/devops-netology/blob/main/07-terraform-05-golang/dev3.go)  
```
package main

import "fmt"

func main() {
        for i:=1; i<=100; i++ {
      if i % 3 == 0 {
      fmt.Println(i)
      }
    }
}
```
![image](https://user-images.githubusercontent.com/87534423/180664173-4bd3328b-9843-48bc-b5bc-017e5076f4af.png)
