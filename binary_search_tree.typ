= 二叉搜索树 BST(Binary Search Tree)

各数据项依所持关键码而彼此区分，循关键码访问：call-by-KEY。关键码之间必须同时支持比较（大小）与比对（相等）。数据集中的数据项，统一地表示和实现为词条（entry）形式。

词条
```cpp
template <typename K, typename V> struct Entry { //词条模板类
    K key; V value; //关键码、数值
    Entry( K k = K(), V v = V() ) : key(k), value(v) {}; //默认构造函数
    Entry( Entry<K, V> const & e ) : key(e.key), value(e.value) {}; //克隆
    // 比较器、判等器（从此，不必严格区分词条及其对应的关键码）
    bool operator< ( Entry<K, V> const & e ) { return key < e.key; } //小于
    bool operator> ( Entry<K, V> const & e ) { return key > e.key; } //大于
    bool operator==( Entry<K, V> const & e ) { return key == e.key; } //等于
    bool operator!=( Entry<K, V> const & e ) { return key != e.key; } //不等
};
```

== 顺序性——BST的中序遍历

BST的存储需要保证：

- 任一节点均不小/大于其左/右*后代*

与 任一节点均不小于/不大于其左/右*孩子*并不等效

三位一体：节点 $~$ 词条 $~$ 关键码

#figure(
  image("fig\BST\1.png",width: 80%),
  caption:"BST的顺序性"
)

顺序性虽只是对局部特征的刻画，却可导出BST的整体特征：*BST的中序遍历序列，必然单调非降*。

BST留出这样的接口：
```cpp
template <typename T> class BST : public BinTree<T> {
public: //以virtual修饰，以便派生类重写
    virtual BinNodePosi<T> & search( const T & ); //查找
    virtual BinNodePosi<T> insert( const T & ); //插入
    virtual bool remove( const T & ); //删除
protected:
    BinNodePosi<T> _hot; //命中节点的父亲
    BinNodePosi<T> connect34( //3+4重构
    BinNodePosi<T>, BinNodePosi<T>, BinNodePosi<T>,
    BinNodePosi<T>, BinNodePosi<T>, BinNodePosi<T>, BinNodePosi<T> );
    BinNodePosi<T> rotateAt( BinNodePosi<T> ); //旋转调整
};
```

== BST的基本算法与实现
=== 查找`search()`

从根节点出发，逐步地缩小查找范围，直到发现目标（成功）， 或抵达空树（失败）。本质上讲，就是有序向量的二分查找。

```cpp
template <typename T> BinNodePosi<T> & BST<T>::search( const T & e ) {
    if ( !_root || e == _root->data ) //空树，或恰在树根命中
        { _hot = NULL; return _root; }
    for ( _hot = _root; ; ) { //否则，自顶而下
        BinNodePosi<T> & v = ( e < _hot->data ) ? _hot->lc : _hot->rc; //深入一层
        if ( !v || e == v->data ) return v; _hot = v; //一旦命中或抵达叶子，随即返回
    } //返回目标节点位置的引用，以便后续插入、删除操作
} //无论命中或失败， _hot均指向v之父亲（v是根时， hot为NULL）
```

复杂度是$O(h)$，其中$h$是BST的高度。若BST退化为链，则复杂度退化为$O(n)$。
=== 插入`insert()`

先借助`search(e)`确定插入位置及方向。 若`e`尚不存在， 则再将新节点作为叶子插入
- `_hot`为新节点的父亲
- `v = search(e)`为`_hot`对新孩子的引用
令`_hot`通过`v`指向新节点

```cpp
template <typename T> BinNodePosi<T> BST<T>::insert( const T & e ) {
    BinNodePosi<T> & x = search( e ); //查找目标（留意_hot的设置）
    if ( ! x ) { //既禁止雷同元素，故仅在查找失败时才实施插入操作
        x = new BinNode<T>( e, _hot ); //在x处创建新节点，以_hot为父亲
        _size++; updateHeightAbove( x ); //更新全树规模，更新x及其历代祖先的高度
    }
    return x; //无论e是否存在于原树中，至此总有x->data == e
} //验证：对于首个节点插入之类的边界情况，均可正确处置
```

时间主要消耗耗于`search(e)`和`updateHeightAbove(x)`，均为$O(h)$，其中$h$是BST的高度。
=== 删除`remove()`

