= 栈与队列Stack & Queue
== 栈Stack
=== 接口与实现

栈（stack）是受限的序列
- 只能在栈顶（top）插入和删除
- 栈底（bottom）为盲端
- 后进先出（LIFO），先进后出（FILO）

基本接口是
- `size()` / `empty()`
- `push()` 入栈
- `pop()` 出栈
- `top()` 查顶
- 扩展接口： `getMax(`)...

直接基于向量或列表派生
```cpp
template <typename T> class Stack: public Vector<T> { //原有接口一概沿用
public:
    void push( T const & e ) { insert( e ); } //入栈
    T pop() { return remove( size() – 1 ); } //出栈
    T & top() { return (*this)[ size() – 1 ]; } //取顶
}; //以向量首/末端为栈底/顶——颠倒过来呢？
```
如此实现的栈各接口，均只需$O(1)$时间
=== 调用栈

#figure(
  image("fig\栈\1.png",width: 70%),
  caption: "调用栈",
)

#figure(
  image("fig\栈\2.png",width: 80%),
  caption: "调用栈",
)

#figure(
  image("fig\栈\3.png",width: 80%),
  caption: "调用栈——递归深度",
)

递归算法所需的空间主要取决于*递归深度*，而非递归实例总数。
==== 消除递归

为隐式地维护调用栈，需花费额外的时间、空间。为节省空间，可
- 显式地维护调用栈
- 将递归算法改写为迭代版本

```cpp
int fib( int n ) 
    { return (n < 2) ? n : fib(n - 1) + fib(n - 2); }

int fib( int n ) { //O(1)空间
    int f = 0, g = 1;
    while ( 0 < n-- )
        { g += f; f = g - f; }
    return f;
}
```

通常，消除递归只是在常数意义上优化空间，但也可能有实质改进。
==== 尾递归

尾递归是在递归实例中，作为最后一步的递归调用。
```cpp
fac(n) {
    if (1 > n) return 1; //base
    return n * fac( n-1 ); //tail recursion
}
```

#figure(
  image("fig\栈\4.png",width: 50%),
  caption: "尾递归",
)

一旦抵达递归基，便会
- 引发一连串的return（且返回地址相同）
- 调用栈相应地连续pop
尾递归优化：时间复杂度有常系数改进，空间复杂度或有渐近改进。
```cpp
fac(n) { //尾递归
    if (1 > n) return 1;
    return n * fac( n-1 ); 
}//O(n)时间 + O(n)空间

fac(n) { //统一转换为迭代
    int f = 1; //记录子问题的解
next: //转向标志，模拟递归调用
    if (1 > n) return f;
    f *= n--;
    goto next; //模拟递归返回
}//O(n)时间 + O(1)空间

fac(n) { //简捷
    int f = 1;
    while (1 < n) 
        f *= n--;
    return f;
}//O(n)时间 + O(1)空间
```
=== 进制转换

常用短除法，进行进制转换。

#figure(
  image("fig\栈\5.png",width: 80%),
  caption: "进制转换",
)

位数$m$并不确定，如何正确记录并输出转换结果？具体地
- 如何支持足够大的$m$，同时空间也不浪费？
- 自低而高得到的数位，如何自高而低输出？
若使用向量，则扩容策略必须得当；若使用列表，则多数接口均被闲置。使用栈， 既可满足以上要求， 亦可有效控制计算成本。

```cpp
void convert( Stack<char> & S, __int64 n, int base ) {
    char digit[] = "0123456789ABCDEF"; //数位符号，如有必要可相应扩充
    while ( n > 0 ) //由低到高，逐一计算出新进制下的各数位
        { S.push( digit[ n % base ] ); n /= base; } //余数入栈， n更新为除商
} //新进制下由高到低的各数位，自顶而下保存于栈S中
main() {
    Stack<char> S; convert( S, n, base ); //用栈记录转换得到的各数位
    while ( ! S.empty() ) printf( "%c", S.pop() ); //逆序输出
}
```
=== 括号匹配

括号匹配的问题难以用减而之治和分而治之的思想由外而内解决。

颠倒以上思路：消去一对紧邻的左右括号，不影响全局的匹配判断
$
L |( " " )| R => L | R
$
顺序扫描表达式，用栈记录已扫描的部分的左括号。反复迭代：凡遇"("，则进栈；凡遇")"，则出栈。

