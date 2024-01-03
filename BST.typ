= 更多BST
== 区间树Interval Tree

看这样一个问题：

_*Stabbing Query:*给定集合_
$
S = {s_i=[x_i,x'_i] | 1<=i<=n}
$
_以及一个待查询的点$q_x$，目标是寻找所有的$s_i$，使得$q_x$在$s_i$的区间内，即_
$
{s_i | q_x in s_i}
$

为解决这个问题，我们引入*区间树*。

为了方便查询，我们需要进行预处理：

先找出区间端点构成的集合$P=diff S$，有$|P|=2n$。令$x_mid$为$P$中的中位数。

#figure(
    image("fig\BST\11.png" ,width: 70%),
    caption: "区间树——中位数",
)

这些集合可分成三部分，$S_"left"$是所有在$x_mid$左侧的区间，$S_"right"$是所有在$x_mid$右侧的区间，$S_"mid"$是所有包含$x_mid$的区间。

而$S_"left"$和$S_"right"$又可以分别继续递归地进行划分，直到只剩下一个区间，或者没有区间。

#figure(
    image("fig\BST\12.png" ,width: 80%),
    caption: "区间树——划分",
)

这样，我们就得到了一棵二叉搜索树，称为*区间树*。

*平衡性*：区间树的高度为$O(log n)$。

$
max{|S_"left"|,|S_"right"|} <= n/2
$

为了方便查询，我们还需要组织好区间树的结构。保证所有$S_"mid"$的区间都按照左/右排序。

#figure(
    image("fig\BST\13.jpg" ,width: 50%),
    caption: "区间树——排序",
)

*空间大小*：是$O(n)$的，因为每个区间只会在节点出现两次。

*构造*：构造的时间是$O(n log n)$的，依次排序即可。

*查询*：

```cpp
def queryIntervalTree( v, qx ):
if ( ! v ) return; //base
if ( qx < xmid(v) )
    report all segments of Smid(v) containing qx;
    queryIntervalTree( lc(v), qx );
else if ( xmid(v) < qx )
    report all segments of Smid(v) containing qx;
    queryIntervalTree( rc(v), qx );
else //with a probability ≈ 0
    report all segments of Smid( v ); //both rc(v) & lc(v) can be ignored
```

在查询时候，每次都从根节点开始，如果$q$在当前节点的区间内，则将当前节点加入结果集，然后递归地查询左右子树。总的查询时间是$O(log n + k)$的，其中$k$是结果集的大小。
== 线段树Segment Tree
=== 基本区间Elementary Intervals
对于$n$个区间$I = {s_i=[x_i,x'_i] | 1<=i<=n}$，可以将区间端点排序${p_1,p_2,...,p_{m}}$，其中$m<=2n$。将整个区间分成$m+1$个基本区间，$(-oo,p_1],(p_1,p_2],...,(p_m,oo)$。

对于给定的区间，我们就可以实现离散化（Discretization）。在每段基本区间上，他们有一样的性质。

#figure(
    image("fig\BST\14.png" ,width: 80%),
    caption: "线段树——基本区间",
)

可以用$O(log n)$二分查找目标区间，然后在$O(k)$的进行输出，其中$k$是结果集的大小。

#figure(
    image("fig\BST\15.png" ,width: 60%),
    caption: "线段树——基本区间——最坏情况",
)
但最坏情况需要占用$O(n^2)$的空间。

=== 线段树Segment Tree

为了解决上述问题，我们引入线段树。线段树是个完全二叉树，最底层的每个节点都是一个基本区间。

#figure(
    image("fig\BST\16.png" ,width:70%),
    caption: "线段树",
)
在存储的时候，先在最底层存满，对有共同祖先的区间向上贪婪合并(greedy merging)。

对于多个区间可以如下储存：

#figure(
    image("fig\BST\17.png" ,width: 70%),
    caption: "线段树——储存",
)

这些合并的区间被称为*标准子集Canonical Subsets*，占用的空间是$O(n log n)$的。

```cpp
def BuildSegmentTree(I):
Sort all endpoints in I before
    determining all the EI's //O(nlogn)
Create T a BBST on all the EI's //O(n)
    Determine R(v) for each node v
//O(n) if done in a bottom-up manner
For each s of I
    InsertSegment( T.root, s )
```
每次插入区间贪婪合并，但事实上实现是从顶层摔下去，保留包含在插入标区间内的节点区间。
```cpp
def InsertSegment( v , s ):
if ( R(v) is subset of s ) //greedy by top-down
    store s at v and return;
if ( R( lc(v) ) ∩ s != Empty ) //recurse
    InsertSegment( lc(v), s );
if ( R( rc(v) ) ∩ s != Empty ) //recurse
    InsertSegment( rc(v), s );
```
需要$O(log n)$的时间。

