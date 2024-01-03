= 排序

== 快速排序Quick Sort

选择一个轴点，将小于轴点的元素放在轴点左边，大于轴点的元素放在轴点右边，然后递归地对左右两个子序列进行快速排序。$"sorted"(S) = "sorted"(S_L) + "pivot" + "sorted"(S_R)$

pivot： $max["lo", "mi") <= "pivot" < min("mi", "hi")$

排好的轴点就是排序之后的位置，此后不会再动。快速排序就是将所有元素逐个转换为轴点的过程。


```cpp
template <typename T> void Vector<T>::quickSort( Rank lo, Rank hi ) {
  if ( hi - lo < 2 ) return;
  Rank mi = partition( lo, hi ); //能否足够高效？
  quickSort( lo, mi );
  quickSort( mi + 1, hi );
}
```
=== `partition`——LUG版

每次选取一个轴点的候选，从前缀和后缀交替扫描，将小于轴点的元素交换到前缀，大于轴点的元素交换到后缀，直至交换至前缀与后缀的交界处。

#figure(
  image("fig\排序\1.png",width: 80%),
  caption: "LUG版partition"
)

交替的方法是：从前缀开始，如果当前元素小于候选者，则继续向后扫描；如果当前元素大于候选者，则从后缀开始，向前扫描，直至找到一个小于轴点的元素，将其交换至前缀，然后继续向后扫描。

```cpp
template <typename T> Rank Vector<T>::partition( Rank lo, Rank hi ) { //[lo, hi)
    swap( _elem[lo], _elem[lo + rand() % (hi-lo)] ); //随机交换
    T pivot = _elem[lo]; //经以上交换，等效于随机选取候选轴点
    while ( lo < hi ) { //从两端交替地向中间扫描，彼此靠拢
        do hi--; while ( (lo < hi) && (pivot <= _elem[hi]) ); //向左拓展G
        if (lo < hi) _elem[lo] = _elem[hi]; //凡 小于 轴点者，皆归入L
        do lo++; while ( (lo < hi) && (_elem[lo] <= pivot) ); //向右拓展L
        if (lo < hi) _elem[hi] = _elem[lo]; //凡 大于 轴点者，皆归入G
    } //assert: lo == hi or hi+1
    _elem[hi] = pivot; return hi; //候选轴点归位；返回其秩
}
```

==== 时间复杂度

最好的情况下，每次都几乎均匀地划分成两个子序列，递归树的深度为$O(log n)$，每层的时间复杂度为$O(n)$，总的时间复杂度为$O(n log n)$。

最坏的情况下，每次都只能划分成一个子序列，递归树的深度为$O(n)$，每层的时间复杂度为$O(n)$，总的时间复杂度为$O(n^2)$。

采用*随机选取（Randomization）、 三者(low,high,mid)取中（Sampling）*之类的策略，降低最坏情况的概率，而无法杜绝。但是数据是非理想随机的，所以这些策略可能有效。
==== 空间复杂度

空间复杂度即是递归栈的深度，最好情况下，递归栈的深度为$O(log n)$，空间复杂度为$O(log n)$。

模拟进栈过程：
```cpp
#define Put( K, s, t ) { if ( 1 < (t) - (s) ) { K.push(s); K.push(t); } }
#define Get( K, s, t ) { t = K.pop(); s = K.pop(); }
template <typename T> void Vector<T>::quickSort( Rank lo, Rank hi ) {
Stack<Rank> Task; Put( Task, lo, hi ); //类似于对递归树的先序遍历
    while ( !Task.empty() ) {
        Get( Task, lo, hi ); Rank mi = partition( lo, hi );
        if ( mi-lo < hi-mi ) { Put( Task, mi+1, hi ); Put( Task, lo, mi ); }
        else { Put( Task, lo, mi ); Put( Task, mi+1, hi ); }
    } //大|小任务优先入|出栈，可保证（辅助栈） 空间不过O(logn)
}
```

小任务优先出栈，大任务优先入栈，可保证辅助栈空间不过$O(log n)$。

===== 递归深度分析

