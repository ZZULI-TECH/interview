## 递归  
程序调用自身的编程技巧称为递归（ recursion）。递归的两个要素：  
（1）递归的边界（程序退出出口）  
（2）递归的逻辑，即递归公式（原问题分解而成的子问题，子问题和原问题的关联关系）  
满足以上两个要素的问题适合使用递归解决。  
**【经典递归问题】**  
1. 阶乘问题  
2. 汉诺塔问题
3. 斐波那契数列
  
**【阶乘问题】**  
求n!的值,f(n) = n!
n! = n*(n-1)*(n-2)...1;得出边界是n==1  
分解成子问题：n! = n(n-1)!   (n-1)! = (n-1)(n-2)!  
**【代码】**  
```
static int fn(int n){
    if(n <= 1){
        return 1;
    }else{
        return n*fn(n-1);
    }
}
```
**【汉诺塔问题】**   
一次只能移动一个盘子；不能把大盘子放在小盘子上；除去盘子在两个柱子之间移动的瞬间，盘子必须都在柱子上。（在这三点要求下把盘子从起始柱子A全部移动到目标柱子C上）   
![image](https://github.com/ZZULI-TECH/interview/blob/master/images/hannuotower.jpg?raw=true)   
只有一个盘子时，直接从A-->C  
边界:n==1,子问题:A-->C  
**【代码】**  
```
public static void hanNuoTower(int n ,char a,char b,char c){
    if(n==1){
        move(a,c);
    }else{
        hanNuoTower(n-1,a,c,b);
        move(a,c);
        hanNuoTower(n-1,b,a,c);
    }
}
    
public static void move(char a , char c){
    System.out.println("move  "+a+"  to  "+c);
}
```
