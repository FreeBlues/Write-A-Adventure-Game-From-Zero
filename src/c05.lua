-- c05.lua

Threads = class()

function Threads:init()
    self.threads = {}    
    self.time = os.clock()   
    self.timeTick = 0.1 
    self.worker = 1
    self.task = function() end
end

-- 切换点, 可放在准备暂停的函数内部, 一般选择放在多重循环的最里层, 这里耗时最多
function Threads:switchPoint()
    -- 切换线程，时间片耗尽，而工作还没有完成，挂起本线程，自动保存现场。
    if (os.clock() - self.time) >= self.timeTick then       
        self.time = os.clock()  
        -- 挂起当前协程 
        coroutine.yield()    
    end
end

-- 计算某个整数区间内所有整数之和，要在本函数中设置好挂起条件
function Threads:taskUnit()
	-- 可在此处执行用户的任务函数
	self.task()
        
	-- 切换点, 放在 self.task() 函数内部耗时较长的位置处, 以方便暂停
	self:switchPoint()      
end

-- 创建协程，分配任务，该函数执行一次即可。
function Threads:job ()
	local f = function () self:taskUnit() end
    -- 为 taskUnit() 函数创建协程。
    local co = coroutine.create(f)
    table.insert(self.threads, co)
end


-- 在 draw 中运行的分发器，借用 draw 的循环运行机制，调度所有线程的运行。
function Threads:dispatch()
    local n = #self.threads
    -- 线程表空了, 表示没有线程需要工作了。
    if n == 0 then return end   
    for i = 1, n do
    	-- 记录哪个线程在工作。
        self.worker = i    
        -- 恢复"coroutine"工作。
        local status = coroutine.resume(self.threads[i])
        -- 线程是否完成了他的工作？"coroutine"完成任务时，status是"false"。
        ---[[ 若完成则将该线程从调度表中删除, 同时返回。
        if not status then
            table.remove(self.threads, i)
            return
        end
        --]]
    end
end

-- 主程序框架
function setup()
    print("Threads...")
    
    myT = Threads()
    myT:job()
end

function draw()
    background(0)
    
    myT:dispatch()
    
    sysInfo()
end

-- 显示FPS和内存使用情况
function sysInfo()
    pushMatrix()
    pushStyle()
    
    fill(255, 255, 255, 255)
    -- 根据 DeltaTime 计算 fps, 根据 collectgarbage("count") 计算内存占用
    local fps = math.floor(1/DeltaTime)
    local mem = math.floor(collectgarbage("count"))
    text("FPS: "..fps.."    Mem："..mem.." KB",650,740)
    popStyle()
    popMatrix()
end
