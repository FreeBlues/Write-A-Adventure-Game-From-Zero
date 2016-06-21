#	从零开始写一个武侠冒险游戏-6-用GPU提升性能(2)

##	概述

用 `mesh` 改写地图类, 带来的一大好处是控制逻辑可以变得非常简单, 作为一个地图类, 最基本的控制逻辑就是显示哪一部分和地图如何卷动, 而这两点可以通过 `mesh` 的纹理贴图非常容易地解决, 因为在 `OpenGL ES 2.0/3.0` 中, 可以通过设置纹理坐标来决定如何在地图上显示纹理贴图, 而这些控制逻辑如果不用 `mesh`, 自己去写, 就有些繁琐了, 不信你可以试试. 

另外我们之前实现的地图类的地图绘制是极其简陋的, 比如地面就是一些单色的矩形块, 本章我们将会把很小的纹理贴图素材拼接起来生成更具表现力和真实感的地面.

基于 `OpenGL ES 2.0/3.0` 的纹理贴图特性, 我们既可以使用一块很小的纹理, 然后用拼图的方式把大屏幕铺满, 也可以使用一块很大的超出屏幕范围的图片做纹理, 然后选择其中一个尺寸跟屏幕尺寸相当的区域来显示. 

在本章中, 这两种方法都会用到, 前者用来生成一张大大的地图, 后者用来显示这块大地图的局部区域.

##	用 mesh 改写地图类

###	整体思路

地图类的处理相对来说复杂一些, 正如我们在 `概述` 中提到的, 要在两个层面使用 `mesh`, 第一层是用小素材纹理通过拼图的方式生成一张超过屏幕尺寸的大地图图片, 第二层是把这张大地图图片作为纹理素材, 通过纹理坐标的设置来从大地图图片素材中选择一个尺寸刚好是屏幕大小的区域, 然后把它显示在屏幕上.

###	先改写第二层面

因为我们是前面的基础上改写, 也就是说用来生成大地图图片的代码已经写好了, 所以我们可以选择先从简单的开始, 那就是先实现第二层面: 用大图片作为纹理贴图, 利用 `mesh` 的纹理坐标来实现显示小区域和地图卷动等功能.

####	具体实现方法

具体办法就是先在初始化函数 `Maps:init()` 中用 `mesh:addRect()` 新建一个屏幕大小的矩形, 然后加载已经生成的大地图图片作为纹理贴图, 再通过设置纹理坐标 `mesh:setRectTex(i, x, y, w, t)` 取得对应于纹理贴图上的一块屏幕大小的区域; 然后再在 `Maps:drawMap()` 函数中根据角色移动来判断是否需要卷动地图, 以及如果需要卷动向哪个方向卷动, 最后在 `Maps:touched(touch)` 函数中把纹理坐标的 `(x, y)` 跟触摸数据关联起来, 这样我们屏幕上显示的地图就会随着角色移动到屏幕边缘而自动把新地图平移过来.

####	代码说明

在初始化函数 `Maps:init()` 中主要是这些处理: 

-	先根据我们设置的地图参数计算出整个大地图的尺寸 `w,h`, 
- 	再申请一个这么大的图形对象 `self.imgMap`, 我们的大地图就要绘制在这个图形对象上, 
-	接着把屏幕放在大地图中央,计算出屏幕左下角在大地图上的绝对坐标值 `self.x, self.y`, 这里把大地图的左下角坐标设为 `(0,0)`, 
-	然后创建一个 `mesh` 对象 `self.m`, 
-	再在 `self.m` 上新增一个矩形, 该矩形中心坐标为 `(WIDTH/2, HEIGHT/2)`, 宽度为 `WIDTH`, 高度为 `HEIGHT`, 也就是一个跟屏幕一样大的矩形, 
-	把大地图 `self.imgMap` 设为 `self.m` 的纹理贴图, 
-	因为我们的纹理贴图大于屏幕, 所以需要设置纹理坐标来映射纹理上的一块区域, 再次提醒, 纹理坐标大范围是 `[0,1]`, 所以需要我们把坐标的绝对数值转换为 `[0,1]` 区间内的相对数值, 也就是用屏幕宽高除以大地图的宽高 `local u,v = WIDTH/w, HEIGHT/h`
-	最后把这些计算好的变量用 `mesh:setRectTex()` 设置进去

就是下面这些代码:

```
	...
	-- 根据地图大小申请图像
    local w,h = (self.gridCount+1)*self.scaleX, (self.gridCount+1)*self.scaleY
    self.imgMap = image(w,h)
    
    -- 使用 mesh 绘制地图
    -- 设置当前位置为矩形中心点的绝对数值，分别除以 w, h 可以得到相对数值
    self.x, self.y = w/2-WIDTH/2, h/2-HEIGHT/2
    self.m = mesh()
    self.mi = self.m:addRect(WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    self.m.texture = self.imgMap
    -- 利用纹理坐标设置显示区域，根据中心点坐标计算出左下角坐标，除以纹理宽度得到相对值，w h 使用固定值(小于1)
    local u,v = WIDTH/w, HEIGHT/h
    self.m:setRectTex(self.mi, self.x/w, self.y/h, u, v)
    ...
```

