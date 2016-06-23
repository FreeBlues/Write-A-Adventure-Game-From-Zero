-- c06.lua

-- 主程序框架

-- 需建立地图坐标的对应关系

function setup() 
    displayMode(OVERLAY)
    -- 初始化状态
    myStatus = Status()
    
    -- 以下为帧动画代码
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
    myS.m.shader.maxWhite = vec4(0.9, 0.9, 0.9, 0.9)

    myS.w, myS.h = WIDTH/10, HEIGHT/10
    -- 设置速度
    myS.speed = 1/20
    print(myS.x,myS.y)
    
    ---[[ 初始化摄像机，触摸摇杆
    touches = {}
    -- cam = Camera(pos.x,pos.y,pos.z,pos.x+look.x,look.y,pos.z+look.z)
    ls,rs = Stick(20,WIDTH-300,200),Stick(2,WIDTH-120)
    -- ls,rs = Stick(1),Stick(3,WIDTH-120)
    
    -- 初始化地图
    myMap = Maps()
    myMap:createMapTable()
    
    ss =""
end

function draw()
    pushMatrix()
    pushStyle()
    -- spriteMode(CORNER)
    -- rectMode(CORNER)
    background(32, 29, 29, 255)
        
    -- 绘制 mesh 地图
    myMap:drawMap()
    
    -- 绘制状态栏
    myStatus:drawUI()
    --myStatus:raderGraph()
    
    -- 绘制 mesh 角色帧动画
    myS:draw()
    -- sysInfo()
    
    -- background(0)
    ls:draw()
    rs:draw()
    fill(249, 7, 7, 255)
    text(ss, 500,100)
        
    sysInfo()
    popStyle()
    popMatrix()

end

-- 显示FPS和内存使用情况
function sysInfo()
    pushStyle()
    fill(255, 255, 255, 255)
    -- 根据 DeltaTime 计算 fps, 根据 collectgarbage("count") 计算内存占用
    local fps = math.floor(1/DeltaTime)
    local mem = math.floor(collectgarbage("count"))
    text("FPS: "..fps.."    Mem："..mem.." KB",650,740)
    popStyle()
end

-- 处理玩家的移动，理论上讲只要把 camera 的相关参数跟触摸信息关联起来就可以营造出移动效果
function touched(touch)
    
    -- 连续的触摸数据放入 touches 表中
    if touch.state == ENDED then
        touches[touch.id] = nil
    else
        touches[touch.id] = touch
        -- for k,v in pairs(touches) do print(k,v) end
    end
    
    -- 用于测试修炼
    if touch.x > WIDTH/2 and touch.state == ENDED then myStatus:update() end
    
    -- 用于测试移动方向：点击左侧向右平移，点击右侧向左平移
    if touch.x > WIDTH/2 and touch.state == ENDED then 
        s = -1
    elseif touch.x < WIDTH/2 then 
        s = 1
    end
    
    -- 用于测试帧动画
    myS:touched(touch)
    
    -- 用于测试地图物体交互
    myMap:touched(touch)
    
end

-- 使用 mesh() 绘制地图
Maps = class()

function Maps:init()
    
    self.gridCount = 20
    -- self.scaleX = 200
    -- self.scaleY = 200
    self.plantSeed = 20.0
    self.minerialSeed = 50.0
    
    -- 根据地图大小申请图像，scaleX 可实现缩放物体
    -- local w,h = (self.gridCount+0)*self.scaleX, (self.gridCount+0)*self.scaleY
    -- print("大地图尺寸: ",w,h)
    -- self.imgMap = image(w,h)
    
    -- 使用 mesh 绘制第一层面的地图地面  
    self.m1 = mesh()
    self.m1.texture = readImage("Documents:3D-Wall")
    -- 小纹理贴图的宽度，高度
    local tw,th = self.m1.texture.width, self.m1.texture.height

    local mw,mh = (self.gridCount+0)*tw, (self.gridCount+0)*th
    print("大地图尺寸: ",mw,mh)
    -- 临时调试用, 调试通过后删除
    self.imgMap = image(mw, mh)
    
    -- local ws,hs = WIDTH/tw, HEIGHT/th
    local ws,hs = mw/tw, mh/th
    print("网格数目: ",ws,hs)
    self.m1i = self.m1:addRect(mw/2, mh/2, mw, mh)
    self.m1:setRectTex(self.m1i, 1/2, 1/2, ws, hs)
    -- 使用拼图 shader
    self.m1.shader = shader(shadersMap["maps"].vs,shadersMap["maps"].fs)
    
    -- 使用 mesh 绘制第二层面的地图
    -- 屏幕左下角(0,0)在大地图上对应的坐标值(1488, 1616)
    -- 设置屏幕当前位置为矩形中心点的绝对数值，分别除以 w, h 可以得到相对数值
    self.x, self.y = (mw/2-WIDTH/2), (mh/2-HEIGHT/2)
    self.m = mesh()
    self.mi = self.m:addRect(WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    self.m.texture = self.imgMap
    -- 利用纹理坐标设置显示区域，根据中心点坐标计算出左下角坐标，除以纹理宽度得到相对值，w h 使用固定值(小于1)
    -- 这里计算得到的是大地图中心点处的坐标，是游戏刚开始运行的坐标
    local u,v = WIDTH/mw, HEIGHT/mh
    self.m:setRectTex(self.mi, self.x/mw, self.y/mh, u, v)
    
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
        -- myS.x, myS.y = touch.x, touch.y
    end

    if touch.state == ENDED then
        c1,c2 = myMap:where(myMap.x + touch.x, myMap.y + touch.y)
        myMap:showGridInfo(c1,c2)
        myMap:removeMapObject(c1,c2)
        print("点击处的坐标绝对值:", (myMap.x + touch.x)/200, (myMap.y + touch.y)/200)
        print("c1:c2 "..c1.." : "..c2)
        
        ss = c1.." : "..c2
    end
end

--局部重绘函数
function Maps:updateItem(i,j)
	setContext(self.imgMap)
    -- 根据网格坐标 i,j 计算出对应于大地图上的实际坐标，然后绘制地面小纹理贴图
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
    fill(255, 0, 0, 255)
    text(position.x..":"..position.y,x,y)
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
shadersMap = {
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


--# Sprites
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
    self.w, self.h = WIDTH/5, HEIGHT/5
    self.mi = self.m:addRect(self.x, self.y, w, h)
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
    self.x, self.y = self.x+ls.x, self.y+ls.y
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
]]}
}

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
    pushMatrix()
    pushStyle()
    
    -- rectMode(CENTER)
    spriteMode(CENTER)
    textMode(CENTER)
    setContext(self.img)
    background(118, 120, 71, 109)

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
    setContext()
    
    -- 在状态栏绘制雷达图
    --self:raderGraph()
    self:radarGraphDraw()
    
    -- 绘制状态栏
    sprite(self.img, self.img.width/2,HEIGHT-self.img.height/2)

    
    ---[[ 测试代码
    fill(143, 255, 0, 255)
    rect(WIDTH/2,HEIGHT/2,100,80)
    fill(0, 55, 255, 255)
    text("修炼", WIDTH/2+50,HEIGHT/2+40)
    --]]
    
    popStyle()
    popMatrix()
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
    
    -- 中心坐标，半径，角度，缩放比例
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

