-- Released under MIT License
-- Created by Jaya Polumuru

----------------------------------------------------------------------------------------
-- Split Information
-- 
-- Compatibility: 
-- LÖVE 11.4
-- LuaJIT 2.1
----------------------------------------------------------------------------------------

--be = require("bezier")

XmlParser = require("xml_parser")



function drawMyCurve(pathCurve)
--	be = require("bezier")

	for i = 2, #pathCurve,3 do 

		local src = pathCurve[i-1];
		local srcAngle = pathCurve[i];
		local destAngle = pathCurve[i+1];
		local dest = pathCurve[i+2];

--		be.drawCurve({
--			src=src,
--			srcCtrlPt=srcAngle,
--			destCtrlPt=destAngle,
--			dest=dest
--		})
	end

end







----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------


function love.load()
--	success = love.window.setMode( 800, 800)


	pathCurve = { 
		{x=155.45091, y=121.75114 },
		{x=132.99905, y=118.63369 },
		{x=88.396117, y=136.55905 },
		{x=45.69419, y=177.0584 },
		{x=46.404538, y=199.11231 },
		{x=61.061375, y=241.77014 },
		{x=95.080232, y=294.61088 },
		{x=102.667602, y=301.5453 },
		{x=123.194382, y=306.72902 },
		{x=150.176422, y=304.27686 },
		{x=167.789582, y=290.61337 },
		{x=196.697852, y=253.83526 },
		{x=221.679152, y=194.62943 },
		{x=217.845102, y=175.39042 },
		{x=194.288802, y=140.91897 },
		{x=151.008532, y=109.23687 } 
	}

--	drawMyCurve(pathCurve);



--	local pathArray = extractPath('exp.svg') -- pathname

	pathLines = XmlParser:main ('exp.svg')
	print ('#lines:', #pathLines)
	
	
--	local pathCurves = {}
	

--	for k1,v1 in pairs(pathArray) do 	

--		local finalPts =  extractPointsFromPath({pathd=v1});
--		table.insert (pathCurves, finalPts)

--		-- Draw curve for each orbit
----		drawMyCurve(finalPts);

--	end


end

function love.draw()
	
	for i, line in ipairs (pathLines) do
--		for i = 1, #line-3, 2 do
--			local x1 = line[i]
--			local y1 = line[i+1]
--			local x2 = line[i+2]
--			local y2 = line[i+3]
--			love.graphics.line (x1,y1, x2,y2)
--		end
		love.graphics.line (line)
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end
