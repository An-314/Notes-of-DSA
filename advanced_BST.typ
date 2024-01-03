= 高级BST
== 伸展树Splay Tree
=== 局部性/Locality

时间：刚被访问过的节点，极有可能很快地再次被访问

空间：下一将要访问的节点，极有可能就在刚被访问过节点的附近

AVL连续的m次查找（m >> n），共需$O(m log n)$时间，希望可以利用局部性加速。

- 自适应链表：节点一旦被访问，随即移动到最前端
- 模仿：希望BST的节点一旦被访问，随即调整到树根

如果节点被访问，就将其旋转到根节点，这样下次访问时，就可以直接访问到了。
=== 逐层伸展
#figure(
  image("fig\BST\33.png", width: 80%),
  caption: "逐层伸展"
)

但这样很有可能导致树的不平衡，比如下面的例子：

#figure(
  image("fig\BST\34.png", width: 80%),
  caption: "逐层伸展——最坏情况"
)
=== 双层伸展

向上追溯两层，而非一层。

反复考察祖孙三代：`g = parent(p), p = parent(v), v`。根据它们的相对位置，经两次旋转，使`v`上升两层，成为（子）树根。

*zig-zag/zag-zig*

#figure(
  image("fig\BST\35.png", width: 80%),
  caption: "双层伸展——情形1"
)

对于`v`是`p`的左孩子，`p`是`g`的右孩子的情况，先对`p`进行一次旋转，再对`v`进行一次旋转。

这样的效果事实上和逐层旋转是一样的。

*zig-zig/zag-zag*

#figure(
  image("fig\BST\36.png", width: 80%),
  caption: "双层伸展——情形2"
)

但是如果是`v`是`p`的左孩子，`p`是`g`的左孩子的情况，两种旋转方式就有区别。

连续两次旋转根节点（上图下面的旋转方法），可以使得`v`上升两层，成为（子）树根。

这种情况下，节点访问之后，对应路径的长度随即折半。最坏情况不致持续发生。

伸展操作分摊下来，仍然是$O(log n)$的。

#figure(
  image("fig\BST\37.png", width: 80%),
  caption: "双层伸展——情形2"
)

*zig/zag*

如果`v`只有父亲，没有祖父，此时必有`v.parent() == T.root()`，只做一次旋转即可。只会出现在最后一次。
=== 算法实现

接口
```cpp
template <typename T> class Splay : public BST<T> { //由BST派生
protected:
    BinNodePosi<T> splay( BinNodePosi<T> v ); //将v伸展至根
public: //伸展树的查找也会引起整树的结构调整，故search()也需重写
    BinNodePosi<T> & search( const T & e ); //查找（重写）
    BinNodePosi<T> insert( const T & e ); //插入（重写）
    bool remove( const T & e ); //删除（重写）
};
```
伸展算法
```cpp
template <typename T> BinNodePosi<T> Splay<T>::splay( BinNodePosi<T> v ) {
    if ( ! v ) return NULL; BinNodePosi<T> p; BinNodePosi<T> g; //父亲、祖父
    while ( (p = v->parent) && (g = p->parent) ) {
    /* 自下而上， 反复地双层伸展 */
    }
    if ( p = v->parent ) { /* 若p果真是根，只需再额外单旋一次 */ }
    v->parent = NULL; return v; //伸展完成， v抵达树根
}
```
填充上面的空白，得到伸展算法的实现。
```cpp
while ( (p = v->parent) && (g = p->parent) ) { //自下而上，反复双层伸展
    BinNodePosi<T> gg = g->parent; //每轮之后， v都将以原曾祖父为父
    if ( IsLChild( * v ) )
        if ( IsLChild( * p ) ) { /* zig-zig */ } else { /* zig-zag */ }
    else
        if ( IsRChild( * p ) ) { /* zag-zag */ } else { /* zag-zig */ }
    if ( !gg ) v->parent = NULL; //无曾祖父gg的v即为树根；否则， gg此后应以v为
    else ( g == gg->lc ) ? attachAsLC(v, gg) : attachAsRC(gg, v); //左或右孩子
    updateHeight( g ); updateHeight( p ); updateHeight( v );
}
```
对于`zig-zig`的情况，有：
```cpp
if ( IsLChild( * v ) )
    if ( IsLChild( * p ) ) { //zIg-zIg
        attachAsLC( p->rc, g ); //Y
        attachAsLC( v->rc, p ); //X
        attachAsRC( p, g );
        attachAsRC( v, p );
    } else { /* zIg-zAg */ }
else
    if ( IsRChild( * p ) ) { /* zAg-zAg */ } else { /* zAg-zIg */ }
```
剩下情况类似，不再赘述。

查找算法。伸展树的查找，与常规`BST::search()`不同：很可能会改变树的拓扑结构，不再属于静态操作：
```cpp
template <typename T> BinNodePosi<T> & Splay<T>::search( const T & e ) {
// 调用标准BST的内部接口定位目标节点
    BinNodePosi<T> p = BST<T>::search( e );
// 无论成功与否，最后被访问的节点都将伸展至根
    _root = splay( p ? p : _hot ); //成功、失败
// 总是返回根节点
    return _root;
}
```

