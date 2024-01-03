= 向量Vector

和数组一样，寻秩访问(Call by Rank)：元素各由编号唯一指代，并可直接访问。为了使数组可以动态操作，引入`ADT::Vector`。

向量是数组的抽象与泛化，由一组元素按线性次序封装而成。

各元素与$[0, n)$内的秩（rank）一一对应： 
```cpp
using Rank = unsigned int; //call-by-rank
```

提供接口：
```cpp
size() / empty()  // 报告元素总数 / 判定是否为空 向量
get(r) / put(r, e) // 获取秩为r的元素 / 用e替换秩为r元素的数值 向量
insert(r, e) / insert(e) // 将e作为秩为r的 / 最后一个元素插入 向量
remove(lo, hi) / remove(r) // 删除秩为r / 区间内的元素 向量
disordered() / sort(lo, hi) / unsort(lo, hi) // 检测是否整体有序 / 整体排序 / 整体置乱 向量
find(e , lo, hi) / search(e, lo, hi) // 在指定区间内查找目标e 向量 / 有序向量
dedup() / uniquify() // 剔除重复元素 向量 / 有序向量
traverse( visit() ) // 遍历向量，统一按visit()处理所有元素 向量
```
*模板类：*
  
```cpp
template <typename T> class Vector { //向量模板类
private: Rank _size; Rank _capacity; T* _elem; //规模、容量、数据区
protected:
/* ... 内部函数 */
public:
/* ... 构造函数 */
/* ... 析构函数 */
/* ... 只读接口 */
/* ... 可写接口 */
/* ... 遍历接口 */
/* ... 遍历接口 */
};
```
构造 + 析构：重载
```cpp
#define DEFAULT_CAPACITY 3 //默认初始容量（实际应用中可设置为更大）
Vector( int c = DEFAULT_CAPACITY )
    { _elem = new T[ _capacity = c ]; _size = 0; } //默认构造
Vector( T const * A, Rank lo, Rank hi ) //数组区间复制
    { copyFrom( A, lo, hi ); }
Vector( Vector<T> const & V, Rank lo, Rank hi ) //向量区间复制
    { copyFrom( V._elem, lo, hi ); }
Vector( Vector<T> const & V ) //向量整体复制
    { copyFrom( V._elem, 0, V._size ); }
~Vector() { delete [] _elem; } //释放内部空间
```
基于复制的构造
```cpp
template <typename T> //T为基本类型，或已重载赋值操作符'='
void Vector<T>::copyFrom( T const * A, Rank lo, Rank hi ) { //A中元素不致被篡改
    _elem = new T[ _capacity = max( DEFAULT_CAPACITY, 2*(hi − lo) ) ]; //分配空间
    for ( _size = 0; lo < hi; _size++, lo++ ) //A[lo, hi)内的元素， 逐一
        _elem[ _size ] = A[ lo ]; //复制至_elem[0, hi-lo)
} //O(hi – lo) = O(n)
```
== 可扩充向量

开辟内部数组`_elem[]`并使用一段地址连续的物理空间，`_capacity`：总容量，`_size`：当前的实际规模$n$。

定义*装填因子*(load factor)： $lambda$ `= _size/_capacity`，分为：
- 上溢(overflow)： `_elem[]`不足以存放所有元素，尽管此时系统往往仍有足够的空间
- 下溢(underflow)： `_elem[]`中的元素寥寥无几

这种时候就要进行动态空间管理，扩容或缩容。

扩容：
```cpp
template <typename T> void Vector<T>::expand() { //向量空间不足时扩容
    if ( _size < _capacity ) return; //尚未满员时，不必扩容
    _capacity = max( _capacity, DEFAULT_CAPACITY ); //不低于最小容量
    T* oldElem = _elem; _elem = new T[ _capacity <<= 1 ]; //容量加倍
    for ( Rank i = 0; i < _size; i++ ) //复制原向量内容
        _elem[i] = oldElem[i]; //T为基本类型，或已重载赋值操作符'='
    delete [] oldElem; //释放原空间
} //得益于向量的封装，尽管扩容之后数据区的物理地址有所改变，却不致出现野指针
```
分析扩容的复杂度需要用到分摊想法，因为扩容本身不是每次都发生的，而是在一定条件下才发生的，所以要分析一系列操作的总体复杂度，而不是单纯的扩容操作。

