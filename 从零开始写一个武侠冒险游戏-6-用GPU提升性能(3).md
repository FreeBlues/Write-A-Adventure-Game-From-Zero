#	从零开始写一个武侠冒险游戏-6-用GPU提升性能(3)

##	概述

现在轮到用 `mesh` 改写那个给性能带来巨大影响的状态类了, 分析一下不难发现主要是那个实时绘制并且不停旋转的雷达图拖累了帧速, 那么我们就先从雷达图入手.

开始我感觉这个雷达图改写起来会比较复杂, 因为毕竟在状态类的代码中, 雷达图就占据了一多半, 而且又有实时绘制, 又要旋转, 想想都觉得麻烦, 所以就把它放到最后面来实现.

不过现在正式开始考虑时, 才发现, 其实想多了, 而且又犯了个特别容易犯的毛病: 一次性考虑所有的问题, 于是问题自然就变复杂了, 那么我们继续遵循最初的原型开发原则, 先提取核心需求, 从简单入手, 一步一步来, 一次只考虑一个问题, 这样把整个问题分解开发就发现其实也没多难.

##	用 mesh 改写状态类

###	整体思路

改写工作的核心就是先画个大六边形作为雷达图的背景, 再根据角色的 `6` 个属性值画一个小多边形(可能会凹进去), 最后让它旋转, 其中涉及的实时计算全部放到 `shader` 中.

还有要做的就是在六边形顶点处显示属性名称, 最后把状态栏也用 `mesh` 绘制出来.

###	改写雷达图

具体来说就是两部分工作:

-	绘制雷达图背景:大六边形
-	绘制技能线:小多边形

我们前面也用过 `mesh` 绘图, 使用了函数 `addRect()`, 因为我们当时绘制的是一个方形区域, 现在要绘制六边形, 可以使用 `mesh` 的另一种绘图方式: 为其提供多边形的顶点, 这些顶点用于组成一个个的三角形, 使用属性 `mesh.vertices` 来传递顶点, 形如:

```
mesh.vertices = {vec2(x1,y1), vec2(x2,y2), vec2(x3,y3), ...}
```

这种绘图方式最灵活, 不过也比较麻烦, 因为要计算好各个三角形的位置, 这些三角形还要设置好顺序, 否则就容易画错, 好在 `Codea` 还提供了一个把多边形拆分为三角形的函数 `triangulate()`(实际是封装了 `OpenGL ES 2.0/3.0` 的函数), 只要给出多边形的顶点坐标, 就可以返回拼接成多边形的多个三角形的顶点坐标.

先试试再说, 为避免影响已有代码, 我们在 `Status` 类中单独写一个新函数 `Status:radarGraphMesh()`, 在这个函数里进行我们的改写工作, 代码如下:

```
-- 用 mesh 绘制雷达图
function Status:raderGraphMesh()
    -- 雷达图底部大六边形背景
    self.m = mesh()
    -- 雷达图中心坐标，半径，角度
    local x0,y0,r,a,s = 250,330,500,360/6,4
    -- 计算右上方斜线的坐标
    local x,y = r* math.cos(math.rad(30)), r* math.sin(math.rad(30))
    -- 六边形 6 个顶点坐标，从正上方开始，逆时针方向
    local points = triangulate({vec2(0,r/s),vec2(-x/s,y/s),vec2(-x/s,-y/s),
                                vec2(0,-r/s),vec2(x/s,-y/s),vec2(x/s,y/s)})
    print(#points, points[1], points[2],points[3])
    self.m.vertices = points
    local c1 = color(0, 255, 121, 123)
    self.m:setColors(c1)    
end


-- main 主程序框架
function setup()
    displayMode(OVERLAY)
    myStatus = Status()
    myStatus:raderGraphMesh()
end

function draw()
    background(32, 29, 29, 255)
    
    translate(650,300)
    myStatus.m:draw()
    
    sysInfo()
end

-- 系统信息: 显示FPS和内存使用情况
function sysInfo()
    pushStyle()
    fill(255, 255, 255, 255)
    -- 根据 DeltaTime 计算 fps, 根据 collectgarbage("count") 计算内存占用
    local fps = math.floor(1/DeltaTime)
    local mem = math.floor(collectgarbage("count"))
    text("FPS: "..fps.."    Mem："..mem.." KB",650,740)
    popStyle()
end
```

截图如下:

![雷达图背景大六边形]()

看起来不错, 再在这个大六边形上面画一个小六边形, 小六边形的顶点需要根据属性值(`体力`,`内力`,`精力`,`智力`,`气`,`血`)来计算, 还好我们前面写过一个计算函数 `linesDynamic(t,n,j,z,q,x)`, 把它改个名字, 再稍作改动, 让它返回计算出来的顶点, 然后再新建一个名为 `m1` 的 `mesh`, 用来绘制代表属性值的小六边形, 代码如下:

```
-- 用 mesh 绘制雷达图
function Status:raderGraphMesh()
	...
	-- 实时绘制顶点位置，根据各状态属性值，实时计算顶点位置
    local function axisDynamic()
        local t,n,j,z,q,x = self.tili, self.neili, self.jingli,self.zhili, self.qi, self.xue
        local c,s = math.cos(math.rad(30)), math.sin(math.rad(30))
        local points = triangulate({vec2(0,t),vec2(-n*c,n*s),vec2(-j*c,-j*s),
                                    vec2(0,-z),vec2(q*c,-q*s),vec2(x*c,x*s)})
        return points
    end
    
    -- 绘制代表属性值的小六边形
    self.m1 = mesh()
    self.m1.vertices = axisDynamic()
    local c = color(0, 255, 121, 123)
    self.m1:setColors(c)
    ...
end
```
在主程序的 `draw()` 中增加一句 `myStatus.m1:draw()` 就可以了, 看看运行截图:

![增加了属性值小六边形]()

很好, 非常符合我们的要求, 不过有一点就是作为背景的大六边形的对角的线没有画出来, 现在需要处理一下, 实际上用 `shader` 最适合画的图形就是三角形, 直线有点麻烦(虽然 `OpenGL ES 2.0` 支持 `三角形`, `直线` 和 `点` 三种基本图形绘制, 不过我在 `Codea` 中没找到`直线`的函数), 当然, 我们也可以用两个狭长的三角形拼成一个细长的矩形来模拟直线, 不过这样比较麻烦, 所以我们打算改用另外一种方法来实现: 把组成六边形的三角形的顶点设置不同的颜色, 这样相邻两个三角形之间那条公共边就被突出了.

在 `mesh` 中, 可以用这个函数来设定顶点的颜色 `mesh:color(i, color)`, 第一个参数 `i` 是顶点在顶点数组中的索引值, 从 `1` 开始, 貌似我们的六边形总共生成了 `12` 个顶点(好像有些不对), 每 `3` 个顶点组成一个三角形, 先随便改改看看是什么效果, 就修改其中 `1`,`5`,`9` 号顶点好了, 马上试验:

```
	...
	local c1,c2 = color(0, 255, 121, 123),color(255, 57, 0, 123)
    self.m:setColors(c2)
    self.m:color(1,c1)
    self.m:color(5,c1)
    self.m:color(9,c1)
	...
```




