-- 用 mesh 绘制，先绘制背景六边形，再绘制技能六边形，再绘制动态技能，最后再考虑旋转
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
    setContext(self.img)
    background(119, 121, 72, 255)
    pushStyle()
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
    popStyle()
    setContext()
    
    self:radarGraphDraw()
    sprite(self.img, 400,300)
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


-- main 主程序框架
function setup()
    displayMode(OVERLAY)
    myStatus = Status()
end

function draw()
    background(32, 29, 29, 255)
    
    myStatus:drawUI()
    
    sysInfo()
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

