= 绪论
== 算法

计算机、程序、算法

- 计算 = 信息处理 = 借助某种工具，遵照一定规则，以明确而机械的形式进行
- 计算模型 = 计算机 = 信息处理工具
- 所谓算法，即特定计算模型下，旨在解决特定问题的指令序列

算法的特性：
- *输入* 待处理的信息（问题）
- *输出* 经处理的信息（答案）
- *正确性* 的确可以解决指定的问题
- *确定性* 可描述为一个由基本操作组成的序列
- *可行性* 每一基本操作都可实现，且在常数时间内完成
- *有穷性* 对于任何输入，经有穷次基本操作，都可以得到输出
不能确定有穷的程序不能称之为一个算法。可放宽为期望上有穷，例如几何级数。
== 计算模型

$T_A (P)$ = 算法A求解问题实例P的计算成本

$T_A (n) = max{T_A (P) | |P|=n}$在规模同为$n$的所有实例中，只关注最坏（成本最高）者，有时候我们也会关注期望成分。

为给出客观的评判，需要抽象出一个理想的平台或模型
- 不再依赖于程序员、编译器、计算机、编程语言等具体因素
- 从而直接而准确地描述、测量并评价算法
=== 图灵机Turing Machine(TM)
#figure(
  image("fig\绪论\1.png",width: 80%),
  caption: "图灵机"
)
- 无限长的纸带(Tape)，纸带上有无限多个格子，每个格子上有一个字符
- 读写头(Head)，每次只能读写一个格子，经过一个节拍可以移动一格
- 字符集(Alphabet)，纸带上的字符来自于字符集
- 状态集(State)，有限个状态，每个状态下有一个动作表，约定`h`停机

*转换函数*
```cpp
Transistion(q,c; d, L/R, p)
```
- `q`当前状态
- `c`当前字符
- `d`写入字符
- `L/R`移动方向
- `p`下一状态
特别地，一旦转入约定的状态`h`，则停机。从启动至停机，所经历的节拍数目，即可用以度量计算的成本；亦等于Head累计的移动次数。

下面的例子就是`Increase`算法的TM实现
#figure(
  image("fig\绪论\2.png",width: 80%),
  caption: "Increase算法的TM实现"
)
=== 随机存取机Random Access Machine(RAM)

#figure(
  image("fig\绪论\3.png",width: 80%),
  caption: "RAM"
)
- 无限长的存储器(Memory)，存储器被划分为若干个存储单元，每个存储单元存储一个字
- call-by-rank，每次可以直接访问任意存储单元

与TM模型一样， RAM模型也是一般计算工具的简化与抽象，使我们可以独立于具体的平台，对算法的效率做出可信的比较与评判。

在这些模型中
- 算法的运行时间 $prop$ 算法需要执行的基本操作次数
- $T(n) = $算法为求解规模为$n$的问题，所需执行的基本操作次数

下面的例子就是`Ceiling Division`算法的RAM实现
#figure(
  image("fig\绪论\4.png",width: 80%),
  caption: "Ceiling Division算法的RAM实现"
)
== 渐进复杂度Big-O Notation

渐近分析：更关心问题规模足够大之后，计算成本的增长趋势。

借用渐进分析中的$O$、$Omega$和$Theta$符号来描述算法的渐进复杂度。
=== 多项式复杂度

==== $O(1)$:constant

这类算法的效率最高。

可能含循环、分支、递归等语句，但其执行次数与问题规模无关。
==== $O(log^c n)$:poly-logarithmic

这类算法非常有效，复杂度无限接近于常数。
$
forall c > 0, log n = O(n^c)
$
==== $O(n^c)$:polynomial

线性（linear function）：$O(n)$

从$O(1)$ 到 $O(n^2)$，一般来说都是能接受的。$O(n^2)$有时候也过高。但是更大次幂，是非常低效的。
=== $O(c^n)$:exponential

这类算法的计算成本增长极快，通常被认为不可忍受。

从$O(n^c)$到$O(2^n)$，是从有效算法到无效算法的分水岭。

有些问题的最优算法的复杂度就是指数级的，例如NPC问题。

NPC问题：就目前的计算模型而言，不存在可在多项式时间内解决此问题的算法。并且这类问题的解法，可以在多项式时间内验证。

