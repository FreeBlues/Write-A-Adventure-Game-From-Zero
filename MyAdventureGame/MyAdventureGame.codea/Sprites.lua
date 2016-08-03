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
    end
    self.q=self.q+1
    -- rect(800,500,120,120) 
    
    -- rotate(30)
    -- sprite(self.imgs[self.k+1],self.i*10%WIDTH+100,HEIGHT/6,HEIGHT/8,HEIGHT/8) 
    --sprite(imgs[math.fmod(q,8)+1],i*10%WIDTH+100,HEIGHT/6,HEIGHT/8,HEIGHT/8) 
    sprite(self.imgs[self.k+1], self.x, self.y,50,50)
    popStyle()
    popMatrix()
    -- sprite(imgs[self.index], self.x, self.y)
end