查询也很容易，只需要从根到叶子，逐层报告结果即可。
```cpp
def Query( v , qx ):
report all the intervals in Int(v)
if ( v is a leaf )
    return
if ( qx in R( lc(v) ) )
    Query( lc(v), qx )
else //qx in R( rc(v) )
    Query( rc(v), qx )
```
查询的时间是$O(log n + k)$的，其中$k$是结果集的大小。因为每次在标准子集上的时间是$k_i+1$，而从根到叶子的时间是$O(log n)$。

== 高阶搜索树Multi-Level Search Tree

=== Range Query

考虑Range Query问题
==== 1D情况

给定$P={p_1,p_2,...,p_n}$是在数轴上排列的$n$个点，给定一个查询区间$I= [x,y]$，目标是找出所有在$I$内的点。

Brute-Force的方法是$O(n)$的。

但是我们可以用二分查找的方法：先补充$P[0] = -oo$，可以二分查找$I$的右端点，之后回退，直到找到左端点。这样可以将时间降低到$O(log n + k)$，其中$k$是结果集的大小。

```cpp
For any interval I = (x1, x2]
    Find t = search(x2) = max{ i | p[i] <= x2 } //O(logn)
    Traverse the vector BACKWARD from p[t] and report each point //O(k)
    until escaping from I at point p[s]
    return k = t - s //output size
```

输出敏感度（Output-Sensitivity）：如果$k$很小，那么算法的时间就很小。但是如果$k$很大，可能不如两次二分查找。

这个方法也无法拓展到2D情况。
==== 2D情况

给定$P={p_1,p_2,...,p_n}$是在平面上排列的$n$个点，给定一个查询区间$I= [x_1,x_2] * [y_1,y_2]$，目标是找出所有在$I$内的点。

可以用类似动态规划的记忆法记住从左下角到该点的信息，再用容斥原理，可以得到一个小矩形内的信息。

#figure(
    image("fig\BST\18.png" ,width: 80%),
    caption: "Range Query——2D——预处理",
)

这样，我们就可以在$O(log n)$（因为要用二分查找最近的给定点）的时间内得到一个小矩形内的信息。

#figure(
    image("fig\BST\19.png" ,width: 80%),
    caption: "Range Query——2D——查询",
)

但要占用$O(n^2)$的空间。

=== Multi-Level Search Tree: 1D

结构是一个Complete (Balanced) BST，重构成以下形式：

#figure(
    image("fig\BST\20.png" ,width: 80%),
    caption: "Multi-Level Search Tree——1D",
)

$
forall v , v."key" = min{u."key" | u in v."rTree"} = v."succ.key"
$
则有性质$forall u in v."lTree" , u."key" < v."key"$和$forall u in v."rTree" , u."key" >= v."key"$。令`search(x)`返回最大的$u$，使得$u."key" <= x$。

保证树是完全二叉的，这样可以保证叶节点恰好存满所有给定的数据。这棵树可以在一个完全二叉树的基础上改进得到。原先二叉树最下层的每一个节点的左儿子（如果没有的话）存其前驱，而右节点存自己本身，就可以得到这棵树。

核心想法是寻找最低的公共祖先（Lowest Common Ancestor）

#figure(
    image("fig\BST\21.png" ,width: 80%),
    caption: "Multi-Level Search Tree——1D——查找",
)

由公共祖先LCA出发，取从左上来的路上节点的右子树，和从右上来的路上节点的左子树，就可以得到结果。

#figure(
    image("fig\BST\22.png" ,width: 80%),
    caption: "Multi-Level Search Tree——1D——查找",
)

查询复杂度是$O(log n + k)$，预处理复杂度是$O(n log n)$，空间复杂度是$O(n)$。

#figure(
    image("fig\BST\23.png" ,width: 80%),
    caption: "Multi-Level Search Tree——1D——总结",
)

用线段树理解就是上图的样子。

=== Multi-Level Search Tree: 2D
==== 2D Range Query = x-Query + y-Query

先对x-Query，再对剩余的候选者做y-Query。

对于最坏的情况，用k-d tree的方法可以做到$O(1 + sqrt(n))$，但是用Multi-Level Search Tree的方法需要做到$O(n)$。

#figure(
    image("fig\BST\24.png" ,width: 80%),
    caption: "Multi-Level Search Tree——2D——最坏情况",
)

==== 2D Range Query = x-Query \* y-Query

需要构造一棵树的树：
- 为第一个维度的query问题 (x-query)构造一个一维的BBST(x-tree)

- 而对于每个x-range tree的节点v，建立一个 y 维度的 BBST(y-tree)，其中包含与 v 关联的标准子集(canonical subset)

也就是构造一个x-tree和数个y-tree，称作Multi-Level Search Tree。

#figure(
    image("fig\BST\25.png" ,width: 50%),
    caption: "Multi-Level Search Tree——2D——查找",
)

这样的复杂度是$O(log^2 n + k)$，其中$k$是结果集的大小。

#figure(
    image("fig\BST\26.png" ,width: 30%),
    caption: "Multi-Level Search Tree——2D——构造",
)

