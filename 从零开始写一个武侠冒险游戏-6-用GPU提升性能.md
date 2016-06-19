#	从零开始写一个武侠冒险游戏-6-用GPU提升性能

##	概述

我们之前所有的绘图工作都是直接使用基本绘图函数来绘制的, 这样写出来的代码容易理解, 不过这些代码基本都是由 `CPU` 来执行的, 实际上现在的移动设备都有着功能不弱的 `GPU`(需要移动设备支持 `OpenGL ES 2.0/3.0`), 本章的目标就是把我们游戏绘图相关的大部分工作都转移到 `GPU` 上, 这样既可以解决我们代码目前存在的一些小问题, 也会有很多额外好处:

-	首先是性能可以得到很大提升, 我们现在的帧速是40左右, 主要是雷达图的实时绘制拖慢了帧速;
-	方便在地图类上实现各种功能:大地图的局部显示, 地图平滑卷动, 地图物体更新后重绘时的效率;
-	帧动画每次起步时速度忽然加快的问题, 反向移动时角色动作显示为倒退, 需要镜像翻转;
-	状态栏可以通过 `纹理贴图` 来使用各种中文字体(`Codea`不支持中文字体);
-	可以通过 `shader` 来自己编写各种图形特效.

在 `Codea` 里使用 `GPU` 的方法就是使用 `mesh` 和 `shader`, 而 `mesh` 本身就是一种内置 `shader`. 还有一个很吸引人的地方就是: 使用 `mesh` 后续可以很容易地把我们的 `2D` 游戏改写为 `3D` 游戏.

所以我们后续会把大部分游戏绘图工作都放到 `GPU` 上, `CPU` 只负责绘制耗费资源很少的操作菜单等`UI` 绘制.

本章先简单介绍一下 `Codea` 中的 `mesh` 和 `shader`, 接着按照从易到难的顺序, 依次把 `帧动画类`, `地图类` 和 `状态类` 改写为用 `GPU` 绘制(也就是用 `mesh` 绘制)

##	Codea 中的 mesh + shader 介绍

###	介绍 mesh

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

###	介绍 shader

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
	coords = {vec2(0,3/4), vec2(1/2,3/4), vec2(0,2/4), vec2(1/2,2/4), 
	          vec2(0,1/4), vec2(1/2,1/4), vec2(0,0), vec2(1/2,0)}
	-- 把第一幅子帧设置为它的纹理坐标
	m:setRectTex(mi, self.coords[1].x, self.coords[1].y ,1/2, 1/4)
	...
end
```


因为我们这幅素材图分 `2` 列, `4` 行, 共有 `8` 副子帧, 第一幅子帧在左上角, 所以第一幅子帧对应的纹理坐标就是 `vec2(0,3/4)`, 其余以此类推, 我们把所有子帧的纹理坐标按显示顺序依次存放在一个表中, 后续可以方便地过递增索引来循环显示.

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
	m:setRect(mi, x, y, WIDTH/10, HEIGHT/10)
```

目前我们的代码需要每副子帧的尺寸一样大, 如果子帧尺寸不一样大的话, 就需要做一个转换, 我们决定让属性纹理坐标表仍然使用真实坐标, 新增一个类方法来把它转换成范围为 `[0,1]` 的表, 如下:

```
-- 原始输入为形如的表:
pos = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
       {320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}

function convert(coords)
	local w, h = m.texture.width, m.texture.height
	local n = #coords
	for i = 1, n do
		coords[i].x, coords[i].y = coords[i].x/w, coords[i].y/h
		coords[i].z, coords[i].w = coords[i].z/w, coords[i].y/h
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

###	完整代码

写成类的完整代码如下:

```
--# Shaders
-- 用 mesh/shader 实现帧动画，把运算量转移到 GPU 上，可用 shader 实现各种特殊效果
Sprites = class()

function Sprites:init()
    self.m = mesh()
    self.tex = readImage("Documents:catRunning")
    self.m.texture = self.tex
    self.m.shader = shader(shaders["sprites"].vs,shaders["sprites"].fs)
    self.coords = {vec4(0,3/4,1/2,1/4), vec4(1/2,3/4,1/2,1/4), 
    			   vec4(0,2/4,,1/2,1/4), vec4(1/2,2/4,,1/2,1/4), 
                   vec4(0,1/4,,1/2,1/4), vec4(1/2,1/4,,1/2,1/4), 
                   vec4(0,0,,1/2,1/4), vec4(1/2,0,,1/2,1/4)}
    self.i = 1
    
    local w,h = self.tex.width, self.tex.height
    local ws,hs = WIDTH/w,HEIGHT/h
    self.x, self.y = w/2,h/2
    self.mi = self.m:addRect(self.x, self.y,WIDTH/10,HEIGHT/10)
    self.speed = 1/30
    self.time = os.clock()
    
    self:convert()
end

function Sprites:convert()
	local w, h = self.tex, self.tex.height
	local n = #self.coords
	for i = 1, n do
		coords[i].x, coords[i].y = coords[i].x/w, coords[i].y/h
		coords[i].z, coords[i].w = coords[i].z/w, coords[i].y/h
	end
end

function Sprites:draw()
    -- 依次改变贴图坐标，取得不同的子帧
    self.m:setRectTex(self.mi, 
    				  self.coords[(self.i-1)%8+1].x,self.coords[(self.i-1)%8+1].y, 
    				  self.coords[i].z, self.coords[i].w)
    -- 根据 self.x, self.y 重新设置显示位置
    self.m:setRect(self.mi, self.x, self.y, WIDTH/10,HEIGHT/10,50)
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
    img1 = readImage("Documents:catRunning")
    pos1 = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
			{320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}
       
	-- 帧动画素材2       
	img2 = readImage("Documents:catRunning")
    local w,h = 1024,1024
    pos2 = {{0,h*3/4,w/2,h/4},{w/2,h*3/4,w/2,h/4},{0,h*2/4,w/2,h/4},{0,h*2/4,w/2,h/4},
            {0,h*1/4,w/2,h/4},{w/2,h*1/4,w/2,h/4},{0,h*0/4,w/2,h/4},{0,h*0/4,w/2,h/4}}
      
	-- 开始初始化帧动画类            
    myS = Sprites()
    myS.tex = img2
    myS.coords = pos2
    myS.speed = 1/20
    myS.x = 200
end

function draw()
    background(39, 31, 31, 255)

    myS:draw()
    sysInfo()
end

function touched(touch)
    myS:touched(touch)
end


-- Shader
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
]]}
}
``` 
回头来看, 就发现用 `mesh` 改写后的帧动画类既简单又高效.

##	用 mesh 改写地图类

地图类的处理相对来说复杂一些, 它可以从两个层面使用 `mesh`, 一个是

## 所有章节链接

[从零开始写一个武侠冒险游戏-1-状态原型](http://my.oschina.net/freeblues/blog/687421)   
[从零开始写一个武侠冒险游戏-2-帧动画](http://my.oschina.net/freeblues/blog/689399)  
[从零开始写一个武侠冒险游戏-3-地图生成](http://my.oschina.net/freeblues/blog/690618)  
[从零开始写一个武侠冒险游戏-4-第一次整合](http://my.oschina.net/freeblues/blog/690718)  
[从零开始写一个武侠冒险游戏-5-使用协程](http://my.oschina.net/freeblues/blog/691552)  
[从零开始写一个武侠冒险游戏-6-用GPU提升性能](http://my.oschina.net/freeblues/blog/691552)