插入算法。`Splay::search()`已集成`splay()`，查找失败之后， `_hot`即是根，随即就在树根附近接入新节点。
```cpp
template <typename T> BinNodePosi<T> Splay<T>::insert( const T & e ) {
    if ( !_root ) { _size = 1; return _root = new BinNode<T>( e ); } //原树为空
    BinNodePosi<T> t = search( e ); if ( e == t->data ) return t; //t若存在，伸展至根
    if ( t->data < e ) { //在右侧嫁接（rc或为空， lc == t必非空）
        t->parent = _root = new BinNode<T>( e, NULL, t, t->rc );
        if ( t->rc ) { t->rc->parent = _root; t->rc = NULL; }
    } else { //e < t->data，在左侧嫁接（lc或为空， rc == t必非空）
        t->parent = _root = new BinNode<T>( e, NULL, t->lc, t );
        if ( t->lc ) { t->lc->parent = _root; t->lc = NULL; }
    }
    _size++; updateHeightAbove( t ); return _root; //更新规模及t与_root的高度，插入成功
} //无论如何， 返回时总有_root->data == e
```

#figure(
  image("fig\BST\38.png", width: 80%),
  caption: "伸展树——插入"
)

删除算法。`Splay::search()`成功之后，目标节点即是树根，在树根附近完成目标节点的摘除。
```cpp
template <typename T> bool Splay<T>::remove( const T & e ) {
    if ( !_root || ( e != search( e )->data ) ) return false; //若目标存在，则伸展至根
    BinNodePosi<T> L = _root->lc, R = _root->rc; release(_root); //记下子树后，释放之
    if ( !R ) { //若R空
        if ( L ) L->parent = NULL; _root = L; //则L即是余树
    } else { //否则
        _root = R; R->parent = NULL; search( e ); //在R中再找e：注定失败， 但最小节点必
        if (L) L->parent = _root; _root->lc = L; //伸展至根， 故可令其以L作为左子树
    }
    _size--; if ( _root ) updateHeight( _root ); //更新记录
    return true; //删除成功
}
```

#figure(
  image("fig\BST\39.png", width: 80%),
  caption: "伸展树——删除"
)

*综合评价*：

- 无需记录高度或平衡因子；编程实现简单——优于AVL树
- 分摊复杂度$O(n log n)$ ——与AVL树相当
- 局部性强、缓存命中率极高时（即 $k << n << m $）时候（$k$是被访问的节点数，$m$是被访问次数），性能优于AVL树
  - 效率甚至可以更高——自适应的$O(log k)$
  - 任何连续的$m$次查找， 仅需$O(m log k + n log n)$时间
- 若反复地顺序访问任一子集，分摊成本仅为常数
- 不能杜绝单次最坏情况，不适用于对效率敏感的场合
=== 分摊分析

利用势能的方法，对伸展树的分摊复杂度进行分析。

对于伸展树，势能函数定义为：
$
Phi(S) = log(product_(v in S) "size"(v)) = sum_(v in S) log("size"(v)) = sum_(v in S) "rank"(v) = sum_(v in S) log V
$
越平衡/倾侧的树，势能越小/大。单链是$O(n log n)$，满树是$O(n)$。

考查对伸展树$S$的$m>>n$次连续访问（不妨仅考查`search()`），记
$
A^(k) = T^(k) + Delta Phi^(k)
$
则有
$
A - O(n log n) <= T = A - Delta Phi <= A + O(n log n)
$
下面证明
$
A = O(m log n)
$
则有
$
T = O(n log n)
$
而$A^(k)$都不致超过节点v的势能变化量， 即：$O("rank"^(k)(v)-"rank"^(k-1)(v))= O(log n)$。

$A^(k)$是`v`的若干次连续伸展操作（时间成本）的累积，这些操作无非三种情况。

#figure(
  image("fig\BST\40.png", width: 70%),
  caption: "伸展树——分摊分析"
)
#figure(
  image("fig\BST\41.png", width: 70%),
  caption: "伸展树——分摊分析"
)
#figure(
  image("fig\BST\42.png", width: 70%),
  caption: "伸展树——分摊分析"
)

== B树
=== 缓存Cache

先考虑这样一个问题：_就地循环位移_

_仅用$O(1)$辅助空间，将数组`A[0, n)`中的元素向左循环移动k个单元
`void shift( int * A, int n, int k );`_

*蛮力解法*：每次移动一个单元，共移动k次，时间复杂度$O(k n)$。

```cpp
void shift0( int * A, int n, int k ) //反复以1为间距循环左移
    { while ( k-- ) shift( A, n, 0, 1 ); } //共迭代k次， O(n*k)
```

#figure(
  image("fig\BST\43.png", width: 70%),
  caption: "就地循环位移——蛮力解法"
)

*迭代版Stride-k Reference Pattern *：分成k组，每组内部循环左移，共移动n次，时间复杂度$O(n)$。

```cpp
int shift( int * A, int n, int s, int k ) { // O( n / GCD(n, k) )
    int b = A[s]; int i = s, j = (s + k) % n; int mov = 0; //mov记录移动次数
    while ( s != j ) //从A[s]出发，以k为间隔，依次左移k位
        { A[i] = A[j]; i = j; j = (j + k) % n; mov++; }
    A[i] = b; return mov + 1; //最后，起始元素转入对应位置
} //[0, n)由关于k的g = GCD(n, k)个同余类组成， shift(s, k)能够且只能够使其中之一就位

void shift1(int* A, int n, int k) { //经多轮迭代，实现数组循环左移k位，累计O(n+g)
    for (int s = 0, mov = 0; mov < n; s++) //O(g) = O(GCD(n, k))
        mov += shift(A, n, s, k);
}
```

