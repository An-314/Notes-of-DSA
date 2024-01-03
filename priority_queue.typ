= 优先级队列Priority Queue

*循优先级访问：*对存入的数据约定一定的优先级，每次访问是严格按照优先级的。

+ 在应用中会出现需要循优先级访问的例子：
  - 离散事件模拟
  - 操作系统：任务调度/中断处理/MRU/...
  - 输入法：词频调整
+ 希望能够：
  - 快速找到极值元素：须反复地、快速地定位
  - 集合组成：可动态变化
  - 元素优先级：可动态变化
+ 作为底层数据结构所支持的高效操作是很多高效算法的基础
  - 内部、外部、在线排序
  - 贪心算法： Huffman编码、 Kruskal
  - 平面扫描算法中的事件队列

```cpp
template <typename T> struct PQ { //priority queue
    virtual void insert( T ) = 0;
    virtual T getMax() = 0;
    virtual T delMax() = 0;
}; //作为ADT的PQ有多种实现方式，各自的效率及适用场合也不尽相同
```
- Stack和Queue，都是PQ的特例——优先级完全取决于元素的插入次序；
- Steap和Queap，也是PQ的特例——插入和删除的位置受限。


对于前面的`vector`、`sorted_vector`、`list`、`sorted_list`、`BBST`。若只需查找极值元，则不必维护所有元素之间的全序关系，*偏序*足矣。

因此有理由相信，存在某种更为简单、维护成本更低的实现方式，使得各功能接口的时间复杂度依然为$O(log n)$，而且实际效率更高。
== 完全二叉堆Heap

由于完全二叉树的特性，我们可以把一棵完全二叉树存在一个线性的列表中。并且可以通过秩的代数运算得到父亲和儿子。

```cpp
#define Parent(i) ( ((i) - 1) >> 1 )
#define LChild(i) ( 1 + ((i) << 1) )
#define RChild(i) ( (1 + (i)) << 1 )
```

#figure(
  image("fig\堆\1.png",width: 80%),
  caption: "完全二叉堆的存储结构",
)

```cpp
template <typename T> struct PQ_ComplHeap : public PQ<T>, public Vector<T> {
    PQ_ComplHeap( T* A, Rank n ) { copyFrom( A, 0, n ); heapify( _elem, n ); }
    void insert( T ); T getMax(); T delMax();
};
// 该结构的实现包括下面的一些函数
template <typename T> Rank percolateDown( T* A, Rank n, Rank i ); //下滤
template <typename T> Rank percolateUp( T* A, Rank i ); //上滤
template <typename T> void heapify( T* A, Rank n); //Floyd建堆算法
```
该完全二叉堆满足*堆序性*，即：
只要 $0<i$，必满足 `H[i] <= H[Parent(i)]`，故`H[0]`即是全局最大。
```cpp
template <typename T> T PQ_ComplHeap<T>::getMax() { return _elem[0]; }
```
现在讨论如何在动态操作后，仍维护*堆序性*。
=== 插入：逐层上滤

```cpp
template <typename T> void PQ_ComplHeap<T>::insert( T e ) //插入
    { Vector<T>::insert( e ); percolateUp( _elem, _size - 1 ); } //先接入，再上滤
```
在插入一个元素时，我们把它放在队列的最后。每次与父亲对比，如果比父亲大，就swap，直到不能替换。
```cpp
template <typename T> Rank percolateUp( T* A, Rank i ) { //0 <= i < _size
    while ( 0 < i ) { //在抵达堆顶之前，反复地
        Rank j = Parent( i ); //考查[i]之父亲[j]
        if ( lt( A[i], A[j] ) ) break; //一旦父子顺序，上滤旋即完成；否则
        swap( A[i], A[j] ); i = j; //父子换位，并继续考查上一层
    } //while
    return i; //返回上滤最终抵达的位置
}
```
该算法的效率是$O(log n)$。
=== 删除：割肉补疮 + 逐层下滤

每次删除的是最顶层的节点，为了保证完全二叉树的结构，我们把最后一个节点放到顶层，然后逐层下滤。

```cpp
template <typename T> T PQ_ComplHeap<T>::delMax() { //取出最大词条
    swap( _elem[0], _elem[ --_size ] ); //堆顶、堆尾互换（_size递减不致引发shrink()）
    percolateDown( _elem, _size, 0 ); //新堆顶下滤
    return _elem[_size]; //返回原堆顶
}
```
相当于去掉最顶层的节点后，变成两颗子树的合并。取来最后一个节点放在顶层，并逐层下滤即可。
```cpp
template <typename T> Rank percolateDown( T* A, Rank n, Rank i ) { //0 <= i < n
    Rank j; //i及其（至多两个）孩子中，堪为父者
    while ( i != ( j = ProperParent( A, n, i ) ) ) //只要i非j，则
        swap( A[i], A[j] ), i = j; //换位，并继续考察i
    return i; //返回下滤抵达的位置（亦i亦j）
}
```
=== 批量建堆
==== 自上而下的上滤

