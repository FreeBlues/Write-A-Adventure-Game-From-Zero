--

function initParams()
    print("Simple Map Sample!!")
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