在绘制函数 `Maps:drawMap()` 中要做这些处理:

-	首先判断大地图有没有变化, 比如某个位置的某棵树是不是被玩家角色给砍掉了, 等等, 如果有就重新生成, 重新设置一遍, 
-	检查玩家角色 `myS` 当前所在的坐标 `(myS.x, myS.y)` 是不是已经处于地图边缘, 如果是则开始切换地图(也就是把地图卷动过来), 切换的办法就是给地图的纹理坐标的起始点一个增量操作,
- 	如果走到屏幕左边缘, 则需要地图向右平移, `self.x = self.x - WIDTH/1000`, 
-	如果走到屏幕右边缘, 则需要地图向左平移, `self.x = self.x + WIDTH/1000`, 
-	如果走到屏幕上边缘, 则需要地图向下平移, `self.y = self.y + HEIGHT/1000`,
-	如果走到屏幕下边缘, 则需要地图向上平移, `self.y = self.y - HEIGHT/1000`,
-	然后把这些数据全部除以 `w,h` 得到位于 `[0,1]` 区间内的坐标的相对值,
-	用这些坐标相对值作为函数 `self.m:setRectTex()` 的参数.

代码是这些:

```
	...
	-- 更新纹理贴图, --如果地图上的物体有了变化
	self.m.texture = self.imgMap
	local w,h = self.imgMap.width, self.imgMap.height
	local u,v = WIDTH/w, HEIGHT/h
	-- 增加判断，若角色移动到边缘则切换地图：通过修改贴图坐标来实现
	print(self.x,self.y)
	local left,right,top,bottom = WIDTH/10, WIDTH*9/10, HEIGHT/10, HEIGHT*9/10
	local ss = 800
	if myS.x <= left then self.x= self.x - WIDTH/ss end
	if myS.x >= right then self.x= self.x + WIDTH/ss end
	if myS.y <= bottom then self.y = self.y - HEIGHT/ss end
	if myS.y >= top then self.y = self.y + HEIGHT/ss end
	
	-- 根据计算得到的数据重新设置纹理坐标
	self.m:setRectTex(self.mi, self.x/w, self.y/h, u, v)  
	...
```

另外, 我们使用了一个局部变量 `local ss = 800` 来控制屏幕卷动的速度, 因为考虑到玩家角色可能行走, 也可能奔跑, 而我们这是一个武侠游戏, 可能会设置 `轻功` 之类的技能, 这样当角色以不同速度运动到屏幕边缘时, 地图卷动的速度也各不相同, 看起来真实感更强一些.

补充说明一点, 为方便编程, 我们使用的 `self.x, self.y` 都用了绝对数值, 但是在函数 `self.m:setRectTex()` 中需要的是相对数值, 所以作为参数使用时都需要除以 `w, h`, 这里我在调程序的时候也犯过几次晕.

在函数 `Maps:touched(touch)` 中, 把触摸位置坐标 `(touch.x, touch.y)` 跟玩家角色坐标 `(myS.x, myS.y)` 建立关联, 这里这么写主要是为了方便我们现在调试用.

代码很简单:

```
	if touch.state == BEGAN then
		myS.x, myS.y = touch.x, touch.y
	end
```

另外还需要在 `setup()` 函数中设置一下 `(myS.x, myS.y)` 的初值, 让它们位于屏幕中央就可以了.

```
	myS.x, myS.y = WIDTH/2, HEIGHT/2
```

####	修改后代码

完整代码如下:

```
-- c06-02.lua

-- 主程序框架
function setup()
    displayMode(OVERLAY)

    myS = {}
    myS.x, myS.y = WIDTH/2, HEIGHT/2
    myMap = Maps()
    myMap:createMapTable()
end

function draw()
    background(40, 40, 50)    
    
    -- 绘制地图
    myMap:drawMap()
    sysInfo()
end

function touched(touch)
    myMap:touched(touch)
end


-- 使用 mesh() 绘制地图
Maps = class()

function Maps:init()
    
    self.gridCount = 100
    self.scaleX = 40
    self.scaleY = 40
    self.plantSeed = 20.0
    self.minerialSeed = 50.0
    
    -- 根据地图大小申请图像
    local w,h = (self.gridCount+1)*self.scaleX, (self.gridCount+1)*self.scaleY
    -- print(w,h)
    self.imgMap = image(w,h)
    
    -- 使用 mesh 绘制地图
    -- 设置当前位置为矩形中心点的绝对数值，分别除以 w, h 可以得到相对数值
    self.x, self.y = (w/2-WIDTH/2), (h/2-HEIGHT/2)
    self.m = mesh()
    self.mi = self.m:addRect(WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    self.m.texture = self.imgMap
    -- 利用纹理坐标设置显示区域，根据中心点坐标计算出左下角坐标，除以纹理宽度得到相对值，w h 使用固定值(小于1)
    local u,v = WIDTH/w, HEIGHT/h
    self.m:setRectTex(self.mi, self.x/w, self.y/h, u, v)
    
    -- 整个地图使用的全局数据表
    self.mapTable = {}
        
    -- 设置物体名称
    tree1,tree2,tree3 = "松树", "杨树", "小草"    
    mine1,mine2 = "铁矿", "铜矿"
    
    -- 后续改用表保存物体名称
    self.trees = {"松树", "杨树", "小草"}
    self.mines = {"铁矿", "铜矿"}
        
    -- 设置物体图像
    imgTree1 = readImage("Planet Cute:Tree Short")
    imgTree2 = readImage("Planet Cute:Tree Tall")
    imgTree3 = readImage("Platformer Art:Grass")
    imgMine1 = readImage("Platformer Art:Mushroom")
    imgMine2 = readImage("Small World:Treasure")
    
    -- 存放物体: 名称，图像
    self.itemTable = {[tree1]=imgTree1,[tree2]=imgTree2,[tree3]=imgTree3,[mine1]=imgMine1,[mine2]=imgMine2}
       
    -- 尺寸为 3*3 的数据表示例
    self.mapTable = {{pos=vec2(1,1),plant=nil,mineral=mine1},{pos=vec2(1,2),plant=nil,mineral=nil},
                {pos=vec2(1,3),plant=tree3,mineral=nil},{pos=vec2(2,1),plant=tree1,mineral=nil},
                {pos=vec2(2,2),plant=tree2,mineral=mine2},{pos=vec2(2,3),plant=nil,mineral=nil},
                {pos=vec2(3,1),plant=nil,mineral=nil},{pos=vec2(3,2),plant=nil,mineral=mine2},
                {pos=vec2(3,3),plant=tree3,mineral=nil}}
    
    print("地图初始化开始...")
    -- 根据初始参数值新建地图
    -- self:createMapTable()
end

function Maps:drawMap() 
    -- sprite(self.imgMap,-self.scaleX,-self.scaleY)
    -- sprite(self.imgMap,0,0)
    
    -- 更新纹理贴图, --如果地图上的物体有了变化
	self.m.texture = self.imgMap
	local w,h = self.imgMap.width, self.imgMap.height
	local u,v = WIDTH/w, HEIGHT/h
	-- 增加判断，若角色移动到边缘则切换地图：通过修改贴图坐标来实现
	-- print(self.x,self.y)
	local left,right,top,bottom = WIDTH/10, WIDTH*9/10, HEIGHT/10, HEIGHT*9/10
	local ss = 800
	if myS.x <= left then self.x= self.x - WIDTH/ss end
	if myS.x >= right then self.x= self.x + WIDTH/ss end
	if myS.y <= bottom then self.y = self.y - HEIGHT/ss end
	if myS.y >= top then self.y = self.y + HEIGHT/ss end
	
	-- 根据计算得到的数据重新设置纹理坐标
	self.m:setRectTex(self.mi, self.x/w, self.y/h, u, v)
    
    -- self:updateMap()
    self.m:draw()
end

function Maps:touched(touch)
    if touch.state == BEGAN then
        myS.x, myS.y = touch.x, touch.y
    end
end

-- 新建地图数据表, 插入地图上每个格子里的物体数据
function Maps:createMapTable()
    --local mapTable = {}
    for i=1,self.gridCount,1 do
        for j=1,self.gridCount,1 do
            self.mapItem = {pos=vec2(i,j), plant=self:randomPlant(), mineral=self:randomMinerial()}
            --self.mapItem = {pos=vec2(i,j), plant=nil, mineral=nil}
            table.insert(self.mapTable, self.mapItem)
            -- myT:switchPoint(myT.taskID)
        end
    end
    print("OK, 地图初始化完成! ")
    self:updateMap()
end

-- 根据地图数据表, 刷新地图，比较耗时，可以考虑使用协程，每 1 秒内花 1/60 秒来执行它；
-- 协程还可用来实现时间系统，气候变化，植物生长，它赋予我们操纵游戏世界运行流程的能力(相当于控制时间变化)
-- 或者不用循环，只执行改变的物体，传入网格坐标
function Maps:updateMap()
    setContext(self.imgMap)   
    for i = 1,self.gridCount*self.gridCount,1 do
        local pos = self.mapTable[i].pos
        local plant = self.mapTable[i].plant
        local mineral = self.mapTable[i].mineral
        -- 绘制地面
        self:drawGround(pos)
        -- 绘制植物和矿物
        if plant ~= nil then self:drawTree(pos, plant) end
        if mineral ~= nil then self:drawMineral(pos, mineral) end
    end
    setContext()
end

function Maps:touched(touch)
    if touch.state == BEGAN then
        myS.x, myS.y = touch.x, touch.y
    end
end

-- 根据像素坐标值计算所处网格的 i,j 值
function Maps:where(x,y)
    local i = math.ceil((x+self.scaleX) / self.scaleX)
    local j = math.ceil((y+self.scaleY) / self.scaleY)
    return i,j
end

-- 随机生成植物，返回值是代表植物名称的字符串
function Maps:randomPlant()
    local seed = math.random(1.0, self.plantSeed)
    local result = nil
    
    if seed >= 1 and seed < 2 then result = tree1
    elseif seed >= 2 and seed < 3 then result = tree2
    elseif seed >= 3 and seed < 4 then result = tree3
    elseif seed >= 4 and seed <= self.plantSeed then result = nil end
    
    return result
end

-- 随机生成矿物，返回值是代表矿物名称的字符串
function Maps:randomMinerial()
    local seed = math.random(1.0, self.minerialSeed)
    local result = nil

    if seed >= 1 and seed < 2 then result = mine1
    elseif seed >= 2 and seed < 3 then result = mine2
    elseif seed >= 3 and seed <= self.minerialSeed then result = nil end
    
    return result
end

function Maps:getImg(name)
    return self.itemTable[name]
end

-- 重置  
function Maps:resetMapTable()
    self.mapTable = self:createMapTable()
end

-- 绘制单位格子地面
function Maps:drawGround(position)
    local x,y = self.scaleX * position.x, self.scaleY * position.y
    pushMatrix()
    stroke(99, 94, 94, 255)
    strokeWidth(1)
    fill(5,155,40,255)
    -- fill(5,155,240,255)
    rect(x,y,self.scaleX,self.scaleY)
    --sprite("Documents:3D-Wall",x,y,scaleX,scaleY)
    popMatrix()
end

-- 绘制单位格子内的植物
function Maps:drawTree(position,plant)
    local x,y = self.scaleX * position.x, self.scaleY * position.y
    pushMatrix()
    -- 绘制植物图像
    sprite(self.itemTable[plant],x,y,self.scaleX*6/10,self.scaleY)
    
    --fill(100,100,200,255)
    --text(plant,x,y)
    popMatrix()
end

-- 绘制单位格子内的矿物
function Maps:drawMineral(position,mineral)
    local x,y = self.scaleX * position.x, self.scaleY * position.y
    pushMatrix()
    -- 绘制矿物图像
    sprite(self.itemTable[mineral],x+self.scaleX/2,y,self.scaleX/2,self.scaleX/2)

    --fill(100,100,200,255)
    --text(mineral,x+self.scaleX/2,y)
    popMatrix()
end
```

