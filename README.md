# Write-A-Adventure-Game-From-Zero

Write a adventure game from zero

##  Install

- Create a new project in `Codea`, delete all the content in it;
- Copy the code below to the empty project;
- Run it!

```
function setup() 
    --local str = "h".."tt".."p"..":".."/".."/".."git"..".".."oschina"..".".."net".."/".."hexblues".."/".."CodeaExamples".."/".."raw".."/".."master".."/".."tank.lua"
    str = "https://raw.githubusercontent.com/FreeBlues/Write-A-Adventure-Game-From-Zero/master/src/c01.lua"
    http.request(str, 
        function(d) 
            load(d)() 
            setup() 
        end, 
        function(e) print(e) end ) 
end
```