相当于每次插入在最后插入元素，然后上滤，直到插入所有元素。
```cpp
PQ_ComplHeap( T* A, Rank n )
    { copyFrom( A, 0, n ); heapify( _elem, n ); }
```
不断调用上滤函数即可。
```cpp
template <typename T> void heapify( T* A, const Rank n ) { //蛮力
    for ( Rank i = 1; i < n; i++ ) //按照逐层遍历次序逐一
        percolateUp( A, i ); //经上滤插入各节点
}
```
这种方法是低效的，最坏情况下每个节点都需上滤至根。耗时是$O(n log n)$的。这足以全排序，一定有更好的方法。
==== 自下而上的下滤

任意给定堆$H_1$和$H_2$，以及节点$p$。为得到堆$H_1 union p union H_2$，只需将$H_1$和$H_2$的根当作$p$的孩子，再对$p$下滤。

```cpp
template <typename T> //Robert Floyd， 1964
void heapify( T* A, Rank n ) { //自下而上
    for ( Rank i = n/2 - 1; -1 != i; i-- ) //依次
        percolateDown( A, n, i ); //经下滤合并子堆
} //可理解为子堆的逐层合并， 堆序性最终必然在全局恢复
```
类似自下而上的归并排序。

二者的区别在于，前者（自上而下的上滤）每一个节点都要经过其深度次操作，但是后者（自下而上的下滤）每一个节点只要经过其高度次操作。

从而该算法的效率是$O(n)$的。
== 堆排序Heap Sort

`selectionSort()`的想法是，从后向前排序，每次把前缀最大者交换到后缀的最前端。这样，每次交换后，前缀都是有序的。复杂度是$O(n^2)$的。

这个过程可以被堆优化。做一定的预处理，将前缀建成堆，然后每次取出堆顶，放到后缀的最前端。这样，每次取出后，前缀都是有序的。复杂度是$O(n log n)$的。

```cpp
template <typename T> void Vector<T>::heapSort( Rank lo, Rank hi ) { //就地堆排序
    T* A = _elem + lo; Rank n = hi - lo; heapify( A , n ); //待排序区间建堆， O(n)
    while ( 0 < --n ) //反复地摘除最大元并归入已排序的后缀，直至堆空
        { swap( A[0], A[n] ); percolateDown( A, n, 0 ); } //堆顶与末元素对换后下滤
}
```
具体实现是就地建堆，对顶就是第一个元素，然后每次取出堆顶，放到后缀的最前端，再对新堆顶下滤。
== 锦标赛树Tournament Tree

锦标赛树是完全二叉堆的等效方法。
=== 胜者树

锦标赛树的每一个节点都是一个比赛，每一个节点都有一个胜者。每一个节点的胜者都是其左右孩子的胜者中的较小者。从而树的根部就是最小者，类似于堆顶。

```cpp
Tournamentsort()
CREATE a tournament tree for the input list
while there are active leaves
- REMOVE the root
- RETRACE the root down to its leaf
- DEACTIVATE the leaf
- REPLAY along the path back to the root
```
每次取出胜者后，沿着胜者的路径，重新比赛，可以算出新的胜者。

#figure(
  image("fig\堆\2.png",width: 80%),
  caption: "锦标赛树的更新",
)

锦标赛树的`create()`是$O(n)$的，`replay()`是$O(log n)$的。

从而如果利用锦标赛树排序，是$O(n log n)$的。

在锦标赛树中，进行$k$次迭代选取的话，一共需要$O(k log n)$的时间。在渐进意义上与完全二叉堆是一样的。但是由于占用空间和堆局部性不好的原因，常系数差别较大。堆的每次下滤不一定到最底层，而胜者树一定会遍历所有层。
=== 败者树

胜者树重赛过程中，须交替访问沿途节点及其兄弟，这造成了比较大的开销。

而败者树内部的节点记录比赛的败者，增设根的父亲，记录冠军。
#figure(
  image("fig\堆\3.png",width: 80%),
  caption: "败者树的储存",
)
在构造时，每个节点都会留下败者，向上抛出胜者：每次比较两个节点（下方节点抛给的胜者），把败者放在父亲上，把胜者向上抛出。

而更新时，就直接沿着胜者的路径，重新比赛，可以算出新的胜者。不需要再访问兄弟节点了。
#figure(
  image("fig\堆\4.png",width: 80%),
  caption: "败者树的更新",
)

