= 串string/char[]

用`char[]`表示串，主要讨论串的匹配。
== 蛮力算法BF

从前往后遍历，每次匹配失败则推进到下一个位置。

通常建议用双移动的指针实现。
```cpp
int match( char * P, char * T ) 
{
    size_t n = strlen(T), i = 0;
    size_t m = strlen(P), j = 0;
    while ( j < m && i < n ) //自左向右逐次比对（可优化）
    if ( T[i] == P[j] ) { i ++; j ++; } //若匹配，则转到下一对字符
    else { i -= j-1; j = 0; } //否则， T回退、 P复位
    return i-j; //最终的对齐位置：藉此足以判断匹配结果
}
```
通过移动同时移动`i`和`j`，逐位比较，之后`i`回退，`j`复位，继续比较。

这种算法的时间复杂度为$O(m n)$，其中$m$为模式串长度，$n$为文本串长度。
== KMP算法

一次比较在第`j`位失配，已经掌握了前`j`位的信息，可以利用这些信息，跳过一些不必要的比较。

例如，一次比较后，就可以直接跳转到下图的位置，而不必从头开始比较。
```
R E G R E S S ...
R E G R E T S
      R E G R E T S
```
*快速右移+决不后退：*这满足，模式串长为`j`的前缀的一部分真前缀等于真后缀，且要保证真前缀的长度最大。
=== `next[]`表

用这样的方式构造查询表`next[]`。

#figure(
  image("fig\串\1.png",width: 80%),
  caption: "next[]表",
)

用数学语言描述是：
$ forall j >= 1, bold(N)(P,j)&={0<=t<j | P[0,t) = P[j-t,j)} \
 "next"[j] &= max{bold(N)(P,j)} $

下面写出构造的递推关系：

$ "next"[j+1] = "next"[j] + 1 <=> P[j] = P["next"[j]] $
这是因为，如果$P[j] = P["next"[j]]$，那么$P[j+1] = P["next"[j]+1]$，所以$P[j+1]$的真前缀长度为$P[j]$的真前缀长度加一。

如果$P[j] != P["next"[j]]$，就向前递推，看$P[J]$与$P["next"["next"[j]]]$是否相等。如果相等，就可令$"next"[j+1] = "next"["next"[j]] + 1$，否则继续递推。直到找到一个相等的，或者$j$递推到$0$（$"next"[0]=-1$）。

```cpp
int* buildNext( char* P ) {
    size_t m = strlen(P), j = 0;
    int* next = new int[m];
    int t = next[0] = -1;
    while ( j < m - 1 )
        if ( 0 > t || P[t] == P[j] ) { //匹配
            ++t; ++j; next[j] = t; //则递增赋值
        } else //否则
            t = next[t]; //继续尝试下一值得尝试的位置
    return next;
}
```

这样以来KMP算法(Knuth-Morris-Pratt)就可以写成：
```cpp
int match( char * P, char * T ) {
    int * next = buildNext(P);
    int n = (int) strlen(T), i = 0;
    int m = (int) strlen(P), j = 0;
    while ( j < m && i < n ) //可优化
        if ( 0 > j || T[i] == P[j] ) {
        i ++; j ++;
    } else
        j = next[j];
    delete [] next;
    return i - j;
}
```
通过生成模式串的`next[]`表，可以在匹配失败时，直接跳转到`next[]`表中的位置，而不必从头开始比较。
=== 分摊分析
KMP算法的时间复杂度为$O(m+n)$，其中$m$为模式串长度，$n$为文本串长度。

其中，生成`next[]`表的时间复杂度为$O(m)$，匹配的时间复杂度为$O(n)$。

#figure(
  image("fig\串\2.png",width: 80%),
  caption: "KMP算法的分摊分析",
)

考虑上图，浅绿色是不言自明的比较、深绿色是消耗时间的比较。将红色即失配部分，前移后，可以看到所有深绿与红色的部分之和，为$O(n)$的。

