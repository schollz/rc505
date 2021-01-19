Draw = {}


function Draw.square(x,y,width)

end

function Draw.circle_with_arc(x,y,r,percent)
	for angle=1,360,5 do 
		if angle < percent*360 then 
			screen.level(15)
		else
			screen.level(1)
		end
		for j=-1,1 do 
	        screen.pixel(x+(r-j)*math.sin(math.rad(angle)),y+(r-j)*math.cos(math.rad(angle)))
	        screen.stroke()
       	end
    end
end


return Draw