考虑连续插入$n$次，扩容的次数不超过$log_2n$次，每次扩容的复杂度为$O(n)$，所以分摊杂度为$O(1)$。采取*装填因子比一半大就扩容*比每次都扩容好。

_平均（average complexity）：根据各种操作出现概率的分布，将对应的成本加权平均_
- _各种可能的操作，作为独立事件分别考查_
- _割裂了操作之间的相关性和连贯性_
- _往往不能准确地评判数据结构和算法的真实性能_
_分摊（amortized complexity）： 连续实施的足够多次操作，所需总体成本摊还至单次操作_
- _从实际可行的角度，对一系列操作做整体的考量_
- _更加忠实地刻画了可能出现的操作序列_
- _更为精准地评判数据结构和算法的真实性能_
== 无序向量
=== 基本操作
==== 元素访问
```cpp
template <typename T> //可作为左值： V[r] = (T) (2*x + 3)
    T & Vector<T>::operator[]( Rank r ) { return _elem[ r ]; }
template <typename T> //仅限于右值： T x = V[r] + U[s] * W[t]
    const T & Vector<T>::operator[]( Rank r ) const { return _elem[ r ]; }
// 这里采用了简易的方式处理意外和错误（比如，入口参数约定： 0 <= r < _size）
```
抛弃`V.get(r)``V.put(r,e)`接口，重载`[]`操作符。
==== 插入

在装填因子大于一半时扩容：
```cpp
template <typename T> Rank Vector<T>::insert( Rank r, T const & e ) { //0<=r<=size
    expand(); //如必要，先扩容
    for ( Rank i = _size; r < i; i-- ) //O(n-r)： 自后向前
        _elem[i] = _elem[i - 1]; //后继元素顺次后移一个单元
    _elem[r] = e; _size++; return r; //置入新元素，更新容量，返回秩
}
```
插入操作的复杂度为$O(n)$。
==== 区间删除

在装填因子小于$1/4$时缩容：
```cpp
template <typename T> Rank Vector<T>::remove( Rank lo, Rank hi ) { //0<=lo<=hi<=n
    if ( lo == hi ) return 0; //出于效率考虑，单独处理退化情况
    while ( hi < _size ) _elem[ lo++ ] = _elem[ hi++ ]; //后缀[hi,n)前移
    _size = lo; shrink(); //更新规模， lo = _size之后的内容无需清零；如必要，则缩容
    return hi - lo; //返回被删除元素的数目
}
```
区间删除操作的复杂度为$O(n)$。选取$1/4$的界而不是$1/2$的界，是为了避免在连续删除操作中频繁地扩容和缩容。
==== 单元素删除
```cpp
template <typename T>
T Vector<T>::remove( Rank r ) {
    T e = _elem[r]; //备份
    remove( r, r+1 ); //“区间”删除
    return e; //返回被删除元素
} //O(n-r)
```
要先定义`remove( Rank lo, Rank hi )`，再定义`remove( Rank r )`，否则如果用后者实现前者，会导致前者的复杂度为$O(n^2)$。
==== 查找