一个典型的问题是Subset Sum问题。

_给定一个集合$S$，以及一个目标值$T$，判断$S$中是否存在一个子集，其元素之和为$T$。_

_最优的解法是穷举法，复杂度为$O(2^n)$。_

#figure(
  image("fig\绪论\5.png",width: 80%),
  caption: "渐近复杂度的层次级别"
)
== 复杂度分析：级数、递归与主定理Master Theorem
=== 算法分析

两个主要任务 $=$ 正确性（不变性 $times$ 单调性） $+$ 复杂度

为确定后者，不必将算法描述为RAM的基本指令，再累计各条代码的执行次数。C++等高级语言的基本指令，均等效于常数条RAM的基本指令； 在渐近意义下，二者大体相当
- 分支转向： `goto` [算法的灵魂；为结构化而被隐藏]
- 迭代循环： `for()`、 `while()`、 ...  [本质上就是“`if` + `goto`”]
- 调用 + 递归（自我调用） [本质上也是`goto`]

主要方法： 迭代（级数求和）、递归（递归跟踪 $+$ 递推方程）、实用（猜测 $+$ 验证）
=== 级数

一些常见的级数：
- 算术级数（与末项平方同阶）：$1 + 2 + 3 + ... + n = n(n+1)/2=O(n^2)$
- 幂方级数（比幂次高出一阶）：$sum_(i=0)^n i^k = O(n^(k+1))$
- 几何级数（与末项同阶）：$sum_(i=0)^n q^i = (1-q^(n+1))/(1-q) = O(q^n), q>1$
- 收敛级数，例如倒数平方和：$O(1)$
- 几何分布：$(1-lambda) (1+2lambda+3lambda^2+...+n lambda^(n-1)) = O(1)$
- 调和级数：$sum_(i=1)^n 1/i = Theta(log n)$
- 对数级数：$sum_(i=1)^n log i = Theta(n log n)$
- 对数+线性+指数：$sum_(i=1)^n i log i = O(n^2 log n)$，$sum_(i=1)^n i 2^i = O(n 2^n)$
可以通过积分等方法求得。
=== 迭代
可以画图进行分析
- 迭代+算术级数 $O(n^2)$
```cpp
for( int i = 0; i < n; i++ )
for( int j = 0; j < n; j++ )
O1op(const i, const j);

for( int i = 0; i < n; i++ )
for( int j = 0; j < i; j++ )
O1op(const i, const j);
```
- 迭代+级数 $O(n)$
```cpp
for( int i = 1; i < n; i <<= 1 )
for( int j = 0; j < i; j++ )
O1op( const i, const j );
```
- 迭代+复杂级数 如$O(n log n)$
```cpp
for( int i = 0; i <= n; i++ )
for( int j = 1; j < i; j += j )
O1op( const i, const j );
```
=== 封底估算
- 地球（赤道）周长 $≈ 787 times 360/7.2 = 787 times 50 = 39,350 "km"$
- 1天 $= 24"hr" times 60"min" times 60"sec"≈ 25 times 4000 = 10^5 "sec"$
- 1生 $≈$ 1世纪 $= 100"yr" times 365 = 3 times 10^4 "day" = 3 times 10^9 sec$
- “为祖国健康工作五十年” $≈ 1.6 x 10^9 sec$
- “三生三世” $≈ 300 "yr" = 10^10 = (1 "googel")^(1/10) sec$
- 宇宙大爆炸至今 $= 4 times 10^17 > 10^8 times "一生"$
== 迭代与递归
=== 减而治之Decrease-and-conquer

#figure(
  image("fig\绪论\6.png",width: 80%),
  caption: "减而治之"
)
为求解一个大规模的问题，可以
- 将其划分为两个子问题：其一平凡，另一规模缩减
- 分别求解子问题；再由子问题的解，得到原问题的解

例如
```cpp
int SumI( int A[], int n ) {
    int sum = 0; //O(1)
    for ( int i = 0; i < n; i++ ) //O(n)
    sum += A[i]; //O(1)
    return sum; //O(1)
}
/* Decrease-and-conquer:Linear Recursion */
sum( int A[], int n )
{ return n < 1 ? 0 : sum(A, n - 1) + A[n - 1]; }
```
递归跟踪：绘出计算过程中出现过的所有递归实例（及其调用关系）
#figure(
  image("fig\绪论\7.jpg",width: 50%),
  caption: "递归跟踪"
)

