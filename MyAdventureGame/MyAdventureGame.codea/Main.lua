-- 主程序框架

function setup()
    displayMode(OVERLAY)
    myStatus = Status()
    
    -- 以下为帧动画代码
    fill(249, 249, 249, 255)
    imgs = {}
    pos = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
           {320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}
    
    img = readImage("Documents:runner")
    --saveImage("Dropbox:runner",img)
    
    m = Sprites(600,400,img,pos)
end

function draw()
    background(32, 29, 29, 255)
    myStatus:drawUI()
    --myStatus:raderGraph()
    fill(143, 255, 0, 255)
    rect(WIDTH/2,HEIGHT/2,200,200)
    fill(0, 55, 255, 255)
    text("修炼", WIDTH/2,HEIGHT/2)
    
    m:draw()
    sysInfo()
end

function touched(touch)
    if touch.x > WIDTH/2 and touch.state == ENDED then myStatus:update() end
end

function sysInfo()
    -- 显示FPS和内存使用情况
    pushStyle()
    fill(0,0,0,105)
    rect(650,740,220,30)
    fill(150, 152, 255, 255)
    text("FPS: "..math.floor(1/DeltaTime).."    Mem："..math.floor(collectgarbage("count")).." KB",650,740)
    popStyle()
end