```cpp
bool paren( const char exp[], Rank lo, Rank hi ) { //exp[lo, hi)
    Stack<char> S; //使用栈记录已发现但尚未匹配的左括号
    for ( Rank i = lo; i < hi; i++ ) //逐一检查当前字符
        if ( '(' == exp[i] ) S.push( exp[i] ); //遇左括号：则进栈
        else if ( ! S.empty() ) S.pop(); //遇右括号：若栈非空，则弹出对应的左括号
        else return false; //否则（遇右括号时栈已空），必不匹配
    return S.empty(); //最终栈空， 当且仅当匹配
}
```

#figure(
  image("fig\栈\6.png",width: 80%),
  caption: "括号匹配",
)

当括号为单一的一种的时候，甚至可以用一个计数器进行简化。
=== 栈混洗 Stack Permutation

有栈$A = (a_1, a_2, ..., a_n)$，栈$B = S = Phi$：

每次可以
- 将 $A$ 的顶元素弹出并压入 $S$ ，或
- 将 $S$ 的顶元素弹出并压入 $B$

最终所有元素都从 $A$ 移动到 $B$，且$B$为$A$的一个排列$B = (a_(p_1), a_(p_2), ..., a_(p_n))$。

#figure(
  image("fig\栈\7.png",width: 80%),
  caption: "栈混洗",
)

$B$中的排列是有限制的，满足要求的排列有
$
"Catalan"(n) = 1/(n+1) mat(2n; n)
$
个。这是因为，设$n$个元素的栈混洗排列有$"SP"(n)$个，则有递推关系
$
"SP"(n) = sum_(i=1)^n "SP"(i-1) dot "SP"(n-i)
$

*栈混洗排列的充要条件*：不存在312的模式。即在栈混洗排列中，任意三个连续元素$a_i, a_j, a_k$，满足$i < j < k$，有$a_i < a_k < a_j$。

这样可以得到一个$O(n^3)$的检验算法。