###	再改写第一层面

现在开始把第一层面改写为用 `mesh` 绘图, 也就是说以 `mesh` 方式来生成大地图, 具体来说就是改写这些函数:

-	`Maps:updateMap()` 负责把所有的绘制函数整合起来, 绘制出整副地图
-	`Maps:drawGround()` 负责绘制单位格子地面
-	`Maps:drawTree()` 负责绘制单位格子内的植物
-	`Maps:drawMineral()` 负责绘制单位格子内的矿物

这里稍微麻烦一些, 因为我们打算用小纹理贴图来拼接, 所以一旦小纹理确定, 那么这些属性就不需要显式指定了:

-	`self.scaleX` = 40
-	`self.scaleY` = 40
 
它们实际上就是小纹理贴图的 `宽度` 和 `高度`, 假设使用名为 `tex` 的小纹理, 那么这两个值就分别是 `tex.width` 和 `tex.height`, 虽然我们一般提倡使用正方形的纹理, 不过这里还是区分了 `宽度` 和 `高度`.

而矩形的大小, 则可以通过属性 `self.gridCount = 100` 来设定需要用到多少块小纹理, 这里设置的是 `100`, 表示横向使用 `100` 块小纹理, 纵向使用 `100` 块小纹理. 

看起来这次改写涉及的地方比较多.

####	具体实现方法

这里还是通过 `mesh` 的纹理贴图功能来实现, 不过跟在第一层面的用法不同, 这里我们会使用很小的纹理贴图, 比如大小为 `50*50` 像素单位, 通过纹理坐标的设置和 `shader` 把它们拼接起来铺满整个地图, 之所以要用到 `shader`, 是因为在这里, 我们提供纹理坐标的取值大于 `[0,1]` 的范围, 必须在 `shader` 中对纹理坐标做一个转换, 让它们重新落回到 `[0,1]` 的区间.

比如假设我们程序提供的纹理坐标是 `(23.4, 20.8)`, 前面的整数部分 `(23, 20)` 代表的都是整块的纹理图, 相当于横向有 `23` 个贴图, 纵向有 `20` 个贴图, 那么剩下的小数部分 `(0.4, 0.8)` 就会落在一块小纹理素材图内, 这个 `(0.4, 0.8)` 才是我们真正要取的点.

####	绘制地面

我们先从地面开始, 先新建一个名为 `m1` 的 `mesh`, 接着在这个 `mesh` 上新建一个大大的矩形, 简单来说就是跟我们的地图一样大, 再加载一个尺寸较小的地面纹理贴图, 通过纹理坐标的设置和 `shader` 的处理把它以拼图的方式铺满整个矩形, 最后用函数 `m1:draw()` 把它绘制到 `self.img` 上, 不过为方便调试, 我们先临时增加一个属性 `self.img1`, 所有改写部分先在它上面绘制, 调试无误后再绘制到 `self.imgMap1` 上.

初始化函数 `Maps:init()` 中需要增加的代码

