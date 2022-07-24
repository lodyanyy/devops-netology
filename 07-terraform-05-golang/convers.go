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
