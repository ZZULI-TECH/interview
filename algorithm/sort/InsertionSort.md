# 插入排序

插入排序包括直接插入排序、折半插入排序和希尔排序等

## 直接插入排序

直接插入排序是一种很简单的排序方式，它假设当前元素之前的元素顺序都是有序的，然后寻找合适的位置进行插入，以保持整体的有序性。

**【算法步骤】**

在实现元素的元素的有序插入时，有两种方式：从前往后遍历和从后往前遍历，这里采用从后往前遍历。

由于第一个默认是排序的，所以从第二个开始，重复以下步骤：

1. 取出第j的元素，并从当前元素开始从后往前遍历
2. 如果j-1的元素大于j的元素，将两者的位置交换，位置前移
3. 重复2，直至j-1的元素小于j的元素

**【排序过程】**

![image](https://github.com/ZZULI-TECH/interview/blob/master/images/direct_insertion_sort.png?raw=true)

**【代码】**

```Java
public static void insertionSort(int[] arr) {
    int len = arr.length;
    for (int i = 1; i < len; i++) {
        int j = i;
        while (j > 0 && arr[j] < arr[j-1]) {
            swap(arr, j, j-1);
            j--;
        }
    }
}

```

**【算法分析】**

从排序步骤来看，直接插入排序的基本操作为比较元素的大小和移动位置。
直接插入排序的时间复杂度取决于原始数组的初始顺序。对于整个排序过程需要执行n-1趟，最好情况下，总比较次数达到最小值n-1，记录不需要移动；最坏情况，总比较次数为~ n<sup>2</sup>/2，总移动次数为~ n<sup>2</sup>/2；平均情况下，总比较次数和总移动数为~ n<sup>2</sup>/4。

## 折半插入排序

折半插入排序是对直接插入排序的改进，在排序过程中，不断将元素插入到前面已经排好序的序列中，由于前半部分为已排好序的数列，可以采用折半查找的方法来加快寻找插入点的速度。

```Java
public static void binaryInsertionSort(int[] arr) {
    int len = arr.length;
    int low, high, mid;
    for (int i = 1; i < len; i++) {
        low = 0;
        high = i - 1;
        while (low <= high) {
            mid = (low + high) / 2;
            // 判断当前元素在mid位置的左边还是右边
            if (arr[i] > arr[mid]) {
                // 查找右半部分
                low = mid + 1;
            } else {
                // 查找左半部分
                high = mid - 1;
            }
        }

        int j = i;
        while (j > low && arr[j] < arr[j-1]) {
            swap(arr, j, j-1);
            j--;
        }
    }
}
```
