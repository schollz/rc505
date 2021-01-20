Draw = {}

local drawings = {
beat_repeat = {{9,53,15},{9,54,15},{9,55,15},{9,56,15},{9,57,15},{9,58,15},{9,59,15},{10,53,15},{10,59,15},{11,53,15},{11,54,15},{11,55,15},{11,56,15},{11,57,15},{11,58,15},{11,59,15},{12,53,15},{12,59,15},{13,53,15},{13,54,15},{13,55,15},{13,56,15},{13,57,15},{13,58,15},{13,59,15},{14,53,15},{14,59,15},{15,53,15},{15,54,15},{15,55,15},{15,56,15},{15,57,15},{15,58,15},{15,59,15}},
beat_shuffle = {{49,53,15},{49,54,15},{49,55,15},{49,56,15},{49,57,15},{49,58,15},{49,59,15},{50,53,15},{50,54,15},{50,59,15},{51,53,15},{51,54,15},{51,55,15},{51,56,15},{51,57,15},{51,58,15},{51,59,15},{52,53,15},{52,58,15},{52,59,15},{53,53,15},{53,54,15},{53,55,15},{53,56,15},{53,57,15},{53,58,15},{53,59,15},{54,53,15},{54,54,15},{54,55,15},{54,59,15},{55,53,15},{55,54,15},{55,55,15},{55,56,15},{55,57,15},{55,58,15},{55,59,15}},
playing = {{21,23,15},{21,24,15},{21,25,15},{21,26,15},{21,27,15},{21,28,15},{21,29,15},{22,24,15},{22,25,15},{22,26,15},{22,27,15},{22,28,15},{23,24,15},{23,25,15},{23,26,15},{23,27,15},{23,28,15},{24,25,15},{24,26,15},{24,27,15},{25,25,15},{25,26,15},{25,27,15},{26,26,15}},
recording = {{60,26,15},{60,27,15},{61,25,15},{61,26,15},{61,27,15},{61,28,15},{62,24,15},{62,25,15},{62,26,15},{62,27,15},{62,28,15},{62,29,15},{63,24,15},{63,25,15},{63,26,15},{63,27,15},{63,28,15},{63,29,15},{64,24,15},{64,25,15},{64,26,15},{64,27,15},{64,28,15},{64,29,15},{65,25,15},{65,26,15},{65,27,15},{65,28,15},{66,26,15},{66,27,15}},
selected = {{9,13,15},{9,14,15},{9,15,15},{9,16,11},{9,36,11},{9,37,15},{9,38,15},{9,39,15},{10,13,15},{10,39,15},{11,13,15},{11,39,15},{12,13,11},{12,39,11},{33,13,11},{33,39,11},{34,13,15},{34,39,15},{35,13,15},{35,39,15},{36,13,15},{36,14,15},{36,15,15},{36,16,11},{36,36,11},{36,37,15},{36,38,15},{36,39,15}},
}

function Draw.drawing(name,x,y)
	if drawings[name] == nil then 
		print("no name "..name)
		do return end
	end
	for _,p in ipairs(drawings[name]) do
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
	Draw.circle_with_arc(23+40*(track.i-1),26,12.5,0.25)
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