#	从零开始写一个武侠冒险游戏-6-用GPU提升性能(3)
##	--解决因绘制雷达图导致的帧速下降问题

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

![雷达图背景大六边形](https://static.oschina.net/uploads/img/201606/23205641_CJxT.png "雷达图背景大六边形")

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

![增加了属性值小六边形](https://static.oschina.net/uploads/img/201606/23205725_gguL.png "增加了属性值小六边形")

很好, 非常符合我们的要求, 不过有一点就是作为背景的大六边形的对角的线没有画出来, 现在需要处理一下, 实际上用 `shader` 最适合画的图形就是三角形, 直线有点麻烦(虽然 `OpenGL ES 2.0` 支持 `三角形`, `直线` 和 `点` 三种基本图形绘制, 不过我在 `Codea` 中没找到`直线`的函数), 当然, 我们也可以用两个狭长的三角形拼成一个细长的矩形来模拟直线, 不过这样比较麻烦, 所以我们打算改用另外一种方法来实现: 把组成六边形的三角形的顶点设置不同的颜色, 这样相邻两个三角形之间那条公共边就被突出了.

在 `mesh` 中, 可以用这个函数来设定顶点的颜色 `mesh:color(i, color)`, 第一个参数 `i` 是顶点在顶点数组中的索引值, 从 `1` 开始, 貌似我们的六边形总共生成了 `12` 个顶点(感觉好像有些不对), 每 `3` 个顶点组成一个三角形, 先随便改改看看是什么效果, 就修改其中 `1`,`5`,`9` 号顶点好了, 马上试验:

```
	...
	local c1,c2 = color(0, 255, 121, 123),color(255, 57, 0, 123)
    self.m:setColors(c2)
    self.m:color(1,c1)
    self.m:color(5,c1)
    self.m:color(9,c1)
	...
```

看看截图:

![第一次修改顶点颜色](https://static.oschina.net/uploads/img/201606/23205847_cfNb.png "第一次修改顶点颜色")

果然, 完全不是我们想象中的六个小三角形, 原来出于优化的原因, 函数 `triangulate()` 会生成尽量少的三角形, 我们的六边形只需要 `4` 个三角形就可以了, 所以它返回 `12` 个顶点, 看来想达到我们的效果, 还得手动设定顶点, 好在我们的图形比较规则, 只需要再加一个中心的坐标就够了, 而我们中心点的坐标很有先见之明地被设置为了 `vec2(0,0)`, 代码如下:

```
	...
	-- 手动定义组成六边形的6个三角形的顶点
    local points = {vec2(0,r/s), vec2(-x/s,y/s), vec2(0,0),
                    vec2(-x/s,y/s), vec2(-x/s,-y/s), vec2(0,0),
                    vec2(-x/s,-y/s), vec2(0,-r/s), vec2(0,0),
                    vec2(0,-r/s), vec2(x/s,-y/s), vec2(0,0),
                    vec2(x/s,-y/s), vec2(x/s,y/s), vec2(0,0),
                    vec2(x/s,y/s), vec2(0,r/s), vec2(0,0)} 
    self.m.vertices = points
    
    local c1,c2 = color(186, 255, 0, 123),color(25, 235, 178, 123)
    self.m:setColors(c2)
    self.m:color(1,c1)
    self.m:color(4,c1)
    self.m:color(7,c1)
    self.m:color(10,c1)
    self.m:color(13,c1)
    self.m:color(16,c1)
    
    ...
```

![六个三角形颜色区分的截图](https://static.oschina.net/uploads/img/201606/23205940_rIG4.png "六个三角形颜色区分的截图")

再看看效果, 还可以, 好, 就按这个方式写了.

现在需要处理的是这个用于实时计算属性值顶点的函数 `axisDynamic()`, 认真分析一下, 就会发现, 其实我们不需要实时计算, 因为属性值并不是实时更新的, 它应该是随着角色的活动而变化, 角色有活动它才会变, 当然这也取决于我们的设定, 如果我们设定说角色只要有动作就会耗费体力, 哪怕角色坐着不动, 只要时间流逝它也会变的话, 那么它就需要实时绘制了, 我们先按实时绘制来实现. 既然是实时计算, 那我们希望把这部分计算处理也放到 `GPU` 中处理, 也就是说需要在 `shader` 中实现这个函数.

另外就是目前只用一个函数 `radarGraphMesh()` 来实现雷达图的绘制, 有些结构不合理, 一些初始化的工作在每次绘制时都要做, 所以打算把它拆分成三个个函数, 函数 `radarGraphInit()` 用来负责初始化一些顶点数据, 函数 `radarGraphVertex()` 用来根据属性值实时计算顶点坐标, 函数 `radarGraphDraw()` 用来执行绘图操作, 如下:

```
function Status:radarGraphInit()
	-- 雷达图底部六边形背景
    self.m = mesh()
    p = {"体力","内力","精力","智力","气","血"}
    -- 中心坐标，半径，角度，缩放比例
    local x0,y0,r,a,s = 150,230,50,360/6,1
    -- 计算右上方斜线的坐标
    local x,y = r* math.cos(math.rad(30)), r* math.sin(math.rad(30))
    -- 六边形 6 个顶点坐标，从正上方开始，逆时针方向
    local points = triangulate({vec2(0,r/s),vec2(-x/s,y/s),vec2(-x/s,-y/s),
                                vec2(0,-r/s),vec2(x/s,-y/s),vec2(x/s,y/s)})
    print(#points, points[1], points[2],points[3])
    -- 手动定义组成六边形的6个三角形的顶点
    local points = {vec2(0,r/s), vec2(-x/s,y/s), vec2(0,0),
                    vec2(-x/s,y/s), vec2(-x/s,-y/s), vec2(0,0),
                    vec2(-x/s,-y/s), vec2(0,-r/s), vec2(0,0),
                    vec2(0,-r/s), vec2(x/s,-y/s), vec2(0,0),
                    vec2(x/s,-y/s), vec2(x/s,y/s), vec2(0,0),
                    vec2(x/s,y/s), vec2(0,r/s), vec2(0,0)} 
    self.m.vertices = points
    
    local c1,c2 = color(186, 255, 0, 123),color(25, 235, 178, 123)
    self.m:setColors(c2)
    self.m:color(1,c1)
    self.m:color(4,c1)
    self.m:color(7,c1)
    self.m:color(10,c1)
    self.m:color(13,c1)
    self.m:color(16,c1)
    
    
    -- 绘制代表属性值的小六边形
    self.m1 = mesh()
    self.m1.vertices = self:radarGraphVertex()
    local c = color(221, 105, 55, 123)
    self.m1:setColors(c)
    
end

-- 实时绘制顶点位置，根据各状态属性值，实时计算顶点位置
function Status:radarGraphVertex()
	local l = 4
	local t,n,j,z,q,x = self.tili/l, self.neili/l, self.jingli/l,self.zhili/l, self.qi/l, self.xue/l
	local c,s = math.cos(math.rad(30)), math.sin(math.rad(30))
	local points = triangulate({vec2(0,t),vec2(-n*c,n*s),vec2(-j*c,-j*s),
                                    vec2(0,-z),vec2(q*c,-q*s),vec2(x*c,x*s)})
	return points
end

function Status:radarGraphDraw()
	setContext(self.img)
    pushMatrix()
    pushStyle()
	-- 平移到中心 (x0,y0), 方便以此为中心旋转
    translate(x0,y0)
    -- 围绕中心点匀速旋转
    rotate(30+ElapsedTime*10)
    
    self.m:draw()
	self.m1:draw()

    
    strokeWidth(2)    
    -- noSmooth()
    stroke(21, 42, 227, 255)
    fill(79, 229, 28, 255)
    -- 绘制雷达图相对顶点之间的连线
    for i=1,6 do
        -- print(i)
        text(p[i],0,45)
        -- line(0,0,0,r)
        rotate(a)
    end

    popStyle()
    popMatrix()
    setContext()	
end
```

再把 `Status:radarGraphInit()` 放到 `Status:init()` 中, 把 `Status:radarGraphDraw()` 放到 `Status:drawUI()` 中, 如下:

```
function Status:init() 
    ...
        
    -- 初始化雷达图
    self:radarGraphInit()
end

function Status:drawUI()
    ...
    
    self:radarGraphDraw()
    sprite(self.img, 400,300)
end
```

运行发现帧速大幅提升, 基本在 `60` 左右, 看来之前拖累性能的原因是不合理的程序结构(把所有工作都放到一个函数 `Status:radarGraph()` 中去绘制雷达图), 真是歪打正着, 这么看来, 这里仅仅做完这两点:

-	把绘图方式改写为 `mesh`;
-	修改不合理的程序结构.

就已经把性能大幅度提升了, 也就没必要再用 `shader` 来改写了.

剩下的就是一些收尾工作, 比如把一些调试时使用的全局变量改写为类属性什么的, 完成后的完整状态类如下:

```
-- 用 mesh 绘制，先绘制背景六边形，再绘制技能六边形，再绘制动态技能，最后再考虑旋转
-- 角色状态类
Status = class()

function Status:init() 
    -- 体力，内力，精力，智力，气，血
    self.tili = 100
    self.neili = 30
    self.jingli = 70
    self.zhili = 100
    self.qi = 100
    self.xue = 100
    self.gongfa = {t={},n={},j={},z={}}
    self.img = image(200, 300)
    -- 初始化雷达图
    self:radarGraphInit()
end

function Status:update()
    -- 更新状态：自我修炼，日常休息，战斗
    self.neili = self.neili + 1
    self:xiulian()
end

function Status:drawUI()
    setContext(self.img)
    background(119, 121, 72, 255)
    pushStyle()
    fill(35, 112, 111, 114)
    rect(5,5,200-10,300-10)
    fill(70, 255, 0, 255)
    textAlign(RIGHT)
    local w,h = textSize("体力: ")
    text("体力: ",30,280) 
    text(math.floor(self.tili), 30 + w, 280)
    text("内力: ",30,260) 
    text(math.floor(self.neili),  30 + w, 260)
    text("精力: ",30,240) 
    text(math.floor(self.jingli), 30 + w, 240)
    text("智力: ",30,220) 
    text(math.floor(self.zhili), 30 + w, 220)
    text("气    : ",30,200) 
    text(math.floor(self.qi), 30 + w, 200)
    text("血    : ",30,180) 
    text(math.floor(self.xue), 30 + w, 180)
    -- 绘制状态栏绘制的角色
    sprite("Documents:B1", 100,90)
    popStyle()
    setContext()
    
    self:radarGraphDraw()
    sprite(self.img, 400,300)
end

function Status:xiulian()
    -- 修炼基本内功先判断是否满足修炼条件: 体力，精力大于50，修炼一次要消耗一些
    if self.tili >= 50 and self.jingli >= 50 then
        self.neili = self.neili * (1+.005)
        self.tili = self.tili * (1-.001)
        self.jingli = self.jingli * (1-.001)
    end
end

-- 用 mesh 绘制, 改写为3个函数
function Status:radarGraphInit()
	-- 雷达图底部六边形背景
    self.m = mesh()
    p = {"体力","内力","精力","智力","气","血"}
    -- 中心坐标，半径，角度，缩放比例
    self.x0, self.y0, self.rr, self.ra, self.rs = 150,230,40,360/6,1
    local x0,y0,r,a,s = self.x0, self.y0, self.rr, self.ra, self.rs
    -- 计算右上方斜线的坐标
    local x,y = r* math.cos(math.rad(30)), r* math.sin(math.rad(30))
    -- 六边形 6 个顶点坐标，从正上方开始，逆时针方向
    local points = triangulate({vec2(0,r/s),vec2(-x/s,y/s),vec2(-x/s,-y/s),
                                vec2(0,-r/s),vec2(x/s,-y/s),vec2(x/s,y/s)})
    print(#points, points[1], points[2],points[3])
    -- 手动定义组成六边形的6个三角形的顶点
    local points = {vec2(0,r/s), vec2(-x/s,y/s), vec2(0,0),
                    vec2(-x/s,y/s), vec2(-x/s,-y/s), vec2(0,0),
                    vec2(-x/s,-y/s), vec2(0,-r/s), vec2(0,0),
                    vec2(0,-r/s), vec2(x/s,-y/s), vec2(0,0),
                    vec2(x/s,-y/s), vec2(x/s,y/s), vec2(0,0),
                    vec2(x/s,y/s), vec2(0,r/s), vec2(0,0)} 
    self.m.vertices = points
    
    local c1,c2 = color(186, 255, 0, 123),color(25, 235, 178, 123)
    self.m:setColors(c2)
    self.m:color(1,c1)
    self.m:color(4,c1)
    self.m:color(7,c1)
    self.m:color(10,c1)
    self.m:color(13,c1)
    self.m:color(16,c1)
    
    
    -- 绘制代表属性值的小六边形
    self.m1 = mesh()
    self.m1.vertices = self:radarGraphVertex()
    local c = color(221, 105, 55, 123)
    self.m1:setColors(c)
    
end

-- 实时绘制顶点位置，根据各状态属性值，实时计算顶点位置
function Status:radarGraphVertex()
	local l = 4
	-- 中心坐标，半径，角度，缩放比例
	local x0,y0,r,a,s = self.x0, self.y0, self.rr, self.ra, self.rs
	local t,n,j,z,q,x = self.tili/l, self.neili/l, self.jingli/l,self.zhili/l, self.qi/l, self.xue/l
	local c,s = math.cos(math.rad(30)), math.sin(math.rad(30))
	local points = triangulate({vec2(0,t),vec2(-n*c,n*s),vec2(-j*c,-j*s),
                                    vec2(0,-z),vec2(q*c,-q*s),vec2(x*c,x*s)})
	return points
end

function Status:radarGraphDraw()
	setContext(self.img)
    pushMatrix()
    pushStyle()
    
    -- 中心坐标，半径，角度
    local x0,y0,r,a,s = self.x0, self.y0, self.rr, self.ra, self.rs
	-- 平移到中心 (x0,y0), 方便以此为中心旋转
    translate(x0,y0)
    -- 围绕中心点匀速旋转
    rotate(30+ElapsedTime*10)
    
    self.m:draw()

    strokeWidth(2)    
    -- Smooth()
    stroke(21, 42, 227, 255)
    fill(79, 229, 128, 255)
    -- 绘制雷达图相对顶点之间的连线
    for i=1,6 do
        text(p[i],0,r+15)
        -- line(0,0,0,49)
        rotate(a)
    end
    self.m1.vertices = self:radarGraphVertex()
    self.m1:draw()

    popStyle()
    popMatrix()
    setContext()	
end


-- main 主程序框架
function setup()
    displayMode(OVERLAY)
    myStatus = Status()
end

function draw()
    background(32, 29, 29, 255)    
    myStatus:drawUI()
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


-- Shader
shadersStatus = {
status = { vs=[[
// 雷达图着色器: 用 shader 绘制雷达图
//--------vertex shader---------
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

varying vec2 vTexCoord;
varying vec4 vColor;

uniform mat4 modelViewProjection;

void main()
{
	vColor = color;
	vTexCoord = texCoord;
	gl_Position = modelViewProjection * position;
}
]],
fs=[[
//---------Fragment shader------------
//Default precision qualifier
precision highp float;

varying vec2 vTexCoord;
varying vec4 vColor;

// 纹理贴图
uniform sampler2D texture;

void main()
{
	// vec4 col = texture2D(texture,vec2(mod(vTexCoord.x,1.0), mod(vTexCoord.y,1.0)));
	vec4 col = texture2D(texture,vTexCoord);
	gl_FragColor = vColor * col;
}
]]}
}
```

发现改写为 `mesh`, 再把原来的一个函数拆分成三个后, 不仅性能提升了, 而且代码也没那么多了, 更重要的是读起来很清晰.


## 本章小结

现在, 我们已经用 `mesh` 完成 `帧动画`, `地图类` 和 `状态类` 的改写, 而且效果还不错, 帧速也提升到了 `60` 左右, 既然达到了起初的目标, 那么剩下的就是再次把这几个改写后的模块整合到一起, 整合后的代码在这里: [c06.lua](https://raw.githubusercontent.com/FreeBlues/Write-A-Adventure-Game-From-Zero/master/src/c06.lua).


## 所有章节链接

###	Github项目地址

[Github项目地址](https://github.com/FreeBlues/Write-A-Adventure-Game-From-Zero), 源代码放在 `src/` 目录下, 图片素材放在 `assets/` 目录下, 整个项目文件结构如下:

```
Air:Write-A-Adventure-Game-From-Zero admin$ tree
.
├── README.md
├── Vim 列编辑功能详细讲解.md
├── assets
│   ├── IMG_0097.PNG
│   ├── IMG_0099.JPG
│   ├── IMG_0100.PNG
│   ├── c04.mp4
│   ├── cat.JPG
│   └── runner.png
├── src
│   ├── c01.lua
│   ├── c02.lua
│   ├── c03.lua
│   ├── c04.lua
│   ├── c05.lua
│   ├── c06-01.lua
│   ├── c06-02.lua
│   ├── c06-03.lua
│   └── c06.lua
├── 从零开始写一个武侠冒险游戏-0-开发框架Codea简介.md
├── 从零开始写一个武侠冒险游戏-1-状态原型.md
├── 从零开始写一个武侠冒险游戏-2-帧动画.md
├── 从零开始写一个武侠冒险游戏-3-地图生成.md
├── 从零开始写一个武侠冒险游戏-4-第一次整合.md
├── 从零开始写一个武侠冒险游戏-5-使用协程.md
├── 从零开始写一个武侠冒险游戏-6-用GPU提升性能(1).md
├── 从零开始写一个武侠冒险游戏-6-用GPU提升性能(2).md
└── 从零开始写一个武侠冒险游戏-6-用GPU提升性能(3).md

2 directories, 26 files
Air:Write-A-Adventure-Game-From-Zero admin$ 
```

### 开源中国项目文档链接

[从零开始写一个武侠冒险游戏-1-状态原型](http://my.oschina.net/freeblues/blog/687421)   
[从零开始写一个武侠冒险游戏-2-帧动画](http://my.oschina.net/freeblues/blog/689399)  
[从零开始写一个武侠冒险游戏-3-地图生成](http://my.oschina.net/freeblues/blog/690618)  
[从零开始写一个武侠冒险游戏-4-第一次整合](http://my.oschina.net/freeblues/blog/690718)  
[从零开始写一个武侠冒险游戏-5-使用协程](http://my.oschina.net/freeblues/blog/691552)  
[从零开始写一个武侠冒险游戏-6-用GPU提升性能(1)](http://my.oschina.net/freeblues/blog/694246)  
[从零开始写一个武侠冒险游戏-6-用GPU提升性能(2)](http://my.oschina.net/freeblues/blog/698529)
[从零开始写一个武侠冒险游戏-6-用GPU提升性能(3)](http://my.oschina.net/freeblues/blog/700143)