#figure(
  image("fig\BST\44.png", width: 70%),
  caption: "就地循环位移——Stride-k Reference Pattern"
)

*倒置版Stride-1 Reference Pattern*：如下图，经过三次倒置即可。复杂度是$O(3n)$。

```cpp
void shift2( int * A, int n, int k ) {
    reverse( A, k ); //O(3k/2)
    reverse( A + k, n – k ); //O(3(n-k)/2)
    reverse( A, n ); //O(3n/2)
} //O(3n)
```

#figure(
  image("fig\BST\45.png", width: 70%),
  caption: "就地循环位移——Stride-1 Reference Pattern"
)

可以看到这种方法虽然看上去常系数很大，但是实际上是最快的。这是因为利用了缓存。

- 实用的存储系统，由不同类型的存储器级联而成，以综合其各自的优势

#figure(
  image("fig\BST\46.png", width: 70%),
  caption: "存储系统"
)

- 分级存储：利用数据访问的局部性

#figure(
  image("fig\BST\47.png", width: 70%),
  caption: "分级存储"
)

- 这就导致：在外存读写1B，与读写1KB几乎一样快
  - 以页（page）为单位， 借助缓冲区批量访问， 可大大缩短单位字节的平均访问时间
=== B树的结构

出于缓存的考虑，B树每$d$代合并为超级节点
- $m = 2^d$ 路
- $m-1$ 个关键码
逻辑上与BBST完全等价。

#figure(
  image("fig\BST\48.png", width: 70%),
  caption: "B树"
)

I/O优化： 多级存储系统中使用B-树，可针对外部查找，大大减少I/O次数。

#figure(
  image("fig\BST\49.png", width: 50%),
  caption: "B树"
)

所谓$m$阶B-树， 即m路完全平衡搜索树（$m >= 3$）
- 外部节点的深度统一相等，约定以此深度作为树高$h$
- 叶节点的深度统一相等$h-1$
- 内部节点
  - 各含 $n <= m-1$ 个关键码：$K_1 < K_2 < ... < K_n$
  - 各有 $n+1 <= m$个分支：$A_0, A_1, ... , A_n$
  - 反过来，分支数也不能太少
    - 树根：$2 <= n+1$
    - 其余：$ceil(m/2) <= n+1$
  - 故也称作$(ceil(m/2), m)$-树

#figure(
  image("fig\BST\50.png", width: 70%),
  caption: "B树——紧凑表示"
)

`BTNode`：用两个长度差1的向量存储关键码和孩子
```cpp
template <typename T> struct BTNode { //B-树节点
    BTNodePosi<T> parent; //父
    Vector<T> key; //关键码（总比孩子少一个）
    Vector< BTNodePosi<T> > child; //孩子
    BTNode() { parent = NULL; child.insert( NULL ); }
    BTNode( T e, BTNodePosi<T> lc = NULL, BTNodePosi<T> rc = NULL ) {
        parent = NULL; //作为根节点
        key.insert( e ); //仅一个关键码，以及
        child.insert( lc ); if ( lc ) lc->parent = this; //左孩子
        child.insert( rc ); if ( rc ) rc->parent = this; //右孩子
    }
};
```

#figure(
  image("fig\BST\51.png", width: 40%),
  caption: "B树——节点"
)

`BTree`模板类
```cpp
template <typename T> using BTNodePosi = BTNode<T>*; //B-树节点位置
template <typename T> class BTree { //B-树
protected:
    Rank _size, _m; //关键码总数、 阶次
    BTNodePosi<T> _root, _hot; //根、 search()最后访问的非空节点
    void solveOverflow( BTNodePosi<T> ); //因插入而上溢后的分裂处理
    void solveUnderflow( BTNodePosi<T> ); //因删除而下溢后的合并处理
public:
    BTNodePosi<T> search( const T & e ); //查找
    bool insert( const T & e ); //插入
    bool remove( const T & e ); //删除
};
```
=== B树的查找

和BST一样，B树的查找也是从根节点开始，逐层向下，直到外部节点。
```cpp
从（常驻RAM的）根节点开始
只要当前节点不是外部节点
    在当前节点中顺序查找 //RAM内部
    若找到目标关键码，则
        return 查找成功
    否则 //止于某一向下的引用
        沿引用找到孩子节点
        将其读入内存 //I/O耗时
return 查找失败
```

#figure(
  image("fig\BST\52.png", width: 50%),
  caption: "B树——查找"
)

```cpp
template <typename T> BTNodePosi<T> BTree<T>::search( const T & e ) {
    BTNodePosi<T> v = _root; _hot = NULL; //从根节点出发
    while ( v ) { //逐层深入地
        Rank r = v->key.search( e ); //在当前节点对应的向量中顺序查找
        if ( 0 <= r && e == v->key[r] ) return v; //若成功，则返回；否则...
        _hot = v; v = v->child[ r + 1 ]; //沿引用转至对应的下层子树，并载入其根（I/O）
    } //若因!v而退出，则意味着抵达外部节点
    return NULL; //失败
}
```

性能：忽略内存中的查找，运行时间主要取决于I/O次数，在每一深度至多一次I/O，故$O(h)$。可以证明，$log_m (N+1) <= h <= 1 + floor(log_ceil(m/2)((N+1)/2))$，其中$N$是关键码总数，$h$是树高。$h = O(log_m N)$。
=== B树的插入

