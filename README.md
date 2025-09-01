# ICLAB
數位ICLAB之實作，每個LAB年份不同
以下是每個LAB的簡介，以及我是怎麼寫的

## lab01
給五組輸入，每組為一個MOS的寬度(W)、VGS、VDS。
並且根據另一個輸入(mode)，算出輸出的電流/電壓的最大/最小值。
![image](https://github.com/108350035/ICLAB/blob/main/lab1/lab1.PNG)

直接硬幹，以組合電路為主。
但注意寫排序時，不要當成"軟體"在寫，信號不能被多次賦值
