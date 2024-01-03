= 列表List

根据是否修改数据结构，所有操作大致分为两类方式
- 静态： 仅读取，数据结构的内容及组成一般不变：`get`、`search`
- 动态： 需写入，数据结构的局部或整体将改变： `put`、`insert`、`remove`

与操作方式相对应地，数据元素的存储与组织方式也分为两种
- 静态：数据空间整体创建或销毁
  
  数据元素的物理次序与其逻辑次序严格一致；可支持高效的静态操作；比如向量，元素的物理地址与其逻辑次序线性对应
- 动态：为各数据元素动态地分配和回收的物理空间
  
  相邻元素记录彼此的物理地址，在逻辑上形成一个整体；可支持高效的动态操作

列表（`list`）是采用动态储存策略的典型结构
- 其中的元素称作节点（`node`），通过指针或引用彼此联接
- 在逻辑上构成一个线性序列
- 相邻节点彼此互称前驱（`predecessor`）或后继（`successor`）
- 没有前驱/后继的节点称作首（`first/front`） /末（`last/rear`）节点
- 循位置访问(call by position)

*`ListNode`接口*
```cpp
pred() / succ() // 当前节点前驱/后继节点的位置
data() // 当前节点所存数据对象
insertAsPred() / insertAsSucc() // 插入前驱/后继节点，返回新节点位置
```

```cpp
template <typename T> using ListNodePosi = ListNode<T>*; //列表节点位置（C++.0x）
template <typename T> struct ListNode { //简洁起见，完全开放而不再严格封装
    T data; //数值
    ListNodePosi<T> pred; //前驱
    ListNodePosi<T> succ; //后继
    ListNode() {} //针对header和trailer的构造
    ListNode(T e, ListNodePosi<T> p = NULL, ListNodePosi<T> s = NULL)
      : data(e), pred(p), succ(s) {} //默认构造器
    ListNodePosi<T> insertAsPred( T const & e ); //前插入
    ListNodePosi<T> insertAsSucc( T const & e ); //后插入
};
```

*`List`接口*
```cpp
size() / empty() // 报告节点总数 / 判定是否为空 列表
first() / last() // 返回首 / 末节点的位置 列表
insertAsFirst(e) / insertAsLast(e) // 将e当作首 / 末节点插入 列表
insert(p, e), insert(e, p) // 将e当作节点p的直接后继、 前驱插入 列表
remove(p) // 删除节点p 列表
sort(p, n) / sort() // 区间 / 整体排序 列表
find(e, n, p) / search(e, n, p) // 在指定区间内查找目标e 列表 / 有序列表
dedup() / uniquify() // 剔除重复节点 列表 / 有序列表
traverse( visit() ) // 遍历列表，统一按visit()处理所有节点 列表
```

```cpp
template <typename T> class List { //列表模板类
private: Rank _size; ListNodePosi<T> header, trailer; //哨兵
//头、 首、 末、 尾节点的秩， 可分别理解为-1、 0、 n-1、 n
protected: /* ... 内部函数 */
public: /* ... 构造函数、析构函数、只读接口、可写接口、遍历接口 */
};
```

*构造*

```cpp
template <typename T> void List<T>::init() { //初始化，创建列表对象时统一调用
    header = new ListNode<T>;
    trailer = new ListNode<T>;
    header->succ = trailer; header->pred = NULL;
    trailer->pred = header; trailer->succ = NULL;
    _size = 0;
}
```

*访问*：重载下标操作符，可模仿向量的循秩访问方式
```cpp
template <typename T> //O(r)效率，虽方便，勿多用
ListNodePosi<T> List<T>::operator[]( Rank r ) const { //0 <= r < size
    ListNodePosi<T> p = first(); //从首节点出发
    while ( 0 < r-- ) p = p->succ; //顺数第r个节点即是
    return p; //目标节点
} //秩 == 前驱的总数
```
时间复杂度为$O(r)$，均匀分布时期望为$O(n)$。
== 无序列表
=== 插入与删除

实现是容易的，就是修改指针指向的问题，但是要注意的是，插入的时候，要先修改前驱的后继，再修改后继的前驱，删除的时候，先修改前驱的后继，再修改后继的前驱，最后删除节点。


通过重载性质，直接从函数声明上区分前插入、后插入
```cpp
template <typename T> ListNodePosi<T> List<T>:: //e当作p的前驱插入
insert(T const & e, ListNodePosi<T> p) { _size++; return p->insertAsPred( e ); }

template <typename T> //前插入算法（后插入算法完全对称）
ListNodePosi<T> ListNode<T>::insertAsPred( T const & e ) { //O(1)
    ListNodePosi<T> x = new ListNode( e, pred, this ); //创建
    pred->succ = x; pred = x; //次序不可颠倒
    return x; //建立链接，返回新节点的位置
} //得益于哨兵，即便this为首节点亦不必特殊处理——此时等效于insertAsFirst(e)
```