插入算法的核心是`solveOverflow()`，它的作用是：将上溢的节点分裂为两个节点，分别作为两个儿子，选出中位数推送到原来的父亲。
```cpp
template <typename T> bool BTree<T>::insert( const T & e ) {
    BTNodePosi<T> v = search( e );
    if ( v ) return false; //确认e不存在
    Rank r = _hot->key.search( e ); //在节点_hot中确定插入位置
    _hot->key.insert( r+1, e ); //将新关键码插至对应的位置
    _hot->child.insert( r+2, NULL ); _size++; //创建一个空子树指针
    solveOverflow( _hot ); //若上溢，则分裂
    return true; //插入成功
}
```

设上溢节点中的关键码依次为：
$
{k_0, k_1, ..., k_(m-1)}
$
取中位数$s = floor(m/2)$，则有划分：
$
{k_0, k_1, ..., k_(s-1)} {k_s} {k_(s+1), ..., k_(m-1)}
$
关键码$k_s$上升一层。

#figure(
  image("fig\BST\53.png", width: 30%),
  caption: "B树——上溢"
)

若上溢节点的父亲本已饱和，则在接纳被提升的关键码之后，也将上溢：套用前法，继续分裂。

上溢可能持续发生，并逐层向上传播，直至根节点。次数是$O(h)$的。

此时，如果根节点也上溢，需创建新的根节点，作为B树的新根。注意：新生的树根仅有两个分支。

#figure(
  image("fig\BST\54.png", width: 70%),
  caption: "B树——上溢——实例"
)

```cpp
template <typename T> void BTree<T>::solveOverflow( BTNodePosi<T> v ) {
    while ( _m <= v->key.size() ) { //除非当前节点不再上溢
        Rank s = _m / 2; //轴点（此时_m = key.size() = child.size() - 1）
        BTNodePosi<T> u = new BTNode<T>(); //注意：新节点已有一个空孩子
        for ( Rank j = 0; j < _m - s - 1; j++ ) { //分裂出右侧节点u（效率低可改进）
            u->child.insert( j, v->child.remove( s + 1 ) ); //v右侧_m–s-1个孩子
            u->key.insert( j, v->key.remove( s + 1 ) ); //v右侧_m–s-1个关键码
        } 
        u->child[ _m - s - 1 ] = v->child.remove( s + 1 ); //移动v最靠右的孩子
        if ( u->child[ 0 ] ) //若u的孩子们非空，则统一令其以u为父节点
            for ( Rank j = 0; j < _m - s; j++ ) u->child[ j ]->parent = u;
        BTNodePosi<T> p = v->parent; //v当前的父节点p
        if ( ! p ) //若p为空，则创建之（全树长高一层，新根节点恰好两度）
            { _root = p = new BTNode<T>(); p->child[0] = v; v->parent = p; }
        Rank r = 1 + p->key.search( v->key[0] ); //p中指向u的指针的秩
        p->key.insert( r, v->key.remove( s ) ); //轴点关键码上升
        p->child.insert( r + 1, u ); u->parent = p; //新节点u与父节点p互联
        v = p; //上升一层，如有必要则继续分裂——至多O(logn)层
    } //while
} //solveOverflow
```

=== B树的删除

和BST一样，B树的删除也是先寻找，如果节点在叶子上，直接删除；如果节点在内部节点上，找到其后继，将后继的关键码替换到当前节点，然后删除后继。

```cpp
template <typename T>
bool BTree<T>::remove( const T & e ) {
    BTNodePosi<T> v = search( e );
    if ( ! v ) return false; //确认e存在
    Rank r = v->key.search(e); //e在v中的秩
    if ( v->child[0] ) { //若v非叶子，则
        BTNodePosi<T> u = v->child[r + 1]; //在右子树中
        while ( u->child[0] ) u = u->child[0]; //一直向左，即可找到e的后继（必在底层）
        v->key[r] = u->key[0]; v = u; r = 0; //交换
    }
    //assert: 至此， v必位于最底层，且其中第r个关键码就是待删除者
    v->key.remove( r ); v->child.remove( r + 1 ); _size--;
    solveUnderflow( v ); return true; //如有必要，需做旋转或合并
}
```

处理下溢：

非根节点`V`下溢时，必恰有$ceil(m/2)-2$个关键码$ceil(m/2)-1$个个分支。视其左、右兄弟`L`、`R`的规模，可分三种情况加以处理：

1. 若`L`存在，且至少包含$ceil(m/2)$个关键码：
- 将 `P` 中的分界关键码 `y` 移至 `V` 中（作为最小关键码）
- 将 `L` 中的最大关键码 `x` 移至 `P` 中（取代原关键码 `y` ）
- 儿子也要转走

#figure(
  image("fig\BST\55.jpg", width: 40%),
  caption: "B树——下溢——情形1"
)

如此旋转之后，局部乃至全树都重新满足B-树条件，下溢修复完毕

2. 若 `R` 存在，且至少包含$ceil(m/2)$个关键码
- 也可旋转，完全对称

#figure(
  image("fig\BST\56.png", width: 40%),
  caption: "B树——下溢——情形2"
)

