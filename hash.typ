= 词典Dictionary

我们希望可以通过*寻对象访问*键值对，这就是字典的想法。

```cpp
template <typename K, typename V> //key、 value
struct Dictionary {
    virtual Rank size() = 0;
    virtual bool put( K, V ) = 0;
    virtual V* get( K ) = 0;
    virtual bool remove( K ) = 0;
};
```
字典定义了接口（如获取、设置、删除键值对），而下面的散列和跳表提供了这些接口的具体实现。

哈希表通常提供更快的查找、插入和删除操作，但它们不支持有序键的高效操作。跳表提供有序存储和范围查询的能力，但在某些操作上可能不如哈希表高效。

== 散列Hashtable
对于在很大范围$R$中的词条，但是往往只会用到其中的一小部分$N$，如果利用数组就会造成空间的浪费，因此可以利用散列。通过Hash函数，将关键字映射到表中一个位置来访问记录，以加快查找速度。

利用桶（规模为$M$）直接存放或间接指向一个词条。利用散列函数$"hash"(k)$将词条关键码$k$转换为桶号，然后将词条存入桶中。如果两个词条的关键码相同，就会发生冲突，可以通过开放定址法、链地址法、再散列法等解决冲突。

这样一来，查找、插入、删除的*期望*复杂度是$O(1)$。
=== 冲突

冲突是指两个不同的关键码被映射到同一个桶中。当装填因子$lambda=N/M$越大，冲突越多，查找效率越低。

如果数据集固定且已知，可以实现完美散列，关键码不存在冲突。一般而言，要选取合适的散列函数，使得冲突尽可能少。
== 散列函数Hash Function

散列函数的设计要求：
- 确定：对于同一个关键码，散列函数应该总是返回同一个值
- 快速：计算散列函数的时间应该尽可能短$O(1)$
- 满射：充分利用散列空间
- 均匀：散列函数应该尽可能地将关键码均匀地散列到各个桶中，避免聚集现象
=== 除余法

$ "hash"(k)=k\%M $
非理想随机的时候，$M$选取素数更好。

缺陷：
- 不论表长$M$怎么取，都有$"hash"(0)=0$
- 相邻关键码散列地址也相邻
=== MAD法：Multiply-Add-Divide

$ "hash"(k)=(a k+b)\%M $
=== 其他散列函数

- 数字分析：选取关键码中的一部分作为散列地址
- 平方取中法：取关键码平方后的中间几位作为散列地址
- 折叠法：将关键码分割成几部分，然后将这几部分叠加起来作为散列地址
- 位异或法：将关键码的各个部分进行异或运算，得到的值作为散列地址
=== 随机数

伪随机数算法：`rand( x + 1 ) = [ a * rand( x ) ] % M //M素数， a % M != 0`
```cpp
unsigned long int next = 1; //sizeof(long int) = 8
void srand(unsigned int seed) { next = seed; } //sizeof(int) = 4 or 8
int rand(void) { //1103515245 = 3^5 * 5 * 7 * 129749
    next = next * 1103515245 + 12345;
    return (unsigned int)(next/65536) % 32768;
}
```
从而
$"hash"("key") = "rand"("key") = ("rand"(0) a^"key") % M $
这样生成的结果是理想随机的。
=== hashCode与多项式法

比较好的一种由字符串生成散列地址的方法是多项式法，即将字符串看作是一个多项式，然后将多项式的值作为散列地址。
```cpp
static Rank hashCode( char s[] ) {
Rank n = strlen(s); Rank h = 0;
    for ( Rank i = 0; i < n; i++ ) {
        h = (h << 5) | (h >> 27);
        h += s[i];
    } //乘以32，加上扰动，累计贡献
return h;
}
```

== 冲突解决：开放散列

开放散列是指当发生冲突时，不是将词条放入桶中，而是将词条放入其他的桶中。
=== 多槽位

将每个桶扩展为一个槽位数组，每个槽位存放一个词条。当发生冲突时，依次检查槽位，直到找到一个空槽位，然后将词条放入其中。如果槽位数组满了，就需要扩容。

缺点是空间浪费，并且仍有情况需要一直扩容，不可控。
=== 公共溢出区Overflow Area
开辟一块连续空间，发生冲突的词条都放入其中。查找时，先在桶中查找，如果没有，再在溢出区查找。同一个关键码给出的词条用指针串起来。

缺点是溢出区查找效率低。
=== 独立链Linked-List Chaining / Separate Chaining

将每个桶扩展为一个链表，每个槽位存放一个链表的头结点。当发生冲突时，将词条插入到链表中。查找时，先在桶中查找，如果没有，再在链表中查找。

缺点是空间未必连续分布、系统缓存很难生效，并且节点的动态分配和释放会带来额外的开销。
== 冲突解决：封闭散列