下面我们证明：最坏情况递归$Omega (n)$层，概率极低；平均情况递归$O(log n)$层，概率极高。

对于一个区间，我们定义好的轴点为居中占比为$lambda$的部分的轴点。事实上对于除非过于侧偏的pivot，都会有效地缩短递归深度。
```
  |<--(1-lambda)/2-->|<--lambda-->|<--(1-lambda)/2-->|
  |<-----坏轴点----->||<--好轴点-->||<-----坏轴点----->|
```
于是，在任何一条递归路径上， 好轴点决不会多于
$
d(n, lambda) = log_(2/(n+1)) n
$
这是因为之后递归的所有好节点会出现在当前区间的中间占比为$lambda + (1-lambda)/2$的部分。

以$lambda = 0.5$为例，$d(n, 0.5) = log_(4/3) n approx 2.41 log n $。这意味着同时，深入$1/lambda d(n, lambda)$层后，即可期望出现$d(n, lambda)$个好轴点——从而在此之前终止递归。

下面证明任何一条递归路径的长度，只有极小的概率超过
$
D(n, lambda) = 2/lambda d(n, lambda)
$

事实上此概率
$
&<= sum_(k=0)^(D(n, lambda)) (1-lambda)^k lambda^(D-k) \
&= 2^(-D(n, lambda)) sum_(k=0)^(D(n, lambda)) (2 lambda)^k \
&<= 2^(-4D) (e D/d)^d
= 16^(-d)(4e)^d \
&approx n^(-1.343)
$

当$n=10^6$时，递归深度不超过$D$的概率$>=1-n^(-0.343)approx 99.12%$。从而可以说复杂度为$O(log n)$是极高概率发生（occurring w.h.p）的。

===== 比较次数分析

记期望的比较次数为$T(n)$，是一个期望值，下面分析$T(n)$的递归表达式。

+ 递推分析

  设$T(n)$为$n$个元素的序列的期望比较次数，是`partition`与递归任务的期望之和，$T(0) = T(1) = 0$，
  $ T(n) &= n-1 + 1/n sum_(k=0)^(n-1) (T(i) + T(n-i-1)) \
        &= n-1 + 2/n sum_(k=0)^(n-1) T(i) \
        &approx 2 n ln n $

+ 后向分析

  设经排序后得到的输出序列为：${a_1, a_2, ...,a_i,...,a_j,..., a_n}$。

  这一输出与具体使用何种算法无关，故可使用Backward Analysis。

  比较操作的期望次数应为
  $
  T(n) = sum_(i=0)^(n-2) sum_(j=i+1)^(n-1) P(i,j)
  $
  亦即，每一对$<a_i,a_j>$在排序过程中接受比较之概率的总和。

  `quickSort`的过程及结果，可理解为：按某种次序，将各元素逐个确认为`pivot`。

  若$k in [0,i) union (j,n)$，则$a_k$早于或晚于$a_i$和$a_j$被确认，均与$P(i,j)$无关。实际上，$<a_i,a_j>$接受比较，当且仅当在${a_i,...,a_j}$中，$a_i$或$a_j$率先被确认。

  从而
  $
  T(n) &= sum_(i=0)^(n-2) sum_(j=i+1)^(n-1) P(i,j)\
        &= sum_(j=0)^(n-1) sum_(i=0)^(k-1) P(i,j) \
        &= sum_(j=0)^(n-1) sum_(i=0)^(k-1) 2/(j-i+1) \
        &approx sum_(j=0)^(n-1)2 (ln(j) - 1) \
        &<= 2 n ln n
  $

#figure(
  image("fig\排序\2.png",width: 80%),
  caption: "排序算法的对比"
)

=== `partition`——DUP版

有大量元素与轴点雷同时
- 切分点将接近于lo
- 划分极度失衡
- 递归深度接近于$O(n)$
- 运行时间接近于$O(n^2)$

移动`lo`和`hi`的过程中，同时比较相邻元素，若属于相邻的重复元素，则不再深入递归。但一般情况下，如此计算量反而增加，得不偿失。