对于词条定义判等器和比较器，在无需向量中、判等器即可，有序向量中、可以定义比较器。
```cpp
template <typename K, typename V> struct Entry { //词条模板类
    K key; V value; //关键码、数值
    Entry ( K k = K(), V v = V() ) : key ( k ), value ( v ) {}; //默认构造函数
    Entry ( Entry<K, V> const& e ) : key ( e.key ), value ( e.value ) {}; //克隆
    bool operator== ( Entry<K, V> const& e ) { return key == e.key; } //等于
    bool operator!= ( Entry<K, V> const& e ) { return key != e.key; } //不等于
    bool operator< ( Entry<K, V> const& e ) { return key < e.key; } //小于
    bool operator> ( Entry<K, V> const& e ) { return key > e.key; } //大于
}; //得益于比较器和判等器，从此往后， 不必严格区分词条及其对应的关键码
```
查找在无序向量中只能采用顺序查找：
```cpp
template <typename T> Rank Vector<T>:: //O(hi - lo) = O(n)
    find( T const & e, Rank lo, Rank hi ) const { //0 <= lo < hi <= _size
    while ( (lo < hi--) && (e != _elem[hi]) ); //逆向查找
    return hi; //返回值小于lo即意味着失败；否则即命中者的秩（有多个时，返回最大者）
}
```
复杂度为$O(n)$。
==== 去重
```cpp
template <typename T> Rank Vector<T>::dedup() {
    Rank oldSize = _size;
    for ( Rank i = 1; i < _size; )
        if ( -1 == find( _elem[i], 0, i ) ) //O(i)
            i++;
    else
        remove(i); //O(_size - i)
    return oldSize - _size;
} //O(n^2)：对于每一个e， 只要find()不是最坏情况（查找成功），则remove()必执行
```
只要既运行`find()`又运行`remove()`，这一次严格$n$此操作，从而复杂度为$O(n^2)$。
==== 遍历

对向量中的每一元素，统一实施`visit()`操作，利用函数指针或者函数对象
```cpp
template <typename T> //函数指针，只读或局部性修改
void Vector<T>::traverse( void ( * visit )( T & ) )
    { for ( Rank i = 0; i < _size; i++ ) visit( _elem[i] ); }

template <typename T> template <typename VST> //函数对象，全局性修改更便捷
void Vector<T>::traverse( VST & visit )
    { for ( Rank i = 0; i < _size; i++ ) visit( _elem[i] ); }
```
例如遍历加一：
```cpp
/* 先实现一个可使单个T类型元素加一的类（结构） */
template <typename T> //假设T可直接递增或已重载操作符“++”
struct Increase //函数对象：通过重载操作符“()”实现
    { virtual void operator()( T & e ) { e++; } }; //加一
/* 再将其作为参数传递给遍历算法 */
template <typename T> void increase( Vector<T> & V )
{ V.traverse( Increase<T>() ); } //即可以之作为基本操作，遍历向量
```
== 有序向量：二分搜索
=== 有序性
通过计算逆序对的数量，可以统计向量的有序性：
```cpp
template <typename T> void checkOrder ( Vector<T> & V ) { //通过遍历
    int unsorted = 0; V.traverse( CheckOrder<T>(unsorted, V[0]) ); //统计紧邻逆序对
    if ( 0 < unsorted )
        printf ( "Unsorted with %d adjacent inversion(s)\n", unsorted );
    else
        printf ( "Sorted\n" );
}
```
=== 基本操作
==== 唯一化
```cpp
/* 勤奋的低效算法 */
template <typename T> int Vector<T>::uniquify() {
    int oldSize = _size; int i = 1;
    while ( i < _size )
        _elem[i-1] == _elem[i] ? remove( i ) : i++;
    return oldSize - _size;
}
/* 懒惰的高效算法： Two-Pointer Technique */
template <typename T> int Vector<T>::uniquify() {
    Rank i = 0, j = 0;
    while ( ++j < _size )
        if ( _elem[ i ] != _elem[ j ] )
            _elem[ ++i ] = _elem[ j ]; //可能徒劳无益
    _size = ++i;
    shrink();
    return j - i;
}
```
直接就地改写，而不是先统计再删除，这样可以避免多余的删除操作。

#figure(
  image("fig\向量\1.png", width: 80%),
  caption: "唯一化算法"
)

==== 查找
```cpp
template <typename T> //查找算法统一接口， 0 <= lo < hi <= _size
Rank Vector<T>::search( T const & e, Rank lo, Rank hi ) const {
    return ( rand() % 2 ) ? //等概率地随机选用
    binSearch( _elem, e, lo, hi ) //二分查找算法， 或
    : fibSearch( _elem, e, lo, hi ); //Fibonacci查找算法
}
```
对于有序向量，利用序性，可以加速查找。最常见的方法就是二分查找。

