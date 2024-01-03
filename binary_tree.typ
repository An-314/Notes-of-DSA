= 二叉树Binary Tree

- 树是有层次结构的表示：
  - 表达式
  - 文件系统
  - URL
- 树是综合性的数据结构
  - 兼具Vector和List的优点
  - 兼顾高效的查找、 插入、 删除
- 树是半线性的结构
  - 不再是简单的线性结构，但在确定某种次序之后，具有线性特征

== 二叉树Binary Tree
=== 图论基础
==== 有根树Rooted tree

树是极小连通图、极大无环图$T(V,E)$，节点数$n=|V|$，边数$e=|E|$。

指定一个节点$r in V$作为根节点，其他节点到根节点有唯一路径，称为有根树。

若$T_1,T_2,...T_d$为有根树，则$T =( (union.big_i T_i) union {r}, ((union.big_i E_i ))union {<r,r_i>|1<= i <= d})$为有根树。相对于$T$，$T_i$被称为以$r_i$为根的子树。
==== 有序树Ordered Tree

有根树中，节点的子树有次序，称为有序树。

可以证明树的结点和边满足$n=e+1$。
==== 连通+无环

连通与无环意味着任意两个节点只有一条路径，即不存在环。

从而可以从根出发，对树进行深度的等价类划分。
==== 深度+层次

节点$v$的深度定义为$"depth"(v) = |"path"(v)|$，其中$"path"(v)$为从根到$v$的路径。

根节点和叶子的深度为0，其他节点的深度为其父节点的深度加1，空树的深度为-1。

所有叶子深度的最大者叫作树的高度，即$"height"(T) = max{"depth"(v)|v in V}$。

=== 树的表示

树提供接口：

#table(
  columns: (auto, auto, auto, auto, auto, auto, auto,),
  align: horizon,
  [`root()`], [`parent()`], [`firstChild()`], [`nextSibling()`],
  [`insert(i, e)`],  [`remove(i)`], [`traverse()`],
  [根节点], [父节点], [第一个孩子], [下一个兄弟],
  [插入], [删除], [遍历],
)

树可以用线性结构储存：
+ 利用父节点的信息

  除了根节点，每个节点都有一个父节点，可以用线性结构储存。在一个数组`data`存储树节点的值；另开一个数组`parent`存储每个节点的父节点的下标，根节点的父节点下标为其本身。

+ 利用孩子节点的信息

  除了叶子节点，每个节点都有一个孩子节点，可以用线性结构储存。在一个数组`data`存储树节点的值；另开一个数组`children`存储每个节点的第一个孩子节点的下标，如果有多个孩子就用链表储存所有的孩子。

+ 父节点+孩子节点

  前面的方法要么只能访问孩子节点，要么只能访问父节点。三个数组同时使用就能双向访问。

=== 二叉树Binary Tree

二叉树是所有节点的（出）度数都不超过2的树。是有根、有序的树。
==== 二叉树和多叉树的等价变换

有根、有序的多叉树和二叉树可以相互转换。

#figure(
  image("fig\树\1.png",width: 80%),
  caption: "多叉树和二叉树的等价变换",
)
只要是多叉树中，一个节点的长子，成为二叉树的左儿子，其他的兄弟顺延成为右儿子。也就是说在二叉树中每个节点的右儿子们都是原来的兄弟，左儿子是原来的长子。
==== 满二叉树
==== 真二叉树

引入$n_1+2n_0$个外部节点`null`，使得每个节点都有两个儿子，称为真二叉树。

对于红黑树之类的结构，真二叉树可以用来简化描述、理解、实现、分析。

=== 二叉树的实现