```cpp
template <typename T> bool BST<T>::remove( const T & e ) {
    BinNodePosi<T> & x = search( e ); //定位目标节点
    if ( !x ) return false; //确认目标存在（此时_hot为x的父亲）
    removeAt( x, _hot ); _size--; //分两大类情况实施删除
    _size--; updateHeightAbove( _hot ); //更新全树规模，更新_hot及其历代祖先的高度
    return true;
} //删除成功与否，由返回值指示
```
这样，时间主要消耗于`search(e)`和`updateHeightAbove(x)`，后面证明`removeAt(x, _hot)`也为$O(h)$，其中$h$是BST的高度。

删除将分为两种情况：

1. 单分支

  该节点只有一个孩子，直接将其孩子接入其父亲即可。

  ```cpp
template <typename T> static BinNodePosi<T>
removeAt( BinNodePosi<T> & x, BinNodePosi<T> & hot ) {
    BinNodePosi<T> w = x; //实际被摘除的节点，初值同x
    BinNodePosi<T> succ = NULL; //实际被删除节点的接替者
    if ( ! HasLChild( *x ) ) succ = x = x->rc; //左子树为空
    else if ( ! HasRChild( *x ) ) succ = x = x->lc; //右子树为空
    else { /* ...左、右子树并存的情况，略微复杂些... */ }
    hot = w->parent; //记录实际被删除节点的父亲
    if ( succ ) succ->parent = hot; //将被删除节点的接替者与hot相联
    release( w->data ); release( w ); return succ; //释放被摘除节点，返回接替者
} //此类情况仅需O(1)时间
  ```

2. 双分支

  该节点有两个孩子，需要找到其直接后继（或直接前驱）节点，将其值替换到该节点，然后删除直接后继（或直接前驱）节点。由于直接后继一定没有左儿子，从而转化为单分支情况。

  ```cpp
template <typename T> static BinNodePosi<T>
removeAt( BinNodePosi<T> & x, BinNodePosi<T> & hot ) {
/* ...... */
else { //若x的左、右子树并存，则
    w = w->succ(); swap( x->data, w->data ); //令*x与其后继*w互换数据
    BinNodePosi<T> u = w->parent; //原问题即转化为，摘除非二度的节点w
    ( u == x ? u->rc : u->lc ) = succ = w->rc; //兼顾特殊情况： u可能就是x
}
/* ...... */
} //时间主要消耗于succ()，正比于x的高度——更精确地， search()与succ()总共不过O(h)
  ```

== 平衡二叉搜索树BBST
=== 平衡

若不能有效地控制树高，就无法体现出BST相对于向量、列表等数据结构的明显优势，比如在最（较）坏情况下，二叉搜索树可能彻底地（接近地） 退化为列表，此时的性能不仅没有提高，而且因为结构更为复杂，反而会（在常系数意义上）下降。

用两种统计学口径分析平衡性：
1. 随机生成：将$n$个词条${e_i}$随机插入一棵空树按随机排列$sigma = (i_1, i_2, ..., i_n)$，得到一棵随机生成的BST$T$，其高度$h_T$是一个随机变量，假定所有BST等概率地出现，其期望值为$E(h_T) = O(log n)$

2. 随即组成：将一样的拓扑结构视作一类，随机生成的BST$T$的高度$h_T$是一个随机变量，假定所有BST等概率地出现，其期望值为$E(h_T) = O(sqrt(n))$

  $n$个节点组成的BST的个数为$S(n)$则
  $
  S(n) = sum_(i=1)^(n)S(i-1)S(n-i) = "catalan"(n) = (2n)!/(n!(n+1)!)
  $

理想随机在实际中绝难出现：局部性、关联性、（分段）单调性、（近似）周期性、 ...较高甚至极高的BST频繁出现；平衡化处理很有必要。

由$n$个节点组成的二叉树，高度不致低于$floor(log_2(n+1))$
。达到这一下界时，称作*理想平衡*。

而*渐近平衡*在渐近的意义下，高度不致超过$O(log n)$。满足这样的BST称为*平衡二叉树*（Balanced Binary Search Tree，BBST）。
=== 平衡等价变换

#figure(
  image("fig\BST\3.png",width: 70%),
  caption:"等价BST"
)

限制条件 + 局部性：

各种BBST都可视作BST的某一子集，相应地满足精心设计的限制条件
- 单次动态修改操作后，至多$O(log n)$处局部不再满足限制条件（可能相继违反，未必同时）
- 可在$O(log n)$时间内，使这些局部（以至全树）重新满足

