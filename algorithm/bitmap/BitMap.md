# 位图 BitMap     
*如何给数据排序？  这一个问题有很多种解法。*      

那有没有既快速又占用内存小的方法来实现？     

或者这样问，**如何使用1MB左右的 内存空间来给一个最多包含n个正整数且都小于n,不重复的文件排序，n=10^7^**  

这里需要用到位图（`BitMap`）算法，将数据进行状态压缩，一个`int`类型的数据对应一个二进制位([位运算了解一下](https://zzuli-tech.github.io/interview/algorithm/bitmap/BitOperation.html))     

一个int型4个字节，也就是32位，可以映射32个int型整数，例如：    
数组`[1,3,5,6,9,10]`  可以映射为：`1010 1100 11` （有数据映射为1，无数据映射为0）      

没有超过32位用一个int型即可完成映射        

将数据映射完成后，数据就已经是有序的了（因为其数值大小就对应其在二进制中的第几位），取数据时，遍历位图，查看数据映射的位置即可。      
 
**映射数据实例代码如下：**      
```
/**
* 位图映射
**/
public static int[] bitMap(){
        // 每个int整型是由4个字节，也就是32位
        int size = 32;
        // 给一千万以内的数字进行排序
        int max = 10000000;
        // 创建一个整型数组用来存放位图
        int arraySize = max/size + (max%size == 0 ? 0 : 1);
        int[] array = new int[arraySize];

        // 待处理数据
        int[] testData = new int[]{1,2,777777,456,25869,321,1111111,222222,2545412,241302,9999};

        // 进行位图处理
        for (int data: testData) {
            // 该数据array数组中的位置
            int index = data/size + (data%size==0?0:1 - 1);
            // 计算偏移量，即data在array[index]（一共有size=32位）的第几位
            int offSet = data%size - 1;
            // 将data按位映射入array数组，并得到一个新的array[index]
            array[index] = array[index] | (1 << (size - offSet - 1));

            System.out.println("待处理数据data=："+data+"    放入数组array中的位置index="+index+
                    "   偏移量offSet="+offSet+"     放入数组array后的新值array[index]="+array[index]);
        }
        return array;
    }
```    
**取数据实例代码如下:** 
```
public static void main(String[] args) {

        int[] array = bitMap();
        // 遍历位图取出结果
        for (int i = 0; i < array.length; i++) {
            int indexData = array[i];
            for (int j = 0; j < 32; j++) {
                // 求该位上的值是1还是0
                int bitValue = (indexData >> (31-j)) & 1;

                if (bitValue == 1) {
                    System.out.print((32*i+j+1)+",");
                }
            }
        }
    }
```