用节点`BinNode`表示二叉树的节点，用`BinTree`表示二叉树。
```cpp
template <typename T> using BinNodePosi = BinNode<T>*; //节点位置
template <typename T> struct BinNode {
    BinNodePosi<T> parent, lc, rc; //父亲、孩子
    T data; Rank height, npl; Rank size(); //高度、 npl、子树规模
    BinNodePosi<T> insertAsLC( T const & ); //作为左孩子插入新节点
    BinNodePosi<T> insertAsRC( T const & ); //作为右孩子插入新节点
    BinNodePosi<T> succ(); //（中序遍历意义下）当前节点的直接后继
    template <typename VST> void travLevel( VST & ); //层次遍历
    template <typename VST> void travPre( VST & ); //先序遍历
    template <typename VST> void travIn( VST & ); //中序遍历
    template <typename VST> void travPost( VST & ); //后序遍历
};
```
并且直接实现引入新节点
```cpp
template <typename T>
BinNodePosi<T> BinNode<T>::insertAsLC( T const & e )
    { return lc = new BinNode( e, this ); }
template <typename T>
BinNodePosi<T> BinNode<T>::insertAsRC( T const & e )
    { return rc = new BinNode( e, this ); }
```
用`BinNode`实现`BinTree`，并且实现`BinTree`的接口
```cpp
template <typename T> class BinTree {
protected: 
    Rank _size; //规模
    BinNodePosi<T> _root; //根节点
    virtual Rank updateHeight( BinNodePosi<T> x ); //更新节点x的高度
    void updateHeightAbove( BinNodePosi<T> x ); //更新x及祖先的高度
public: 
    Rank size() const { return _size; } //规模
    bool empty() const { return !_root; } //判空
    BinNodePosi<T> root() const { return _root; } //树根
    /* ... 子树接入、删除和分离接口；遍历接口 ... */
}
```
引入新节点，用顺序直接重载函数，表示左右插入
```cpp
BinNodePosi<T> BinTree<T>::insert( BinNodePosi<T> x, T const & e ); //作为右孩子
BinNodePosi<T> BinTree<T>::insert( T const & e, BinNodePosi<T> x ) { //作为左孩子
    _size++;
    x->insertAsLC( e );
    updateHeightAbove( x ); //及时维护高度
    return x->lc;
}
```
接入子树
```cpp
BinNodePosi<T> BinTree<T>::attach( BinTree<T>* &S, BinNodePosi<T> x ); //接入左子树
BinNodePosi<T> BinTree<T>::attach( BinNodePosi<T> x, BinTree<T>* &S ) { //接入右子树
    if ( x->rc = S->_root ) //去除插入空树的情况
        x->rc->parent = x;
    _size += S->_size;
    updateHeightAbove(x); //及时维护高度
    S->_root = NULL; S->_size = 0;
    release(S); S = NULL;
    return x;
}
```
用`if`中的赋值大大化简了代码量，其中实时更新高度的函数为
```cpp
#define stature(p) ( (int) ( (p) ? (p)->height : -1 ) ) //空树高度-1，以上递推
template <typename T> //勤奋策略：及时更新节点x高度，具体规则因树不同而异
Rank BinTree<T>::updateHeight( BinNodePosi<T> x ) //此处采用常规二叉树规则， O(1)
    { return x->height = 1 + max( stature( x->lc ), stature( x->rc ) ); }
template <typename T> //更新节点及其历代祖先的高度
void BinTree<T>::updateHeightAbove( BinNodePosi<T> x ) //O( n = depth(x) )
    { while (x) { updateHeight(x); x = x->parent; } } //可优化
```
分离子树
```cpp
template <typename T> BinTree<T>* BinTree<T>::secede( BinNodePosi<T> x ) {
    FromParentTo( * x ) = NULL; updateHeightAbove( x->parent );
// 以上与BinTree<T>::remove()一致；以下还需对分离出来的子树重新封装
    BinTree<T> * S = new BinTree<T>; //创建空树
    S->_root = x; x->parent = NULL; //新树以x为根
    S->_size = x->size(); _size -= S->_size; //更新规模
    return S; //返回封装后的子树
}
```
== 二叉树的遍历

#figure(
  image("fig\树\2.png",width: 80%),
  caption: "二叉树的遍历",
)

树的遍历是按照一定顺序，访问树中的每个节点，且每个节点仅访问一次。