DUP的想法就是在LUG `partition`的比较上，将两头指针移动的判定条件的判定条件由`<=`改为`<`，从而使相邻元素不再重复比较。

```cpp
template <typename T> Rank Vector<T>::partition( Rank lo, Rank hi ) { //[lo, hi)
    swap( _elem[lo], _elem[lo + rand() % (hi-lo)] ); //随机交换
    T pivot = _elem[lo]; //经以上交换，等效于随机选取候选轴点
    while ( lo < hi ) { //从两端交替地向中间扫描，彼此靠拢
        /* 与LUG版仅改变符号 */
        do hi--; while ( (lo < hi) && (pivot < _elem[hi]) ); //向左拓展G
        if (lo < hi) _elem[lo] = _elem[hi]; //凡不大于轴点者，皆归入L
        do lo++; while ( (lo < hi) && (_elem[lo] < pivot) ); //向右拓展L
        if (lo < hi) _elem[hi] = _elem[lo]; //凡不小于轴点者，皆归入G
    } //assert: lo == hi or hi+1
    _elem[hi] = pivot; return hi; //候选轴点归位；返回其秩
}
```

- 可以正确地处理一般情况同时复杂度并未实质增高；
- 遇到连续的重复元素时
    - `lo`和`hi`会交替移动
    - 切分点接近于`(lo+hi)/2`
- 由LUG版的勤于拓展、懒于交换，转为懒于拓展、勤于交换

=== `partition`—— LGU版

在形式上将`partition`化简，全部用swap实现。呈现形式是Piovt + L + G + U 。用这样的方式，可以大大化简代码。

#figure(
  image("fig\排序\3.png",width: 65%),
  caption: "LGU版partition"
)

采用`swap`实现滚动拓展，而非平移拓展

```cpp
template <typename T> Rank Vector<T>::partition( Rank lo, Rank hi ) { //[lo, hi)
    swap( _elem[ lo ], _elem[ lo + rand() % ( hi – lo ) ] ); //随机交换
    T pivot = _elem[ lo ]; Rank mi = lo;
    for ( Rank k = lo + 1; k < hi; k++ ) //自左向右考查每个[k]
        if ( _elem[ k ] < pivot ) //若[k]小于轴点，则将其
            swap( _elem[ ++mi ], _elem[ k ]); //与[mi]交换， L向右扩展
    swap( _elem[ lo ], _elem[ mi ] ); //候选轴点归位（从而名副其实）
    return mi; //返回轴点的秩
}
```

== k-selection 

k-selection：在任意一组可比较大小的元素中，由小到大，找到次序为$k$者。亦即，在这组元素的非降排序序列$S$中，找出$S[k]$。

median：长度为$n$的有序序列$S$中，元素$S[floor(n/2)]$称作中位数。
=== 众数Majority

无序向量中，若有一半以上元素同为$m$，则称之为众数。
==== 充分条件

如果获取了中位数，只需要验证该数是否为众数即可，若不是，则无众数。

```cpp
template <typename T> bool majority( Vector<T> A, T & maj )
    { return majEleCheck( A, maj = median( A ) ); }
```

mode：众数若存在，则亦必频繁数。

```cpp
template <typename T> bool majority( Vector<T> A, T & maj )
    { return majEleCheck( A, maj = mode( A ) ); }
```

同样地：`mode()`算法难以兼顾时间、空间的高效。
==== 减而治之——丢掉前缀

若在向量A的前缀$P$（$|P|$为偶数）中，元素 $x$ 出现的次数恰占半数，则$A$有众数，仅当对应的后缀 $A - P$ 有众数$m$，且$m$就是 $A$ 的众数。

证：
1. 若$x = m$，则在排除前缀 $P$ 之后， $m$与其它元素在数量上的差距保持不变
2. 若$x != m$，则在排除前缀 $P$ 之后， $m$与其它元素在数量上的差距不致缩小

从而可以按照这样的方法，不断地剪掉前缀、保存候选者，进行扫描。