3.  `L` 和 `R` 或不存在，或均不足$ceil(m/2)$个关键码：
-  `L` 和 `R` 仍必有其一（不妨以 `L` 为例），且
-  恰含$ceil(m/2) - 1$个关键码
从 `P` 中抽出介于 `L` 和 `V` 之间的分界关键码 `y`
- 通过 `y` 做粘接，将 `L` 和 `V` 合成一个节点
- 同时合并此前 `y` 的孩子引用
此处下溢得以修复，但可能继而导致 `P` 下溢，继续旋转或合并
- 下溢可能持续发生并向上传播；但至多不过 $O(h)$ 层

#figure(
  image("fig\BST\57.png", width: 40%),
  caption: "B树——下溢——情形3"
)


下溢修复：
```cpp
template <typename T> void BTree<T>::solveUnderflow( BTNodePosi<T> v ) {
    while ( (_m + 1) / 2 > v->child.size() ) {//除非当前节点没有下溢
        BTNodePosi<T> p = v->parent; if ( !p ) { /* 已到根节点 */ }
        Rank r = 0; while ( p->child[r] != v ) r++; //确定v是p的第r个孩子
        if ( 0 < r ) { /∗ 情况 #1：若v的左兄弟存在，且... ∗/ }
        if ( p−>child.size() − 1 > r ) { /∗ 情况 #2：若v的右兄弟存在，且... ∗/ }
        if ( 0 < r ) { /∗ 与左兄弟合并 ∗/ } else { /∗ 与右兄弟合并 ∗/ } //情况 #3
        v = p; //上升一层， 如有必要则继续旋转或合并——至多O(logn)层
    } //while
} //solveUnderflow
```
情况#1：旋转（向左兄弟借关键码）
```cpp
if (0 < r) { //若v不是p的第一个孩子，则
    BTNodePosi<T> ls = p->child[r - 1]; //左兄弟必存在
    if ( (_m + 1) / 2 < ls->child.size() ) { //若该兄弟足够“胖”，则
        v->key.insert( 0, p->key[r-1] ); //p借出一个关键码给v（作为最小关键码）
        p->key[r - 1] = ls->key.remove( ls->key.size() – 1 ); //ls的最大key转入p
        v->child.insert( 0, ls->child.remove( ls->child.size() – 1 ) );//同时ls的最右侧孩子过继给v（作为v的最左侧孩子）
        if ( v->child[0] ) v->child[0]->parent = v;
        return; //至此，通过右旋已完成当前层（以及所有层）的下溢处理
    }
} //情况#2完全对称
```
情况#3：合并
```cpp
if (0 < r) { //与左兄弟合并
    BTNodePosi<T> ls = p->child[r-1]; //左兄弟必存在
    ls->key.insert( ls->key.size(), p->key.remove(r - 1) );
    p->child.remove( r ); //p的第r - 1个关键码转入ls， v不再是p的第r个孩子
    ls->child.insert( ls->child.size(), v->child.remove( 0 ) );
    if ( ls->child[ ls->child.size() – 1 ] ) //v的最左侧孩子过继给ls做最右侧孩子
        ls->child[ ls->child.size() – 1 ]->parent = ls;
    while ( !v->key.empty() ) { //v剩余的关键码和孩子，依次转入ls
        ls->key.insert( ls->key.size(), v->key.remove(0) );
        ls->child.insert( ls->child.size(), v->child.remove(0) );
        if ( ls->child[ ls->child.size() – 1 ] )
            ls->child[ ls->child.size() – 1 ]->parent = ls;
    } //while
    release(v); //释放v
} else
    { /* 与右兄弟合并，完全对称 */ }
```

下面的图就给了下溢处理的例子：

#figure(
  image("fig\BST\58.png", width: 70%),
  caption: "B树——下溢——实例"
)

#figure(
  image("fig\BST\59.png", width: 70%),
  caption: "B树——下溢——实例"
)

== 红黑树Red-Black Tree
=== 动机

*并发性*：Concurrent Access To A Database

修改之前先加锁（lock）；完成后解锁（unlock），访问延迟主要取决于“lock/unlock”周期

对于BST而言，每次修改过程中，唯结构有变（reconstruction）处才需加锁，访问延迟主要取决于这类局部之数量...

- Splay：结构变化剧烈，最差可达$O(n)$
- AVL： `remove()`时$0(log n)$，`insert()`时可保证$O(1)$
- Red-Black：无论`insert/remove`， 均不超过$O(1)$

*持久性*：Persistent structures：支持对历史版本的访问

#figure(
  image("fig\BST\60.png", width: 80%),
  caption: "持久性"
)

#figure(
  image("fig\BST\61.png", width: 80%),
  caption: "持久性"
)

对于这样的版本控制，我们希望就树形结构的拓扑而言，相邻版本之间的差异不能超过$O(1)$，而Red-Black树可以做到。
=== 红黑树的结构

由红、黑两类节点组成的BST，统一增设外部节点NULL， 使之成为真二叉树。

规则：

1. 树根：必为黑色
2. 外部节点：均为黑色
3. 红节点：只能有黑孩子（及黑父亲）
4. 外部节点： 黑深度（黑的真祖先数目）相等
  - 亦即根（全树）的黑高度
  - 子树的黑高度，即后代NULL的相对黑深度

#figure(
  image("fig\BST\62.png", width: 40%),
  caption: "红黑树"
)

将红节点提升至与其（黑）父亲等高，红边折叠起来——可以得到一棵等价的(2,4)树。

#figure(
  image("fig\BST\63.png", width: 80%),
  caption: "红黑树——等价的(2,4)树"
)