只要有必要，任何散列桶都可以接纳任何词条；为每个词条，都需事先约定若干备用桶，优先级逐次下降。沿试探链（Probe Sequence/Chain），逐个转向下一桶单元，直到命中成功，或者抵达一个空桶而失败。
=== 线性试探Linear Probing

一旦冲突，则试探后一紧邻的桶，直到命中（成功），或抵达空桶（失败）。

新增非同义词之间的冲突，数据堆积（clustering）现象严重。但试探链连续，数据局部性良好，通过装填因子，冲突与堆积都可有效控制。

*插入：*新词条若尚不存在，则存入试探终止处的空桶。

*懒惰删除：*若词条存在，则将其标记为“已删除”，而非立即删除，以免破坏试探链。(_空宅与故居_)

```cpp
template <typename K, typename V> int Hashtable<K, V>::probe4Hit(const K& k) {
    int r = hashCode(k) % M; //按除余法确定试探链起点
    while ( ( ht[r] && (k != ht[r]->key) ) || removed->test(r) )
        r = ( r + 1 ) % M; //线性试探（跳过带懒惰删除标记的桶）
return r; //调用者根据ht[r]是否为空及其内容，即可判断查找是否成功
}
template <typename K, typename V> int Hashtable<K, V>::probe4Free(const K& k) {
    int r = hashCode(k) % M; //按除余法确定试探链起点
    while ( ht[r] ) r = (r + 1) % M; //线性试探，直到空桶（无论是否带有懒惰删除标记）
return r; //只要有空桶，线性试探迟早能找到
}
```
查找时，若遇到“已删除”标记，则继续试探下一桶。插入时，若遇到“已删除”标记，则将词条存入此处，而非继续试探下一桶。

*重散列：*装填因子过大时，重散列操作将桶数组容量倍增，同时将已有词条逐一移动到新桶中，以期平摊试探成本。

*填装因子的计算：*$lambda = N/M$，其中$N$为词条总数，$M$为桶数组容量。是一定要把懒惰删除词条减掉，才能统计真正有多少桶被占用了。

```cpp
template <typename K, typename V> //随着装填因子增大，冲突概率、排解难度都将激增
void Hashtable<K, V>::rehash() { //此时，不如“集体搬迁”至一个更大的散列表
int oldM = M; Entry<K, V>** oldHt = ht;
ht = new Entry<K, V>*[ M = primeNLT( 4 * N ) ]; N = 0; //新表“扩”容
memset( ht, 0, sizeof( Entry<K, V>* ) * M ); //初始化各桶
release( removed ); removed = new Bitmap(M); L = 0; //懒惰删除标记
for ( int i = 0; i < oldM; i++ ) //扫描原表
    if ( oldHt[i] ) //将每个非空桶中的词条
        put( oldHt[i]->key, oldHt[i]->value ); //转入新表
release( oldHt ); //释放——因所有词条均已转移，故只需释放桶数组本身
}
```
插入
```cpp
template <typename K, typename V> bool Hashtable<K, V>::put( K k, V v ) {
    if ( ht[ probe4Hit( k ) ] ) return false; //雷同元素不必重复插入
    int r = probe4Free( k ); //为新词条找个空桶（只要装填因子控制得当，必然成功）
    ht[ r ] = new Entry<K, V>( k, v ); ++N; //插入
    if ( removed->test( r ) ) { removed->clear( r ); --L; } //懒惰删除标记
    if ( (N + L)*2 > M ) rehash(); //若装填因子高于50%，重散列
return true;
}
```
删除
```cpp
template <typename K, typename V> bool Hashtable<K, V>::remove( K k ) {
    int r = probe4Hit( k ); if ( !ht[r] ) return false; //确认目标词条确实存在
    release( ht[r] ); ht[r] = NULL; --N; //清除目标词条
    removed->set(r); ++L; //更新标记、计数器
    if ( 3*N < L ) rehash(); //若懒惰删除标记过多，重散列
return true;
}
```
=== 双向平方试探Quadratic Probing
试探链改成平方试探，即每次试探的步长为$1^2, 2^2, 3^2, \cdots$，而不是$1, 2, 3, \cdots$。这样可以避免线性试探中的堆积现象。但这样试探链不会遍历完全剩余系，$M$是素数的时候，只会有$ceil(M/2)$被取到。

为了可以遍历完全剩余系，取$M$是模4余3的素数，这样它的正负平方可以遍历完全剩余系。而模4余1的素数，它的正负平方只能遍历到一半。
== 桶排序Bucket sort

对于$(0,m]$的整数，可以借助散列表排序。

将他们存入散列表，然后依次遍历散列表，将非空桶中的词条按照关键码顺序输出。