如果采用最直接的递归方式
```cpp
/* 先序遍历 */
template <typename T, typename VST>
void traverse( BinNodePosi<T> x, VST & visit ) {
    if ( ! x ) return;
    visit( x->data );
    traverse( x->lc, visit );
    traverse( x->rc, visit );
} //O(n)
/* 中序遍历 */
template <typename T, typename VST>
void traverse( BinNodePosi<T> x, VST & visit ) {
    if ( !x ) return;
    traverse( x->lc, visit );
    visit( x->data );
    traverse( x->rc, visit ); //tail
}
/* 后序遍历 */
template <typename T, typename VST>
void traverse( BinNodePosi<T> x, VST & visit ) {
    if ( ! x ) return;
    traverse( x->lc, visit );
    traverse( x->rc, visit );
    visit( x->data );
}

```
则会导致栈溢出，因为递归深度与树的高度成正比。
=== 先序遍历

按照$x|L|R$的顺序进行遍历，如下图

#figure(
  image("fig\树\3.png",width: 80%),
  caption: "先序遍历",
)
观察图，发现，可以理解为藤缠树。先顺着左儿子构成的藤爬下去，再顺着右儿子构成的藤爬上去；每个右儿子都是一棵子树，在子树中递归地调用先序遍历即可。

沿着左侧藤，整个遍历过程可分解为：
- 自上而下访问藤上节点，再
- 自下而上遍历各右子树
各右子树的遍历彼此独立自成一个子任务

爬藤而下：
```cpp
template <typename T, typename VST> static void visitAlongVine
( BinNodePosi<T> x, VST & visit, Stack < BinNodePosi<T> > & S ) { //分摊O(1)
    while ( x ) { //反复地
        visit( x->data ); //访问当前节点
        S.push( x->rc ); //右孩子（右子树）入栈（将来逆序出栈）
        x = x->lc; //沿藤下行
    } //只有右孩子、 NULL可能入栈——增加判断以剔除后者，是否值得？
}
```
先序遍历：
```cpp
template <typename T, typename VST>
void travPre_I2( BinNodePosi<T> x, VST & visit ) {
    Stack < BinNodePosi<T> > S; //辅助栈
    while ( true ) { //以右子树为单位， 逐批访问节点
        visitAlongVine( x, visit, S ); //访问子树x的藤蔓，各右子树（根）入栈缓冲
        if ( S.empty() ) break; //栈空即退出
        x = S.pop(); //弹出下一右子树（根）
    } //#pop = #push = #visit = O(n) = 分摊O(1)
}
```
用栈记录沿藤而下的节点，再向上去访问右子树。如果右子树还需要爬藤，就继续进栈出栈。

先序遍历是在向下爬藤时，就把左儿子遍历的。而下面的中序遍历在向下爬藤时，只进栈，等到向上爬藤时才遍历（，随即立刻遍历其右儿子）。
=== 中序遍历

按照$L|x|R$的顺序进行遍历，如下图

#figure(
  image("fig\树\4.png",width: 80%),
  caption: "中序遍历",
)

沿着左侧藤，遍历可*自底而上*分解为$d+1$步迭代：访问藤上节点，再遍历其右子树。各右子树的遍历彼此独立，自成一个子任务。

自藤底向上爬：
```cpp
template <typename T> 
static void goAlongVine(BinNodePosi<T> x, Stack < BinNodePosi<T> > & S){
    while ( x )
    { S.push( x ); x = x->lc; }
} //逐层深入，沿藤蔓各节点依次入栈
```
中序遍历：
```cpp
template <typename T, typename V> void travIn_I1( BinNodePosi<T> x, V& visit ) {
    Stack < BinNodePosi<T> > S; //辅助栈
    while ( true ) { //反复地
        goAlongVine( x, S ); //从当前节点出发，逐批入栈
        if ( S.empty() ) break; //直至所有节点处理完毕
        x = S.pop(); //x的左子树或为空，或已遍历（等效于空），故可以
        visit( x->data ); //立即访问之
        x = x->rc; //再转向其右子树（可能为空，留意处理手法）
    }
}
```
和先序遍历的区别是，读取藤的时机。先序遍历向下爬藤时读取，中序遍历向上爬藤时读取。