本例中，共计$n+1$个递归实例，各自只需$O(1)$时间，故总时间为$O(n)$。开出$n+1$个栈帧，故空间为$O(n)$。

*递推方程*：递归实例的计算成本$T(n)$与其规模$n$的关系
$
T(n) = T(n-1) + O(1) = O(n)
$
本例的复杂度是$O(n)$。

*尾递归*：递归调用出现在函数体的最后一条语句中。尾递归可以被转化为迭代，从而节省空间。

例如，将数组中的区间`A[lo,hi]`前后颠倒`void reverse( int * A, int lo, int hi );`
减治：$"Rev"("lo", "hi") = ["hi"] + "Rev"("lo" + 1, "hi" - 1) + ["lo"]$
```cpp
if (lo < hi) { //递归版
    swap( A[lo], A[hi] );
    reverse( A, lo + 1, hi – 1 );
} //线性递归（尾递归）， O(n)

while (lo < hi) //迭代版
    swap( A[lo++], A[hi--] ); //亦是O(n)
```
=== 分而治之Divide-and-conquer

为求解一个大规模的问题，可以将其划分为若干子问题（通常两个，且规模大体相当）。分别求解子问题，由子问题的解合并得到原问题的解。

#figure(
  image("fig\绪论\8.png",width: 80%),
  caption: "分而治之"
)

例如前面的`SumI`算法，可以改写为
```cpp
/* Divide-and-conquer:Binary Recursion */
sum( int A[], int lo, int hi ) { //区间范围A[lo, hi)
    if ( hi - lo < 2 ) return A[lo];
    int mi = (lo + hi) >> 1; return sum( A, lo, mi ) + sum( A, mi, hi );
} //入口形式为sum( A, 0, n )
```
可以列出递推方程
$
T(n)=2T(n/2)+O(1)=O(n)
$
而对于一般的这种方程，可以用主定理求解

*主定理Master Theorem*
$
T(n)=a T(n/b)+O(f(n))
$
- 若$f(n)=O(n^(log_b a)-epsilon)$，则$T(n)=Theta(n^(log_b a))$
- 若$f(n)=Theta(n^(log_b a) dot log^k n)$，则$T(n)=Theta(n^(log_b a) dot log^(k+1) n)$
- 若$f(n)=Omega(n^(log_b a)+epsilon)$，则$T(n)=Theta(f(n))$

即比较$f(n)$与$n^(log_b a)$的大小关系，若$f(n)$更大，则复杂度为$f(n)$；若相当，则复杂度为$n^(log_b a) dot log^k n$；若更小，则复杂度为$n^(log_b a)$。

几个后面会出现的例子：
- `kd-search`:$T(n)=2T(n/4)+O(1)=O(sqrt(n))$
- `binary search`:$T(n)=T(n/2)+O(1)=O(log n)$
- `merge sort`:$T(n)=2T(n/2)+O(n)=O(n log n)$
- `STL merge sort`:$T(n)=2T(n/2)+O(n log n)=O(n log^2 n)$
- `quickSelect`:$T(n)=T(n/2)+O(n)=O(n)$

例如大数乘法：
1. Naive + DAC
```
    AB
    CD
x_____
  AC
    BD
   AD
   BC        
```
$T(n)=4T(n/2)+O(n)=O(n^2)$
2. Optimal
```
    AB
    CD
x_____
  AC
    BD
   AC
   BD 
(A-B)(D-C)       
```
这样只用计算三个乘法$T(n)=3T(n/2)+O(n)=O(n^(log_2 3))$
=== 例：总和最大区段问题

给定一个整数序列$A[0, n)$，求其总和最大的区段$A[i, j)$，其中$0≤i<j<n$，（有多个时，短者、靠后者优先）。
==== 蛮力算法BF

枚举所有区段，计算其总和，选出最大者。
```cpp
int gs_BF( int A[], int n ){ //蛮力策略： O(n^3)
    int gs = A[0]; //当前已知的最大和
    for ( int i = 0; i < n; i++ )
        for ( int j = i; j < n; j++ ) //枚举所有的O(n^2)个区段！
            int s = 0;
            for ( int k = i; k <= j; k++ ) s += A[k]; //用O(n)时间求和
            if ( gs < s ) gs = s; //择优、 更新
    return gs;
}
```
==== 递增策略

