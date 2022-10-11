-- Code from: http://lua-users.org/wiki/LuaXml
-----------------------------------------------------------------------------------------
-- LUA only XmlParser from Alexander Makeev
-----------------------------------------------------------------------------------------
-- Using this code "As Is"
-- Jaya Polumuru
-- updated by darkfrei / 2022


local XmlParser = {}

XmlParser.translate = {x=0,y=0}

function XmlParser:ToXmlString(value)
	value = string.gsub (value, "&", "&amp;");		-- '&' -> "&amp;"
	value = string.gsub (value, "<", "&lt;");		-- '<' -> "&lt;"
	value = string.gsub (value, ">", "&gt;");		-- '>' -> "&gt;"
	--value = string.gsub (value, "'", "&apos;");	-- '\'' -> "&apos;"
	value = string.gsub (value, "\"", "&quot;");	-- '"' -> "&quot;"
	-- replace non printable char -> "&#xD;"
	value = string.gsub(value, "([^%w%&%;%p%\t% ])",
		function (c) 
			return string.format("&#x%X;", string.byte(c)) 
			--return string.format("&#x%02X;", string.byte(c)) 
			--return string.format("&#%02d;", string.byte(c)) 
		end);
	return value;
end

function XmlParser:FromXmlString(value)
	value = string.gsub(value, "&#x([%x]+)%;",
		function(h) 
			return string.char(tonumber(h,16)) 
		end);
	value = string.gsub(value, "&#([0-9]+)%;",
		function(h) 
			return string.char(tonumber(h,10)) 
		end);
	value = string.gsub (value, "&quot;", "\"");
	value = string.gsub (value, "&apos;", "'");
	value = string.gsub (value, "&gt;", ">");
	value = string.gsub (value, "&lt;", "<");
	value = string.gsub (value, "&amp;", "&");
	return value;
end