将黑节点与其红孩子视作关键码，再合并为B-树的超级节点。四种组合，分别对应于4阶B-树的一类内部节点。

#figure(
  image("fig\BST\64.png", width: 80%),
  caption: "红黑树——等价的B树"
)

包含$n$个内部节点的红黑树$T$，高度$h = O(log n)$：
$
log_2 (n+1) <= h <= 2 log_2 (n+1)
$
若$T$高度为$h$，红/黑高度为$R$/$H$，则
$
H <= h <= H + R <= 2H
$
若$T$所对应的B-树为$T_B$，则$H$即是$T_B$的高度。$T_B$的每个节点，都恰好包含$T$的一个黑节点。
$
H <= log_2 ((n+1)/2) +1 = log_2 (n+1)
$
从而*红黑树是一棵BBST*。

`RedBlack`模板类
```cpp
template <typename T> class RedBlack : public BST<T> { //红黑树
public: //BST::search()等其余接口可直接沿用
    BinNodePosi<T> insert( const T & e ); //插入（重写）
    bool remove( const T & e ); //删除（重写）
protected: 
    void solveDoubleRed( BinNodePosi<T> x ); //双红修正
    void solveDoubleBlack( BinNodePosi<T> x ); //双黑修正
    Rank updateHeight( BinNodePosi<T> x ); //更新节点x的高度（重写）
};

#define stature( p ) ( ( p ) ? ( p )->height : 0 ) //外部节点黑高度为0，以上递推
template <typename T> int RedBlack<T>::updateHeight( BinNodePosi<T> x )
    { return x->height = IsBlack( x ) + max( stature( x->lc ), stature( x->rc ) ); }
```
=== 红黑树的插入

按BST规则插入关键码`e` ，`x = insert(e)`必为叶节点。
- 除非是首个节点（根）， `x`的父亲`p = x->parent`必存在
- 首先将`x`染红：`x->color = isRoot(x) ? B : R`
- 至此，条件1、 2、 4依然满足；但3不见得，有可能出现*双红/double-red*：`p->color == x->color == R`
- 考查：
  - 祖父`g = p->parent` 必为黑
  - 叔父`u = uncle( x ) = sibling( p )`
视`u`的颜色，分两种情况处理：

#figure(
  image("fig\BST\65.png", width: 30%),
  caption: "红黑树——插入"
)

```cpp
template <typename T> BinNodePosi<T> RedBlack<T>::insert( const T & e ) {
    // 确认目标节点不存在（留意对_hot的设置）
    BinNodePosi<T> & x = search( e ); if ( x ) return x;
    // 创建红节点x，以_hot为父，黑高度 = 0
    x = new BinNode<T>( e, _hot, NULL, NULL, 0 ); _size++;
    // 如有必要，需做双红修正，再返回插入的节点
    BinNodePosi<T> xOld = x; solveDoubleRed( x ); return xOld;
} //无论原树中是否存有e，返回时总有x->data == e
```
双红修正
```cpp
template <typename T> void RedBlack<T>::solveDoubleRed( BinNodePosi<T> x ) {
    if ( IsRoot( *x ) ) { //若已（递归）转至树根， 则将其转黑， 整树黑高度也随之递增
        { _root->color = RB_BLACK; _root->height++; return; } //否则...
    BinNodePosi<T> p = x->parent; //考查x的父亲p（必存在）
    if ( IsBlack( p ) ) return; //若p为黑， 则可终止调整； 否则
    BinNodePosi<T> g = p->parent; //x祖父g必存在，且必黑
    BinNodePosi<T> u = uncle( x ); //以下视叔父u的颜色分别处理
    if ( IsBlack( u ) ) { /* ... u为黑（或NULL） ... */ }
    else                { /* ... u为红 ... */ }
    }
}
```
==== RR-1： u->color == B——一次3+4重构+两点反转红黑【一蹴而就】

此时， `x`、 `p`、 `g`的四个孩子（可能是外部节点）
- 全为黑， 且
- 黑高度相同
按照B树理解如下图

#figure(
  image("fig\BST\66.png", width: 20%),
  caption: "红黑树——插入——RR-1"
)
#figure(
  image("fig\BST\67.png", width: 20%),
    caption: "红黑树——插入——RR-1"
)

局部“3+4”重构：`b`转黑， `a`或`c`转红。在某三叉节点中插入红关键码后，原黑关键码不再居中（RRB或BRR）。调整的效果，是将三个关键码的颜色改为RBR。

#figure(
  image("fig\BST\68.png", width: 20%),
  caption: "红黑树——插入——RR-1"
)

如此调整， 一蹴而就。

```cpp
template <typename T> void RedBlack<T>::solveDoubleRed( BinNodePosi<T> x ) {
/* ...... */
if ( IsBlack( u ) ) { //u为黑或NULL
    // 若x与p同侧，则p由红转黑， x保持红；否则， x由红转黑， p保持红
    if ( IsLChild( *x ) == IsLChild( *p ) ) p->color = RB_BLACK;
    else x->color = RB_BLACK;
    g->color = RB_RED; //g必定由黑转红
    BinNodePosi<T> gg = g->parent; //great-grand parent
    BinNodePosi<T> r = FromParentTo( *g ) = rotateAt( x );
    r->parent = gg; //调整之后的新子树，需与原曾祖父联接
    } else { /* ... u为红 ... */ }
}
```

==== RR-2： u->color == R——上溢解决（无需旋转）：叔父染黑+祖父染红【递归上溯】

