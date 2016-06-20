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
    
    self.gridCount = 100
    self.scaleX = 40
    self.scaleY = 40
    self.plantSeed = 20.0
    self.minerialSeed = 50.0
    
    -- 根据地图大小申请图像
    local w,h = (self.gridCount+1)*self.scaleX, (self.gridCount+1)*self.scaleY
    -- print(w,h)
    self.imgMap = image(w,h)
    
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
    self.m1.shader = shader(shaders["sprites3"].vs,shaders["sprites3"].fs)
    
    -- 使用 mesh 绘制第二层面的地图
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

-- 临时调试用
function Maps:updateMap1()
    setContext(self.imgMap)   
    m1:draw()
    setContext()
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

// 定义一个用于比较的颜色值, 由用户自行控制
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
]]},

sprites3 = { vs=[[
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