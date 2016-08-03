------------------------------------------------
-- Import common libraries into global namespace
------------------------------------------------

json = require("dkjson")

------------------------------------------------
-- Block out any dangerous or insecure functions
------------------------------------------------

arg=nil

os.execute=nil
os.exit=nil