其复杂度是$O(n)$的，因为一共执行$O(n)$次`pop`和`push`，每次`pop`和`push`都是$O(1)$的。
==== 前驱和后继

考虑一个节点的后继：如果有右子树，直接后继是最靠左的右后代：相当于沿着该节点的右儿子爬藤而下到底。如果没有右子树，需要找最低的左祖先：相当于辅助栈中的下一个节点，寻找的方法是一直寻找父亲，直到访问的这条路成为了某一个父亲的左儿子。

```cpp
//在中序遍历意义下的直接后继
//稍后将被BST::remove中的removeAt()调用
template <typename T>
BinNodePosi<T> BinNode<T>::succ() {
    BinNodePosi<T> s = this;
        if ( rc ) { //若有右孩子，则
        s = rc; //直接后继必是右子树中的
        while ( HasLChild( * s ) )
        s = s->lc; //最小节点
    }else { //否则
        //后继应是“以当前节点为直接前驱者”
        while ( IsRChild( * s ) )
        s = s->parent; //不断朝左上移动
        //最后再朝右上移动一步
        s = s->parent; //可能是NULL
    }
    return s; //两种情况下，运行时间分别为
} //当前节点的高度与深度，不过O(h)
```
=== 后序遍历

子树的删除和`BinNode::size()`和` BinTree::updateHeight()`维护，就是一个后序遍历的例子。

按照$L|R|x$的顺序进行遍历，如下图

#figure(
  image("fig\树\5.png",width: 80%),
  caption: "后序遍历",
)

从根出发下行尽可能沿左分支，实不得已才沿右分支，这样找到*leftmost leaf*。最后一个节点必是叶子，而且是按中序遍历次序最靠左者，也是递归版中`visit()`首次执行处。

#figure(
  image("fig\树\6.png",width: 40%),
  caption: "后序遍历",
)

在沿着这条曲折的藤向上爬时，如果有右儿子，就对右子树进行递归，没有就向上走。这条藤事实上在右子树封装的情况下实现了后序遍历，只需要把封装的右子树展开。

寻找`leftmost leaf`
```cpp
template <typename T> static void gotoLeftmostLeaf( Stack <BinNodePosi<T>> & S ) {
    while ( BinNodePosi<T> x = S.top() ) //自顶而下反复检查栈顶节点
        if ( HasLChild( * x ) ) { //尽可能向左。在此之前
            if ( HasRChild( * x ) ) //若有右孩子，则
            S.push( x->rc ); //优先入栈
            S.push( x->lc ); //然后转向左孩子
        } else //实不得已
            S.push( x->rc ); //才转向右孩子
    S.pop(); //返回之前，弹出栈顶的空节点
}
```
后序遍历：
```cpp
template <typename T, typename V> void travPost_I( BinNodePosi<T> x, V & visit ) {
    Stack < BinNodePosi<T> > S; //辅助栈
    if ( x ) S.push( x ); //根节点首先入栈
    while ( ! S.empty() ) { //x始终为当前节点
        if ( S.top() != x->parent ) //若栈顶非x之父（而为右兄），则
            gotoLeftmostLeaf( S ); //在其右兄子树中找到最靠左的叶子
        x = S.pop(); //弹出栈顶（即前一节点之后继）以更新x
        visit( x->data ); //并随即访问之
    }
}
```

也可以分析得到复杂度是$O(n)$的。

==== 表达式

一个运算表达式可以存储在一个树种，每个节点是一个运算符，每个叶子是一个操作数。括号的层级就是树的深度。

#figure(
  image("fig\树\8.png",width: 80%),
  caption: "表达式",
)

#figure(
  image("fig\树\9.png",width: 80%),
  caption: "表达式",
)

可以看出这些红色和绿色的节点构成一棵树，就是下面的表达式树。

#figure(
  image("fig\树\7.png",width: 80%),
  caption: "表达式树",
)

而先序、中序、后序遍历就是表达式的前缀、中缀、后缀表示。
=== 层次遍历

层次遍历是按照层次进行遍历。可以用一个队列实现：

在取出一个节点时，把它的左右儿子入队，这样达到的效果是按照顺序，将每一层的节点从左向右遍历。

