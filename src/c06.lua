-- c06.lua

--# Shaders
-- 用 mesh/shader 实现帧动画，把运算量转移到 GPU 上，可用 shader 实现各种特殊效果
Sprites = class()

function Sprites:init()
    self.m = mesh()
    self.tex = readImage("Documents:catRunning")
    self.m.texture = self.tex
    self.m.shader = shader(shaders["sprites"].vs,shaders["sprites"].fs)
    self.coords = {vec4(0,3/4,1/2,1/4), vec4(1/2,3/4,1/2,1/4), 
    			   vec4(0,2/4,,1/2,1/4), vec4(1/2,2/4,,1/2,1/4), 
                   vec4(0,1/4,,1/2,1/4), vec4(1/2,1/4,,1/2,1/4), 
                   vec4(0,0,,1/2,1/4), vec4(1/2,0,,1/2,1/4)}
    self.i = 1
    
    local w,h = self.tex.width, self.tex.height
    local ws,hs = WIDTH/w,HEIGHT/h
    self.x, self.y = w/2,h/2
    self.mi = self.m:addRect(self.x, self.y,WIDTH/10,HEIGHT/10)
    self.speed = 1/30
    self.time = os.clock()
    
    self:convert()
end

function Sprites:convert()
	local w, h = self.tex, self.tex.height
	local n = #self.coords
	for i = 1, n do
		coords[i].x, coords[i].y = coords[i].x/w, coords[i].y/h
		coords[i].z, coords[i].w = coords[i].z/w, coords[i].y/h
	end
end

function Sprites:draw()
    -- 依次改变贴图坐标，取得不同的子帧
    self.m:setRectTex(self.mi, 
    				  self.coords[(self.i-1)%8+1].x,self.coords[(self.i-1)%8+1].y, 
    				  self.coords[i].z, self.coords[i].w)
    -- 根据 self.x, self.y 重新设置显示位置
    self.m:setRect(self.mi, self.x, self.y, WIDTH/10,HEIGHT/10,50)
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
    img1 = readImage("Documents:catRunning")
    pos1 = {{0,0,110,120},{110,0,70,120},{180,0,70,120},{250,0,70,120},
			{320,0,105,120},{423,0,80,120},{500,0,70,120},{570,0,70,120}}
       
	-- 帧动画素材2       
	img2 = readImage("Documents:catRunning")
    local w,h = 1024,1024
    pos2 = {{0,h*3/4,w/2,h/4},{w/2,h*3/4,w/2,h/4},{0,h*2/4,w/2,h/4},{0,h*2/4,w/2,h/4},
            {0,h*1/4,w/2,h/4},{w/2,h*1/4,w/2,h/4},{0,h*0/4,w/2,h/4},{0,h*0/4,w/2,h/4}}
      
	-- 开始初始化帧动画类            
    myS = Sprites()
    myS.tex = img2
    myS.coords = pos2
    myS.speed = 1/20
    myS.x = 200
end

function draw()
    background(39, 31, 31, 255)

    myS:draw()
    sysInfo()
end

function touched(touch)
    myS:touched(touch)
end


-- Shader
shaders = {
sprites = { vs=[[
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
]]}
}