等价变换 + 旋转调整： *序齿不序爵*

刚刚失衡的BST，必可速转换为一棵等价的BBST。
#figure(
  image("fig\BST\4.png",width: 80%),
  caption:"等价变换"
)

`zig`和`zag`：仅涉及常数个节点，只需调整其间的联接关系；均属于局部的基本操作。调整之后： `v`/`c`深度加/减1，子（全）树高度的变化幅度，上下差异不超过1。

实际上，经过不超过$O(n)$次旋转，等价的BST均可相互转化。
== AVL树

G. Adelson-Velsky & E. Landis (1962) 提出的平衡二叉搜索树，以其发明者的名字命名。

=== AVL树的定义
AVL的核心是：*平衡因子*（Balance Factor，BF）。

$
"BF"(v) = "height"(v->l c) - "height"(v->r c)
$
AVL在每次操作后要进行维护，保证：
$
forall v in T, |"BF"(v)| <= 1
$
AVL树未必理想平衡，但必然渐近平衡。
==== AVL渐近平衡

对于固定高度$h$的AVL树，其最少节点数$S(h)$满足递推关系：
$
S(h) = S(h-1) + S(h-2) + 1
$
从而$S(h)="fib"(h+3)-1$，从而对于$n$个节点构成的AVL树，其高度不会超过$O(log n)$。
==== Fibonacci Tree

高度为$h$，规模恰好为$S(h)$的AVL树，称为*Fibonacci树*（Fibonacci Tree）。

是最“瘦”的、临界的AVL树。
==== AVL接口

```cpp
#define Balanced(x) ( stature( (x).lc ) == stature( (x).rc ) ) //理想平衡
#define BalFac(x) (stature( (x).lc ) - stature( (x).rc ) ) //平衡因子
#define AvlBalanced(x) ( ( -2 < BalFac(x) ) && (BalFac(x) < 2 ) ) //AVL平衡条件
template <typename T> class AVL : public BST<T> { //由BST派生
public: //BST::search()等接口，可直接沿用
    BinNodePosi<T> insert( const T & ); //插入（重写）
    bool remove( const T & ); //删除（重写）
};
```

=== 重平衡

AVL树的插入和删除操作，都可能导致局部失衡，需要通过旋转调整来重平衡。

#figure(
  image("fig\BST\5.png",width: 80%),
  caption:"AVL树的重平衡"
)

- 插入：从祖父开始，每个祖先都有可能失衡，且可能同时失衡。
- 删除：从父亲开始，每个祖先都有可能失衡，但至多一个。

利用旋转变换进行重平衡：
- 局部性：所有的旋转都在局部进行，每次只需$O(1)$时间
- 快速性：在每一深度只需检查并旋转至多一次，共$O(log n)$次
==== 插入

插入分为两种情况：

*单旋*：黄色方块恰好存在其一

只需要经过一次`zag`或者`zig`，并且旋转后的子树高度不变严格变回插入之前，即可恢复平衡，不需要再向上探；并且该子树的父亲的`BF`不变，不会导致更高层的失衡。

#figure(
  image("fig\BST\6.png",width: 80%),
  caption:"AVL树的插入"
)

*双旋*

需要经过两次`zag`或者`zig`，并且旋转后的子树高度不变严格变回插入之前，即可恢复平衡，不需要再向上探；并且该子树的父亲的`BF`不变，不会导致更高层的失衡。

#figure(
  image("fig\BST\7.png",width: 80%),
  caption:"AVL树的插入"
)

注意：即便g未失衡，高度亦可能增加。

```cpp
template <typename T> BinNodePosi<T> AVL<T>::insert( const T & e ) {
    BinNodePosi<T> & x = search( e ); if ( x ) return x; //若目标尚不存在
    BinNodePosi<T> xx = x = new BinNode<T>( e, _hot ); _size++; //则创建新节点
    // 此时，若x的父亲_hot增高，则祖父有可能失衡
    for ( BinNodePosi<T> g = _hot; g; g = g->parent ) //从_hot起，逐层检查各代祖先g
        if ( ! AvlBalanced( *g ) ) { //一旦发现g失衡，则通过调整恢复平衡
            FromParentTo(*g) = rotateAt( tallerChild( tallerChild( g ) ) );
            break; //局部子树复衡后，高度必然复原；其祖先亦必如此，故调整结束
        } else //否则（g仍平衡）
            updateHeight( g ); //只需更新其高度（注意：即便g未失衡，高度亦可能增加）
    return xx; //返回新节点位置
}
```