求和时记忆，故相同开头的区段，只需在前者的基础上加上一个元素即可。
```cpp
int gs_IC( int A[], int n ){ //递增策略： O(n^2)
    int gs = A[0]; //当前已知的最大和
    for ( int i = 0; i < n; i++ ) //枚举所有起始于i
        int s = 0;
        for ( int j = i; j < n; j++ ) //终止于j的区间
            s += A[j]; //递增地得到其总和： O(1)
            if ( gs < s ) gs = s; //择优、 更新
    return gs;
}
```
=== 分治策略：前缀 + 后缀
$
A["lo", "hi") = A["lo", "mi") union A["mi", "hi") = P union S
$
借助递归，便可求得$P,S$内部的`GS`；而剩余的实质任务是考察那些跨越切分线的区段。

所以每段返回两个值，一个是区段内的`GS`，一个是含端点的`GS`。

二者可以独立计算，累计用时为$O(n)$，故总时间为$O(n log n)$。
```cpp
int gs_DC( int A[], int lo, int hi ) { //Divide-And-Conquer: O(n*logn)
    if ( hi - lo < 2 ) return A[lo]; //递归基
    int mi = (lo + hi) / 2; //在中点切分
    int gsL = A[mi-1], sL = 0, i = mi; //枚举
    while ( lo < i-- ) //所有[i, mi)类区段
        if ( gsL < (sL += A[i]) ) gsL = sL; //更新
    int gsR = A[mi], sR = 0, j = mi-1; //枚举
    while ( ++j < hi ) //所有[mi, j)类区段
    if ( gsR < (sR += A[j]) ) gsR = sR; //更新
        return max( gsL + gsR, max( gs_DC(A, lo, mi), gs_DC(A, mi, hi) ) ); //递归
}
```
=== 分治策略：最短的总和非正的后缀 $~$ 总和最大区段

考虑后缀$S$，若其总和非正，则可将其舍弃，因为其不可能是最大区段的一部分。

所以只需在后缀$S$中，找出总和最大的区段即可。通过一次线性扫描实现，不断剪除负和后缀。时间复杂度为$O(n)$。

```cpp
int gs_LS( int A[], int n ) { //Linear Scan: O(n)
    int gs = A[0], s = 0, i = n;
    while ( 0 < i-- ) { //在当前区间内
        s += A[i]; //递增地累计总和
        if ( gs < s ) gs = s; //并择优、更新
        if ( s <= 0 ) s = 0; //剪除负和后缀
    }
    return gs;
}
```

#figure(
  image("fig\绪论\9.jpg",width: 60%),
  caption: "分治策略：最短的总和非正的后缀 $~$ 总和最大区段"
)
== 动态规划Dynamic Programming
=== 记忆法Memoization

例如`fib()`的递归算法：
```cpp
int fib(n) { return (2 > n) ? n : fib(n-1) + fib(n-2); }
```
$
T(n) = T(n-1) + T(n-2) + O(1)
$
这个算法的时间复杂度是$O(phi^n)$。

#figure(
  image("fig\绪论\10.png",width: 80%),
  caption: "递归算法的递归跟踪"
)

可以看到，有很多重复的计算，例如`fib(3)`被计算了两次，`fib(2)`被计算了三次，`fib(1)`被计算了五次。

所以可以用一个数组来存储已经计算过的值，这样就可以避免重复计算，这就是*记忆法*。
```cpp
def f(n)
    if ( n < 1 ) return trivial( n );
    return f(n-X) + f(n-Y)*f(n-Z);
/* Memoization: Top-down Dynamic Programming */
T M[ N ]; //init. with UNDEFINED
def f(n)
    if ( n < 1 ) return trivial( n );
    // recur only when necessary & always write down the result
    if ( M[n] == UNDEFINED )
        M[n] = f(n-X) + f(n-Y)*f(n-Z);
    return M[n];
```
#figure(
  image("fig\绪论\11.png",width: 80%),
  caption: "记忆法的递归跟踪"
)