在B-树中，等效于超级节点发生上溢。

#figure(
  image("fig\BST\69.png", width: 20%),
  caption: "红黑树——插入——RR-2"
)

#figure(
  image("fig\BST\70.png", width: 20%),
  caption: "红黑树——插入——RR-2"
)

`p`与`u`转黑，`g`转红：在B-树中，等效于节点分裂，关键码`g`上升一层。

#figure(
  image("fig\BST\71.png", width: 20%),
  caption: "红黑树——插入——RR-2"
)

可能继续向上传递——亦即， `g`与`parent(g)`再次构成双红。等效地将`g`视作新插入的节点，区分以上两种情况，如法处置。

`g`若果真到达树根， 则强行将其转为黑色（整树黑高度加一）。

```cpp
template <typename T> void RedBlack<T>::solveDoubleRed( BinNodePosi<T> x ) {
    /* ...... */
    if ( IsBlack( u ) ) { /* ... u为黑（含NULL） ... */ }
    else { //u为红色
        p->color = RB_BLACK; p->height++; //p由红转黑，增高
        u->color = RB_BLACK; u->height++; //u由红转黑，增高
        g->color = RB_RED; //在B-树中g相当于上交给父节点的关键码，故暂标记为红
        solveDoubleRed( g ); //继续调整：若已至树根，接下来的递归会将g转黑（尾递归）
    }
}
```
`RedBlack::insert()`仅需$O(log n)$时间，至多$O(log n)$次染色和$O(1)$次旋转。

#align(
  center,
  table(
  columns: (auto, auto, auto, auto),
  align: center,
  // align: horizon,
  [], [*旋转*], [*染色*],[*此后*],
  [u为黑], [1 or 2], [2], [调整完成],
  [u为红], [0], [3], [递归上溯],
)
)

#figure(
  image("fig\BST\72.png", width: 30%),
  caption: "红黑树——插入——总结"
)
=== 红黑树的删除

首先按照BST常规算法，执行`r = removeAt( x, _hot )`，实际被摘除的可能是`x`的前驱或后继`w`，简捷起见，以下不妨统称作`x`。

`x`由孩子`r`接替，此时另一孩子`k`必为`NULL`
- 但在随后的调整过程中`x`可能逐层上升
- 故需假想地、统一地、等效地理解为：
  - `k`为一棵黑高度与`r`相等的子树，且
  - 随`x`一并摘除（尽管实际上从未存在过）

#figure(
  image("fig\BST\73.png", width: 30%),
  caption: "红黑树——删除"
)

```cpp
template <typename T> bool RedBlack<T>::remove( const T & e ) {
    BinNodePosi<T> & x = search( e ); if ( !x ) return false; //查找定位
    BinNodePosi<T> r = removeAt( x, _hot ); //删除_hot的某孩子， r指向其接替者
    if ( ! ( -- _size ) ) return true; //若删除后为空树，可直接返回
    if ( ! _hot ) { //若被删除的是根， 则
        _root->color = RB_BLACK; //将其置黑， 并
        updateHeight( _root ); //更新（全树）黑高度
        return true;
    } //至此，原x（现r）必非根
    // 若父亲（及祖先）依然平衡，则无需调整
    if ( BlackHeightUpdated( * _hot ) ) return true;
    // 至此，必失衡
    // 若替代节点r为红，则只需简单地翻转其颜色
    if ( IsRed( r ) ) { r->color = RB_BLACK; r->height++; return true; }
    // 至此， r以及被其替代的x均为黑色
    solveDoubleBlack( r ); //双黑调整（入口处必有 r == NULL）
    return true;
}
```
完成`removeAt()`之后
- 条件1、 2依然满足
- 但条件3、 4却不见得

*其一为红*：

在原树中，考查x与r
- 若x为红，则条件3、 4自然满足
- 若r为红，则令其与x交换颜色，即可满足条件3、 4
一蹴而就。

#figure(
  image("fig\BST\73.png", width: 30%),
  caption: "红黑树——删除——RB"
)

*双黑*：

若`x`与`r`均黑（double black），则不然。
- 摘除`x`并代之以`r`后，全树黑深度不再统一（稍后可见，等效于B-树中`x`所属节点下溢）
- 在新树中，考查`r`的父亲、兄弟
    - `p = r->parent //亦是原x的父亲`
    - `s = sibling( r )`
以下分四种情况处理：

#figure(
  image("fig\BST\74.png", width: 30%),
  caption: "红黑树——删除——双黑"
)
```cpp
template <typename T> void RedBlack<T>::solveDoubleBlack( BinNodePosi<T> r ) {
    BinNodePosi<T> p = r ? r->parent : _hot; if ( !p ) return; //r的父亲
    BinNodePosi<T> s = (r == p->lc) ? p->rc : p->lc; //r的兄弟
    if ( IsBlack( s ) ) { //兄弟s为黑
        BinNodePosi<T> t = NULL; //s的红孩子（若左、右孩子皆红，左者优先；皆黑时为NULL）
        if ( IsRed ( s->rc ) ) t = s->rc;
        if ( IsRed ( s->lc ) ) t = s->lc;
        if ( t ) { /* ... 黑s有红孩子： BB-1 ... */ }
        else { /* ... 黑s无红孩子： BB-2R或BB-2B ... */ }
    } else { /* ... 兄弟s为红： BB-3 ... */ }
}
```

