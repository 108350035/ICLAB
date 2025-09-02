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

騎士的判斷需用狀態機去寫，除了前進或後退，也包刮選擇方向、判斷有無出界、以及是否走過。 

因此要宣告二維陣列記錄走過的格子。

有寫兩種版本，KT_v1以及KT_v2，差異在於v2會預測8個方向的可行性以及紀錄試過的方向，來減少執行cycle

## lab03
用verilog完成跑酷遊戲

![image](https://github.com/108350035/ICLAB/blob/main/lab3/lab3.PNG)

直接硬幹，盡量人物靠近中間，減少走到死路造成的failed。

也是有寫兩個版本，但好像都差不多，只是微調^^

此外PATTERN也不難寫，符合PDF上所說的規則即可

## lab04
用verilog完成ANN(類神經網路)

![image](https://github.com/108350035/ICLAB/blob/main/lab4/lab4.PNG)

小心使用IP核，一個cycle執行一次就好，切勿做超過兩個以上的操作，不然會時序違反

NN.v 執行時間:8cycle 、 NN_ver2.v 執行時間:9cycle

PATTERN嘗試用python產出，用過都說讚

## lab05
利用SRAM，完成三個矩陣相乘並找到trace

![image](https://github.com/108350035/ICLAB/blob/main/lab5/lab5.PNG)

SRAM的輸入跟輸出要連著reg，不然會時序違反

計算過程很繁雜但不難，只是容易出錯，像是搞混colum或row或矩陣相乘的順序

太著急，反而更花時間，欲速則不達

MMT period 6.8   MMT_v2 period_7.3

## lab06
elliptic curve group operation是橢圓曲線密碼學中的核心運算

利用verilog完成此運算

![image](https://github.com/108350035/ICLAB/blob/main/lab6/lab6.PNG)

用組合邏輯來實現輾轉相除法，並將作為軟IP核

ECGO就照講義寫的算法，不會難

## lab07
循環冗餘校驗 (Cyclic Redundancy Check)，一種用於偵測資料傳輸錯誤的演算法
用verilog的方式完成該演算法

![image](https://github.com/108350035/ICLAB/blob/main/lab7/lab7.PNG)

分別處理三個module，然後clk不要搞混。最後將三個module連在一起，clk之間接同步器即可
不會特別難，按照講義上一步一步來就過了

## lab08
利用clock gating的技術，完成串行處理

![image](https://github.com/108350035/ICLAB/blob/main/lab8/lab8.PNG)

每個數據處理區塊，各獨立為一個clk，處理數據完的區塊就關閉clk，達到省電

要很謹慎，稍微寫錯幾行，即可功能正確，也會很大概率出現時序違反

剩下的就稍微了解primetime怎麼操作即可

## lab09
用system-verilog模擬購物平台

![image](https://github.com/108350035/ICLAB/blob/main/lab9/lab9.PNG)

不懂sv語法跟物件導向就看CSDN

購物平台的spec很繁瑣，花了很多時間理解

## lab10
寫CHECKER.sv 驗證TA的PATTERN.sv正確性

用TA的CHECKER.sv檢驗自己的lab09 PATTERN之覆蓋率是否符合spec

![image](https://github.com/108350035/ICLAB/blob/main/lab10/lab10.PNG)

看講義學語法，再不懂則看CSDN，CHECKER就能輕鬆寫出來

為了盡可能以最少的pattern數完成spec，pattern的部分花了較多時間

## lab11
用innovus完成APR

![image](https://github.com/108350035/ICLAB/blob/main/lab11/lab11.PNG)

照講義的步驟做即可

![image](https://github.com/108350035/ICLAB/blob/main/lab11/APR1.PNG)

![image](https://github.com/108350035/ICLAB/blob/main/lab11/APR2.PNG)

## lab12
完成lab02的APR

![image](https://github.com/108350035/ICLAB/blob/main/lab12/lab12.PNG)

跟Lab11一樣，看步驟做

![image](https://github.com/108350035/ICLAB/blob/main/lab12/APR.PNG)

![image](https://github.com/108350035/ICLAB/blob/main/lab12/APR2.PNG)

## bonus
學習操作JasperGold

![image](https://github.com/108350035/ICLAB/blob/main/bonus/bonus.PNG)

bridge.sv 有4個bug，將他們找出

其餘就照講義的作即可