```cpp
template <typename T> T majCandidate( Vector<T> A ) {
    T maj;
    for ( Rank c = 0, i = 0; i < A.size(); i++ )
        if ( 0 == c ) {
            maj = A[i]; c = 1;
        } else
            maj == A[i] ? c++ : c--;
    return maj;
}
```
最后验证候选者是否为众数。
    
```cpp
template <typename T> bool majority( Vector<T> A, T & maj )
    { return majEleCheck( A, maj = majEleCandiate( A ) ); }
```

=== QuickSelect

下图是对`k-selection`的尝试，采用了不同的方法。
#figure(
    image("fig\排序\4.png",width: 90%),
    caption: "尝试"
)

希望能找到$O(n)$的算法。

采用快速排序的想法，每次选取一个轴点，将小于轴点的元素放在轴点左边，大于轴点的元素放在轴点右边。直到轴点的秩为$k$。
```cpp
template <typename T> void quickSelect( Vector<T> & A, Rank k ) {
    for ( Rank lo = 0, hi = A.size(); lo < hi; ) {
        Rank i = lo, j = hi; T pivot = A[lo]; //大胆猜测
        while ( i < j ) { //小心求证： O(hi - lo + 1) = O(n)
            do j--; while ( (i < j) && (pivot <= A[j]) ); if (i < j) A[i] = A[j];
            do i++; while ( (i < j) && (A[i] <= pivot) ); if (i < j) A[j] = A[i];
        } //assert: quit with i == j or j+1
        A[j] = pivot;
        if ( k <= j ) hi = j; //suffix trimmed
        if ( i <= k ) lo = i; //prefix trimmed
    } //A[k] is now a pivot
}
```

在期望上讲，复杂度为$O(n)$，但是最坏情况下，复杂度为$O(n^2)$。

可以用递推的方式证明：
$
T(n) &= (n-1) + 1/n sum_(k=0)^(n-1) max{T(k) , T(n-k-1)} \
     &= (n-1) + 1/n sum_(k=0)^(n-1) T(max{k, n-k-1}) \
     &<= (n - 1) + 2/n sum_(k=n/2)^(n-1) T(k) \
$
其中
$
T(1) = 0, T(2) = 1
$
可以归纳
$
T(n) < 4n
$
从而，该算法在期望上讲，复杂度为$O(n)$。
=== LinearSelect

`LinearSelect`是`QuickSelect`的改进版，采用了*中位数的中位数*的思想。

先找局部中位数，取这些中位数的中位数，得到较好的猜测位置。由这个中位数进行分割，递归地进行查找。

```cpp
def linearSelect( A, n, k ):
Let Q be a small constant
1. if ( n = |A| < Q ) return trivialSelect( A, n, k )
2. else divide A evenly into n/Q subsequences (each of size Q)
3. Sort each subsequence and determine n/Q medians //e.g. by insertionsort
4. Call linearSelect() to find M, median of the medians //by recursion
5. Let L/E/G = { x </=/> M | x in A }
6. if (k < |L|) return linearSelect(A, |L|, k)
if (k < |L|+|E|) return M
return linearSelect(A+|L|+|E|, |G|, k-|L|-|E|)
```

#figure(
    image("fig\排序\5.png",width: 50%),
    caption: "LinearSelect"
)

将`linearSelect()`算法的运行时间记作`T(n)`
- 第0步： $O(1) = O(Q log Q)$ ，递归基：序列长度$|A| <= Q$
- 第1步： $O(n)$ ，子序列划分
- 第2步： $O(n) = Q^2 times n/Q$ ，/子序列各自排序，并找到中位数
- 第3步： $T(n/Q)$ ，从$n/Q$个中位数中，递归地找到全局中位数
- 第4步： $O(n)$ ，划分子集`L/E/G`，并分别计数 —— 一趟扫描足矣
- 第5步： $T((3n)/4)$，如下图，至少有$1/4$被排除

#figure(
    image("fig\排序\6.png",width: 60%),
    caption: "LinearSelect——复杂度"
)

从而总复杂度是线性的，并且选取$Q=5$。

由于常系数过大($~ >$40)，理论价值比应用价值高。
== Shell Sort

