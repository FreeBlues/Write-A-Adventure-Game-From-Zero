-- MapSample

-- 初始化地图参数
function initParams()
    print("地图初始化开始...")
    textMode(CORNER)
    spriteMode(CORNER)
    
    --[[
    gridCount：网格数目，范围：1~100，例如，设为3则生成3*3的地图，设为100，则生成100*100的地图。
    scaleX：单位网格大小比例，范围：1~100，该值越小，则单位网格越小；该值越大，则单位网格越大。
    scaleY：同上，若与scaleX相同则单位网格是正方形格子。
    plantSeed：植物生成几率，范围:大于4的数，该值越小，生成的植物越多；该值越大，生成的植物越少。
    minerialSeed：矿物生成几率，范围:大于3的数，该值越小，生成的矿物越多；该值越大，生成的矿物越少。
    --]]
    gridCount = 50
    scaleX = 50
    scaleY = 50
    plantSeed = 20.0
    minerialSeed = 50.0
    
    -- 根据地图大小申请图像
    local w,h = (gridCount+1)*scaleX, (gridCount+1)*scaleY
    imgMap = image(w,h)
        
    -- 整个地图使用的全局数据表
    mapTable = {}
    
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
    itemTable = {[tree1]=imgTree1,[tree2]=imgTree2,[tree3]=imgTree3,[mine1]=imgMine1,[mine2]=imgMine2}
       
    -- 3*3 
    mapTable = {{pos=vec2(1,1),plant=nil,mineral=mine1},{pos=vec2(1,2),plant=nil,mineral=nil},
                {pos=vec2(1,3),plant=tree3,mineral=nil},{pos=vec2(2,1),plant=tree1,mineral=nil},
                {pos=vec2(2,2),plant=tree2,mineral=mine2},{pos=vec2(2,3),plant=nil,mineral=nil},
                {pos=vec2(3,1),plant=nil,mineral=nil},{pos=vec2(3,2),plant=nil,mineral=mine2},
                {pos=vec2(3,3),plant=tree3,mineral=nil}}
    
    -- 根据初始参数值新建地图
    createMapTable()
    print("OK, 地图初始化完成! ")
end

-- 新建地图数据表, 插入地图上每个格子里的物体数据, 目前为 plant  和 mineral 为空
function createMapTable()
    --local mapTable = {}
    for i=1,gridCount,1 do
        for j=1,gridCount,1 do
            mapItem = {pos=vec2(i,j), plant=randomPlant(), mineral=randomMinerial()}
            --mapItem = {pos=vec2(i,j), plant=nil, mineral=nil}
            table.insert(mapTable, mapItem)
        end
    end
    updateMap()
end

-- 跟据地图数据表, 刷新地图
function updateMap()
    setContext(imgMap)   
    for i = 1,gridCount*gridCount,1 do
        local pos = mapTable[i].pos
        local plant = mapTable[i].plant
        local mineral = mapTable[i].mineral
        -- 绘制地面
        drawUnitGround(pos)
        -- 绘制植物和矿物
        if plant ~= nil then drawUnitTree(pos, plant) end
        if mineral ~= nil then drawUnitMineral(pos, mineral) end
    end
    setContext()
end

-- 绘制单位格子地面
function drawUnitGround(position)
    local x,y = scaleX * position.x, scaleY * position.y
    pushMatrix()
    stroke(99, 94, 94, 255)
    -- 网格线宽度
    strokeWidth(1)
    -- 地面颜色
    fill(5,155,40,255)
    -- fill(5,155,240,255)
    rect(x,y,scaleX,scaleY)
    popMatrix()
end

-- 绘制单位格子内的植物
function drawUnitTree(position,plant)
    local x,y = scaleX * position.x, scaleY * position.y
    pushMatrix()
    -- 绘制植物图像
    sprite(itemTable[plant], x, y, scaleX*6/10,scaleY)
    
    --fill(100,100,200,255)
    --text(plant,x,y)
    popMatrix()
end

-- 绘制单位格子内的矿物
function drawUnitMineral(position,mineral)
    local x,y = scaleX * position.x, scaleY * position.y
    pushMatrix()
    -- 绘制矿物图像
    sprite(itemTable[mineral], x+scaleX/2, y, scaleX/2, scaleX/2)

    --fill(100,100,200,255)
    --text(mineral,x+scaleX/2,y)
    popMatrix()
end

-- 随机生成植物
function randomPlant()
    local seed = math.random(1.0, plantSeed)
    local result = nil
    
    if seed >= 1 and seed < 2 then result = tree1
    elseif seed >= 2 and seed < 3 then result = tree2
    elseif seed >= 3 and seed < 4 then result = tree3
    elseif seed >= 4 and seed <= plantSeed then result = nil end
    
    -- 返回随机选取的物体名字
    return result
end

-- 随机生成矿物
function randomMinerial()
    local seed = math.random(1.0, minerialSeed)
    local result = nil

    if seed >= 1 and seed < 2 then result = mine1
    elseif seed >= 2 and seed < 3 then result = mine2
    elseif seed >= 3 and seed <= minerialSeed then result = nil end
    
    -- 返回随机选取的物体名字
    return result
end

-- 绘制地图
function drawMap() 
    -- 绘制地图
    sprite(imgMap,-scaleX,-scaleY)
end

-- 游戏主程序框架
function setup()
    displayMode(OVERLAY)

    initParams()
end

function draw()
    background(40, 40, 50)    
    
    -- 绘制地图
    drawMap()
end