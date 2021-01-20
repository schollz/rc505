-- rc505


local Formatters=require 'formatters'
draw = include("rc505/lib/draw")
lattice = include("rc505/lib/lattice")
utils = include("rc505/lib/utils")

-- state 
tracks = {}
clocks = {}
ti = 1 -- track selected
shifted = false -- shift activated

-- constants
track_buffer = {
  {buffer=1,start=5},
  {buffer=1,start=130},
  {buffer=2,start=5},
}
divisions_available = {"1/64","1/32","1/16","1/8","1/4","1/2","1"}


function init()
  -- turn down sensitivity
  norns.enc.sens(1,4)

  for i=1,3 do 
    tracks[i] = {}
    tracks[i].beat = 1 
    tracks[i].division = 1/4
  end

  -- setup clocks for the divisions
  lattice_timing = lattice:new()
  for i,division in ipairs(divisions_available) do 
    clocks[i] = lattice_timing:new_pattern{
      action = function(t)
        clock_tick(division,t,i)
      end,
      enabled = division==1/4 -- only enable quarter-note, fx enable others
    }
  end


  -- initialize refresh timer
  timer=metro.init()
  timer.time=0.05
  timer.count=-1
  timer.event=refresh
  timer:start()

  -- setup parameters
  setup_parameters()
end

function refresh()

  redraw()
end

function key(k,z)
  if k==1 then 
    shifted = z==1
  end
end


function enc(k,d)
  if k==1 then 
    ti = utils.sign_cycle(ti,d,1,3)
  elseif k==2 then 
    params:delta(ti.."level",d)
  elseif k==3 then 
    params:delta(ti.."effect division",d)
  end
end

function redraw()
	screen.clear()

  -- draw track information
  for i=1,3 do 
    Draw.track({
      i=i,
      selected=ti==i,
      level=params:get(i.."level"),
      playing=params:get(i.."playing")==1,
      recording=params:get(i.."recording")==1,
      beat_repeat=params:get(i.."effect type")==1,
      beat_shuffle=params:get(i.."effect type")==2,
      division=divisions_available[params:get(i.."effect division")],
      beat_total=params:get(i.."beats"),
      beat_current=tracks[i].beat,
    })
  end

	screen.update()
end

function clock_tick(division,t,clock_i)
  if division==1/4 then 
    for i=1,3 do 
      if params:get(i.."playing")==1 then 
        -- update all the track beat numbers
        track[i].beat = track[i].beat + 1 
        if track[i].beat > params:get(i.."beats") and params:get(i.."beats") > 0 then 
          -- reset any tracks that need reset
          track[i].beat = 1 
          softcut.position(i,track_buffer[i].start)
        end
      end
    end
    -- TODO update the screen
  end
  -- if division equals track division and is beat repeating, do something
  -- -- TODO: disable division if there are not tracks needing it anymore
  -- for i=1,3 do 
  --   has_division = false
  --   if tonumber(params:get(i.."effect division"))==division then 
  --     has_division = true
  --   end
  --   if not has_division and division ~= 1/4 then 
  --     clocks[clock_i]:stop()
  --   end
  -- end
end