```cpp
Query Algorithm:
1. Determine the canonical subsets of points that satisfy the first query
// there will be O(logn) such canonical sets,
// each of which is just represented as a node in the x-tree
1. Find out from each canonical subset which points lie within the y-range
// To do this,
// for each canonical subset,
// we access the y-tree for the corresponding node
// this will be again a 1D range search (on the y-range)
```
整体的复杂度是：

对于一个2阶搜索树，对于空间中的$n$个点，需要$O(n log n)$的时间构造，$O(n log n)$的空间，$O(log^2 n + k)$的时间查询。
=== Multi-Level Search Tree: dD

对于$d$维的情况，整体的复杂度是：

对于一个$d$阶搜索树，对于空间中的$n$个点，需要$O(n log^{d-1} n)$的时间构造，$O(n log^{d-1} n)$的空间，$O(log^d n + k)$的时间查询。
== kD树k Dimentional Tree

我们想把BBST的搜索策略应用到几何范围搜索（Geometric Range Search,GRS）问题中。

从单一区域（整个平面）开始
- 在每个偶/奇数层上
- 垂直/水平划分区域递归划分子区域
为了使其正常工作
- 每个分区应尽可能均匀（中位数）
- 每个区域定义为开/封在左下方/右上方

大致划分过程如下：
#figure(
    image("fig\BST\27.png" ,width: 80%),
    caption: "kD树——划分",
)

有时候对于二维平面，可以用`quadTree`，四叉树，来进行划分。
#figure(
    image("fig\BST\28.png" ,width: 80%),
    caption: "quadTree",
)
=== kD树的构造

```cpp
buildKdTree(P,d) //construct a 2d-tree for point set P at depth d
    if ( P == {p} ) return createLeaf( p ) //base
    Root = createKdNode()
    Root->SplitDirection = even(d) ? VERTICAL : HORIZONTAL
    Root->SplitLine = findMedian( root->SplitDirection, P ) //O(n)!
    ( P1, P2 ) = divide( P, Root->SplitDirection, Root->SplitLine ) //DAC
    Root->LC = buildKdTree( P1, d + 1 ) //recurse
    Root->RC = buildKdTree( P2, d + 1 ) //recurse
    return( Root )
```
#figure(
    image("fig\BST\29.png" ,width: 80%),
    caption: "kD树——构造",
)
=== 标准子集Canonical Subset

每个节点对应
- 平面的一个矩形子区域，以及
- 子区域中包含的点的子集，每一个都被称为典型子集（Canonical Subset）
对于每个有子节点 `L` 和 `R` 的内部节点 `X`，有：`region(X) = region(L) ∪ region(R)`

同一深度的节点子区域互不相交，且它们的并集覆盖整个平面。

每个二维范围查询都可以由多个 CS 的并集来回答。
=== kD树的查询

```cpp
def kdSearch(v,R): // 热刀来切千（logn）层巧克力
if ( isLeaf( v ) )
    if ( inside( v, R ) ) report(v)
    return
if ( region( v->lc ) ⊆ R )
    reportSubtree( v->lc )
else if ( region( v->lc ) ∩ R != Empty )
    kdSearch( v->lc, R )
if ( region( v->rc ) ⊆ R )
    reportSubtree( v->rc )
else if ( region( v->rc ) ∩ R != Empty )
    kdSearch( v->rc, R )
```

和BBST的查询类似，不断向两个子树递归。
#figure(
    image("fig\BST\30.png" ,width: 80%),
    caption: "kD树——查询",
)

#figure(
    image("fig\BST\31.png" ,width: 80%),
    caption: "kD树——查询",
)

当然，对于最后得结果，我们会发现最终的目标区域还和一些周围的区域有交集。对于这种相交但不包含的，直接查询叶子是否在其中即可。

如果想避免这种情况，可以适当缩小Bounding Box。

#figure(
    image("fig\BST\32.png" ,width: 80%),
    caption: "kD树——查询",
)

=== kD树的性能

- *Preprocessing*：将平面划分成$n$个区域，满足$T(n) = 2T(n/2) + O(n)$，所以$T(n) = O(n log n)$。
- *Storage*：树的高度是$O(log n)$，所以空间是$O(n)$。
- *Query Time*：$O(sqrt(n) + k)$，其中$k$是结果集的大小。
    
    搜索时间取决于 $Q(n)$ ：
    - 递归调用次数，即
    - 与查询区域*相交*的子区域（各级），而在完全在查询区域内的子区域（各级）不会被递归调用。

    可以证明：从被分成四块区域开始，每块分别对应一条边。下面的叙述是对于与一条边相交的情况。
    
    每个被递归的节点至多有2个*孙子*(隔层比较)会被递归，即$Q(n) = 2Q(n/4) + O(1)$，所以$Q(n) = O(sqrt(n))$。

更一般地，对于$d$维的情况，整体的复杂度是：
- constructed: $O(n log n)$
- size: $O(n)$
- query time: $O(n^{1-1/d} + k)$