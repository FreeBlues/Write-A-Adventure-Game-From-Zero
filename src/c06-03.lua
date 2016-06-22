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
    fill(36, 112, 111, 255)
    rect(5,5,200-10,300-10)
    fill(70, 255, 0, 255)
    textAlign(RIGHT)
    text("体力: "..math.floor(self.tili),50,280)
    text("内力: "..math.floor(self.neili),50,260)
    text("精力: "..math.floor(self.jingli),50,240)
    text("智力: "..math.floor(self.zhili),50,220)
    text("气  : "..math.floor(self.qi),50,200)
    text("血  : "..math.floor(self.xue),50,180)
    sprite("Documents:B1", 100,90)
    popStyle()
    setContext()
    self:raderGraph()
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

-- 用 mesh 绘制
function Status:raderGraphMesh()
    -- 雷达图底部大六边形背景
    self.m = mesh()
    -- 雷达图中心坐标，半径，角度
    local x0,y0,r,a,s = 250,330,500,360/6,4
    -- 计算右上方斜线的坐标
    local x,y = r* math.cos(math.rad(30)), r* math.sin(math.rad(30))
    -- 六边形 6 个顶点坐标，从正上方开始，逆时针方向
    local points = triangulate({vec2(0,r/s),vec2(-x/s,y/s),vec2(-x/s,-y/s),
                                vec2(0,-r/s),vec2(x/s,-y/s),vec2(x/s,y/s)})
    print(#points, points[1], points[2],points[3])
    self.m.vertices = points
    local c1 = color(0, 255, 121, 123)
    self.m:setColors(c1)    
    
    -- 实时绘制顶点位置，根据各状态属性值，实时计算顶点位置
    local function axisDynamic()
        local t,n,j,z,q,x = self.tili, self.neili, self.jingli,self.zhili, self.qi, self.xue
        local c,s = math.cos(math.rad(30)), math.sin(math.rad(30))
        local points = triangulate({vec2(0,t),vec2(-n*c,n*s),vec2(-j*c,-j*s),
                                    vec2(0,-z),vec2(q*c,-q*s),vec2(x*c,x*s)})
        return points
    end
    
    -- 绘制代表属性值的小六边形
    self.m1 = mesh()
    self.m1.vertices = axisDynamic()
    local c = color(0, 255, 121, 123)
    self.m1:setColors(c2)
end

-- 角色技能雷达图
function Status:raderGraph()
    setContext(self.img)
    pushMatrix()
    pushStyle()
    fill(60, 230, 30, 255)
    -- 中心坐标，半径，角度，比例
    local x0,y0,r,a,s = 150,230,40,360/6,4
    -- 计算右上方斜线的坐标
    local x,y = r* math.cos(math.rad(30)), r* math.sin(math.rad(30))
    p = {"体力","内力","精力","智力","气","血"}
    -- 保存六边形从边缘向里 4 个尺度上的坐标
    axis = {t={vec2(0,r/s),vec2(0,r*2/s),vec2(0,r*3/s),vec2(0,r)},
            n={vec2(-x/s,y/s),vec2(-x*2/s,y*2/s),vec2(-x*3/s,y*3/s),vec2(-x,y)},
            j={vec2(-x/s,-y/s),vec2(-x*2/s,-y*2/s),vec2(-x*3/s,-y*3/s),vec2(-x,-y)},
            z={vec2(0,-r/s),vec2(0,-r*2/s),vec2(0,-r*3/s),vec2(0,-r)},
            q={vec2(x/s,-y/s),vec2(x*2/s,-y*2/s),vec2(x*3/s,-y*3/s),vec2(x,-y)},
            x={vec2(x/s,y/s),vec2(x*2/s,y*2/s),vec2(x*3/s,y*3/s),vec2(x,y)}}
    
    -- 用于绘制把六边形顶点连起来的圈线的函数，固定 4 个点刻度
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
    -- 绘制雷达图相对顶点之间的连线
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

    popStyle()
    popMatrix()
    setContext()
end

-- main 主程序框架
function setup()
    displayMode(OVERLAY)
    myStatus = Status()
    myStatus:raderGraphMesh()
end

function draw()
    background(32, 29, 29, 255)
    
    translate(650,300)
    myStatus.m:draw()
    myStatus.m1:draw()
    
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