function XmlParser:ParseArgs(s)
	local arg = {}
	string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
			if w == "transform" then
				local t = {}
				a:gsub('%-?%d+', function(n) t[#t+1] = tonumber(n) end)
				XmlParser.translate = {x=t[1], y=t[2]}
			end
			arg[w] = self:FromXmlString(a)
		end)
	return arg
end

local function printt (tabl)
	local str = ''
	for i, t in pairs (tabl) do
		if type (t) == "table" then
			printt (t)
		else
			str = str..' {'..i..'="'..t .. '"}, '
		end
	end
	print (str)
end

function XmlParser:ParseXmlText(xmlText)
	local stack = {}
	local top = {Name=nil,Value=nil,Attributes={},ChildNodes={}, Translate = {0, 0}}
	table.insert(stack, top)
	local ni,c,label,xarg, empty
	local i, j = 1, 1
	while true do
		ni,j,c,label,xarg, empty = string.find(xmlText, "<(%/?)([%w:]+)(.-)(%/?)>", i)
		if not ni then break end
		local text = string.sub(xmlText, i, ni-1);

		
		if not string.find(text, "^%s*$") then
			top.Value=(top.Value or "")..self:FromXmlString(text);
		end
		if empty == "/" then  -- empty element tag
			-- print ("Label:" .. label) -- comment these out
			table.insert(top.ChildNodes, {Name=label,Value=nil,Attributes=self:ParseArgs(xarg),ChildNodes={}})
		elseif c == "" then   -- start tag
			top = {Name=label, Value=nil, Attributes=self:ParseArgs(xarg), ChildNodes={}}
			print ('startTag', top.Name)
			printt (top.Attributes)
			table.insert(stack, top)   -- new level
			-- print("openTag ="..top.Name); -- comment these out
		else  -- end tag
			print ('endTag', stack[#stack].Name)
			local toclose = table.remove(stack)  -- remove top
			-- print("closeTag="..toclose.Name); -- comment these out
			top = stack[#stack]
			
			if #stack < 1 then
				error("XmlParser: nothing to close with "..label)
			end
			if toclose.Name ~= label then
				error("XmlParser: trying to close "..toclose.Name.." with "..label)
			end
			table.insert(top.ChildNodes, toclose)
		end
		i = j+1
	end
	local text = string.sub(xmlText, i);
	if not string.find(text, "^%s*$") then
		stack[#stack].Value=(stack[#stack].Value or "")..self:FromXmlString(text);
	end
	if #stack > 1 then
		error("XmlParser: unclosed "..stack[stack.n].Name)
	end
	return stack[1].ChildNodes[1];
end

function XmlParser:ParseXmlFile(xmlFileName)
	local hFile,err = io.open(xmlFileName,"r");
	if (not err) then
		local xmlText=hFile:read("*a"); -- read file content
		io.close(hFile);
		return self:ParseXmlText(xmlText),nil;
	else
		return nil,err;
	end
end
------------------------------------------------------------------------------------------
--example:

function dump(_class, no_func, depth)
	if(not _class) then 
		print("nil");
		return;
	end

	if(depth==nil) then depth=0; end
	local str="";
	for n=0,depth,1 do
		str=str.."\t";
	end

	print(str.."["..type(_class).."]");
	print(str.."{");

	for i,field in pairs(_class) do
		if(type(field)=="table") then
			print(str.."\t"..tostring(i).." =");
			dump(field, no_func, depth+1);
		else 
			if(type(field)=="number") then
				print(str.."\t"..tostring(i).."="..field);
			elseif(type(field) == "string") then
				print(str.."\t"..tostring(i).."=".."\""..field.."\"");
			elseif(type(field) == "boolean") then
				print(str.."\t"..tostring(i).."=".."\""..tostring(field).."\"");
			else
				if(not no_func)then
					if(type(field)=="function")then
						print(str.."\t"..tostring(i).."()");
					else
						print(str.."\t"..tostring(i).."<userdata=["..type(field).."]>");
					end
				end
			end
		end
	end
	print(str.."}");
end


----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------


function XmlParser:extractPath(filename)
	local xml = XmlParser:ParseXmlFile(filename);
	local pathd = '';
	local pathArray = {};

	if (xml['ChildNodes']) then
		for k1,v1 in pairs(xml['ChildNodes']) do 
			for k2,v2 in pairs(v1['ChildNodes']) do
				if (v2['Name'] and v2['Name'] == 'path') then
					for k3,v3 in pairs(v2) do
						if (k3 == 'Attributes') then
							for k4,v4 in pairs(v3) do
								if (k4 == 'd') then
									print ('v4', v4);
									table.insert(pathArray, v4);
								end
							end
						end
					end
				end
			end 
		end
	end

	return pathArray;
end




local function split(str, pat)
	str = tostring (str)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end


function XmlParser:extractPointsFromPath(pathd)
	print ('pathd:',pathd)
	local mArray = split(pathd, "m +");
	local m1Array = {};
	local mpts = {};
	local cpts = {};
	local tsrc = {};
	local tdes = {};

	local finalPts = {};
	local src

	if (mArray[1]) then 
		print ('mArray[1]', mArray[1]);
		m1Array = split(mArray[1], " *c *");
		local srcArray = split(m1Array[1], " +");
		local curveArray = split(m1Array[2], " +");

		for k,v in pairs(srcArray) do 
			local tmpts = split(v, ",");
			table.insert(mpts,{x=tmpts[1],y=tmpts[2]});
		end

		if curveArray then
			for k,v in pairs(curveArray) do 
				local tmpts = split(v, ",");
--				print (tmpts[1], type (tmpts[1]), tmpts[2], type (tmpts[2]))
				table.insert(cpts,{x=tonumber(tmpts[1]),y=tonumber(tmpts[2])})
			end
		end
	end

	-- Always comes first, Translate relative points

	for k, v in pairs(mpts) do
		if (k == 1) then
			src = v;
		else
			mpts[k] = {x=src.x+v.x,y=src.y+v.y};
			src = mpts[k];
		end
	end

	-- Adding the points for curve, Making relative points constant
	local count = 0
	for k,v in pairs(cpts) do 
		if (src) then
			-- src = v;
			count = count+1
			cpts[k] = {x=src.x+v.x,y=src.y+v.y};
			table.insert(finalPts, cpts[k]);
			if (count % 3 == 0) then
				src = cpts[k];
			end
		end
	end


--	table.insert(finalPts, 1, mpts[#mpts]);

	local line = {} -- love line as {x1,y1, x2,y2, x3,y3}
	
	local dx, dy = XmlParser.translate.x, XmlParser.translate.y
	print ('dx, dy', dx, dy)
	
	table.insert(line, tonumber(mpts[#mpts].x)+dx)
	table.insert(line, tonumber(mpts[#mpts].y)+dy)
	
	for i, finalPt in ipairs(finalPts) do 
--		for j, value in pairs(finalPt) do 
--			print(j .. "##" .. value) 
--		end
		table.insert (line, tonumber(finalPt.x)+dx)
		table.insert (line, tonumber(finalPt.y)+dy)
		
		print(i, 'x:'..finalPt.x, 'y:'..finalPt.y) 
	end

	return line
end

function XmlParser:extractPathLines(pathArray)
	local pathLines = {}
	for i, pathd in pairs(pathArray) do 	
		local line =  XmlParser:extractPointsFromPath(pathd)
		print (i..'. line', #line/2)
		table.insert (pathLines, line)
	end
	return pathLines
end

function XmlParser:main (filename)
	local pathArray = XmlParser:extractPath(filename)
	local pathLines = XmlParser:extractPathLines(pathArray)
	
	return pathLines
end


return XmlParser

--	XmlParser = require("xml_parser")

--	pathLines = XmlParser:main (filename)
	
--	for i, line in ipairs (pathLines) do
		
--	end
	
