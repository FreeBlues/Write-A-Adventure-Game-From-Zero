#	从零开始写一个武侠冒险游戏-6-用GPU提升性能(1)

##	概述

我们之前所有的绘图工作都是直接使用基本绘图函数来绘制的, 这样写出来的代码容易理解, 不过这些代码基本都是由 `CPU` 来执行的, 没怎么发挥出 `GPU` 的作用, 实际上现在的移动设备都有着功能不弱的 `GPU`(一般都支持 `OpenGL ES 2.0/3.0`), 本章的目标就是把我们游戏中绘图相关的大部分工作都转移到 `GPU` 上, 这样既可以解决我们代码目前存在的一些小问题, 同时也会带来很多额外好处:

-	首先是性能可以得到很大提升, 我们现在的帧速是40左右, 主要是雷达图的实时绘制拖慢了帧速;
-	方便在地图类上实现各种功能, 如大地图的局部显示, 地图平滑卷动;
-	保证地图上的物体状态更新后重绘地图时的效率;
-	帧动画每次起步时速度忽然加快的问题, 反向移动时角色动作显示为倒退, 需要镜像翻转;
-	状态栏可以通过 `纹理贴图` 来使用各种中文字体(`Codea`不支持中文字体);
-	最大的好处是: 可以通过 `shader` 来自己编写各种图形特效.

在 `Codea` 里使用 `GPU` 的方法就是用 `mesh` 和 `shader` 来绘图, 而 `mesh` 本身就是一种内置 `shader`. 还有一个很吸引人的地方就是: 使用 `mesh` 后续可以很容易地把我们的 `2D` 游戏改写为 `3D` 游戏, 这也是我们这个游戏的一个尝试: 玩家可以自由地在 `2D` 和 `3D` 之间转换.

基于以上种种理由, 我们后续会把游戏中大部分图形绘制工作都放到 `GPU` 上, `CPU` 只负责处理耗费资源很少的菜单选项等 `UI` 绘制.

本章先简单介绍一下 `Codea` 中的 `mesh` 和 `shader`, 接着按照从易到难的顺序, 依次把 `帧动画类`, `地图类` 和 `状态类` 改写为用 `GPU` 绘制(也就是用 `mesh` 绘制)

>这部分内容稍微深入一些, 需要读者对 `OpenGL ES 2.0` 中的坐标系统有一点了解, 另外对于着色器语言 `shader language` 也要有一定了解, 这样读起来不会太吃力, 不过没有这方面背景也不要紧, 多读几遍, 上机跑几遍例程, 再自己胡乱修改修改看看是什么效果, 这么折腾一番也差不多会了.

因为一方面本章内容稍微难一些, 另一方面本章的篇幅也比较长, 因此本章将拆分为两个或者三个子章节.

##	Codea 中的 mesh + shader 介绍

###	简单介绍 mesh

`mesh` 是 `Codea` 中的一个用来绘图的类, 用来实现一些高级绘图, 用法也简单, 先新建一个 `mesh` 实例, 接着设置它的各项属性, 诸如设置顶点 `m.vertices`, 设置纹理贴图 `m.texture`, 设置纹理坐标 `m.texCoords`, 设置着色器 `m.shader= shader(...)` 等等, 最后就是用它的 `draw()` 方法来绘制, 如果有触摸事件需要处理, 那就写一下它的 `touched(touch)` 函数, 最简单例程如下:

```
function setup()
	m = mesh()	
	mi = m:addRect(x, y, WIDTH/10, HEIGHT/10)
	m.texture = readImage("Documents:catRunning")
	m.shader = shader(shaders["sprites"].vs,shaders["sprites"].fs)
	m:setRectTex(mi, s, t, w,h)
end

function draw()
	m:draw()
end

```

###	简单介绍 shader

`shader` 是 `OpenGL` 中的概念, 我们在移动设备上使用的 `OpenGL` 版本是 `OpenGL ES 2.0/3.0`, `shader` 是其中的着色器, 用于在管线渲染的两个环节通过用户的自定义编程实行人工干预, 这两个环节一个是 `顶点着色-vertex`, 一个是 `片段(像素)着色-fragment`, 也就是说实际上它就是针对 `vertex` 和 `fragment` 的两段程序, 它的最简单例程如下:

```
shaders = {
sprites = { vs=[[
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
	// 取得像素点的纹理采样
	lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
	gl_FragColor = col;
}
]]}
}
```

为方便调用,我们把它们写在两段字符串中, 然后放到一个表里.

