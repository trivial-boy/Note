#  垃圾回收的过程

##  堆内存的分布

JDK 7 版本及 之前，堆内存通常分为下面三部分

1. 新生代内存
2. 老年代
3. 永久代

下图所示的 Eden 区、两个 Survivor 区 S0 和 S1 都属于新生代，中间一层属于老年代，最下面一层属于永久代。

 ![hotspot-heap-structure](https://javaguide.cn/assets/hotspot-heap-structure.41533631.png)

下图所示的 Eden 区、两个 Survivor 区 S0 和 S1 都属于新生代，中间一层属于老年代，最下面一层属于永久代。

## 内存的分配过程

### 对象首先在Eden 区分配

大多数情况下，对象在新生代的Eden区分配内存。当Eden区没有足够空间进行分配时，虚拟机将发起一次Minor GC。

### 大对象直接进入老年代

大对象就是需要大量连续内存空间的对象（如：字符串、数组）

### 长期存活的对象进入老年代

大部分情况，对象都会首先在 Eden 区域分配。如果对象在 Eden 出生并经过第一次 Minor GC 后仍然能够存活，并且能被 Survivor 容纳的话，将被移动到 Survivor 空间（s0 或者 s1）中，并将对象年龄设为 1(Eden 区->Survivor 区后对象的初始年龄变为 1)。

对象在 Survivor 中每熬过一次 MinorGC,年龄就增加 1 岁，当它的年龄增加到一定程度（默认为 15 岁），就会被晋升到老年代中。对象晋升到老年代的年龄阈值，可以通过参数 `-XX:MaxTenuringThreshold` 来设置。



## JVM 调优