也可以存在同义词，同义词再进行排序即可（每个桶表示一个区间，每次将元素插入对应的桶中）。同义词可以用链表储存。可以保存存入的次序，这对后面的基数排序有作用。这被称为*稳定性*。
=== 例：MaxGap

任意n个互异点均将实轴分为n-1段有界区间，其中的哪一段最长？

线性算法：
+ 找到最左点、最右点 $O(n)$
+ 将有效范围均匀地划分为$n-1$段（$n$个桶） $O(n)$
+ 通过散列，将各点归入对应的桶 $O(n)$
+ 在各桶中，动态记录最左点、最右点 $O(n)$
+ 算出相邻（非空）桶之间的“距离” $O(n)$
+ 最大的距离即MaxGap
== 基数排序Radix Sort

词典排序（lexicographic order）：自$k_1$到$k_t$（低位优先），依次以各域为序做一趟桶排序。

时间成本是$O(t(n+M))$，其中$M$是基数，$t$是关键码的个数。

```cpp
typedef unsigned int U; //约定：类型T或就是U；或可转换为U，并依此定序

template <typename T> void List<T>::radixSort( ListNodePosi<T> p, int n ) {
    ListNodePosi<T> head = p->pred; ListNodePosi<T> tail = p;
    for ( int i = 0; i < n; i++ ) tail = tail->succ; //待排序区间为(head, tail)
    for ( U radixBit = 0x1; radixBit && (p = head); radixBit <<= 1 ) //以下反复地
    for ( int i = 0; i < n; i++ ) //根据当前基数位，将所有节点
        radixBit & U (p->succ->data) ? //分拣为前缀（0）与后缀（1）
            insert( remove( p->succ ), tail ) : p = p->succ;
} //为避免remove()、 insert()的低效率，可拓展List::move(p,tail)接口， 将节点p直接移至tail之前
```
== 计数排序Counting Sort

基数排序中反复做的桶排序，亦属“小集合 + 大数据”类型，是否可以更快。计数排序可以优化基数排序中的桶排序。

仍以纸牌排序为例（$n >> m =4$）。假设已按点数排序，以下（稳定地）按花色排序。

+ 经过分桶， 统计出各种花色的数量。
+ 自前向后扫描各桶，依次累加即可确定各套花色所处的秩区间。
+ 自后向前扫描每一张牌，对应桶的计数减一，即是其在最终有序序列中对应的秩。

该方法的时间复杂度是$O(n+m)$，但是需要额外的空间。
== 跳转表Skiplist

#figure(
    image("fig\词典\1.png",width: 80%),
    caption: "跳转表"
)

跳转表是一种特殊的链表，它的每个节点都有一个指向下一个节点的指针，也有一个指向下一层的指针。这样一来，可以在每一层中进行二分查找，然后跳转到下一层，再进行二分查找，直到最后一层。

跳转表的查找时间复杂度是$O(log n)$，插入和删除的时间复杂度是$O(log n)$。

先定义四联节点，包括前驱、后继、上邻、下邻。
```cpp
template <typename T> using QNodePosi = QNode<T>*; //节点位置
template <typename T> struct QNode { //四联节点
    T entry; //所存词条
    QNodePosi<T> pred, succ, above, below; //前驱、后继、上邻、下邻
    QNode( T e = T(), QNodePosi<T> p = NULL, QNodePosi<T> s = NULL, QNodePosi<T> a = NULL, QNodePosi<T> b = NULL ) //构造器
        : entry(e), pred(p), succ(s), above(a), below(b) {}
    QNodePosi<T> insert( T const& e, QNodePosi<T> b = NULL ); //将e作为当前节点的后继、 b的上邻插入
};
```
由四联节点构成四联表，作为跳转表的一层。
```cpp
template <typename T> struct Quadlist { //四联表
    Rank _size; //节点总数
    QNodePosi<T> header, trailer; //头、尾哨兵
    void init(); int clear(); //初始化、 清除
    Quadlist() { init(); } //构造
    ~Quadlist() { clear(); delete header; delete trailer; } //析构
    T remove( QNodePosi<T> p ); //删除p
    QNodePosi<T> insert( T const & e, QNodePosi<T> p, QNodePosi<T> b = NULL );//将e作为p的后继、 b的上邻插入
};
```
从四联表和字典继承到跳转表。
```cpp
template < typename K, typename V > struct Skiplist : public Dictionary<K, V>, public List< Quadlist< Entry<K, V> >* > {
    Skiplist() { insertAsFirst( new Quadlist< Entry<K, V> > ); }; //至少有一层空列表
    QNodePosi< Entry<K, V> > search( K ); //由关键码查询词条
    Rank size() { return empty() ? 0 : last()->data->size(); } //词条总数
    Rank height() { return List::size(); } //层高，即Quadlist总数
    bool put( K, V ); //插入（Skiplist允许词条重复，故必然成功）
    V * get( K ); //读取
    bool remove( K ); //删除
};
```
=== 性能

