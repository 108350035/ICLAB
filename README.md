# ICLAB
數位ICLAB之實作，每個LAB年份不同
以下是每個LAB的簡介，以及我是怎麼寫的

## lab01
給五組輸入，每組為一個MOS的寬度(W)、VGS、VDS。
並且根據另一個輸入(mode)，算出輸出的電流/電壓的最大/最小值。

![image](https://github.com/108350035/ICLAB/blob/main/lab1/lab1.PNG)

直接硬幹，以組合電路為主。
但注意寫排序時，不要當成"軟體"在寫，信號不能被多次賦值

## lab02
用verilog實現knight tour，即騎士的規定走法走遍整個棋盤的每一個方格，而且每個網格只能夠經過一次 

![image](https://github.com/108350035/ICLAB/blob/main/lab2/lab2.PNG)

騎士的判斷需用狀態機去寫，除了前進或後退，也包刮選擇方向、判斷有無出界、以及是否走過。 因此要宣告二維陣列記錄走過的格子。
有寫兩種版本，KT_v1以及KT_v2，差異在於v2會預測8個方向的可行性以及紀錄試過的方向，來減少執行cycle

