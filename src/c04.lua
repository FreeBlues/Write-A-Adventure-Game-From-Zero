-- c04.lua

function setup() 
    displayMode(OVERLAY)
    -- 初始化状态
    myStatus = Status()
    
    -- 以下为帧动画代码
    s = -1
    fill(249, 249, 249, 255)
    imgs = {}
    pos = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
           {320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}
    
    img = readImage("Documents:runner")

    m = Sprites(600,400,img,pos)
    
    ---[[ 初始化摄像机，触摸摇杆
    --touches = {}
    -- cam = Camera(pos.x,pos.y,pos.z,pos.x+look.x,look.y,pos.z+look.z)
    -- ls,rs = Stick(20,WIDTH-300,200),Stick(2,WIDTH-120)
    -- ls,rs = Stick(1),Stick(3,WIDTH-120)
    
    -- 初始化地图
    myMap = Maps()
    ss =""
end

function draw()
    pushMatrix()
    pushStyle()
    -- spriteMode(CORNER)
    rectMode(CORNER)
    background(32, 29, 29, 255)
    
    -- 增加移动的背景图: + 为右移，- 为左移
    --sprite("Documents:bgGrass",(WIDTH/2+10*s*m.i)%(WIDTH),HEIGHT/2)
    --sprite("Documents:bgGrass",(WIDTH+10*s*m.i)%(WIDTH),HEIGHT/2)
    -- sprite("Documents:bgGrass",WIDTH/2,HEIGHT/2)
    --[[
    if ls.x ~= 0 then
        step = 10 *m.i*ls.x/math.abs(ls.x)
    else
        step = 0
    end
    --]]
    --sprite("Documents:bgGrass",(WIDTH/2 - step)%(WIDTH),HEIGHT/2)
    --sprite("Documents:bgGrass",(WIDTH - step)%(WIDTH),HEIGHT/2)
    
    -- 绘制地图
    myMap:drawMap()
        
    -- 绘制角色帧动画
    m:draw(50,80)
    -- sysInfo()
    
    -- 绘制状态栏
    myStatus:drawUI()
    --myStatus:raderGraph()
    
    -- background(0)
    --ls:draw()
    --rs:draw()
    fill(249, 7, 7, 255)
    text(ss, 500,100)
        
    sysInfo()
    popStyle()
    popMatrix()

end

-- 处理玩家的触摸移动
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
    
    -- c1,c2 = myMap:where(touch.x, touch.y)
    c1,c2 = myMap:where(m.x,m.y)
    -- 显示角色所处网格坐标
    ss = c1.." : "..c2
    
end

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
    
    
    -- m:draw(150,200)
    setContext()
    
    -- 在状态栏绘制雷达图
    self:raderGraph()
    
    -- 绘制状态栏
    sprite(self.img, self.img.width/2,HEIGHT-self.img.height/2)

    
    ---[[ 测试代码
    fill(143, 255, 0, 255)
    rect(WIDTH*7/8,HEIGHT/2,100,80)
    fill(0, 55, 255, 255)
    text("修炼", WIDTH*7/8 +50,HEIGHT/2+40)
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

-- 角色技能雷达图
function Status:raderGraph()
    pushMatrix()
    pushStyle()
    setContext(self.img)
    fill(60, 230, 30, 255)
    -- 中心坐标，半径，角度
    local x0,y0,r,a,s = 150,230,40,360/6,4
    -- 计算右上方斜线的坐标
    local x,y = r* math.cos(math.rad(30)), r* math.sin(math.rad(30))
    p = {"体力","内力","精力","智力","气","血"}
    axis = {t={vec2(0,r/s),vec2(0,r*2/s),vec2(0,r*3/s),vec2(0,r)},
            n={vec2(-x/s,y/s),vec2(-x*2/s,y*2/s),vec2(-x*3/s,y*3/s),vec2(-x,y)},
            j={vec2(-x/s,-y/s),vec2(-x*2/s,-y*2/s),vec2(-x*3/s,-y*3/s),vec2(-x,-y)},
            z={vec2(0,-r/s),vec2(0,-r*2/s),vec2(0,-r*3/s),vec2(0,-r)},
            q={vec2(x/s,-y/s),vec2(x*2/s,-y*2/s),vec2(x*3/s,-y*3/s),vec2(x,-y)},
            x={vec2(x/s,y/s),vec2(x*2/s,y*2/s),vec2(x*3/s,y*3/s),vec2(x,y)}}
    
    -- 用于绘制圈线的函数，固定 4 个点
    function lines(t,n,j,z,q,x)
        line(axis.n[n].x, axis.n[n].y, axis.t[t].x, axis.t[t].y)
        line(axis.n[n].x, axis.n[n].y, axis.j[j].x, axis.j[j].y)
        line(axis.x[x].x, axis.x[x].y, axis.t[t].x, axis.t[t].y)
        line(axis.z[z].x, axis.z[z].y, axis.j[j].x, axis.j[j].y)
        line(axis.x[x].x, axis.x[x].y, axis.q[q].x, axis.q[q].y)
        line(axis.z[z].x, axis.z[z].y, axis.q[q].x, axis.q[q].y)
        --print(axis.z[z].y)
    end
    
    -- 实时绘制位置，实时计算位置
    function linesDynamic(t,n,j,z,q,x)
        local t,n,j,z,q,x = self.tili, self.neili, self.jingli,self.zhili, self.qi, self.xue
        local fm = math.fmod
        -- t,n,j,z,q,x = fm(t,r),fm(n,r),fm(j,r),fm(z,r),fm(q,r),fm(x,r)
        -- print(t,n,j,z,q,x)
        local c,s = math.cos(math.rad(30)), math.sin(math.rad(30))
        line(0,t,-n*c,n*s)
        line(-n*c,n*s,-j*c,-j*s)
        line(0,-z,-j*c,-j*s)
        line(0,-z,q*c,-q*s)
        line(q*c,-q*s,x*c,x*s)
        line(0,t,x*c,x*s)
    end
    
    -- 平移到中心 (x0,y0), 方便以此为中心旋转
    translate(x0,y0)
    -- 围绕中心点匀速旋转
    rotate(30+ElapsedTime*10)
    
    fill(57, 121, 189, 84)
    strokeWidth(0)
    ellipse(0,0,2*r/s)
    ellipse(0,0,4*r/s)
    ellipse(0,0,6*r/s)
    ellipse(0,0,r*2)
    
    strokeWidth(2)    
    -- noSmooth()
    stroke(93, 227, 22, 255)
    fill(60, 230, 30, 255)
    -- 绘制雷达图
    for i=1,6 do
        text(p[i],0,45)
        line(0,0,0,r)
        rotate(a)
    end
    
    -- 绘制圈线
    stroke(255, 0, 0, 102)
    strokeWidth(2)
    for i = 1,4 do
        lines(i,i,i,i,i,i)
    end
    
    function values()
        local t,n,j,z,q,x = self.tili, self.neili, self.jingli,self.zhili, self.qi, self.xue
        local f = math.floor
        -- return math.floor(t/25),math.floor(t/25),math.floor(t/25),math.floor(t/25),math.floor(t/25),math.floor(t/25)
        return f(t/25),f((25+math.fmod(n,100))/25),f(j/25),f(z/25),f(q/25),f(x/25)
    end
    stroke(255, 32, 0, 255)
    strokeWidth(2)
    smooth()
    -- 设定当前各参数的值
    -- print(values())
    local t,n,j,z,q,x = 3,2,3,2,4,1
    local t,n,j,z,q,x = values()    
    -- local t,n,j,z,q,x = self.tili, self.neili, self.jingli,self.zhili, self.qi, self.xue
    lines(t,n,j,z,q,x)
    linesDynamic(t,n,j,z,q,x)

    setContext()
    popStyle()
    popMatrix()
end


-- 帧动画对象类
Sprites = class() 

function Sprites:init(x,y,img,pos)
    self.x = x
    self.y = y
    -- self.index = 1
    self.img = img
    self.imgs = {}
    self.pos = pos
    self.i=0
    self.k=1
    self.q=0
    self.prevTime =0
       
    -- 处理原图，背景色变为透明
    self:deal()
    
    -- 使用循环，把各个子帧存入表中
    for i=1,#self.pos do
        -- imgs[i] = img:copy(pos[i][1],pos[i][2],pos[i][3],pos[i][4])
        self.imgs[i] = self.img:copy(table.unpack(self.pos[i]))
    end

end

function Sprites:deal()
    ---[[ 对原图进行预处理，把背景修改为透明，现存问题：角色内部有白色也会被去掉
    local v = 255
    for x=1,self.img.width do
        for y =1, self.img.height do
            -- 取出所有像素的颜色值
            local r,g,b,a = self.img:get(x,y)
            -- if r >= v and g >= v and b >= v then
            if r == v and g == v and b == v and a == v then
                self.img:set(x,y,r,g,b,0)
            end
        end
    end
    --]]
end

function Sprites:draw(w,h)
    pushMatrix()
    pushStyle()
    -- 绘图模式选 CENTER 可以保证画面中的动画角色不会左右漂移
    rectMode(CENTER)
    spriteMode(CENTER)
    -- 确定每帧子画面在屏幕上停留的时间
    if ElapsedTime > self.prevTime + 0.08 then
        self.prevTime = self.prevTime + 0.08 
        self.k = math.fmod(self.i,#self.imgs) 
        self.i = self.i + 1    
        self.x = self.x + ls.x
        self.y = self.y + ls.y
    end
    self.q=self.q+1
    -- rect(800,500,120,120) 
    
    -- rotate(30)
    -- sprite(self.imgs[self.k+1],self.i*10%WIDTH+100,HEIGHT/6,HEIGHT/8,HEIGHT/8) 
    --sprite(imgs[math.fmod(q,8)+1],i*10%WIDTH+100,HEIGHT/6,HEIGHT/8,HEIGHT/8) 
    -- sprite(self.imgs[self.k+1], self.x, self.y,150,200)
    sprite(self.imgs[self.k+1], self.x, self.y, w or 30, h or 50)
    popStyle()
    popMatrix()
    -- sprite(imgs[self.index], self.x, self.y)
end

Maps = class()

function Maps:init()
    --[[
    gridCount：网格数目，范围：1~100，例如，设为3则生成3*3的地图，设为100，则生成100*100的地图。
    scaleX：单位网格大小比例，范围：1~100，该值越小，则单位网格越小；该值越大，则单位网格越大。
    scaleY：同上，若与scaleX相同则单位网格是正方形格子。
    plantSeed：植物生成几率，范围:大于4的数，该值越小，生成的植物越多；该值越大，生成的植物越少。
    minerialSeed：矿物生成几率，范围:大于3的数，该值越小，生成的矿物越多；该值越大，生成的矿物越少。
    --]]
    self.gridCount = 50
    self.scaleX = 50
    self.scaleY = 50
    self.plantSeed = 20.0
    self.minerialSeed = 50.0
    
    -- 根据地图大小申请图像
    local w,h = (self.gridCount+1)*self.scaleX, (self.gridCount+1)*self.scaleY
    self.imgMap = image(w,h)
    
    -- 整个地图使用的全局数据表
    self.mapTable = {}
        
    -- 设置物体名称
    tree1,tree2,tree3 = "松树", "杨树", "小草"    
    mine1,mine2 = "铁矿", "铜矿"
        
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
    self:createMapTable()
    print("OK, 地图初始化完成! ")
end

-- 新建地图数据表, 插入地图上每个格子里的物体数据
function Maps:createMapTable()
    --local mapTable = {}
    for i=1,self.gridCount,1 do
        for j=1,self.gridCount,1 do
            self.mapItem = {pos=vec2(i,j), plant=self:randomPlant(), mineral=self:randomMinerial()}
            --self.mapItem = {pos=vec2(i,j), plant=nil, mineral=nil}
            table.insert(self.mapTable, self.mapItem)
        end
    end
    self:updateMap()
end

-- 根据地图数据表, 刷新地图
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

function Maps:drawMap() 
    -- sprite(self.imgMap,-self.scaleX,-self.scaleY)
    sprite(self.imgMap,0,0)
end

-- 根据像素坐标值计算所处网格的 i,j 值
function Maps:where(x,y)
    local i = math.ceil((x+self.scaleX) / self.scaleX)
    local j = math.ceil((y+self.scaleY) / self.scaleY)
    return i,j
end

-- 随机生成植物
function Maps:randomPlant()
    local seed = math.random(1.0, self.plantSeed)
    local result = nil
    
    if seed >= 1 and seed < 2 then result = tree1
    elseif seed >= 2 and seed < 3 then result = tree2
    elseif seed >= 3 and seed < 4 then result = tree3
    elseif seed >= 4 and seed <= self.plantSeed then result = nil end
    
    return result
end

-- 随机生成矿物
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