二分查找的想法就是分治：将查找区间一分为二，然后判断目标元素在哪一部分，然后递归地在该部分中查找。二分查找的复杂度是$O(log n)$。
===== 版本A
第一种实现方式是分成三部分，如果命中，返回秩；如果小于，递归地在左侧查找；如果大于，递归地在右侧查找。
```cpp
template <typename T> //在有序向量[lo, hi)区间内查找元素e
static Rank binSearch( T * S, T const & e, Rank lo, Rank hi ) {
    while ( lo < hi ) { //每步迭代可能要做两次比较判断，有三个分支
        Rank mi = ( lo + hi ) >> 1; //以中点为轴点（区间宽度折半，其数值表示右移一位）
        if ( e < S[mi] ) hi = mi; //深入前半段[lo, mi)
        else if ( S[mi] < e ) lo = mi + 1; //深入后半段(mi, hi)
        else return mi; //命中
    }
    return -1; //失败
}
```
每个元素都是轴点，每步迭代可能要做两次比较判断，有三个分支。可以分析关键码的比较次数，即*查找长度（search length）*：

需分别针对成功与失败查找，从最好、最坏、平均等角度评估，这种实现方式的成功、失败时的平均查找长度均大致为$O(1.5 log n)$。

#figure(
  image("fig\向量\2.png", width: 80%),
  caption: "二分查找算法的查找长度"
)

===== 版本B

二分查找中左、右分支转向代价不平衡的问题，也可直接解决，每次迭代仅做1次关键码比较；如此，所有分支只有2个方向，而不再是3个。

同样地，轴点`mi`取作中点，则查找每深入一层，问题规模依然会缩减一半
- `e < x`： 则深入左侧的`[lo, mi)`
- `x <= e`：则深入右侧的`[mi, hi)`

直到`hi - lo = 1`， 才明确判断是否命中。

相对于版本A，最好（坏）情况下更坏（好），整体性能更趋均衡。
  
```cpp
template <typename T>
static Rank binSearch( T * S, T const & e, Rank lo, Rank hi ) {
    while ( 1 < hi - lo ) { //有效查找区间的宽度缩短至1时，算法才终止
        Rank mi = (lo + hi) >> 1; //以中点为轴点，经比较后确定深入[lo, mi)或[mi, hi)
        e < S[mi] ? hi = mi : lo = mi;
    } //出口时hi = lo + 1
    return e == S[lo] ? lo : -1 ;
}// 返回命中处的秩， 或失败标志
```
返回值可能不统一：
- 目标元素不存在
- 目标元素同时存在多个，可能返回的不是最后一个，对于`V.insert( 1 + V.search(e), e )`就不是合法的插入位置
希望做到
- 即便失败，也应给出新元素可安置的位置（有序性）
- 若有重复元素，也需按其插入的次序排列（稳定性）

*返回值的语义扩充*：`m = search(e) = M-1`，其中$-oo < m =max{k|S[k]<=e}$，$M = min{k|e<S[k]} <= +oo$，则
- 若查找成功，返回最后一个目标元素的秩
- 若查找失败，返回比它小的最大元素的秩

#figure(
  image("fig\向量\3.png", width: 50%),
  caption: "二分查找算法返回值的约定"
)
===== 版本C

```cpp
template <typename T>
static Rank binSearch( T * S, T const & e, Rank lo, Rank hi ) {
    while ( lo < hi ) { //不变性： A[0, lo) <= e < A[hi, n)
        Rank mi = (lo + hi) >> 1;
        e < S[mi] ? hi = mi : lo = mi + 1; //[lo, mi)或(mi, hi)， A[mi]或被遗漏？
    } //出口时， 区间宽度缩短至0，且必有S[lo = hi] = M
    return lo - 1; //至此， [lo]为大于e的最小者，故[lo-1] = m即为不大于e的最大者
} //留意与版本B的差异
```
这样就遵守了返回值的语义约定。

#figure(
  image("fig\向量\4.png", width: 80%),
  caption: "二分查找算法的正确性分析"
)