-- Shader
shadersMap = {
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


--# Stick
-- 操纵杆类  作者: @Jaybob
Stick = class()

function Stick:init(ratio,x,y,b,s)
    self.ratio = ratio or 1
    self.i = vec2(x or 120,y or 120)
    self.v = vec2(0,0)
    self.b = b or 180   --大圆半径
    self.s = s or 100   --小圆半径
    self.d = d or 50
    self.a = 0
    self.touchId = nil
    self.x,self.y = 0,0
end

function Stick:draw()
    -- 没有 touched 函数的 Stick 类是如何找到自己对应的触摸数据的？根据点击处坐标跟操纵杆的距离来判断
    if touches[self.touchId] == nil then
        -- 循环取出 touches 表内的数据，比较其坐标跟操纵杆的距离，若小于半径则说明是在点击操纵杆
        for i,t in pairs(touches) do
            if vec2(t.x,t.y):dist(self.i) < self.b/2 then self.touchId = i end
        end
        self.v = vec2(0,0)
    else
        -- 根据对应于操纵杆的触摸的xy坐标设置 self.v，再根据它计算夹角 self.a
        self.v = vec2(touches[self.touchId].x,touches[self.touchId].y) - self.i
        self.a = math.deg(math.atan2(self.v.y, self.v.x))
    end
    -- 根据 self.v 和 self.b 计算得到 self.t
    self.t = math.min(self.b/2,self.v:len())
    
    if self.t >= self.b/2 then
        self.v = vec2(math.cos(math.rad(self.a))*self.b/2,math.sin(math.rad(self.a))*self.b/2)
    end
    
    pushMatrix()
    fill(127, 127, 127, 100)
    -- 分别绘制大圆，小圆
    ellipse(self.i.x, self.i.y, self.b)
    ellipse(self.i.x+self.v.x, self.i.y+self.v.y, self.s)
    --print(self.v.x, self.s)
    popMatrix()
    -- 根据 ratio 重新设置 self.v/self.t   
    self.v = self.v/(self.b/2)*self.ratio
    self.t = self.t/(self.b/2)*self.ratio
    -- 根据 self.v/self.t，重新设置 self.x/self.y
    self.x, self.y = self.v.x, self.v.y
end