可以简化成当且仅当对于任意$i < j$，不含模式$[ ..., j+1, ..., i, ..., j, ... >$。

这样可以得到一个$O(n^2)$的检验算法。

事实上，可以直接用栈来模拟，这样可以得到一个$O(n)$的检验算法。

*括号匹配*的合法排列就是栈混洗排列。
=== 中缀表达式

减而治之：优先级高的局部执行计算，并被代以其数值；运算符渐少，直至得到最终结果。`val(S) = val( SL + str(v0) + SR )`。

延迟缓冲：仅根据表达式的前缀，不足以确定各运算符的计算次序；只有获得足够的后续信息，才能确定其中哪些运算符可以执行。

求值算法 = 栈 + 线性扫描

- 自左向右扫描表达式，用栈记录已扫描的部分，以及中间结果；栈内最终所剩的那个元素，即表达式之值。

```cpp
If (栈的顶部存在可优先计算的子表达式)
    Then 令其退栈并计算；计算结果进栈
    Else 当前字符进栈，转入下一字符
```

- 优先级高的局部执行计算，并被代以其数值；运算符渐少，直至得到最终结果。

```cpp
double evaluate( char* S, char* RPN ) { //S保证语法正确
    Stack<double> opnd; Stack<char> optr; //运算数栈、运算符栈
    optr.push('\0'); //哨兵
    while ( ! optr.empty() ) { //逐个处理各字符，直至运算符栈空
        if ( isdigit( *S ) ) //若为操作数（可能多位、小数），则
            readNumber( S, opnd ); //读入
        else //若为运算符，则视其与栈顶运算符之间优先级的高低
            switch( priority( optr.top(), *S ) ) { /* 分别处理 */ }
    } //while
    return opnd.pop(); //弹出并返回最后的计算结果
}
```
其中优先级的比较可以用一个表格来实现
```cpp
const char pri[N_OPTR][N_OPTR] = { //运算符优先等级 [栈顶][当前]
    /* -- + */ '>', '>', '<', '<', '<', '<', '<', '>', '>',
    /* |  - */ '>', '>', '<', '<', '<', '<', '<', '>', '>',
    /* 栈 * */ '>', '>', '>', '>', '<', '<', '<', '>', '>',
    /* 顶 / */ '>', '>', '>', '>', '<', '<', '<', '>', '>',
    /* 运 ^ */ '>', '>', '>', '>', '>', '<', '<', '>', '>',
    /* 算 ! */ '>', '>', '>', '>', '>', '>', ' ', '>', '>',
    /* 符 ( */ '<', '<', '<', '<', '<', '<', '<', '=', ' ',
    /* |  ) */ ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ',
    /* --\0 */ '<', '<', '<', '<', '<', '<', '<', ' ', '='
    //          +    -    *    /    ^    !    (    )   \0
    //          |-------------- 当前运算符 --------------|
};
```
'<'：静待时机
```cpp
switch( priority( optr.top(), *S ) ) {
    case '<': //栈顶运算符优先级更低
        optr.push( *S ); S++; break; //计算推迟，当前运算符进栈
    case '=':
        /* ...... */
    case '>': {
        /* ...... */
        break;
    } //case '>'
} //
```
#figure(
    image("fig\栈\8.png",width: 80%),
    caption: "中缀表达式求值——'<'",
)
'>'：时机已到
```cpp
switch( priority( optr.top(), *S ) ) {
    /* ...... */
    case '>': {
        char op = optr.pop();
        if ( '!' == op ) opnd.push( calcu( op, opnd.pop() ) ); //一元运算符
        else { double opnd2 = opnd.pop(), opnd1 = opnd.pop(); //二元运算符
            opnd.push( calcu( opnd1, op, opnd2 ) ); //实施计算，结果入栈
        } //为何不直接： opnd.push( calcu( opnd.pop(), op, opnd.pop() ) )？
        break;
    } //case '>'
} //switch
```
#figure(
    image("fig\栈\9.png",width: 80%),
    caption: "中缀表达式求值——'>'",
)
'='：终须了断
```cpp
switch( priority( optr.top(), *S ) ) {
    case '<':
        /* ...... */
    case '=': //优先级相等（当前运算符为右括号，或尾部哨兵'\0'）
        optr.pop(); S++; break; //脱括号并接收下一个字符
    case '>': {
        /* ...... */
        break;
    } //case '>'
} //switch
```
#figure(
    image("fig\栈\10.png",width: 80%),
    caption: "中缀表达式求值——'='",
)
=== 逆波兰表达式Reverse Polish Notation(RNP)

在由运算符（operator）和操作数（operand）组成的表达式中，不使用括号（parenthesis-free），即可表示带优先级的运算关系。

例如：
```
0 !+ 123 + 4 *( 5 * 6 !+ 7 !/ 8 )/ 9
123 + 4 5 6 !* 7 ! 8 /+* 9 /+
```
- 相对于日常使用的中缀式（infix）， RPN亦称作后缀式（postfix）；
- 作为补偿，须额外引入一个起分隔作用的元字符（比如空格），较之原表达式，未必更短。

NRP的求值很容易，只需要一个栈即可。
```cpp
引入栈S //存放操作数
逐个处理下一元素x
    if ( x是操作数 ) 将x压入S
    else //运算符无需缓冲
        从S中弹出x所需数目的操作数
        执行相应的计算，结果压入S //无需顾及优先级！
返回栈顶 // 只要输入的RPN语法正确，此时的栈顶亦是栈底，对应于最终的计算结果
```
#figure(
    image("fig\栈\11.png",width: 80%),
    caption: "逆波兰表达式求值",
)

==== 中缀表达式转换为逆波兰表达式

如果要用程序自动转换，可以在刚才求值的基础上修改。

其实后缀表达式的运算就是在中缀表达式计算的时候，按照优先级的顺序排出来的序列。

```cpp
double evaluate( char* S, char* RPN ) { //RPN转换
    /* ................................. */
    while ( ! optr.empty() ) { //逐个处理各字符，直至运算符栈空
        if ( isdigit( * S ) ) //若当前字符为操作数，则直接
            { readNumber( S, opnd ); append( RPN, opnd.top() ); } //将其接入RPN
        else //若当前字符为运算符
            switch( priority( optr.top(), *S ) ) {
                /* ................................. */
                case '>': { //且可立即执行，则在执行相应计算的同时
                    char op = optr.pop(); append( RPN, op ); //将其接入RPN
                    /* ................................. */
                } //case '>'
                /* ................................. */
            } //switch
        /* ................................. */
    } //while
    /* ................................. */
    return opnd.pop(); //弹出并返回最后的计算结果
}
```