#figure(
  image("fig\向量\5.png", width: 80%),
  caption: "二分查找算法的正确性分析"
)
===== 插值查找
大数定律：越长的序列，元素的分布越有规律；最为常见：独立且均匀的随机分布。

于是 `[lo, hi]`内各元素应大致呈线性趋势增长，因此通过猜测轴点`mi`，可以极大地提高收敛速度。
$
&("mi"-"lo")/("hi"-"lo") = ("e"-"S[lo]")/("S[hi]"-"S[lo]")\

&"mi" = "lo" + ("hi"-"lo")  ("e"-"S[lo]")/("S[hi]"-"S[lo]")
$

最坏：$O(n)$，平均：$O(log log n)$。

这是因为每次比较，待查找区间都会从宽度$n$缩短至$sqrt(n)$。

每经一次比较，查找区间宽度的数值$n$开方，有效字长$log n$减半
- 插值查找 = 在字长意义上的折半查找 $log(n^(1/2)) = 0.5 log n$
- 二分查找 = 在字长意义上的顺序查找 $log(n/2) = log n - 1$

从$O(log n)$到$O(log log n)$，优势并不明显

- 须引入乘法、 除法运算
- 易受畸形分布的干扰和“蒙骗”
- 实际可行的方法：算法接力
  - 首先通过插值查找
  迅速将查找范围缩小到一定的尺度
  - 然后再改为二分查找
  进一步缩小范围
  - 最后（当数据项只有200～ 300时）
  改用顺序查找
=== 排序

对于无序向量，可以排序成有序向量。

```cpp
template <typename T> void Vector<T>::sort( Rank lo, Rank hi ) {
    switch ( rand() % 6 ) {
        case 1 : bubbleSort( lo, hi ); break; //起泡排序
        case 2 : selectionSort( lo, hi ); break; //选择排序
        case 3 : mergeSort( lo, hi ); break; //归并排序
        case 4 : heapSort( lo, hi ); break; //堆排序
        case 5 : quickSort( lo, hi ); break; //快速排序
        default : shellSort( lo, hi ); break; //希尔排序
    } //随机选择算法，以尽可能充分地测试。应用时可视具体问题的特点， 灵活确定或扩充
}
```
== 起泡排序Bubble Sort

反复地扫描交换：

- 观察：有序/无序序列中，任何/总有一对相邻元素顺序/逆序
- 扫描交换：依次比较每一对相邻元素；如有必要，交换之。直至某趟扫描后，确认相邻元素均已顺序。

其复杂度是$O(n^2)$，但是可以通过优化来提高效率。

*基本版*：
```cpp
template <typename T> void Vector<T>::bubbleSort( Rank lo, Rank hi ) {
    while ( lo < --hi ) //逐趟起泡扫描
        for ( Rank i = lo; i < hi; i++ ) //逐对检查相邻元素
            if ( _elem[i] > _elem[i + 1] ) //若逆序
                swap( _elem[i], _elem[i + 1] ); //则交换
}
```
- Loop Invariant： 经$k$趟扫描交换后，最大的$k$个元素必然就位
- Convergence：经$k$趟扫描交换后，问题规模缩减至$n-k$
- Correctness： 经至多$n$趟扫描后，算法必然终止，且能给出正确解答

`[hi]`就位后， `[lo,hi)`可能已经有序（sorted） ——此时，应该可以*提前终止*算法。
```cpp
template <typename T> void Vector<T>::bubbleSort( Rank lo, Rank hi ) {
    for ( bool sorted = false; sorted = !sorted; hi-- )
        for ( Rank i = lo + 1; i < hi; i++ )
            if ( _elem[i-1] > _elem[i] )
                swap( _elem[i-1], _elem[i] ), sorted = false;
}
```
同样地，有可能某一后缀`[last,hi)`已然有序，继续优化：*跳跃版*
```cpp
template <typename T> void Vector<T>::bubbleSort( Rank lo, Rank hi ) {
    for ( Rank last; lo < hi; hi = last )
        for ( Rank i = (last = lo) + 1; i < hi; i++ )
            if ( _elem[i-1] > _elem[i] )
                swap( _elem[i-1], _elem[i] ), last = i;
}
```
#figure(
  image("fig\向量\6.png", width: 30%),
  caption: "起泡排序算法——跳跃版"
)