*Dynamic programming*，颠倒计算方向：由自顶而下递归，改为自底而上迭代。
```cpp
f = 1; g = 0; //fib(-1), fib(0)
while ( 0 < n-- ) {
    g = g + f;
    f = g - f;
}
return g;
```
这样也节省了空间。
=== 例：最长公共子序列LCS

#figure(
  image("fig\绪论\12.png",width: 80%),
  caption: "最长公共子序列LCS"
)

对于序列$A[0,n)$和$B[0,m)$， $"LCS"(n,m)$有三种情况：
1. 若 `n = 0` 或 `m = 0`， 则取作空序列（长度为零），这是递归基：必然总能抵达
2. 若`A[n-1] = 'X' = B[m-1]`，则取作： `LCS(n-1,m-1) + 'X'`[减治策略]
3. 若`A[n-1] != B[m-1]`，则在 `LCS(n,m-1)` 与 `LCS(n-1,m)` 中取更长者[分治策略]

```cpp
Input: two strings A and B of length n and m resp.,
Output: (the length of) the longest common subsequence of A and B
lcs( A[], n, B[], m )
    Compare the last characters of A and B, i.e., A[n-1] and B[m-1]
    If A[n-1] = B[m-1]
        Compute x = lcs(A, n-1, B, m-1) recursively and return 1 + x
    Else
        Compute x = lcs(A, n-1, B, m) & y = lcs(A, n, B, m-1) and return max(x, y)
    As the recursion base, return 0 when either n or m is 0
```
基本实现是
```cpp
unsigned int lcs( char const * A, int n, char const * B, int m ) {
    if (n < 1 || m < 1) //trivial cases
        return 0;
    else if ( A[n-1] == B[m-1] ) //decrease & conquer
        return 1 + lcs(A, n-1, B, m-1);
    else //divide & conquer
        return max( lcs(A, n-1, B, m), lcs(A, n, B, m-1) );
}
```
如果用这种算法，`LCS(A[a],B[b])`被调用的次数是$mat(n+m-a-b;n-a)$，单`LCS(A[0],B[0])`就会被调用$Omega(2^n)$次。

下面我们可以用记忆化进行优化：

#figure(
  image("fig\绪论\13.png",width: 80%),
  caption: "最长公共子序列LCS——记忆法"
)

```cpp
unsigned int lcsMemo(char const* A, int n, char const* B, int m) {
    unsigned int * lcs = new unsigned int[n*m]; //lookup-table of sub-solutions
    memset(lcs, 0xFF, sizeof(unsigned int)*n*m); //initialized with n*m UINT_MAX's
    unsigned int solu = lcsM(A, n, B, m, lcs, m);
    delete[] lcs;
    return solu;
}

unsigned int lcsM( char const * A, int n, char const * B, int m,
unsigned int * const lcs, int const M ) {
    if (n < 1 || m < 1) return 0; //trivial cases
    if (UINT_MAX != lcs[(n-1)*M + m-1]) return lcs[(n-1)*M + m-1]; //recursion stops
    else return lcs[(n-1)*M + m-1] =
        (A[n-1] == B[m-1]) ?
          1 + lcsM(A, n-1, B, m-1, lcs, M)
            max( lcsM(A, n-1, B, m, lcs, M), lcsM(A, n, B, m-1, lcs, M) );
}
```

采用动态规划的策略，只需$O(m n)$时间即可计算出所有子问题。

#figure(
  image("fig\绪论\14.png",width: 50%),
  caption: "最长公共子序列LCS——动态规划"
)

```cpp
unsigned int lcs(char const * A, int n, char const * B, int m) {
    if (n < m) { swap(A, B); swap(n, m); } //make sure m <= n
    unsigned int* lcs1 = new unsigned int[m+1]; //the current two rows are
    unsigned int* lcs2 = new unsigned int[m+1]; //buffered alternatively
    memset(lcs1, 0x00, sizeof(unsigned int) * (m+1)); lcs2[0] = 0;
    for ( int i = 0; i < n; swap( lcs1, lcs2 ), i++ )
        for ( int j = 0; j < m; j++ )
          lcs2[j+1] = ( A[i] == B[j] ) ? 1 + lcs1[j] : max( lcs2[j], lcs1[j+1] );
    unsigned int solu = lcs1[m]; delete[] lcs1; delete[] lcs2; return solu;
}
```