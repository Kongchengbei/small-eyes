# For AXI_Burst

```
  整体连接关系是：

  ICache ──简单请求接口──┐
                        │
                        ├─> axi_bridge
                        │   AXI Master
  DCache ──简单请求接口──┘
                                │
                                │ 五个AXI通道
                                ▼
                         axi_mem_backend
                         AXI Slave + 地址译码
                            │          │
                            │          └──> UART / LED / FPIOA
                            │
                            └──> ddr_axi_bridge
                                        │
                                        ▼
                                    DDR控制器IP
```





#### 文章目录

- [一、Burst Transfer](https://blog.csdn.net/weixin_46022434/article/details/122386328#Burst_Transfer_1)
- [二、Outstanding Transfer](https://blog.csdn.net/weixin_46022434/article/details/122386328#Outstanding_Transfer_23)
- [三、Out-of-order Transfer](https://blog.csdn.net/weixin_46022434/article/details/122386328#Outoforder_Transfer_35)
- [四、Interleaving Transfer](https://blog.csdn.net/weixin_46022434/article/details/122386328#Interleaving_Transfer_39)
- [五、Narrow Transfer](https://blog.csdn.net/weixin_46022434/article/details/122386328#Narrow_Transfer_43)
- [六、Unaligned Transfer](https://blog.csdn.net/weixin_46022434/article/details/122386328#Unaligned_Transfer_57)



## 一、Burst Transfer

  AXI burst读操作：**master只需要发送burst的起始地址**，slave会根据burst的起始地址与burst场地自动进行地址计算，将对应的[ 数据](https://blog.csdn.net/weixin_46022434/article/details/122386328#)与响应发送到master侧。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e60e30e15aa74772993a4e29d67ae05f.png)

  AXI burst写操作中，**也只需要发送burst写的起始地址**，slave只需要接受起始地址，然后根据传输的长度将数据传输到对应的地址缓存中。
  只需要进行一次握手就可以实现地址通道的请求传输，避免系统总线的占用。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/57933efbbf13153aaa39f8989f63fdc1.png) 

挑选计算芯片



  Burst Type：AXI协议中支持不同的Burst传输类型，主要分FIXED、INCR、WRAP。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a2c7ed4dd35305dccd1d324f9ddfbc9e.png)

- **FIXED传输为地址固定传输**，所有传输都会写在同一个地址中。主要应用在FIFO的传输中，因为FIFO为先入先出，只需要往同一个地址写数据即可。
- **INCR传输为地址递增传输**，可根据具体的配置有固定长度递增和非定长递增。大部分的数据传输都是使用这种方式，尤其是在内存访问中，可以大大提高效率。
- **WRAP传输为地址回环传输**，在一定长度后会回环到起始地址。主要应用在Cache操作中，因为cache是按照cache line进行操作，采用wrap传输可以方便的实现从内存中取回整个cache line。

        ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ea52c53a48b557de7e8f675c6911c890.png)

## 二、Outstanding Transfer

  读Outstanding操作是**不需要等待前一笔传输完成就可以发送下一笔操作**。AXI因为是通道分离的所以master不需要等待前一笔操作A响应完成就可以发送下一笔操作请求B，这样可以有效提升通路利用率，提升系统性能。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/606b23937ba26c888fa1e4f136981988.png) 

  写outstanding也是一样，**不需要等待前一笔的写完成就可以发送下一笔传输**。系统设计上需要注意outstanding对应的缓存的需求，否则无法接受master发送的数据出现系统的反压。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5e83927d77e293bdf56f0c860c8f51b8.png)

【注】

- **Burst可以减少地址通道的交互，提升单笔传输的效率。**
- **Outstanding可以较少多笔传输之间的等待，提升多笔传输的效率。**

## 三、Out-of-order Transfer

  Out-of-order传输可针对于多个从机，返回的response可以不安master访问的顺序，慢的可以快，快的可以慢。如果master要求返回的[ 数据](https://blog.csdn.net/weixin_46022434/article/details/122386328#)必须按照他们访问的顺序来返回，则必须使用相同的ID。如果master不要求按顺序返回数据，则可以通过使用不同的ID来实现乱序传输。 也就是说**乱序不乱序的实现是通过master的访问ID来进行控制的**，**同一个ID必须按照顺序，不同ID可以乱序**。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/197d296c3ff65df84841ec0e40da0306.png) 

开通视频会员



## 四、Interleaving Transfer

  交织（交叉）传输，是**在乱序的基础上支持不同ID间数据之间的乱序**。但是相同ID的数据还是顺序返回的，不同ID之间才会有交织传输。 在axi3中支持写交织，axi4/5去掉了wid，不支持写交织。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0a3051290a5b9cca85d64de32c10110b.png)

## 五、Narrow Transfer

  窄传输就是**通过strb信号指定有效传输数据的位宽来实现**。针对一些特定的寄存器 读写，或者在不同数据位宽的总线传输中会使用窄传输操作。

  需要注意**在多笔连续的窄传输操作中，strb会随着地址递增进行响应的变化**，这样方便在系统设计使用中可以方便的将窄传输合并 ，从而提升系统传输效率。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e95f3ab8587106206e180da44d702245.png)

  写选通信号 WSTRB 允许在写数据总线上进行稀疏数据传输。每个写选通信号对应写数据总线上的一个字节。当写选通断言时，表示写数据总线上对应的字节通道中包含将被更新到 memory 的有效信息。
  写数据总线上每 8 位具有一个写选通位，因此 WSTRB[n]对应 WDATA[(8 x n) + 7 : (8 x n)]。图 9-1 展示了一个 64-bit 数据总线上的这种关系。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/67055bd9c5e1c5620a759677e77bfa4b.png)
  主机必须确保只有包含有效数据的字节通道，其对应的写选通信号才会被断言，有效数据由事物的控制信息决定。
          ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d119ced241a756b0a73ccc26b021f786.png) 

部署数据备份



## 六、Unaligned Transfer

  AXI 协议使用基于突发的寻址，意思是，每个事物都包含若干个数据传输。通常来说，每个数据传输都会对齐到传输大小。例如，一个 32-bit 宽的传输通常会对齐到 4-byte 边界。但是在某些时候，会期望在非对齐的地址开始一个突发，即非对齐传输。
  非对齐传输是指**有些传输指令不是按照word对齐，而是按照Byte对齐进行传输**。起始地址可能是任意的地址。如下图中，起始地址为0x1，则在系统上需要按照非对齐的方式进行传输。**第一次传输采用strb信号指定对应的Byte有效，后面的传输可以按照正常的传输进行**。

  **非对齐传输主要体现在第一笔传输的[ 数据](https://blog.csdn.net/weixin_46022434/article/details/122386328#)中**，地址还是按照对word对齐的方式，通过strb指定对应的Byte有效即可。

  下图展示了不同宽度的总线上对齐和非对齐的传输。图中每行代表一个传输。深色方格表示根据地址和控制信息，不会被传输的字节。
    ![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/52344a534d06a8e89ecaa55138ce6806.png)