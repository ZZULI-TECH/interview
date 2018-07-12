# 希尔排序

希尔排序(Shell's Sort)又称“缩小增量排序”(Diminishing Increment Sort)，是插入排序的一种。直接插入排序，当待排序的记录个数较少且待排序序列的关键字基本有序是，效率较高。希尔排序基于以上两点，从“减少记录个数”和“序列基本有序”两个方面对直接插入排序进行了改进。

**【算法步骤】**

希尔排序实质上是采用分组插入的方法。先将整个待排序记录序列分割成几组，从而减少参与直接插入排序的数据量，对每组分别进行之际金额插入排序，然后增加每组的数据量，重新分组。这样当经过几次分组排序后，整个序列中的记录“基本有序”时，再对全体记录进行依次直接插入排序。
希尔对记录的分组，不是简单地“逐段分割”，而是将相隔某个“增量”的记录分成一组。
1. 第一趟取增量d~1~(d~1~<n)把全部记录分成d~1~个组，所有间隔为d~1~的记录分在同一组，在各个组中进行直接插入排序。
2. 第二趟取增量d~2~(d~2~<d~1~)，重复上述的分组和排序。
3. 依次类推，直到所取的增量d~t~=1(d~t~<d~t-1~<...<d~2~<d~1~)，所有记录在同一组中进行直接插入排序为止。

**【示例图】**

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/ShellSort.png?raw=true)

**【代码】**

```Java
void shellSort(int[] arr) {
  int temp;
  for(int dk=arr.length/2;dk>0;dk/=2) {// dk为增量
    for(int i=dk;i<arr.length;i++) {
      int j=i;
      while(j-dk>=0&&arr[j]<arr[j-dk]) {
        swap(arr,j,j-dk);
        temp=arr[j];
        arr[j]=arr[j-dk];
        arr[j-dk]=temp;
        j-=dk;
      }
    }
  }
}
```