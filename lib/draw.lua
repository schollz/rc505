Draw = {}

drawings = include("rc505/lib/drawings")

function Draw.drawing(name,x,y,i)
	local drawing = drawings[name]
	if drawing == nil then 
		print("no name "..name)
		do return end
	end
	if i~= nil then 
		drawing = drawings[name][i]
	end
	for _,p in ipairs(drawing) do
		screen.level(p[3]) 
		screen.pixel(p[1]+x,p[2]+y)
		screen.fill()
	end
end


function Draw.track(track)
	-- i, selected
	screen.move(23+40*(track.i-1),8)
	if track.beat_total > 0 then 
		screen.text_center(track.beat_current.."/"..track.beat_total)
	else
		screen.text_center("FREE")
	end
	screen.move(19+40*(track.i-1),59)
	screen.text(track.division)
	Draw.volume_bar(track.i,track.level)
	if not track.playing then 
		track.progress = 0 
	elseif track.playing and track.progress == 0 then 
		track.progress = 1
	end
	-- Draw.circle_with_arc(23+40*(track.i-1),26,12.5,track.progress)
	Draw.drawing("circle",40*(track.i-1),0,math.floor(100*track.progress)+1)
	if track.selected then 
		Draw.drawing("selected",40*(track.i-1),0)
	end
	
	if track.recording then 
		screen.level(15)
		screen.circle(24+40*(track.i-1),26,4)
		screen.fill()
	elseif track.playing then 
		Draw.drawing("playing",40*(track.i-1),0)
	end
	if track.beat_repeat then 
		Draw.drawing("beat_repeat",40*(track.i-1),0)
	end
	if track.beat_shuffle then 
		Draw.drawing("beat_shuffle",40*(track.i-1),0)
	end
end

function Draw.volume_bar(i,volume)
	x = 10+40*(i-1)
	y = 45
	h = 5 
	w = 27
	screen.level(15)
	screen.rect(x,y,w,h)
	screen.stroke()
	h = 4 
	x = x
	y = y
	w = math.floor((w-1)*volume)
	screen.level(5)
	screen.rect(x,y,w,h)
	screen.fill()
end
function Draw.circle_with_arc(x,y,r,fraction)
	for angle=1,360,8 do 
		if angle > (1-fraction)*360 then 
			screen.level(15)
		else
			screen.level(1)
		end
		for j=0,1 do 
	        screen.pixel(x+(r-j)*math.sin(math.rad(angle)),y+(r-j)*math.cos(math.rad(angle)))
	        screen.stroke()
       	end
    end
end


return Draw