-- c06-01.lua

--# Shaders
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
    self.w, self.h = WIDTH/10, HEIGHT/10
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
    -- 根据 self.x, self.y 重新设置显示位置
    self.m:setRect(self.mi, self.x, self.y, self.w, self.h)
    -- 如果停留时长超过 self.speed，则使用下一帧
    if os.clock() - self.time >= self.speed then
        self.i = self.i + 1
        self.time = os.clock()
    end
    
    self.m:draw()
end

function Sprites:touched(touch)
    self.x, self.y = touch.x, touch.y
end


-- 游戏主程序框架
function setup()
    displayMode(OVERLAY)
    
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
    myS.m.shader.maxWhite = vec4(0.8, 0.8, 0.8, 0.8)
    -- 设置颜色为绿色, 中毒状态
    myS.m:setRectColor(myS.mi, 0, 255,0,255)

    -- 设置速度
    myS.speed = 1/20
    myS.x = 500
end

function draw()
    background(39, 31, 31, 255)
    -- 绘制 mesh
    myS:draw()
    sysInfo()
end

function touched(touch)
    myS:touched(touch)
end

-- 系统信息
function sysInfo()
    -- 显示FPS和内存使用情况
    pushStyle()
    fill(255, 255, 255, 255)
    -- 根据 DeltaTime 计算 fps, 根据 collectgarbage("count") 计算内存占用
    local fps = math.floor(1/DeltaTime)
    local mem = math.floor(collectgarbage("count"))
    text("FPS: "..fps.."    Mem："..mem.." KB",650,740)
    popStyle()
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

// 定义一个用于比较的颜色值, 由用户自行控制
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
]]},

sprites2 = { vs=[[
// 局部变灰
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

float intensity(vec4 col) {
    // 计算像素点的灰度值
    return 0.3*col.x + 0.59*col.y + 0.11*col.z;
}

void main()
{
    // 取得像素点的纹理采样
    lowp vec4 col = texture2D( texture, vTexCoord ) * vColor;
    col.rgba = vec4(intensity(col));
    gl_FragColor = col;
}
]]}
}