```
	-- 使用 mesh 绘制第一层面的地图 
    self.m1 = mesh()
    self.m1.texture = readImage("Documents:3D-Wall")
    local tw,th = self.m1.texture.width, self.m1.texture.height
    local mw,mh = (self.gridCount+1)*tw, (self.gridCount+1)*th
    -- 临时调试用, 调试通过后删除
    self.imgMap1 = image(mw, mh)
    -- local ws,hs = WIDTH/tw, HEIGHT/th
    local ws,hs = mw/tw, mh/th
    print(ws,hs)
    self.m1i = self.m1:addRect(mw/2, mh/2, mw, mh)
    self.m1:setRectTex(self.m1i, 1/2, 1/2, ws, hs)
    -- 使用拼图 shader
    self.m1.shader = shader(shaders["maps"].vs,shaders["maps"].fs)
  
```

因为需要修改的地方较多, 为避免引入新问题, 所以保留原来的处理, 临时增加几个函数, 专门用于调试:

```
-- 临时调试用
function Maps:updateMap1()
    setContext(self.imgMap)   
    m1:draw()
    setContext()
end
```

另外需要在增加一个专门用于拼图的  `shader`, 把小块纹理图拼接起来铺满:

```
-- Shader
shaders = {

maps = { vs=[[
// 拼图着色器: 把小纹理素材拼接起来铺满整个屏幕
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
	vec4 col = texture2D(texture,vec2(mod(vTexCoord.x,1.0), mod(vTexCoord.y,1.0)));
	gl_FragColor = vColor * col;
}
]]}
}
```

####	修改 mapTable 的结构

原来我们的 `mapTable` 是一个一维数组, 现在把它改为二维数组, 这样在知道一个网格的坐标 `i, j` 后可以很快地查找出该网格在数据表中的信息 `mapTable[i][j]`, 非常方便对地图中的物体(植物/矿物)进行操作, 首先是改写地图数据表生成函数 `Maps:createMapTable()`, 这里需要注意的一点是 用 `Lua` 的 `table` 实现二维数组时, 需要显示地创建每一行, 改为如下:

```
function Maps:createMapTable()
    --local mapTable = {}
    for i=1,self.gridCount,1 do
        self.mapTable[i] = {}
        for j=1,self.gridCount,1 do
            self.mapItem = {pos=vec2(i,j), plant=self:randomPlant(), mineral=self:randomMinerial()}
            table.insert(self.mapTable[i], self.mapItem)
            -- self.mapTable[i][j] = self.mapItem
            -- myT:switchPoint(myT.taskID)
        end
    end
    print("OK, 地图初始化完成! ")  
    self:updateMap1()
end
```

也可以这样 `self.mapTable[i][j] = self.mapItem` 来为数组的每个位置赋值.

修改了数据表结构后, 很多针对数据表的相关操作也要做对应修改, 如 `Maps:updateMap()` 函数:

```
function Maps:updateMap()
    setContext(self.imgMap)   
    -- 用 mesh 绘制地面
    self.m1:draw()
    -- 用 sprite 绘制植物，矿物，建筑
    for i = 1,self.gridCount,1 do
        for j=1,self.gridCount,1 do
            local pos = self.mapTable[i][j].pos
            local plant = self.mapTable[i][j].plant
            local mineral = self.mapTable[i][j].mineral
            -- 绘制植物和矿物
            if plant ~= nil then self:drawTree(pos, plant) end
            if mineral ~= nil then self:drawMineral(pos, mineral) end
        end
    end
    setContext()
end
``` 

还有其他几个函数就不一一列举了, 因为修改的地方很清晰.

####	增加一些用于交互的函数

这个游戏程序写了这么久了, 玩家控制的角色还没有真正对地图上的物体做过交互, 这里我们增加几个用于操作地图上物体的函数:

首先提供一个查看对应网格信息的函数 `Maps:showGridInfo()`:

```
function Maps:showGridInfo(i,j)
    local item = self.mapTable[i][j]    
    print(item.pos, item.tree, item.mineral)
    if item.tree ~= nil then 
        fill(0,255,0,255)
        text(item.pos.."位置处有: "..item.tree.." 和 ..", 500,200)
    end
end
```

然后是一个删除物体的函数 `Maps:removeMapObject()`:

```
function Maps:removeMapObject(i,j)
    local item = self.mapTable[i][j] 
    if item.pos == vec2(i,j) then 
        item.plant = nil 
        item.mineral = nil 
    end
end
```

我们之前写过一个根据坐标数值换算对应网格坐标的函数 ``, 现在需要改写一下, 把计算单位换成小纹理贴图的宽度和高度:

```
function Maps:where(x,y)
	local w, h = self.m1.texture.width, self.m1.texture.height
	local i, j = math.ceil(x/w), math.ceil(y/h)
	return i,j
end
```

还存在点小问题, 精度需要提升, 后续改进.

####	绘制植物

要修改函数 `Maps:drawTree()`, 原来是根据 `self.scaleX, self.scaleY` 和网格坐标 `i, j` 来计算绘制到哪个格子上的, 现在因为地面改用 `mesh` 的纹理贴图绘制, 所以就要用地面纹理贴图的 `width, height` 来计算了.

```
-- 临时调试用
function Maps:drawTree(position,plant) 
    local w, h = self.m1.texture.width, self.m1.texture.height
    local x, y =  w * position.x, h * position.y
    print("tree:"..x..y)
    pushMatrix()
    -- 绘制植物图像
    sprite(self.itemTable[plant],x,y,w*6/10,h)
    popMatrix()
end
```