空间上，各层塔高符合几何分布：$P_i = (1/2)^i$，塔高的期望是$2$。故总空间复杂度为$O(n)$。
=== 插入与删除

先查询到插入的位置，在紧邻右边的位置建塔。

```cpp
template <typename K, typename V> bool Skiplist<K, V>::put( K k, V v ) {
    Entry< K, V > e = Entry< K, V >( k, v ); //待插入的词条（将被同一塔中所有节点共用）
    QNodePosi< Entry<K, V> > p = search( k ); //查找插入位置： 新塔将紧邻其右，逐层生长
    ListNodePosi< Quadlist< Entry<K, V> >* > qlist = last(); //首先在最底层
    QNodePosi< Entry<K, V> > b = qlist->data->insert( e, p ); //创建新塔的基座
    while ( rand() & 1 ) {  //经投掷硬币，若新塔需再长高， 则
        /* ... 建塔 ... */
        while ( p->pred && !p->above ) p = p->pred; //找出不低于此高度的最近前驱
        if ( !p->pred && !p->above ) { //若该前驱是header，且已是最顶层，则
            insertAsFirst( new Quadlist< Entry<K, V> > ); //需要创建新的一层
            first()->data->header->below = qlist->data->header;
            qlist->data->header->above = first()->data->header;
        }
        p = p->above; qlist = qlist->pred; //上升一层，并在该层
        b = qlist->data->insert( e, p, b ); //将新节点插入p之后、 b之上
    }
    return true; //Dictionary允许重复元素，故插入必成功
} //体会：得益于哨兵的设置，哪些环节被简化了？
```
建塔时，每上升一层，都要重新组织指针，并且决定是否向上一层是随机的。

删除时，先查询到删除的位置，然后逐层删除。
```cpp
template <typename K, typename V> bool Skiplist<K, V>::remove( K k ) {
    /* ... 1. 预备 ... */
    QNodePosi< Entry<K, V> > p = search( k ); //查找目标词条
    if ( !p->pred || (k != p->entry.key) ) return false; //若不存在，直接返回
    ListNodePosi< Quadlist< Entry<K, V> >* > qlist = last(); //从底层Quadlist开始
    while ( p->above ) { qlist = qlist->pred; p = p->above; } //升至塔顶
    /* ... 2. 拆塔 ... */
    do { QNodePosi< Entry<K, V> > lower = p->below; //记住下一层节点，并
        qlist->data->remove( p ); //删除当前层节点，再
        p = lower; qlist = qlist->succ; //转入下一层
    } while ( qlist->succ ); //直到塔基
    /* ... 3. 删除空表 ... */
    while ( (1 < height()) && (first()->data->_size < 1) ) { //逐层清除
        List::remove( first() );
        first()->data->header->above = NULL;
    } //已不含词条的Quadlist（至少保留最底层空表）
    return true; //删除成功
} //体会：得益于哨兵的设置，哪些环节被简化了？
```
=== 查找

跳转表的查找从左边的塔顶开始，如果当前节点的后继是空，或者后继的关键码大于目标关键码，就向下一层。如果当前节点的后继的关键码等于目标关键码，就返回当前节点的后继。

```cpp
template <typename K, typename V> //关键码不大于k的最后一个词条（所对应塔的基座）
    QNodePosi< Entry<K, V> > Skiplist<K, V>::search( K k ) {
    for ( QNodePosi< Entry<K, V> > p = first()->data->header; ; ) //从顶层的首节点出发
        if ( (p->succ->succ) && (p->succ->entry.key <= k) ) p = p->succ; //尽可能右移
        else if ( p->below ) p = p->below; //水平越界时， 下移
        else return p; //验证：此时的p符合输出约定（可能是最底层列表的header）
} //体会：得益于哨兵的设置，哪些环节被简化了？
```

比较复杂的是估算该过程的复杂度。

跳转分为横向跳转和纵向跳转。

先分析纵向跳转。对于跳表高度，随着$k$的增加，第$k$层为空的概率急剧上升$P(|S_k|=0)=(1-p^k)^n$。从而跳表高度的期望是$O(log n)$的，从而纵向跳转的期望是$O(log n)$的。

再分析横向跳转。可以注意到在同一水平列表中，横向跳转所经节点必然依次紧邻，而且每次抵达都是塔顶。塔的高度理想随机，沿同一层跳转的次数呈几何分布。从而每个高度横向跳转的期望是$O(1)$的。

综上，跳转表的查找时间复杂度是$O(log n)$。