```cpp
template <typename T> T List<T>::remove( ListNodePosi<T> p ) { //删除合法节点p
    T e = p->data; //备份待删除节点存放的数值（设类型T可直接赋值）
    p->pred->succ = p->succ; p->succ->pred = p->pred; //短路联接
    delete p; _size--; return e; //返回备份的数值
} //O(1)
```
=== 构造与析构

`copyNodes()` + 构造
```cpp
template <typename T> void List<T>::copyNodes( ListNodePosi<T> p, Rank n ) { //O(n)
    init(); //创建头、尾哨兵节点并做初始化
    while ( n-- ) { //将起自p的n项依次作为末节点
        insertAsLast( p->data ); //插入
        p = p->succ;
    }
}

List<T>::List( List<T> const & L ) { copyNodes( L.first(), L._size ); }
```
`clear()` + 析构
```cpp
template <typename T> List<T>::~List() //列表析构
{ clear(); delete header; delete trailer; } //清空列表，释放头、尾哨兵节点

template <typename T> Rank List<T>::clear() { //清空列表
    Rank oldSize = _size;
    while ( 0 < _size ) //反复
    remove( header->succ ); //删除首节点， O(n)
    return oldSize;
}
```

#figure(
  image("fig\列表\1.jpg", width: 80%),
  caption: "列表的构造与析构",
)

=== 查找与去重

无序的查找也只能$O(n)$。

```cpp
template <typename T> //0 <= n <= rank(p) < _size
ListNodePosi<T> List<T>::find( T const & e, Rank n, ListNodePosi<T> p ) const {
    while ( 0 < n-- ) //自后向前
        if ( e == ( p = p->pred ) ->data ) //逐个比对（假定类型T已重载“==”）
            return p; //在p的n个前驱中，等于e的最靠后者
    return NULL; //失败
} //O(n)

template <typename T>
ListNodePosi<T> find( T const & e ) const { return find( e, _size, trailer ); }
```

去重
```cpp
template <typename T> Rank List<T>::dedup() {
    Rank oldSize = _size;
    ListNodePosi<T> p = first();
    for ( Rank r = 0; p != trailer; p = p->succ ) //O(n)
        if ( ListNodePosi<T> q = find( p->data, r, p ) ) //O(n)
            remove ( q );
        else
            r++; //无重前缀的长度
    return oldSize - _size; //删除元素总数
} //正确性及效率分析的方法与结论，与Vector::dedup()相同
```
=== 遍历

一样地，利用函数对象或者函数指针。
```cpp
template <typename T> void List<T>::traverse( void ( * visit )( T & ) )
{ for( NodePosi<T> p = header->succ; p != trailer; p = p->succ ) visit( p->data ); }

template <typename T> template <typename VST> void List<T>::traverse( VST & visit )
{ for( NodePosi<T> p = header->succ; p != trailer; p = p->succ ) visit( p->data ); }
```

== 有序列表
=== 唯一化

直接一趟线性扫描即可，时间复杂度为$O(n)$。
```cpp
template <typename T> Rank List<T>::uniquify() {
    if ( _size < 2 ) return 0; //平凡列表自然无重复
    Rank oldSize = _size; //记录原规模
    ListNodePosi<T> p = first(); ListNodePosi<T> q; //各区段起点及其直接后继
    while ( trailer != ( q = p->succ ) ) //反复考查紧邻的节点对(p,q)
        if ( p->data != q->data ) p = q; //若互异，则转向下一对
        else remove(q); //否则（雷同） 直接删除后者， 不必如向量那样间接地完成删除
    return oldSize - _size; //规模变化量，即被删除元素总数
} //只需遍历整个列表一趟， O(n)
```
=== 查找

`search`相较于`find`，在有序结构中，约定语义，希望能返回失败的位置，例如返回失败时左边界的前驱。
```cpp
template <typename T> //在有序列表内节点p的n个真前驱中，找到不大于e的最靠后者
ListNodePosi<T> List<T>::search( T const & e, Rank n, ListNodePosi<T> p ) const {
    do { //初始有： 0 <= n <= rank(p) < _size；此后， n总是等于p在查找区间内的秩
        p = p->pred; n--; //从右向左
    } while ( ( -1 != n ) && ( e < p->data ) ); //逐个比较，直至越界或命中
    return p; //最终停止的位置； 失败时为区间左边界的前驱（可能就是header）
} //调用者可据此判断查找是否成功
```
最好$O(1)$，最坏$O(n)$；等概率时平均$O(n)$，正比于区间宽度。

== 选择排序Selection Sort

对于起泡排序，每次的效果是将最大的元素放到最后。不必经历那么多循环，直接找到最大的元素，放到最后即可。

```cpp
template <typename T> void List<T>::selectionSort( ListNodePosi<T> p, Rank n ) {
    ListNodePosi<T> head = p->pred, tail = p;
    for ( Rank i = 0; i < n; i++ ) tail = tail->succ; //待排序区间为(head, tail)
    while ( 1 < n ) { //反复从（非平凡）待排序区间内找出最大者，并移至有序区间前端
        insert( remove( selectMax( head->succ, n ) ), tail ); //可能就在原地...
        tail = tail->pred; n--; //待排序区间、有序区间的范围，均同步更新
    }
}
```
#figure(
  image("fig\列表\2.png", width: 80%),
  caption: "选择排序",
)