时间效率：最好$O(n)$，最坏$O(n^2)$
输入含重复元素时，算法的稳定性（stability）是更为细致的要求。重复元素在输入、输出序列中的相对次序，需要保持不变。
- 输入： 6, 7a, 3, 2, 7b, 1, 5, 8, 7c, 4
- 输出： 
  - 1, 2, 3, 4, 5, 6, 7a, 7b, 7c, 8 是stable的
  - 1, 2, 3, 4, 5, 6, 7a, 7c, 7b, 8 是unstable的
起泡排序算法是稳定的，因为唯有相邻元素才可交换。
== 归并排序Merge Sort

向量与列表通用的一种分而治之的排序方法。

- 序列一分为二 
- 子序列递归排序 
- 合并有序子序列
$
T(n) = 2T(n/2) + O(n)
$

根据主定理，复杂度是$O(n log n)$。

#figure(
  image("fig\向量\7.png", width: 70%),
  caption: "归并排序算法"
)

```cpp
template <typename T> void Vector<T>::mergeSort( Rank lo, Rank hi ) {
    if ( hi - lo < 2 ) return; //单元素区间自然有序，否则...
    Rank mi = (lo + hi) >> 1; //以中点为界
    mergeSort( lo, mi ); //对前半段排序
    mergeSort( mi, hi ); //对后半段排序
    merge( lo, mi, hi ); //归并
}
```
=== 二路归并

2-way merge：有序序列合二为一，保持有序
$
S["lo","mi") + S["mi","hi") -> S["lo","hi")
$

#figure(
  image("fig\向量\8.png", width: 70%),
  caption: "二路归并算法"
)

```cpp
template <typename T> //[lo, mi)和[mi, hi)各自有序
void Vector<T>::merge( Rank lo, Rank mi, Rank hi ) { //lo < mi < hi
    Rank i = 0; T* A = _elem + lo; //A = _elem[lo, hi)
    Rank j = 0, lb = mi - lo; T* B = new T[lb]; //B[0, lb) <-- _elem[lo, mi)
    for ( Rank i = 0; i < lb; i++ ) B[i] = A[i]; //复制出A的前缀
    Rank k = 0, lc = hi - mi; T* C = _elem + mi;
    //后缀C[0, lc] = _elem[mi, hi)， 就地
    while ( ( j < lb ) && ( k < lc ) ) //反复地比较B、 C的首元素
        A[i++] = ( B[j] <= C[k] ) ? B[j++] : C[k++]; //小者优先归入A中
    while ( j < lb ) //若C先耗尽， 则
        A[i++] = B[j++]; //将B残余的后缀归入A中——若B先耗尽呢？
    delete[] B; //new和delete非常耗时，如何减少？
}
```
只需要$n/2$的辅助空间，这是因为保留后半段的，复制前半段的元素，每次选择元素后直接覆盖原数组，并不会覆盖到后半段未被复制的元素。
需要$O(n)$的时间复杂度。
=== 复杂度
优点
- 实现最坏情况下最优$O(n log n)$性能的第一个排序算法
- 不需随机读写，完全顺序访问——尤其适用于列表之类的序列、磁带之类的设备
- 只要实现恰当，可保证稳定——出现雷同元素时，左侧子向量优先
- 可扩展性极佳，十分适宜于外部排序——海量网页搜索结果的归并
- 易于并行化
缺点
- 非就地，需要对等规模的辅助空间
- 即便输入已是完全（或接近） 有序，仍需$Omega(n log n)$时间
== 位图Bitmap

对于有限整数集，直接用整数作为秩，可以将集合元素与秩一一对应，从而实现集合的快速查找。

```cpp
class Bitmap {
private:
    unsigned char * M;
    Rank N, _sz;
public:
    Bitmap( Rank n = 8 )
        { M = new unsigned char[ N = (n+7)/8 ]; memset( M, 0, N ); _sz = 0; }
    ~Bitmap() { delete [] M; M = NULL; _sz = 0; }
    void set( int k ); void clear( int k ); bool test( int k );
};
```
可以精简到就用1位表示true/false，这样一个8位的`unsigned char`就可以表示8个元素。