function setup_parameters()
  print("setup_parameters")
  -- parameters for softcut loops
  params:add_separator("tracks")
  for i=1,3 do
    params:add_group("track "..i,11)
    params:add {type="control",id=i.."level",name="level",controlspec=controlspec.new(0,1.0,'lin',0.01,0.5,''),
      action=function(value)
        print(i.."level: "..value)
        softcut.level(i,value)
        softcut.level(i+3,value)
      end
    }
    params:add {type="control",id=i.."pan",name="pan",controlspec=controlspec.new(-1,1.0,'lin',0.01,0.0,''),
      action=function(value)
        print(i.."pan: "..value)
        softcut.pan(i,value)
        softcut.pan(i+3,value)
      end
    }
    params:add {type="control",id=i.."rate",name="rate",controlspec=controlspec.new(-2,2.0,'lin',0.01,1.0,''),
      action=function(value)
        print(i.."rate: "..value)
        softcut.rate(i,value)
        softcut.rate(i+3,value)
      end
    }
    params:add {type="control",id=i.."beats",name="beats",controlspec=controlspec.new(0,128,'lin',1,4,'beats'),
      action=function(value)
        print(i.."beats: "..value)
        if value > 0 then 
          softcut.loop_end(i,track_buffer[i].start+clock.get_beat_sec()*value)
        else
          softcut.loop_end(i,track_buffer[i].start+120) -- loop end will be set when recording is turned off
        end
      end
    }
    params:add_option(i.."effect type","effect type",{"repeat","shuffle"},1)
    params:add_option(i.."effect division","effect division",divisions_available,3)
    params:set_action(i.."effect division",function(value)
      print(i.."effect division: "..divisions_available[value])
      -- enable this division on the clocks
      clocks[i]:start()
    end)
    params:add {type="control",id=i.."pre",name="pre rec",controlspec=controlspec.new(0,1.0,'lin',0.01,1.0,''),
      action=function(value)
        softcut.pre_level(i,value)
      end
    }
    params:add {type='control',id=i..'filter_frequency',name='filter cutoff',controlspec=controlspec.new(20,20000,'exp',0,20000,'Hz',100/20000),formatter=Formatters.format_freq,
      action=function(value)
        softcut.post_filter_fc(i,value)
        softcut.post_filter_fc(i+3,value)
      end
    }
    params:add{type='binary',name="playing",id=i..'playing',behavior='toggle',
      action=function(value)
        print(i.."playing: "..value)
        -- TODO: start playing on the beat if synced
        softcut.play(i,value)
        if value==1 then 
          track[i].beat = 1
          softcut.position(i,track_buffer[i].start)
        end
      end
    }
    params:add{type='binary',name="recording",id=i..'recording',behavior='toggle',
      action=function(value)
        print(i.."record: "..value)
        softcut.rec_level(i,value)
        if value == 0 then 
          -- set the loop end? 
          -- TODO: is this supposed to be on the beat?
          -- question: if its free, is the new loop from when you started and when you stopped the recording?
        end
      end
    }
    params:add{type='binary',name="effect",id=i..'effect',behavior='toggle',
      action=function(value)
        print(i.."effect: "..value)
        -- TODO toggle effect
      end
    }
  end
end




function reset_softcut()
  print("reset_softcut")
  softcut.reset()
  softcut.buffer_clear()
  for j=1,3 do
    -- these are the same for main and feedback loop
    for i=j,j+3,3 do 
      softcut.enable(i,1)
      softcut.buffer(i,track_buffer[j].buffer)
      softcut.level(i,params:get(j.."level"))
      softcut.rate(i,params:get(j.."rate"))
      softcut.pan(i,params:get(j.."pan"))
      softcut.play(i,1)
      softcut.loop_start(i,track_buffer[j].start)
      softcut.loop_end(i,track_buffer[j].start+120)
      softcut.loop(i,1)
      softcut.level_slew_time(i,0.4)
      softcut.rate_slew_time(i,0.4)
      softcut.rec_level(i,0.0)
      softcut.position(i,track_buffer[j].start)
      softcut.phase_quant(i,0.025)
      softcut.post_filter_dry(i,0.0)
      softcut.post_filter_lp(i,1.0)
      softcut.post_filter_rq(i,1.0)
      softcut.post_filter_fc(i,params:get(j..'filter_frequency'))
      softcut.pre_filter_dry(i,1.0)
      softcut.pre_filter_lp(i,1.0)
      softcut.pre_filter_rq(i,1.0)
      softcut.pre_filter_fc(i,20100)    
    end

    -- main loop listens to input
    softcut.level_input_cut(1,j,1)
    softcut.level_input_cut(2,j,1)
    -- no input into feedback loop
    softcut.level_input_cut(1,j+3,0)
    softcut.level_input_cut(2,j+3,0)

    -- only main loop records
    softcut.rec(j,1)
    softcut.rec(j+3,0)

    -- only main loop sets pre record feedback?
    softcut.pre_level(j,params:get(i.."pre"))
    softcut.pre_level(j+3,1.0)  
  end
end