只能线性搜索，向前试探
```cpp
template <typename T> //从起始于位置p的n个元素中选出最大者， 1 < n
ListNodePosi<T> List<T>::selectMax( ListNodePosi<T> p, Rank n ) { //Θ(n)
    ListNodePosi<T> max = p; //最大者暂定为p
    for ( ListNodePosi<T> cur = p; 1 < n; n-- ) //后续节点逐一与max比较
        if ( ! lt( (cur = cur->succ)->data, max->data ) ) //data  max
            max = cur; //则更新最大元素位置记录
    return max; //返回最大节点位置
}
```
*稳定性*：有多个元素同时命中时，约定返回其中特定的某一个（比如最靠后者）。若采用平移法，如此即可保证，重复元素在列表中的相对次序，与其插入次序一致。

复杂度是$Theta(n^2)$，但是比起起泡排序，减少了交换次数，因此效率更高。如果采用堆优化，可以将复杂度降低到$O(n log n)$，但是丧失了稳定性。

== 插入排序Insertion Sort

始终将序列视作两部分：
- 前缀 `S[0, r)`：有序
- 后缀 `U[r, n)`：待排序
初始化： `|S| = r = 0`

反复地，针对`e = A[r]`
- 在`S`中查找适当位置
- 插入`e`
- `r ++`

#figure(
  image("fig\列表\3.png", width: 80%),
  caption: "插入排序",
)
核心想法是减而之治。

```cpp
template <typename T> void List<T>::insertionSort( ListNodePosi<T> p, Rank n ) {
    for ( Rank r = 0; r < n; r++ ) { //逐一引入各节点，由Sr得到Sr+1
        insert( search( p->data, r, p ), p->data ); //查找 + 插入
        p = p->succ; remove( p->pred ); //转向下一节点
    } //n次迭代， 每次O(r + 1)
} //仅使用O(1)辅助空间，属于就地算法
```
- 得益于此前约定的`search()`接口语义，前缀的确总是保持有序，而且*稳定*
- 复杂度，最好$O(n)$，最坏$O(n^2)$，平均：

    若前缀已经有序，对于随机的下一个元素，插入位置是均等的，则有
    $
    1 + sum_(k=0)^r k/(r+1) = 1 + 1/(r+1)
    $
    从而总体复杂度是$O(n^2)$。
- 可简明度量有序/乱序的程度与时间成本之成正比
- 输入敏感性/input-sensitivity
- *在线*online：在数据完全就绪之前，即可开始计算

== 归并排序Merge Sort

就像向量中的二路归并排序一样，将列表分为两部分，分别排序，然后合并。

```cpp
template <typename T> void List<T>::mergeSort( ListNodePosi<T> & p, Rank n ) {
    if ( n < 2 ) return; //待排序范围足够小时直接返回，否则...
    ListNodePosi<T> q = p; Rank m = n >> 1; //以中点为界
    for ( Rank i = 0; i < m; i++ ) q = q->succ; //均分列表： O(m) = O(n)
    mergeSort( p, m ); mergeSort( q, n – m ); //子序列分别排序
    p = merge( p, m, *this, q, n – m ); //归并
} //若归并可在线性时间内完成，则总体运行时间亦为O(nlogn)
```

```cpp
template <typename T> ListNodePosi<T> //this.[p +n) & L.[q +m)：归并排序时， L == this
List<T>::merge( ListNodePosi<T> p, Rank n, List<T>& L, ListNodePosi<T> q, Rank m ) {
    ListNodePosi<T> pp = p->pred; //归并之后p或不再指向首节点，故需先记忆，以便返回前更新
    while ( ( 0 < m ) && ( q != p ) ) //小者优先归入
        if ( ( 0 < n ) && ( p->data <= q->data ) ) { p = p->succ; n--; } //p直接后移
        else { insert( L.remove( ( q = q->succ )->pred ) , p ); m--; } //q转至p之前
    return pp->succ; //更新的首节点
} //运行时间O(n + m)，线性正比于节点总数
```
良好的搜索语义保证了*稳定性*。

== 游标实现

有些语言不支持指针类型，可以利用线性数组，以游标方式模拟列表
- elem[]：对外可见的数据项
- link[]：数据项之间的引用
维护逻辑上互补的列表data和free

下图中`data`箭头所指的地方是列表的头，`free`箭头所指的地方是空闲的头。其左侧`elem[]`对应的指针就是他的后继。

#figure(
  image("fig\列表\4.png", width: 80%),
  caption: "游标实现",
)

#figure(
  image("fig\列表\5.png", width: 80%),
  caption: "游标实现",
)

#figure(
  image("fig\列表\6.png", width: 80%),
  caption: "游标实现",
)

#figure(
  image("fig\列表\7.png", width: 80%),
  caption: "游标实现",
)