####	绘制矿物

同样需要修改的还有 `Maps:drawMineral()` 函数:

```
function Maps:drawMineral(position,mineral)
    local w, h = self.m1.texture.width, self.m1.texture.height
    local x, y = w * position.x, h * position.y
    pushMatrix()
    -- 绘制矿物图像
    sprite(self.itemTable[mineral], x+w/2, y , w/2, h/2)
    --fill(100,100,200,255)
    --text(mineral,x+self.scaleX/2,y)
    popMatrix()
end
```

经过上面这些改动, 基本上是完成了, 不过删除地图上的物体后, 需要重绘地图, 如果把数据表 `mapTable` 全都遍历一遍, 相当于整副地图都重绘一遍, 显然没这个必要, 所以我们打算只重绘那些被删除了物体的网格, 因为知道确切坐标, 所以我们可以用这样一个函数来实现:

```
--局部重绘函数
function Maps:updateItem(i,j)
	setContext(self.imgMap)
	local x,y = i * self.m1.texture.width, j * self.m1.texture.height
	sprite(self.m1.texture, x, y)
	setContext()
	self.m.texture = self.imgMap
end
```

###	完整代码

```
-- c06-02.lua

-- 主程序框架
function setup()
    displayMode(OVERLAY)

    -- 角色位置，用于调试
    myS = {}
    myS.x, myS.y = WIDTH/2, HEIGHT/2
    
    -- 生成地图
    myMap = Maps()
    myMap:createMapTable()
    print("左下角在地图的坐标："..myMap.x,myMap.y)
    local i,j = myMap:where(myMap.x,myMap.y)
    print("左下角对应网格坐标："..i.." : "..j)
    -- print(myMap.mapTable[9][10].pos, myMap.mapTable[9][10].plant)
    -- 测试格子坐标计算
    ss = ""
end

function draw()
    background(40, 40, 50)    
    
    -- 绘制地图
    myMap:drawMap()
    sysInfo()  
    
    -- 显示点击处的格子坐标
    fill(255, 0, 14, 255)
    -- text(ss,500,100)
end

function touched(touch)
    myMap:touched(touch)
    
    if touch.state == ENDED then
    c1,c2 = myMap:where(myMap.x + touch.x, myMap.y + touch.y)
    myMap:showGridInfo(c1,c2)
    myMap:removeMapObject(c1,c2)
    print("点击处的坐标绝对值:", (myMap.x + touch.x)/200, (myMap.y + touch.y)/200)
    print("c1:c2 "..c1.." : "..c2) 
    
    ss = c1.." : "..c2
    end
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


-- 使用 mesh() 绘制地图
Maps = class()

function Maps:init()
    
    self.gridCount = 20
    self.scaleX = 200
    self.scaleY = 200
    self.plantSeed = 20.0
    self.minerialSeed = 50.0
    
    -- 根据地图大小申请图像，scaleX 可实现缩放物体
    --local w,h = (self.gridCount+1)*self.scaleX, (self.gridCount+1)*self.scaleY
    local w,h = (self.gridCount+0)*self.scaleX, (self.gridCount+0)*self.scaleY
    print("大地图尺寸: ",w,h)
    self.imgMap = image(w,h)
    
    -- 使用 mesh 绘制第一层面的地图地面  
    self.m1 = mesh()
    self.m1.texture = readImage("Documents:hm1")
    local tw,th = self.m1.texture.width, self.m1.texture.height
    local mw,mh = (self.gridCount+1)*tw, (self.gridCount+1)*th
    -- 临时调试用, 调试通过后删除
    self.imgMap1 = image(mw, mh)
    -- local ws,hs = WIDTH/tw, HEIGHT/th
    local ws,hs = mw/tw, mh/th
    print("网格数目: ",ws,hs)
    self.m1i = self.m1:addRect(mw/2, mh/2, mw, mh)
    self.m1:setRectTex(self.m1i, 1/2, 1/2, ws, hs)
    -- 使用拼图 shader
    self.m1.shader = shader(shaders["maps"].vs,shaders["maps"].fs)
    
    -- 使用 mesh 绘制第二层面的地图
    -- 屏幕左下角(0,0)在大地图上对应的坐标值(1488, 1616)
    -- 设置屏幕当前位置为矩形中心点的绝对数值，分别除以 w, h 可以得到相对数值
    self.x, self.y = (w/2-WIDTH/2), (h/2-HEIGHT/2)
    self.m = mesh()
    self.mi = self.m:addRect(WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    self.m.texture = self.imgMap
    -- 利用纹理坐标设置显示区域，根据中心点坐标计算出左下角坐标，除以纹理宽度得到相对值，w h 使用固定值(小于1)
    -- 这里计算得到的是大地图中心点处的坐标，是游戏刚开始运行的坐标
    local u,v = WIDTH/w, HEIGHT/h
    self.m:setRectTex(self.mi, self.x/w, self.y/h, u, v)
    
    -- 整个地图使用的全局数据表
    self.mapTable = {}
        
    -- 设置物体名称
    tree1,tree2,tree3 = "松树", "杨树", "小草"    
    mine1,mine2 = "铁矿", "铜矿"
    
    imgTree1 = readImage("Planet Cute:Tree Short")
    imgTree2 = readImage("Planet Cute:Tree Tall")
    imgTree3 = readImage("Platformer Art:Grass")
    imgMine1 = readImage("Platformer Art:Mushroom")
    imgMine2 = readImage("Small World:Treasure")
                 
    -- 后续改用表保存物体名称
    self.trees = {"松树", "杨树", "小草"}
    self.mines = {"铁矿", "铜矿"}
        
    -- 设置物体图像  
    self.items = {imgTree1 = readImage("Planet Cute:Tree Short"),
                 imgTree2 = readImage("Planet Cute:Tree Tall"),
                 imgTree3 = readImage("Platformer Art:Grass"),
                 imgMine1 = readImage("Platformer Art:Mushroom"),
                 imgMine2 = readImage("Small World:Treasure")}
    
    -- 存放物体: 名称，图像
    self.itemTable = {[tree1]=imgTree1,[tree2]=imgTree2,[tree3]=imgTree3,[mine1]=imgMine1,[mine2]=imgMine2}
    
    --[=[
    self.itemTable = {[self.trees[1]].self.items["imgTree1"],[self.trees[2]].self.items["imgTree2"],
                      [self.trees[3]].self.items["imgTree3"],[self.mines[1]].self.items["imgMine1"],
                      [self.mines[3]].self.items["imgMine2"]}   
    --]=]   
    
    --[[ 尺寸为 3*3 的数据表示例，连续
    self.mapTable = {{{pos=vec2(1,1),plant=nil,mineral=mine1},{pos=vec2(1,2),plant=nil,mineral=nil},
                     {pos=vec2(1,3),plant=tree3,mineral=nil}},{{pos=vec2(2,1),plant=tree1,mineral=nil},
                     {pos=vec2(2,2),plant=tree2,mineral=mine2},{pos=vec2(2,3),plant=nil,mineral=nil}},
                     {{pos=vec2(3,1),plant=nil,mineral=nil},{pos=vec2(3,2),plant=nil,mineral=mine2},
                     {pos=vec2(3,3),plant=tree3,mineral=nil}}}
    --]]
    
    print("地图初始化开始...")
    -- 根据初始参数值新建地图
    -- self:createMapTable()
end

-- 新建地图数据表, 插入地图上每个格子里的物体数据
function Maps:createMapTable()
    --local mapTable = {}
    for i=1,self.gridCount,1 do
        self.mapTable[i] = {}
        for j=1,self.gridCount,1 do
            self.mapItem = {pos=vec2(i,j), plant=self:randomPlant(), mineral=self:randomMinerial()}
            table.insert(self.mapTable[i], self.mapItem)
            -- self.mapTable[i][j] = self.mapItem
            -- myT:switchPoint(myT.taskID)
        end
    end
    print("OK, 地图初始化完成! ")  
    self:updateMap()
end

-- 更新整副地图:绘制地面, 绘制植物, 绘制矿物
function Maps:updateMap()
    setContext(self.imgMap)   
    -- 用 mesh 绘制地面
    self.m1:draw()
    -- 用 sprite 绘制植物，矿物，建筑
    for i = 1,self.gridCount,1 do
        for j=1,self.gridCount,1 do
            local pos = self.mapTable[i][j].pos
            local plant = self.mapTable[i][j].plant
            local mineral = self.mapTable[i][j].mineral
            -- 绘制植物和矿物
            if plant ~= nil then self:drawTree(pos, plant) end
            if mineral ~= nil then self:drawMineral(pos, mineral) end
        end
    end
    setContext()
end

function Maps:drawMap() 
    -- 更新纹理贴图, --如果地图上的物体有了变化
	self.m.texture = self.imgMap
	local w,h = self.imgMap.width, self.imgMap.height
	local u,v = WIDTH/w, HEIGHT/h
	-- 增加判断，若角色移动到边缘则切换地图：通过修改贴图坐标来实现
    -- print(self.x,self.y)
	local left,right,top,bottom = WIDTH/10, WIDTH*9/10, HEIGHT/10, HEIGHT*9/10
	local ss = 800
	if myS.x <= left then self.x= self.x - WIDTH/ss end
	if myS.x >= right then self.x= self.x + WIDTH/ss end
	if myS.y <= bottom then self.y = self.y - HEIGHT/ss end
	if myS.y >= top then self.y = self.y + HEIGHT/ss end
	
	-- 根据计算得到的数据重新设置纹理坐标
	self.m:setRectTex(self.mi, self.x/w, self.y/h, u, v)
    
    -- self:updateMap()
    self.m:draw()
end

function Maps:touched(touch)
    if touch.state == BEGAN then
        myS.x, myS.y = touch.x, touch.y
    end
end

--局部重绘函数
function Maps:updateItem(i,j)
	setContext(self.imgMap)
	local x,y = i * self.m1.texture.width, j * self.m1.texture.height
	sprite(self.m1.texture, x, y)
	setContext()
	self.m.texture = self.imgMap
end

-- 根据像素坐标值计算所处网格的 i,j 值
function Maps:where(x,y)
    local w, h = self.m1.texture.width, self.m1.texture.height
	local i, j = math.ceil(x/w), math.ceil(y/h)
	return i, j
end

-- 角色跟地图上物体的交互
function Maps:removeMapObject(i,j)
    local item = self.mapTable[i][j] 
    if item.pos == vec2(i,j) then 
        item.plant = nil 
        item.mineral = nil 
        self:updateItem(i,j)
    end
end

-- 显示网格内的物体信息
function Maps:showGridInfo(i,j)
    local item = self.mapTable[i][j]
    
    print("showGridInfo: ", item.pos, item.tree, item.mineral)
    if item.tree ~= nil then 
        fill(0,255,0,255)
        text(item.pos.."位置处有: ", item.tree, 500,200)
    end
end

-- 随机生成植物，返回值是代表植物名称的字符串
function Maps:randomPlant()
    local seed = math.random(1.0, self.plantSeed)
    local result = nil
    
    if seed >= 1 and seed < 2 then result = tree1
    elseif seed >= 2 and seed < 3 then result = tree2
    elseif seed >= 3 and seed < 4 then result = tree3
    elseif seed >= 4 and seed <= self.plantSeed then result = nil end
    
    return result
end

-- 随机生成矿物，返回值是代表矿物名称的字符串
function Maps:randomMinerial()
    local seed = math.random(1.0, self.minerialSeed)
    local result = nil

    if seed >= 1 and seed < 2 then result = mine1
    elseif seed >= 2 and seed < 3 then result = mine2
    elseif seed >= 3 and seed <= self.minerialSeed then result = nil end
    
    return result
end

function Maps:getImg(name)
    return self.itemTable[name]
end

-- 重置  
function Maps:resetMapTable()
    self.mapTable = self:createMapTable()
end

-- 绘制单位格子内的植物
function Maps:drawTree(position,plant) 
    local w, h = self.m1.texture.width, self.m1.texture.height
    local x,y =  w * position.x, h * position.y
    -- print("tree:"..x.." : "..y)
    pushMatrix()
    -- 绘制植物图像
    sprite(self.itemTable[plant], x, y, w*6/10, h)
    
    --fill(100,100,200,255)
    --text(plant,x,y)
    popMatrix()
end

-- 绘制单位格子内的矿物
function Maps:drawMineral(position,mineral)
    local w, h = self.m1.texture.width, self.m1.texture.height
    local x, y = w * position.x, h * position.y
    pushMatrix()
    -- 绘制矿物图像
    sprite(self.itemTable[mineral], x+w/2, y , w/2, h/2)

    --fill(100,100,200,255)
    --text(mineral,x+self.scaleX/2,y)
    popMatrix()
end


-- Shader
shaders = {
maps = { vs=[[
// 拼图着色器: 把小纹理素材拼接起来铺满整个屏幕
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
	vec4 col = texture2D(texture,vec2(mod(vTexCoord.x,1.0), mod(vTexCoord.y,1.0)));
	gl_FragColor = vColor * col;
}
]]}
}
```