注意到每交换一个逆序对，总逆序对数量一定严格减少。

Shell排列考虑将线性序列理解成矩阵，按列进行排序。

*递减增量*（diminishing increment）
- 由粗到细：重排矩阵，使其更窄， 再次逐列排序（h-sorting/h-sorted）
- 逐步求精：如此往复，直至矩阵变成一列（1-sorting/1-sorted）

#figure(
    image("fig\排序\7.png",width: 90%),
    caption: "Shell Sort"
)


```cpp
template <typename T> void Vector<T>::shellSort( Rank lo, Rank hi ) {
    for ( Rank d = 0x7FFFFFFF; 0 < d; d >>= 1 ) //PS Sequence: 1, 3, 7, 15, 31, ...
        for ( Rank j = lo + d; j < hi; j++ ) { //for each j in [lo+d, hi)
        T x = _elem[j]; Rank i = j; //within the prefix of the subsequence of [j]
        while ( (lo + d <= i) && (x < _elem[i-d]) ) //find the appropriate
            _elem[i] = _elem[i-d]; i -= d; //predecessor [i]
        _elem[i] = x; //where to insert [j]
    }
} //0 <= lo < hi <= size <= 2^31
```
对每一列进行插入排序。事实上，Shell排序很适合并行化。

对于Shell排序，选择合适的增量序列是很重要的。
=== Shell序列

Shell给出的是${2^k}$的序列，但是这样的序列并不是最优的。最坏情况要达到$O(n^2)$。

反例是：考查由子序列 `A = unsort[0, 2N−1)` 和 `B = unsort[2N−1, 2N)` 交错而成的序列。在做2-sorting时， A、 B各成一列；故此后必然各自有序。最后一次1-sorting仍需$O(n^2)$。

根源在于，$H_"shell"$中各项并不互素，甚至相邻项也非互素。

这里不加证明的给出几个引理：

*LEM L*:

如下图，设有向量`X[0, m + r)`和 `Y[0, r + n)`，且满足：对任何`0 <= j < r`，都有`Y[j] <= X[m + j]`。在`X`和`Y`分别（按非降次序）排序幵转换为 `X'`和` Y'`后，对任何`0 <= j < r`，依然有`Y'[j] <= X'[m + j]`成立。

#figure(
    image("fig\排序\8.png",width: 60%),
    caption: "LEM L"
)

*THM K*(Knuth):

A g-ordered sequence REMAINS g-ordered after being h-sorted.

证明用到了LEM L。其中h-ordered是指，当排列成长为h的矩阵时，每一列都是有序的，即$S[i] <= S[i + h]$。

由此可以得到，经过一次h-sorting和g-sorting的的序列可以保持h-ordered和g-ordered。

#figure(
    image("fig\排序\9.png",width: 80%),
    caption: "Inversion"
)

*线性组合*：对于任意$m、n ∈ N$，既是h-sorting又是g-ordered的序列称为(g,h)-ordered的，它是(mg+nh)-ordered的序列。

由数论的小性质可知（一些Bezout定理的应用），对于互素的$g,h$，对于任意$k > g h -g -h$，$k$-ordered的序列必然是$(g,h)$-ordered的。  

这就意味着
$
i-j> g h - g - h => S[i] >= S[j]
$

所以除了左侧的$g h - g - h$个元素，元素都要比$S[i]$大。所以逆序对的数量不超过$n dot (g h - g - h)$。
=== PS序列

Papernov & Stasevic给出序列：
$
H_"PS" = {2^k - 1} = H_"shell" - 1
$

需要
- $O(log n)$次外部迭代
- $O(n^(3/2))$的复杂度
=== Pratt序列

Pratt给出序列：
$
H_"Pratt" = {2^i 3^j| i,j in N}
$

复杂度是$O(n log^2 n)$。
=== Sedgewick序列

Sedgewick给出序列：
$
H_"Sedgewick" = {9 times 4^i - 9 times 2^i + 1, 4^i - 3 times 2^i + 1}
$

最坏复杂度是$O(n^(4/3))$，平均是$O(n^(7/6))$。是实践中最好的序列。