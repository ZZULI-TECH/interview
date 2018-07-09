## 冒泡排序

冒泡排序(Bubble Sort)是一种最简单的交换排序方法，它通过两两比较相邻记录的关键字，如果发生逆序，则进行交换，从而使关键字小的记录如气泡一般逐渐往上“漂浮”(左移)，或者使关键字大的记录逐渐向下“坠落”(右移)。

**【算法步骤】**
1. 假设待排序的记录存放在数组r[1...n]中。首先将第一个记录的关键字和第二个记录的关键字进行比较，若为逆序（即第一个关键字大于第二个关键字），则交换两个记录。然后比较第二个记录和第三个记录的关键字。依次类推，直至第n-1个记录和第n个记录的关键字进行过比较位置。上述过程称作第一趟起泡排序，其结果使得关键字最大的记录被安置到最后一个记录的位置上。
2. 然后进行第二趟起泡排序，对前n-1个记录进行同样的操作，其结果是使得关键字第二大的记录被安置到第n-1个记录的位置上。
3. 重复上述比较与交换过程，第i趟是从第1条记录到第n-i+1记录依次比较相邻的两个关键字，并再“逆序”排序是交换相邻记录，其结果是这n-i+1个记录中关键字最大的记录被交换到第n-i+1的位置上。知道在某一趟排序过程中没有进行过交换记录的操作，说明序列已经全部达到排序要求，则完成排序。

**【排序过程】**

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/BubbleSort.png?raw=true)

**【代码】**
```Java
public class BubbleSort {
  public static void main(String[] args) {
    int[] arr = {49,38,65,97,76,13,27};
    new BubbleSort().bubbleSort(arr);
  }
  
  void bubbleSort(int[] arr) {
    int m = arr.length-1;
    boolean flag = true;//flag用来标记某一趟排序是否发生交换（如果没有发生交换则说明已得到最终结果）
    while(m>0 && flag==true) {
      flag = false;
      for(int j=0;j<m;j++) {
        if(arr[j]>arr[j+1]) {
          flag=true;
          int temp = arr[j];
          arr[j] = arr[j+1];
          arr[j+1] = temp;
        }
      }
      --m;
    }
    for(int s:arr) {   //遍历排序后的数组
      System.out.print(s+" ");
    }                  //结果：13，27，38，49，65，76，97
  }
  
}
```