`Codea` 中的 `mesh` 和 `shader` 可以到[官网](https://codea.io/reference/Shaders.html#meshOverview)查看手册, 或者看看 `Codea App` 的内置手册(中文版), 还算全面.

大致介绍了 `mesh` 和 `shader` 之后, 就要开始我们的改写工作了, 先从 `帧动画类开始`.

##	用 mesh 改写帧动画类

###	思路

仔细分析之后, 发现用 `mesh` 去实现帧动画, 简直是最合适不过了, 只要充分利用好它的纹理贴图和纹理坐标属性, 就可以很方便地从一张大图上取得一幅幅小图, 而且动画显示速度控制也很好写, 我们先用 `mesh` 创建一个矩形, 把整副帧动画素材图作为它的纹理贴图, 这样我们就可以通过设置不同的纹理坐标来取得不同的子帧, 而且它的纹理坐标的参数特别适合描述子帧: `左下角 x`, `左下角 y`, `宽度`, `高度`, 注意, 纹理坐标的范围是 `[0,1]`.

>补充说明一下, 鉴于目前并非所有的设备都支持 `3.0`, 所以我们这里使用的都是 `OpenGL ES 2.0`, 在 `3.0` 中, 新增了一种纹理类型 `2Dw纹理数组-2DSampleArray`, 就是专门用于实现帧动画的, 用起来应该更方便.

###	结合具体代码进行说明

下面看看代码:

```
function setup()
	...
	-- 新建一个矩形, 保存它的标识索引 mi
	mi = m:addRect(self.x, self.y,WIDTH/10,HEIGHT/10)
	--	把整副帧动画素材设置为纹理贴图
	m.texture = readImage("Documents:catRunning")
	--	计算出各子帧的纹理坐标存入表中
	coords = {{0,3/4,1/2,1/4}, {1/2,3/4,1/2,1/4}, {0,2/4,1/2,1/4}, {1/2,2/4,1/2,1/4}, 
			{0,1/4,1/2,1/4}, {1/2,1/4,1/2,1/4}, {0,0,1/2,1/4}, {1/2,0,1/2,1/4}}
	-- 把第一幅子帧设置为它的纹理坐标
	m:setRectTex(mi, self.coords[1][1], self.coords[1][2] ,self.coords[1][3], self.coords[1][4])
	...
end
```

因为我们这幅素材图分 `2` 列, `4` 行, 共有 `8` 副子帧, 第一幅子帧在左上角, 所以第一幅子帧对应的纹理坐标就是 `{0, 3/4, 1/2, 1/4}`, 其余以此类推, 我们把所有子帧的纹理坐标按显示顺序依次存放在一个表中, 后续可以方便地过递增索引来循环显示.

先在 `setup()` 中设置好 `time` 和 `speed` 的值, 接着在 `draw()` 中可以通过这段代码来控制每帧的显示时间:

```
function draw()
	...
	-- 如果停留时长超过 speed，则使用下一帧
    if os.clock() - time >= speed then
        i = i + 1
        time = os.clock()
    end
    ...
end
```

我们一般用帧动画来表现玩家控制的角色, 需要移动它的显示位置, 可以在 `draw()` 中用这条语句实现:

```
	-- 根据 x, y 重新设置显示位置
	m:setRect(mi, x, y, w, h)
```

目前我们的代码需要每副子帧的尺寸一样大, 如果子帧尺寸不一样大的话, 就需要做一个转换, 我们决定让属性纹理坐标表仍然使用真实坐标, 新增一个类方法来把它转换成范围为 `[0,1]` 的表, 如下:

```
-- 原始输入为形如的表:
pos = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
       {320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}

-- 把绝对坐标值转换为相对坐标值
function convert(coords)
	local w, h = m.texture.width, m.texture.height
	local n = #coords
	for i = 1, n do
		coords[i][1], coords[i][2] = coords[i][1]/w, coords[i][2]/h
		coords[i][3], coords[i][4] = coords[i][3]/w, coords[i][4]/h
	end
end
```

###	用 shader 实现镜像翻转

现在还有一个问题, 就是当角色先向右移动, 然后改为向左移动时, 角色的脸仍然朝向右边, 看起来就像是倒着走一样, 因为我们的帧动画素材中橘色就是脸朝右的, 该怎么办呢? 有种办法是做多个方向的帧动画素材, 比如向左, 向右, 向前, 向后, 这貌似是通用的解决方案, 不过我们这里有一种办法可以通过 `shader` 实现左右镜像翻转, 然后根据移动方向来决定是否调用翻转 `shader`.

因为我们只是左右翻转, 可以这样想象: 在图像中心垂直画一条中线, 把中线左边的点翻到中线右边, 把中线右边的点翻到中线左边, 也就是每个点只改变它的 `x` 值, 假设一个点原来的坐标为 `(x, y)`, 翻转后它的坐标就变成了 `(1.0-x, y)`, 注意, 此处因为是纹理坐标, 所以该点坐标范围仍然是 `[0,1]`, 这次变化只涉及顶点, 所以我们只需要修改 `vertex shader`, 代码如下:

```
void main()
{
	vColor = color;
	// vTexCoord = texCoord;
	vTexCoord = vec2(1.0-texCoord.x, texCoord.y);
	gl_Position = modelViewProjection * position;
}

```

不过这样处理在每个子帧的尺寸有差异时会出现显示上的问题, 因为我们的纹理坐标是手工计算出来的, 它所确定的子帧不是严格对称的, 解决办法就是给出一个精确左右对称的纹理坐标, 这样弄起来也挺麻烦, 其实最简单的解决办法是把素材处理一下, 让每副子帧的尺寸相同就好了.

###	用 shader 去掉素材白色背景

在使用 `runner` 素材时, 因为它的背景是白色, 需要处理成透明, 之前我们专门写了一个函数 `Sprites:deal()` 预先对图像做了处理, 现在我们换一种方式, 直接在 `shader` 里处理, 也很简单, 就是在用取样函数得到当前像素的颜色时, 看看它是不是白色,若是则使用 `shader` 内置函数 `discard` 将其丢弃, 注意, 这里的颜色值必须写成带小数点的形式, 因为它是一个浮点类型, 对应的 `fragment shader` 代码如下:

```
// 定义一个用于比较的最小 alpha 值, 由用户自行控制
uniform vec4 maxWhite;

void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    
    if ( col.r > maxWhite.x &&  col.g > maxWhite.y && col.b > maxWhite.z) 
    	discard;
    else	    
    	gl_FragColor = col;
}
```

试着执行一下, 发现效果还不错.

发现还有个小问题, 就是修改了 `self.w` 和 `self.h` 后, 显示的区域出现了错误, 看了代码, 需要在 `Sprites:init()` 中修改一下, 修改前为:

```
	self.mi = self.m:addRect(self.x, self.y, self.w, self.h)
```

修改后为:

```
	self.mi = self.m:addRect(self.x, self.y, w, h)
```

另外, 在移动角色时加了一个判断, 避免它走出屏幕范围, 代码如下:

```
	-- 根据 self.x, self.y 重新设置整幅图的显示位置，走到边缘则不再前进
    local l,r,b,t = WIDTH/16,WIDTH*15/16,HEIGHT/16,HEIGHT*15/16
    if self.x >= l and self.x <= r and self.y >= b and self.y <= t then
    	self.m:setRect(self.mi, self.x, self.y, self.w, self.h)
    end
```

不过有些切换不太灵活, 后续需要找一下原因.

###	完整代码

写成类的完整代码如下:

```
-- c06.lua

--# Shaders
-- 用 mesh/shader 实现帧动画，把运算量转移到 GPU 上，可用 shader 实现各种特殊效果
Sprites = class()

function Sprites:init()
    self.m = mesh()
    self.m.texture  = readImage("Documents:catRunning")
    self.m.shader = shader(shaders["sprites"].vs,shaders["sprites"].fs)
    self.coords = {{0,3/4,1/2,1/4}, {1/2,3/4,1/2,1/4}, {0,2/4,1/2,1/4}, {1/2,2/4,1/2,1/4}, 
                    {0,1/4,1/2,1/4}, {1/2,1/4,1/2,1/4}, {0,0,1/2,1/4}, {1/2,0,1/2,1/4}}
    self.i = 1
    
    local w,h = self.m.texture.width, self.m.texture.height
    local ws,hs = WIDTH/w, HEIGHT/h
    self.x, self.y = w/2, h/2
    self.w, self.h = WIDTH/10, HEIGHT/10
    self.mi = self.m:addRect(self.x, self.y, self.w, self.h)
    self.speed = 1/30
    self.time = os.clock()
end

function Sprites:convert()
	local w, h = self.m.texture.width, self.m.texture.height
	local n = #self.coords
	for i = 1, n do
		self.coords[i][1], self.coords[i][2] = self.coords[i][1]/w, self.coords[i][2]/h
		self.coords[i][3], self.coords[i][4] = self.coords[i][3]/w, self.coords[i][4]/h
	end
end

function Sprites:draw()
    -- 依次改变贴图坐标，取得不同的子帧
    self.m:setRectTex(self.mi, 
    				  self.coords[(self.i-1)%8+1][1], self.coords[(self.i-1)%8+1][2], 
    				  self.coords[(self.i-1)%8+1][3], self.coords[(self.i-1)%8+1][4])
    
    -- 根据 self.x, self.y 重新设置整幅图的显示位置，走到边缘则不再前进
    local l,r,b,t = WIDTH/16,WIDTH*15/16,HEIGHT/16,HEIGHT*15/16
    if self.x >= l and self.x <= r and self.y >= b and self.y <= t then
    	self.m:setRect(self.mi, self.x, self.y, self.w, self.h)
    end
    
    -- 如果停留时长超过 self.speed，则使用下一帧
    if os.clock() - self.time >= self.speed then
        self.i = self.i + 1
        self.time = os.clock()
    end
    
    self.m:draw()
end

function Sprites:touched(touch)
    self.x, self.y = touch.x, touch.y
end


-- 游戏主程序框架
function setup()
    displayMode(OVERLAY)
    
    -- 帧动画素材1
    img1 = readImage("Documents:runner")
    pos1 = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
			{320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}
       
	-- 帧动画素材2       
	img2 = readImage("Documents:catRunning")
    local w,h = 1024,1024
    pos2 = {{0,h*3/4,w/2,h/4},{w/2,h*3/4,w/2,h/4},{0,h*2/4,w/2,h/4},{0,h*2/4,w/2,h/4},
            {0,h*1/4,w/2,h/4},{w/2,h*1/4,w/2,h/4},{0,h*0/4,w/2,h/4},{0,h*0/4,w/2,h/4}}
      
	-- 开始初始化帧动画类            
    myS = Sprites()
    myS.m.texture = img1
    myS.coords = pos1
    -- 若纹理坐标为绝对数值, 而非相对数值(即范围在[0,1]之间), 则需将其显式转换为相对数值
    myS:convert()
    
    -- 使用自定义 shader
    myS.m.shader = shader(shaders["sprites1"].vs,shaders["sprites1"].fs)
    -- 设置 maxWhite
    myS.m.shader.maxWhite = 0.8
    

    -- 设置速度
    myS.speed = 1/20
    myS.x = 500
end

function draw()
    background(39, 31, 31, 255)
    -- 绘制 mesh
    myS:draw()
    sysInfo()
end

function touched(touch)
    myS:touched(touch)
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
shaders = {

sprites = { vs=[[
// 左右翻转着色器
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
    // vTexCoord = texCoord;
    vTexCoord = vec2(1.0-texCoord.x, texCoord.y);
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
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    gl_FragColor = col;
}
]]},


sprites1 = { vs=[[
// 把白色背景转换为透明着色器
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

// 定义一个用于比较的最小 alpha 值, 由用户自行控制
uniform float maxWhite;

void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    
    if ( col.r > maxWhite.x &&  col.g > maxWhite.y && col.b > maxWhite.z)  
    	discard;
    else	    
    	gl_FragColor = col;
}
]]}
}
``` 

回头来看, 就发现用 `mesh` 改写后的帧动画类既简单又高效. 而且有了 `shader` 这个大杀器, 我们可以非常方便地为角色添加各种特效, 上面用过的 `镜像` 和 `去素材白色背景` 就是两种比较简单的特效, 我们在下面介绍几种其他特效.

##	在帧动画角色上用 shader 增加特效

###	角色灰化

一些游戏, 比如 `魔兽世界`, 在玩家控制的角色死亡时, 会进入灵魂状态, 这时所有的画面全部变为灰色, 我们也可以在这里写一段 `shader` 来实现这个效果, 不过我们打算稍作修改, 只把玩家角色变为灰色, 屏幕上的其余部分都保持原色.

先写一个从彩色到灰度的转换函数, 这个函数要在 `fragment shader` 中使用:

```
float intensity(vec4 col) {
    // 计算像素点的灰度值
    return 0.3*col.x + 0.59*col.y + 0.11*col.z;
}
```

然后修改片段着色代码:

```
void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    col.rgb = vec3(intensity(col));
    gl_FragColor = col;
}
```

如果我们希望在灰化的同时实现虚化, 也就是让角色变淡, 可以连 `alpha` 一起修改, 这种淡化特效可以用于角色使用了隐匿技能后的显示, 代码如下:

```
void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    col.rgba = vec4(intensity(col));
    gl_FragColor = col;
}
```

效果很不错, 完全达到了我们的预定目标.

###	中毒状态

很多游戏中, 角色如果中毒了, 会在两个地方显示出来, 一个是状态栏, 一个是角色本身, 比如 `仙剑奇侠传` 中会给角色渲染一层深绿色, 我们用 `shader` 实现的话, 只需要把取样得到的像素点颜色乘以一个指定的颜色值(绿色或其他), 该指定颜色可随时间变化而变深, 也可以因为吃了解毒药而逐渐变浅(在我们的设定里不存在一吃药就变好的情况, 只能慢慢好), 这部分处理可以充分利用 `mesh` 的一个方法 `setRectColor()` 来实现, 代码如下:

```
function setup()
	...
	myS.m:setRectColor(myS.mi, 0, 255,0,255)
	...
```

`shader` 中只需要把取样点的颜色跟该颜色`vColor`相乘即可, 我们的模板代码就是这样的:

```
void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    gl_FragColor = col;
```

所以我们只需要在 `setup()` 中设置一下, 然后调用名为 `sprites` 的 `shader` 即可.

效果完美, 后面可以根据游戏需要再加一个根据时间流逝绿色变淡或者变深的处理.

角色的其他状态, 例如受伤出血也可以通过类似的方法实现(把 `vColor` 改为红色即可), 可自行试验.

###	角色光粒子化

实际上, 我们上面实现的几种特效都是比较简单的, 最后我们来一个复杂点的, 角色升华, 变成光粒子消散在空中, 当然这种特效也可以放在 `NPC` 身上, 代码如下:

```
---后续补充
```


###	本章用到的 shader 代码

下面列出我们在这里用于实行各种特性的 `shader` 代码:

```
-- Shader
shaders = {

sprites = { vs=[[
// 左右翻转着色器
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
    // vTexCoord = texCoord;
    vTexCoord = vec2(1.0-texCoord.x, texCoord.y);
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
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    gl_FragColor = col;
}
]]},


sprites1 = { vs=[[
// 把白色背景转换为透明着色器
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

// 定义一个用于比较的最小 alpha 值, 由用户自行控制
uniform vec4 maxWhite;

void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    
    if ( col.r > maxWhite.x &&  col.g > maxWhite.y && col.b > maxWhite.z) 
    	discard;
    else	    
    	gl_FragColor = col;
}
]]},


sprites2 = { vs=[[
// 局部变灰
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

float intensity(vec4 col) {
    // 计算像素点的灰度值
    return 0.3*col.x + 0.59*col.y + 0.11*col.z;
}

void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    col.rgba = vec4(intensity(col));
    gl_FragColor = col;
}
]]}
}
```

##	本章小结

使用 `mesh`绘图时, 可以选择不加载 `shader`, 如果需要自定义修改图像中的某些显示效果, 就要选择加载 `shader` 了.

关于帧动画类的 `GPU` 改造暂时就写这么多, 下一节准备说说如何用 `mesh` 来改写地图类.

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
│   └── c06.lua
├── 从零开始写一个武侠冒险游戏-1-状态原型.md
├── 从零开始写一个武侠冒险游戏-2-帧动画.md
├── 从零开始写一个武侠冒险游戏-3-地图生成.md
├── 从零开始写一个武侠冒险游戏-4-第一次整合.md
├── 从零开始写一个武侠冒险游戏-5-使用协程.md
├── 从零开始写一个武侠冒险游戏-6-用GPU提升性能(1).md
└── 从零开始写一个武侠冒险游戏-6-用GPU提升性能(2).md

2 directories, 22 files
Air:Write-A-Adventure-Game-From-Zero admin$ 
```

### 开源中国项目文档链接

[从零开始写一个武侠冒险游戏-1-状态原型](http://my.oschina.net/freeblues/blog/687421)   
[从零开始写一个武侠冒险游戏-2-帧动画](http://my.oschina.net/freeblues/blog/689399)  
[从零开始写一个武侠冒险游戏-3-地图生成](http://my.oschina.net/freeblues/blog/690618)  
[从零开始写一个武侠冒险游戏-4-第一次整合](http://my.oschina.net/freeblues/blog/690718)  
[从零开始写一个武侠冒险游戏-5-使用协程](http://my.oschina.net/freeblues/blog/691552)  
[从零开始写一个武侠冒险游戏-6-用GPU提升性能(1)](http://my.oschina.net/freeblues/blog/694246)