```cpp
template <typename T> template <typename VST>
void BinNode<T>::travLevel( VST & visit ) { //二叉树层次遍历
    Queue< BinNodePosi<T> > Q; Q.enqueue( this ); //引入辅助队列，根节点入队
    while ( ! Q.empty() ) { //在队列再次变空之前，反复迭代
        BinNodePosi<T> x = Q.dequeue(); visit( x->data ); //取出队首节点并随即访问
        if ( HasLChild( *x ) ) Q.enqueue( x->lc ); //左孩子入队
        if ( HasRChild( *x ) ) Q.enqueue( x->rc ); //右孩子入队
    }
}
```

== 二叉树的重构

二叉树的重构是指，已知二叉树的遍历序列，重构出二叉树。

=== [先序|后序]+中序

已知先序和中序，可以重构出二叉树。

先序序列：$x|L|R$

中序序列：$L|x|R$

先序序列的第一个节点是根节点，中序序列中根节点左边的是左子树，右边的是右子树。

后序同理。

=== 先序+后序

不能重构，因为无法确定左右子树。

=== 增强序列

在输出遍历序列时，将`NULL`也输出，这样就可以重构出二叉树。

可归纳证明：在增强的先序、后序遍历序列中
1. 任一子树依然对应于一个子序列，而且
2. 其中的`NULL`节点恰比非`NULL`节点多一个

== Huffman编码树

如何对各字符编码，使文件最小？
=== PFC编码

将字符集$Sigma$中的字符组织成一棵二叉树，以0/1表示左/右孩子，各字符$x$分别存放于对应的叶子$v(x)$中。

字符$x$的编码串$"rps"(v(x))="rps"(x)$由根到$v(x)$的通路（root path）确定

字符编码不必等长，而且不同字符的编码互不为前缀，故不致歧义（Prefix-Free Code）。

#figure(
  image("fig\树\10.png",width: 40%),
  caption: "PFC编码",
)

按照这样的方法可以分析编码长度。

平均编码长度
$
"ald"(T) = sum_(x in Sigma) "depth"(v(x)) / (|Sigma|)
$
定义对于特定的字符集$Sigma$，$"ald"(T)$最小的二叉树$T_("Opt")$为$Sigma$的最优编码树（Optimal Code Tree）。
=== 最优编码树

最优编码树的性质：
$
forall v in T_("Opt") : "deg"(v)=0 <=> "depth"(v) >= "depth"(T_("Opt")) -1
$
亦即，叶子只能出现在倒数两层以内——否则，通过节点交换即可调整到更优的编码树。

#figure(
  image("fig\树\11.png",width: 80%),
  caption: "最优编码树",
)
=== 最优带权编码树

已知各字符的期望频率，此时的最优编码树称为最优带权编码树（Optimal Weighted Code Tree）。

文件长度 $prop$ 平均带权深度 $"wald"(T) = sum_(x in Sigma) "rps"(x) times w(x)$。此时，完全树未必就是最优编码树。

同样，频率高/低的（超）字符，应尽可能放在高/低处，通过适当交换，同样可以缩短$"wald"(T)$。
=== Huffman的贪心策略

频率低的字符优先引入，其位置亦更低。

#figure(
  image("fig\树\12.png",width: 50%),
  caption: "最优编码树",
)

```cpp
为每个字符创建一棵单节点的树，组成森林F
按照出现频率，对所有树排序
while ( F中的树不止一棵 )
    取出频率最小的两棵树： T1和T2
    将它们合并成一棵新树T，并令：
        lc(T) = T1 且 rc(T) = T2
        w( root(T) ) = w( root(T1) ) + w( root(T2) )
//尽管贪心策略未必总能得到最优解， 但非常幸运，如上算法的确能够得到最优编码树之一
```
将树合成子树，每次比较根节点的权重，取出最小的两棵树，合成一棵新树，再放回去。可以用优先队列优化。

可以证明，Huffman编码树是最优带权编码树。