手动转换的方法：
#figure(
    image("fig\栈\12.png",width: 80%),
    caption: "中缀表达式转换为逆波兰表达式",
)
#figure(
    image("fig\栈\13.png",width: 80%),
    caption: "中缀表达式转换为逆波兰表达式",
)

== 队列Queue
=== 接口与实现

队列（queue）也是受限的序列
- 先进先出（FIFO）
- 后进后出（LILO）

提供接口：
- 只能在队尾插入（查询）： `enqueue()` / `rear()`
- 只能在队头删除（查询）： `dequeue() `/ `front()`
- 扩展接口： `getMax()`...

基于向量或列表派生
```cpp
template <typename T> class Queue: public List<T> { //原有接口一概沿用
public:
    void enqueue( T const & e ) { insertAsLast( e ); } //入队
    T dequeue() { return remove( first() ); } //出队
    T & front() { return first()->data; } //队首
}; //以列表首/末端为队列头/尾——颠倒过来呢？
```
如此实现的队列接口，均只需$O(1)$时间。
=== 队列应用

*资源循环分配*：一组客户（client）共享同一资源时，如何兼顾公平与效率？比如，多个应用程序共享CPU，实验室成员共享打印机

```cpp
RoundRobin //循环分配器
    Queue Q( clients ); //共享资源的所有客户组成队列
    while ( ! ServiceClosed() ) //在服务关闭之前，反复地
        e = Q.dequeue(); //令队首的客户出队，并
        serve( e ); Q.enqueue( e ); //接受服务，然后重新入队
```
=== 直方图内最大矩形

设 `H[0,n)` 是一个非负整数直方图
- 如何找到 `H[]` 中最大的正交矩形？
- 为了消除可能存在的歧义，例如，我们可以选择最左侧的矩形

我们考虑由`H[r]`支撑的最大矩形，满足：
$
&"maxRect"[r] = "H"[r] times (t(r) - s(r))\
&s(r) = max{ 0 <= k < r | "H"[k-1] < "H"[r] }\
&t(r) = min{ t < k <= n | "H"[r] < "H"[k] }
$
其中，$s(r)$是$r$左侧第一个小于$H[r]$的位置，$t(r)$是$r$右侧第一个小于$H[r]$的位置。
#figure(
    image("fig\栈\14.png",width: 80%),
    caption: "直方图内最大矩形",
)

==== Brute-force方法

按照刚才的分析，对每一个位置都计算最大支撑矩形，然后取最大值。这样的复杂度是$O(n^2)$。
==== 利用单调栈

我们希望可以对每个`r`快速找到`s[r]`和`t[r]`。

从前往后扫描，维护一个单调栈：
- 栈内元素单调递增
- 每次插入新元素的时候都会弹出栈内所有比它小的元素
```cpp
Rank* s = new Rank[n]; Stack<Rank> S;
for ( Rank r = 0; r < n; r++ ) //using SENTINEL
    while ( !S.empty() && ( H[S.top()] >= H[r] ) ) S.pop(); //until H[top] < H[r]
    s[r] = S.empty() ? 0 : 1 + S.top(); S.push(r); //S is always ASCENDING
while( !S.empty() ) S.pop();
```
#figure(
    image("fig\栈\15.png",width: 80%),
    caption: "直方图内最大矩形——寻找`s[r]`",
)
- `s[r]`中记录的是左侧第一个`H[k]`小于`H[r]`的`k`（有哨兵），这样就可以计算出`H[r]`支撑的最大矩形的左边界。
    - 对于单调栈：
        - 每个元素都会被压入栈一次，而每个元素也会在后序的某个时刻被弹出栈一次，所以总的时间复杂度是$O(n)$。
        - 递增栈可以保证栈顶元素就是*前一个最小的元素*，即`s[r]`。

按相反的顺序扫描一遍，可以计算出`t[r]`。
==== 一次扫描