###	整合好的代码

跟帧动画整合在一起的代码在这里: [c06.lua](https://github.com/FreeBlues/Write-A-Adventure-Game-From-Zero/blob/master/src/c06.lua)

##	在地图上用 shader 增加特效

到目前为止, 我们对地图类的改写基本完成, 调试通过后, 剩下的就是利用 `shader` 来为地图增加一些特效了.

本来打算写写下面这些特效:

###	气候变化

下雨,下雪,雷电,迷雾,狂风

###	季节变化

春夏秋冬四季变化

###	昼夜变化

光线随时间改变明暗程度

###	流动的河流

让河流动起来

###	波光粼粼的湖泊

湖泊表面闪烁

###	树木(可使用广告牌-在3D阶段实现)

用广告牌实现的树木

###	地面凹凸阴影(2D 和 3D)

让地面产生动态阴影变化

###	天空盒子(3D)

搞一个立方体纹理特贴图

但是一看本章已经写了太长的篇幅了, 所以决定把这些内容放到后面单列一章, 因此本章到此结束.

## 本章小结

本章成功实现了如下目标:

-	用 `mesh` 绘制地图, 用 `mesh` 显示地图
-	利用 `mesh` 的纹理坐标机制解决了地图自动卷动
-	增加了用户跟地图物体的交互处理
-	为后续的地图特效提供了 `shader`.	

临时想到的问题, 后续解决:

-	利用生命游戏的规则, 让随机生成的植物演化一段时间, 以便形成更具真实感的群落
-	需要解决走到地图尽头的问题, 加一个处理, 让图片首尾衔接

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
│   └── c06.lua
├── 从零开始写一个武侠冒险游戏-0-开发框架Codea简介.md
├── 从零开始写一个武侠冒险游戏-1-状态原型.md
├── 从零开始写一个武侠冒险游戏-2-帧动画.md
├── 从零开始写一个武侠冒险游戏-3-地图生成.md
├── 从零开始写一个武侠冒险游戏-4-第一次整合.md
├── 从零开始写一个武侠冒险游戏-5-使用协程.md
├── 从零开始写一个武侠冒险游戏-6-用GPU提升性能(1).md
└── 从零开始写一个武侠冒险游戏-6-用GPU提升性能(2).md

2 directories, 24 files
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