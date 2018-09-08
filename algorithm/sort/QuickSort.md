# 快速排序

快速排序(Quick Sort)是由冒泡排序改进而得的。在冒泡排序过程中，只对相邻的两个记录进行比较，因此每次交换的两个相邻记录时只能消除一个逆序。如果能通过两个（不相邻）记录的一次交换，消除多个逆序，则会大大加快排序的速度。快速排序方法中的一次交换可能消除多个逆序。

**【算法步骤】**

在待排序的n个记录中任取一个记录（通常取第一个记录）作为枢轴（或支点），设其关键字为pivotkey。经过一趟排序后，把所有关键字小于pivotkey的记录交换到前面，把所有关键字大于pivotkey的记录交换到后面，结果将待排序的记录分成两个子表，最后将枢轴放置在分界处的位置。然后，分别对左、右子表重复上述过程，直至每一个子表只有一个记录时，排序完成。

步骤如下：

1. 选择待排序表中的第一个记录作为枢轴，将枢轴记录暂存在r[0]的位置上。附设两个指针low和high,初始时分别指向表的下界和上界。
2. 从表的最右侧位置依次向左搜索，找到第一个关键字小于枢轴关键字pivotkey的记录，将其移到low处。具体操作是：当low<high时，若high所指记录的关键字大于等于pivotkey，则向左移动指针high；否则将high所指记录移动到low所指记录。
3. 然后再从表的最左侧位置，依次向右搜索找到第一个关键字大于pivotkey的记录和枢轴记录交换。具体操作是：当low<high时，若low所指记录的关键字小于等于pivothey，则向右移动指针low；否则将low所指记录与枢轴记录交换。
4. 重复步骤2和步骤3，直至low与high相等为止。此时low或high的位置即为枢轴在此趟排序中的最终位置，原表被分成两个子表。

**【示例图】**

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/QuickSort.png?raw=true)

**【代码】**


```Java
void quicksort(int[] arr,int low,int high) {
  int l=low,h=high;
  int key=0;
  if(l<h) {//起始位置要小于需要排序的数组长度
    key = arr[low];
    while(low<high) {
      if(low<high&&arr[high]>=key)high--;//从右向左遍历
      arr[low]=arr[high];
      if(low<high&&arr[low]<=key)low++;//从左向右遍历
      arr[high]=arr[low];
    }
    arr[low]=key;
  }
  
  ss:
  while(l<h&&low<=h) {
    quicksort(arr,l,low-1);
    quicksort(arr,low+1,h);
    break ss;//跳出当前循环
  }
}
```
