-- 第一章例程源码

-- 角色状态类
Status = class()

function Status:init() 
    -- 体力，内力，精力，智力，气，血
    self.tili = 100
    self.neili = 90
    self.jingli = 70
    self.zhili = 100
    self.qi = 100
    self.xue = 100
    self.img = image(200, 300)
end

function Status:update()
    -- 更新状态：自我修炼，日常休息，战斗
    self.neili = self.neili + 1
end

function Status:drawUI()
    setContext(self.img)
    background(119, 121, 72, 255)
    pushStyle()
    fill(36, 112, 111, 255)
    rect(5,5,200-10,300-10)
    fill(70, 255, 0, 255)
    textAlign(RIGHT)
    text("体力: "..self.tili,50,280)
    text("内力: "..self.neili,50,260)
    text("精力: "..self.jingli,50,240)
    text("智力: "..self.zhili,50,220)
    text("气  : "..self.qi,50,200)
    text("血  : "..self.xue,50,180)
    sprite("Documents:B1", 100,90)
    popStyle()
    setContext()
    self:raderGraph()
    sprite(self.img, 400,300)
end

-- 角色技能雷达图
function Status:raderGraph()
    setContext(self.img)
    pushMatrix()
    pushStyle()
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

    -- 用于绘制圈线的函数
    function lines(t,n,j,z,q,x)
        line(axis.n[n].x, axis.n[n].y, axis.t[t].x, axis.t[t].y)
        line(axis.n[n].x, axis.n[n].y, axis.j[j].x, axis.j[j].y)
        line(axis.x[x].x, axis.x[x].y, axis.t[t].x, axis.t[t].y)
        line(axis.z[z].x, axis.z[z].y, axis.j[j].x, axis.j[j].y)
        line(axis.x[x].x, axis.x[x].y, axis.q[q].x, axis.q[q].y)
        line(axis.z[z].x, axis.z[z].y, axis.q[q].x, axis.q[q].y)
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
        return f(t/25),f((25+math.fmod(n,100))/25),f(j/25),f(z/25),f(q/25),f(x/25)
    end
    stroke(255, 32, 0, 255)
    strokeWidth(2)
    smooth()
    -- 设定当前各参数的值
    print(values())
    -- local t,n,j,z,q,x = 3,2,3,2,4,1
    local t,n,j,z,q,x = values()    
    lines(t,n,j,z,q,x)

    popStyle()
    popMatrix()
    setContext()
end

-- main 主程序框架
function setup()
    displayMode(OVERLAY)
    myStatus = Status()
end

function draw()
    background(32, 29, 29, 255)
    myStatus:drawUI()
    -- myStatus:raderGraph()
    fill(143, 255, 0, 255)
    rect(WIDTH/2,HEIGHT/2,200,200)
    fill(0, 55, 255, 255)
    text("修炼", WIDTH/2+100, HEIGHT/2+100)
end

function touched(touch)
    if touch.x > WIDTH/2 and touch.state == ENDED then myStatus:update() end
end
