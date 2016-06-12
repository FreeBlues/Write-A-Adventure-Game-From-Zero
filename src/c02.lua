-- 第二章例程源码

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

function Sprites:draw()
    -- 确定每帧子画面在屏幕上停留的时间
    if ElapsedTime > self.prevTime + 0.08 then
        self.prevTime = self.prevTime + 0.08 
        self.k = math.fmod(self.i,#self.imgs) 
        self.i = self.i + 1
        -- self.x = self.x + 1    
    end
    self.q=self.q+1
    -- rect(800,500,120,120) 
    pushMatrix()
    -- rotate(30)
    -- sprite(self.imgs[self.k+1],self.i*10%WIDTH+100,HEIGHT/6,HEIGHT/8,HEIGHT/8) 
    --sprite(imgs[math.fmod(q,8)+1],i*10%WIDTH+100,HEIGHT/6,HEIGHT/8,HEIGHT/8) 
    --sprite(self.imgs[self.k+1], self.x, self.y,50,50)
    sprite(self.imgs[self.k+1], self.x, self.y)
    popMatrix()
    -- sprite(imgs[self.index], self.x, self.y)
end

-- Main
function setup()
    displayMode(FULLSCREEN)

    -- 绘图模式选 CENTER 可以保证画面中的动画角色不会左右漂移
    rectMode(CENTER)
    spriteMode(CENTER)

    fill(249, 249, 249, 255)
    imgs = {}
    pos = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
           {320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}

    img = readImage("Documents:runner")

    img1 = readImage("Documents:cats")
    local x,y = 128,43
    pos1 = {{0+x,0+y,32,43},{64+x,0+y,32,43},{96+x,0+y,32,43}}

    img2 = readImage("Documents:catRunning")
    local w,h = 1024,1024
    pos2 = {{0,h*3/4,w/2,h/4},{w/2,h*3/4,w/2,h/4},{0,h*2/4,w/2,h/4},{0,h*2/4,w/2,h/4},
            {0,h*1/4,w/2,h/4},{w/2,h*1/4,w/2,h/4},{0,h*0/4,w/2,h/4},{0,h*0/4,w/2,h/4}}

    m = Sprites(600,400,img,pos)
    m1 = Sprites(500,400,img1,pos1)
    m2 = Sprites(500,200,img2,pos2)
end

function draw()
    background(39, 44, 39, 255)

    m:draw()
    m1:draw()
    m2:draw()
end