下面是代码实现。
先定义Huffman（超）字符
```cpp
#define N_CHAR (0x80 - 0x20) //仅以可打印字符为例
struct HuffChar { //Huffman（超）字符
    char ch; unsigned int weight; //字符、频率
    HuffChar ( char c = '^', unsigned int w = 0 ) : ch ( c ), weight ( w ) {};
    bool operator< ( HuffChar const& hc ) { return weight > hc.weight; } //比较器
    bool operator== ( HuffChar const& hc ) { return weight == hc.weight; } //判等器
};
```
再定义Huffman编码树
```cpp
using HuffTree = BinTree< HuffChar >; //Huffman编码树
using HuffForest = List< HuffTree* >; //Huffman森林
/* 可以替换接口... */
using HuffForest = PQ_List< HuffTree* >; //基于列表的优先级队列
using HuffForest = PQ_ComplHeap< HuffTree* >; //完全二叉堆
using HuffForest = PQ_LeftHeap< HuffTree* >; //左式堆
```
构造编码树：反复合并二叉树
```cpp
HuffTree* generateTree( HuffForest * forest ) { //Huffman编码算法
    while ( 1 < forest->size() ) { //反复迭代，直至森林中仅含一棵树
        HuffTree *T1 = minHChar( forest ), *T2 = minHChar( forest );
        HuffTree *S = new HuffTree(); //创建新树，然后合并T1和T2
        S->insert( HuffChar('^', T1->root()->data.weight + T2->root()->data.weight) );
        S->attach( T1, S->root() ); S->attach( S->root(), T2 );
        forest->insertAsLast( S ); //合并之后，重新插回森林
    } //assert: 森林中最终唯一的那棵树，即Huffman编码树
    return forest->first()->data; //故直接返回之
}
```
查找最小超字符：遍历List/Vector
```cpp
HuffTree* minHChar( HuffForest* forest ) { //此版本仅达到O(n)，故整体为O(n2)
    ListNodePosi<HuffTree*> m = forest->first(); //从首节点出发，遍历所有节点
    for ( ListNodePosi<HuffTree*> p = m->succ; forest->valid( p ); p = p->succ )
        if( m->data->root()->data.weight > p->data->root()->data.weight ) //不断更新
            m = p; //找到最小节点（所对应的Huffman子树）
    return forest->remove( m ); //从森林中取出该子树，并返回
} //Huffman编码的整体效率，直接决定于minHChar()的效率
```
构造编码表：遍历二叉树
```cpp
#include "Hashtable.h" //用HashTable实现
using HuffTable = Hashtable< char, char* >; //Huffman编码表
static void generateCT //通过遍历获取各字符的编码
( Bitmap* code, int length, HuffTable* table, BinNodePosi<HuffChar> v ) {
    if ( IsLeaf( * v ) ) //若是叶节点（还有多种方法可以判断）
        { table->put( v->data.ch, code->bits2string( length ) ); return; }
    if ( HasLChild( * v ) ) //Left = 0，深入遍历
        { code->clear( length ); generateCT( code, length + 1, table, v->lc ); }
    if ( HasRChild( * v ) ) //Right = 1
        { code->set( length ); generateCT( code, length + 1, table, v->rc ); }
} //总体O(n)
```
=== Huffman树的改进

1. 基于向量或者列表

    基于向量或数组的森林每次插入树都要寻找合适的位置以保证有序，这导致查找需要$O(n)$的时间，从而使得整体的复杂度为$O(n^2)$。

2. 基于堆

    可以将所有树组成一个优先级队列，每次取出最小的两棵树，合并成一棵新树，再放回去。这样可以将复杂度降低到$O(n log n)$。

3. 基于栈+队列

    还有一个小技巧是，先经过$O(n log n)$的预排序。再将
    - 所有字符按频率非升序入栈 $O(n log n)$
    - 维护另一（有序） 队列 $O(n)$

    每次看栈顶两个元素与队首元素，取两个最小的，合并成一棵新树，入队。这样可以将复杂度降低到$O(n log n)$。

    #figure(
        image("fig\树\13.png",width: 80%),
        caption: "基于栈+队列的Huffman编码树",
        )