如果数据是在线的，就很难做到正反两次扫描。对于一次扫描：
```cpp
Stack<Rank> SR; __int64 maxRect = 0; //SR.2ndTop() == s(r)-1 & SR.top() == r
for ( Rank t = 0; t <= n; t++ ) //amortized-O(n)
    while ( !SR.empty() && ( t == n || H[SR.top()] > H[t] ) )
        Rank r = SR.pop(), s = SR.empty() ? 0 : SR.top() + 1;
        maxRect = max( maxRect, H[r] * ( t - s ) );
    if ( t < n ) SR.push( t );
return maxRect;
```
#figure(
    image("fig\栈\16.png",width: 80%),
    caption: "直方图内最大矩形——一次扫描",
)
- `SR`同样是一个递增栈，`SR.top()`是当前最小的元素，`SR.2ndTop()`是次小的元素。
- 存先前最大的矩形，每次碰到有更小的数就到了右边界，然后计算面积，再与之前的最大值比较。
== Steap + Queap
=== Steap = Stack + Heap = `push` + `pop` + `getMax`

希望每次可以在$O(1)$时间内找到最大值，可以再开一个并列的堆来维护最大值。

#figure(
    image("fig\栈\17.png",width: 80%),
    caption: "Steap",
)
`P`中每个元素，都是`S`中对应后缀里的最大者： 
```cpp
Steap::getMax() { return P.top(); }
Steap::pop() { P.pop(); return S.pop(); } //O(1)
Steap::push(e) { P.push( max( e, P.top() ) ); S.push(e); } //O(1)
```
通过看`P`的记录值，可以知道`S`中的最大值。

也可以用下面采用的指针+计数的方法：`P'`中存入指针与计数器，每次操作修改计数，加入指针，或者计数器变为0删除指针
#figure(
    image("fig\栈\18.png",width: 80%),
    caption: "Steap",
)
=== Queap = Queue + Heap = `enqueue` + `dequeue` + `getMax`

一样的方法，但是要注意出入口的操作：
```cpp
Queap::dequeue() { P.dequeue(); return Q.dequeue(); } //O(1)
Queap::enqueue(e) {
    Q.enqueue(e); P.enqueue(e);
    for ( x = P.rear(); x && (x->key <= e); x = x->pred ) //最坏情况O(n)
        x->key = e;
}
```
#figure(
    image("fig\栈\19.png",width: 80%),
    caption: "Queap",
)

可以按照同样的方式化简成指针+计数的方法。
#figure(
    image("fig\栈\20.png",width: 80%),
    caption: "Queap",
)
== 双栈当队

Queue = Stack x 2
#figure(
    image("fig\栈\21.png",width: 40%),
    caption: "双栈当队",
)
但是区别是，每次`dequeue`的时候，要把`R`中的元素全部倒入`F`中。

```cpp
def Q.enqueue(e)
    R.push(e);

def Q.dequeue() // 0 < Q.size()
    if ( F.empty() )
        while ( !R.empty() )
            F.push( R.pop() );
    return F.pop();
```
这样单步可能出现$O(n)$的情况。

现在来看分摊下来的复杂度：
==== Amortization By Accounting

#figure(
    image("fig\栈\22.png",width: 50%),
    caption: "Amortization By Accounting",
)

分析每个元素经历的操作次数。在整个过程中，每个元素至多经历1次`R`的`push`，1次`R`的`pop`，1次`F`的`push`，1次`F`的`pop`，所以每个元素至多经历4次操作。这样下来，每个元素的分摊复杂度是$O(1)$。
==== Amortization By Aggregate

考虑$d$次`dequeue()`和$e$次`enqueue()`已经做完了，一定有$d <= e$。所有的时间成本是$4d+3(e-d)=3e+d$。

这样下来，每个元素的分摊复杂度是$O(1)$。
==== Amortization By Potential

设第$k$次操作的势能
$
Phi_k = |F_k| - |R_k|
$
又考虑每次操作的分摊成本（Amortized Cost）
$
A_k = T_k+Delta Phi_k = T_k+ Phi_k - Phi_(k-1) eq.triple 2
$
其中$T_k$是实际成本（Actual Cost）。
从而可以得到：
$
&2n eq.triple sum_(k=1)^n A_k = sum_(k=1)^n T_k + Phi_n - Phi_0 = T(n) + Phi_n - Phi_0 > T(n) - n\
&T(n) < 3n = O(n)
$
所以每个元素的分摊复杂度是$O(1)$。