```cpp
bool test (int k) { expand( k ); return M[ k >> 3 ] & ( 0x80 >> (k & 0x07) ); }
void set (int k) { expand( k ); _sz++; M[ k >> 3 ] |= ( 0x80 >> (k & 0x07) ); }
void clear(int k) { expand( k ); _sz--; M[ k >> 3 ] &= ~( 0x80 >> (k & 0x07) ); }
```
#figure(
  image("fig\向量\9.png", width: 80%),
  caption: "位图的实现"
)
利用掩码`0x80`，可以将`M[k >> 3]`的第`k & 0x07`（是模余8，找到掩码移位数）位取出来，然后与`M[k >> 3]`（是寻找到对应的8位`unsigned char`）进行与或非操作，从而实现对位的操作。
=== 应用

_小集合 + 大数据：`int A[n]`的元素均取自`[0, m)`，如何剔除其中的重复者？_

仿照`Vector::dedup()`改进版，先排序，再扫描$O(n log n + n)$。

但对于大规模的数据，即便能够申请到这么多空间，频繁的I/O也将导致整体效率的低下。

利用位图可以有$O(n + m)$的解决方法。

_Eratosthenes筛法：_

从2开始，将所有2的倍数划去；再从3开始，将所有3的倍数划去；再从5开始，将所有5的倍数划去；……。

```cpp
void Eratosthenes( Rank n, char * file ) {
    Bitmap B( n ); B.set( 0 ); B.set( 1 );
    for ( Rank i = 2; i < n; i++ )
        if ( ! B.test( i ) )
            for ( Rank j = 2*i; j < n; j += i )
                B.set( j );
    B.dump( file );
}
```
效率：不计内循环，外循环自身每次仅一次加法、两次判断，累计$O(n)$；内循环每次$O(n /i )$，由素数定理，外循环至多$n/(log n)$次，累计是$O(n log n)$。

优化：内循环的起点`2*i`可改作`i*i`；外循环的终止条件`i < n`可改作`i*i < n`。这样内循环每次迭代$O(max(1, n/i-i))$，外循环至多$sqrt(n)/(log sqrt(n))$次。
=== 快速初始化
`Bitmap`的构造函数中， 通过 `memset(M,0,N)` 统一清零，需要$O(n)$时间。成为位图最大的瓶颈。

有时，对于大规模的散列表， 初始化的效率直接影响到实际性能

例如：字符串中(后续章节讲到)`bc[]`表的构造算法， 需要 $O(|Sigma|+m) = O(s+m)$ 时间，若能省去`bc[]`表各项的初始化，则可严格地保证是 $O(m)$。

这时候可以用*校验环*策略：

将`B[]`拆分成一对等长向量： `Rank F[m], T[m], top = 0;`

构成校验环：`T[F[k]] == k & F[T[i]] == i`

#figure(
  image("fig\向量\10.png", width: 80%),
  caption: "校验环"
)

检验：
```cpp
bool Bitmap::test( Rank k ) { return (0 <= F[k]) && (F[k] < top) && (k == T[F[k]]); }
```

#figure(
  image("fig\向量\11.png", width: 80%),
  caption: "校验环——检验"
)

复位：$O(1)$
```cpp
void Bitmap::reset() { top = 0; }
```

插入：$O(1)$
```cpp
void Bitmap::set( Rank k ) { if ( !test( k ) ) { T[top] = k; F[k] = top++; } }
```
#figure(
  image("fig\向量\12.png", width: 80%),
  caption: "校验环——插入"
)

删除：$O(1)$
```cpp
void Bitmap::clear( Rank k )
{ if ( test( k ) && ( --top ) ) { F[T[top]] = F[k]; T[F[k]] = T[top]; } }
```
#figure(
  image("fig\向量\13.png", width: 80%),
  caption: "校验环——删除"
)
删除的时候将最后一个元素放到被删除元素的位置，然后更新校验环。