==== BB-1：s为黑，且(侄子是红的)至少有一个红孩子t——下溢解决：一次“3+4”重构+三次染色【一蹴而就】

#figure(
  image("fig\BST\75.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-1"
)

#figure(
  image("fig\BST\76.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-1"
)

“3+4”重构：
- `t ~ a`
- `s ~ b`
- `p ~ c`
重新着色：
- `r`保持黑
- `a`、 `c`染黑
- `b`继承`p`的原色
如此，红黑树性质在全局得以恢复。

如果按照B树理解：通过关键码的旋转，消除超级节点的下溢。
在对应的B-树中
- `p`若为红，问号之一为黑关键码
- `p`若为黑，必自成一个超级节点

#figure(
  image("fig\BST\77.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-1"
)

#figure(
  image("fig\BST\78.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-1"
)

```cpp
if ( IsBlack( s ) ) { //兄弟s为黑
/* ...... */
if ( t ) { //黑s有红孩子： BB-1
    RBColor oldColor = p->color; //备份p颜色，并对t、父亲、祖父
    BinNodePosi<T> b = FromParentTo( *p ) = rotateAt( t ); //旋转
    if (HasLChild( *b )) { b->lc->color = RB_BLACK; updateHeight( b->lc ); }
    if (HasRChild( *b )) { b->rc->color = RB_BLACK; updateHeight( b->rc ); }
        b->color = oldColor; updateHeight( b ); //新根继承原根的颜色
} else { /* ... 黑s无红孩子： BB-2R或BB-2B ... */ }
} else { /* ... 兄弟s为红： BB-3 ... */ }
``` 
==== BB-2R： s为黑，且两个孩子均为黑； p为红——下溢解决：两个染色【一蹴而就】

- `r`保持黑；`s`转红；`p`转黑
- 在对应的B-树中，等效于下溢节点与兄弟合并
- 红黑树性质在全局得以恢复——一蹴而就
失去关键码`p`后，上层节点不会继而下溢。因为合并之前，在`p`之左或右侧还应有一个黑关键码。

#figure(
  image("fig\BST\79.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-2R"
)

#figure(
  image("fig\BST\80.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-2R"
)

==== BB-2B： s为黑，且两个孩子均为黑； p为黑——下溢解决：一次染色【递归上溯】

- `s`转红； `r`与`p`保持黑
- 红黑树性质在*局部*得以恢复
- 在对应的B-树中，等效于下溢节点与兄弟合并
- 合并前，`p`和`s`均属于单关键码节点
孩子的下溢修复后，父节点继而下溢，递归上溯$O(log n)$层

#figure(
  image("fig\BST\81.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-2B"
)

#figure(
  image("fig\BST\82.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-2B"
)

```cpp
if ( IsBlack( s ) ) { //兄弟s为黑
    /* ...... */
    if ( t ) { /* ... 黑s有红孩子： BB-1 ... */ }
    else { /* 黑s无红孩子 */
        s->color = RB_RED; s->height--; //s转红
        if ( IsRed( p ) ) //BB-2R： p转黑，但黑高度不变
        { p->color = RB_BLACK; }
        else //BB-2B： p保持黑，但黑高度下降；递归修正
        { p->height--; solveDoubleBlack( p ); }
    }
} else { /* ... 兄弟s为红： BB-3 ... */ }
```
==== BB-3： s为红（其孩子均为黑）——一次旋转+两次染色【化归成一蹴而就】

- 绕`p`单旋； `s`红转黑， `p`黑转红
- 黑高度依然异常，但`r`有了一个新的黑兄弟`s'`
- 故转化为前述情况，而且`p`已转红，接下来
    - 绝不会是BB-2B
    - 而只能是BB-2R或BB-1
- 于是，再经一轮调整红黑树性质必然全局恢复。

#figure(
  image("fig\BST\83.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-3"
)

#figure(
  image("fig\BST\84.png", width: 30%),
  caption: "红黑树——删除——双黑——BB-3"
)

```cpp
if ( IsBlack( s ) ) { //兄弟s为黑
    if ( t ) { /* ... 黑s有红孩子： BB-1 ... */ }
    else { /* ... 黑s无红孩子： BB-2R或BB-2B ... */ }
} else { //兄弟s为红： BB-3
    s->color = RB_BLACK; p->color = RB_RED; //s转黑， p转红
    BinNodePosi<T> t = IsLChild( *s ) ? s->lc : s->rc; //取t与其父s同侧
    _hot = p; FromParentTo( *p ) = rotateAt( t ); //对t及其父亲、祖父做平衡调整
    solveDoubleBlack( r ); //继续修正r——此时p已转红，故后续只能是BB-1或BB-2R
}
```

`RedBlack::remove()`仅需$O(log n)$时间，至多$O(log n)$次染色和$O(1)$次旋转。

#align(
  center,
  table(
  columns: (auto, auto, auto, auto),
  align: center,
  // align: horizon,
  [], [*旋转*], [*染色*],[*此后*],
  [BB-1:黑s有红子t], [1or2], [3], [调整完成],
  [BB-2R:黑s无红子，p红], [0], [2], [调整完成],
  [BB-2B:黑s无红子，p黑], [0], [1], [递归上溯],
  [BB-3:红s], [1], [2], [转为(1)或(2R),调整完成],
)
)

#figure(
  image("fig\BST\85.png", width: 80%),
  caption: "红黑树——删除——双黑——总结"
)