插入的时间主要在`search(e)`上，为$O(log n)$，其余操作均为$O(1)$，故总体复杂度为$O(log n)$。
==== 删除

删除分为两种情况：

*单旋*：黄色方块至少存在其一；红色方块可有可无

经过一次`zag`或者`zig`后，可能失衡，需要向上到根部，进行调整。

#figure(
  image("fig\BST\8.png",width: 80%),
  caption:"AVL树的删除"
)

*双旋*

经过两次`zag`或者`zig`后，可能失衡，需要向上到根部，进行调整。

#figure(
  image("fig\BST\9.png",width: 80%),
  caption:"AVL树的删除"
)

```cpp
template <typename T> bool AVL<T>::remove( const T & e ) {
    BinNodePosi<T> & x = search( e ); if ( !x ) return false; //若目标的确存在
    removeAt( x, _hot ); _size--; //则在按BST规则删除之后， _hot及祖先均有可能失衡
    // 以下，从_hot出发逐层向上，依次检查各代祖先g
    for ( BinNodePosi<T> g = _hot; g; g = g->parent ) {
        if ( ! AvlBalanced( *g ) ) //一旦发现g失衡，则通过调整恢复平衡
            g = FromParentTo( *g ) = rotateAt( tallerChild( tallerChild( g ) ) );
        updateHeight( g ); //更新高度（注意：即便g未曾失衡或已恢复平衡，高度均可能降低）
    } //可能需做过Ω(logn)次调整；无论是否做过调整，全树高度均可能下降
    return true; //删除成功
}
```
==== (3+4)-重构

`zig`和`zag`的最终是通过(3+4)-重构来实现的。

设`g`为最低的失衡节点，沿最长分支考察祖孙三代： `g ~ p ~ v`
按中序遍历次序，重命名为： `a < b < c`；

它们总共拥有四棵子树（或为空），按中序遍历次序，重命名为：`T0 < T1 < T2 < T3`。

#figure(
  image("fig\BST\10.png",width: 80%),
  caption:"(3+4)-重构"
)

```cpp
template <typename T> BinNodePosi<T> BST<T>::connect34(
BinNodePosi<T> a, BinNodePosi<T> b, BinNodePosi<T> c,
BinNodePosi<T> T0, BinNodePosi<T> T1,
BinNodePosi<T> T2, BinNodePosi<T> T3)
{
    a->lc = T0; if (T0) T0->parent = a;
    a->rc = T1; if (T1) T1->parent = a;
    c->lc = T2; if (T2) T2->parent = c;
    c->rc = T3; if (T3) T3->parent = c;
    b->lc = a; a->parent = b; b->rc = c; c->parent = b;
    updateHeight(a); updateHeight(c); updateHeight(b); return b;
}
```
利用3+4重构，实现`zag`和`zig`：

```cpp
template<typename T> BinNodePosi<T> BST<T>::rotateAt( BinNodePosi<T> v ) {
    BinNodePosi<T> p = v->parent, g = p->parent;
    if ( IsLChild( * p ) ) //zig
    if ( IsLChild( * v ) ) { //zig-zig
        p->parent = g->parent;
        return connect34( v, p, g, v->lc, v->rc, p->rc, g->rc );
    } else { //zig-zag
        v->parent = g->parent;
        return connect34( p, v, g, p->lc, v->lc, v->rc, g->rc );
    }
else //zag
    if ( IsRChild( * v ) ) { //zag-zag
        p->parent = g->parent;
        return connect34( g, p, v, g->lc, p->lc, v->lc, v->rc );
    } else { //zag-zig
        v->parent = g->parent;
        return connect34( g, v, p, g->lc, v->lc, v->rc, p->rc );
    }
}
```

=== AVL综合评价

优点：
- 无论查找、插入或删除，最坏情况下的复杂度均为$O(log n)$
- $O(n)$的存储空间

缺点：
- 借助高度或平衡因子，为此需改造元素结构，或额外封装；实测复杂度与理论值尚有差距
- 插入/删除后的旋转，成本不菲
- 删除操作后，最多需旋转$Omega(log n)$次（Knuth：平均仅0.21次）
- 若需频繁进行插入/删除操作，未免得不偿失
- 单次动态调整后，全树拓扑结构的变化量可能高达$Omega(log n)$