也可以构造计步器$k=2i-j$，这个计步器是严格增加的，最大值是$2n-1$，所以时间复杂度为$O(n)$。
```cpp
while ( j < m && i < n ) //k必随迭代而单调递增，故也是迭代步数的上界
    if ( 0 > j || T[i] == P[j] )
      { i ++; j ++; } //k恰好加1
    else
      j = next[j]; //k至少加1
```

== 优化的KMP算法

按照刚才的方法，每次失配的下一次对比没有用到目前正在比较的`P[j]`的信息。

如果该位置是字符`c`导致失配，那么下一次比较，除了刚才的前后缀相同以外，保证前缀的下一位不再是`c`。这样就可以吸取刚才的教训。
=== `next[]`表

$ forall j >= 1, bold(N)(P,j)&={0<=t<j | P[0,t) = P[j-t,j) "且" P[t]!=P[j]} \
 "next"[j] &= max{bold(N)(P,j)} $

代码实现如下
```cpp
int* buildNext( char* P ) {
    size_t m = strlen(P), j = 0;
    int* next = new int[m]; int t = next[0] = -1;
    while ( j < m – 1 )
        if ( 0 > t || P[t] == P[j] ) {
            if ( P[++t] != P[++j] )
                next[j] = t;
            else //P[next[t]] != P[t] == P[j]
                next[j] = next[t];
        } else
            t = next[t];
    return next;
}
```

该算法单次匹配概率越大（字符集越小），优势越明显。

== BM算法

Boyer-Moore提出了两种策略，BC策略和GS策略。
=== BC策略 

每次匹配从末字符开始，从后向前匹配。如果失配，就考察前面的字符是否有造成失配的，如果有，就将其移动过来，否则就移动整个模式串。

#figure(
  image("fig\串\3.png",width: 80%),
  caption: "BC策略",
)

==== Bad-Character规则

如果失配的字符在模式串中，就将模式串移动到该字符的右侧，否则移动整个模式串。

*画家算法：*将第$j$位对应的字符$c$处的$"bc"[c]$赋值成$j$，如果$c$不在模式串中，就赋值成$-1$。从小到大遍历后，$"bc"[*]$中储存的就是每个字符最后出现的位置。
```cpp
    int * buildBC( char * P ) {
    int * bc = new int[ 256 ];
    for ( size_t j = 0; j < 256; j++ ) bc[j] = -1;
    for ( size_t m = strlen(P), j = 0; j < m; j++ )
        bc[ P[ j ] ] = j; //painter's algorithm
    return bc;
} //O( s + m )
```

只用存储最后一个而不用全部存储的原因是，每次移动可以保证在移动中间的位置都是不合法的，只要一直比较并且移动，就可以保证不会出现不合法的情况。
==== 复杂度分析

最好情况是$O(n/m)$，最坏情况是$O(m n)$。

单次匹配概率越小，性能优势越明显，需单次比较，即可排除m个对齐位置，一次移动$m$个对齐位置。

单次匹配概率越大的场合，性能越接近于蛮力算法。
=== GS策略

仿照KMP，记忆好后缀。相当于KMP从后颠倒。

==== Good-Suffix规则

扫描比对中断于$T[i + j] != P[j]$时，$U = P(j,m)$必为好后缀。下一对齐位置满足：
+ $U$重新与$V(k) = P( k, m + k - j )$匹配 (_经验_)
+ $P[ k ] != P[ j ]$ (_教训_)

=== 综合性能
#figure(
  image("fig\串\4.png",width: 80%),
  caption: "字符串匹配的综合性能",
)

== Karp-Rabin算法

将字符串看成是一个数字，通过哈希函数将字符串转换成数字，然后比较数字是否相等。

通过散列，将指纹压缩至存储器支持的范围，但指纹相同，原串却未必匹配。

=== 快速指纹计算

每次计算指纹时，只需要减去最高位，然后乘以基数，再加上新的最低位即可。这样可以在$O(1)$的时间内完成递推。