-- rc505


local Formatters=require 'formatters'
draw = include("rc505/lib/draw")
lattice = include("rc505/lib/lattice")
utils = include("rc505/lib/utils")

-- state 
track = {}
clk = {}
ti = 1 -- track selected
shifted = false -- shift activated
update_ui = false
lattice_timing=nil

-- constants
track_buffer = {
  {buffer=1,start=10},
  {buffer=1,start=130},
  {buffer=2,start=10},
  {buffer=1,start=1},
  {buffer=1,start=120},
  {buffer=2,start=1},
}
divisions_available = {"1/64","1/32","1/16","1/8","1/4","1/2","1"}


function init()
  -- turn down sensitivity
  norns.enc.sens(1,4)

  for i=1,3 do 
    track[i] = {}
    track[i].beat_sync = 1 
    track[i].beat_effect = 1
    track[i].division_sync = 1/16
    track[i].division_effect = 1/16
    track[i].arm_start_rec = false 
    track[i].arm_start_play = false 
    track[i].arm_start_effect = false
    track[i].arm_stop_rec = false 
    track[i].arm_stop_play = false 
  end

  -- setup clocks for the divisions
  lattice_timing = lattice:new()
  for i,division in ipairs(divisions_available) do 
    division = utils.tonumber(division)
    print("clock on "..division)
    clk[i] = lattice_timing:new_pattern{
      action = function(t)
        clock_tick(division,t,i)
      end,
      division=division,
      enabled = true,
    }
  end
  lattice_timing:start()


  -- initialize refresh timer
  timer=metro.init()
  timer.time=clock.get_beat_sec()/4
  timer.count=-1
  timer.event=refresh
  timer:start()

  -- setup parameters
  setup_parameters()

  --setup softcut
  reset_softcut()
end

function refresh()
  redraw()
end

function key(k,z)
  if k==1 then 
    shifted = z==1
  elseif k==2 and z==1 and shifted then 
    params:set(ti.."playing",0)
  elseif k==2 and z==1 then 
    if params:get(ti.."is_empty") == 1 then 
      print(ti.." arming to play and record")
      track[ti].arm_start_play = true 
      track[ti].arm_start_rec = true 
    elseif params:get(ti.."recording") == 1 then 
      print(ti.." arming to stop rec and play")
      track[ti].arm_stop_rec = true
    elseif params:get(ti.."playing") == 1 then 
      print(ti.." arming to rec")
      track[ti].arm_start_rec = true
    elseif params:get(ti.."playing") == 0 then 
      print(ti.." arming to play")
      track[ti].arm_start_play = true
    end
  elseif k==3 then 
    params:set(ti.."effect",z)
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
      beat_current=math.floor(track[i].beat_sync),
      progress=(track[i].beat_sync-1)/params:get(i.."beats"),
      is_empty=params:get(i.."is_empty")==1,
    })
  end

	screen.update()
end

function clock_tick(division,t,clock_i)
  for i=1,3 do 
    -- update clock
    if params:get(i.."playing")==1 then 
      if division==track[i].division_sync then 
        track[i].beat_sync = track[i].beat_sync + 4*track[i].division_sync
        if track[i].beat_sync > params:get(i.."beats")+0.99 and params:get(i.."beats") > 0 then 
          -- reset any tracks that need reset
          track[i].beat_sync = 1 
          softcut.position(i,track_buffer[i].start)
          -- if params:get(i.."recording") == 1 then 
          --   params:set(i.."recording",0)
          -- end
        end
      end
      if division==track[i].division_effect then 
        track[i].beat_effect = track[i].beat_effect + 4*track[i].division_effect
        if track[i].beat_effect > params:get(i.."beats")+0.99 and params:get(i.."beats") > 0 then 
          track[i].beat_effect = 1 
        end
        if track[i].arm_start_effect then 
          track[i].arm_start_effect = false
          softcut.level_cut_cut(i+3,i,1)
          softcut.position(i+3,track_buffer[i+3].start)
          softcut.level(i,0)
          softcut.level(i+3,params:get(i.."level"))
        end
      end
    end
    -- check whether anything is armed
    if division == track[i].division_sync and track[i].arm_start_play then
      params:set(i.."playing",1)
    end
    if division == track[i].division_sync and track[i].arm_start_rec then 
      params:set(i.."recording",1)
    end
    if division == track[i].division_sync and track[i].arm_stop_play then 
      params:set(i.."playing",0)
    end
    if division == track[i].division_sync and track[i].arm_stop_rec then 
      params:set(i.."recording",0)
    end
  end

  -- if division equals track division and is beat repeating, do something
  -- -- TODO: disable division if there are not tracks needing it anymore
  -- for i=1,3 do 
  --   has_division = false
  --   if tonumber(params:get(i.."effect division"))==division then 
  --     has_division = true
  --   end
  --   if not has_division and division ~= 1/4 then 
  --     clk[clock_i]:stop()
  --   end
  -- end
end

function setup_parameters()
  print("setup_parameters")
  -- parameters for softcut loops
  params:add_separator("tracks")
  for i=1,3 do
    params:add_group("track "..i,12)
    params:add_option(i.."sync division","sync division",divisions_available,3)
    params:set_action(i.."sync division",function(value)
      print(i.."sync division: "..divisions_available[value])
      track[i].division_sync = utils.tonumber(divisions_available[value])
    end)
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
      track[i].division_effect = utils.tonumber(divisions_available[value])
    end)
    params:add {type="control",id=i.."pre level",name="pre level",controlspec=controlspec.new(0,1.0,'lin',0.01,1.0,''),
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
        if track[i].arm_stop_play then
          track[i].arm_stop_play = false 
        end
        if track[i].arm_start_play then
          track[i].arm_start_play = false 
        end
        softcut.play(i,value)
        track[i].beat_sync = 1
        track[i].beat_effect = 1
        softcut.position(i,track_buffer[i].start)
        if value == 0 then 
          params:set(i.."recording",0)
        end
      end
    }
    params:add{type='binary',name="recording",id=i..'recording',behavior='toggle',
      action=function(value)
        print(i.."recording: "..value)
        if track[i].arm_stop_rec then
          track[i].arm_stop_rec = false 
        end
        if track[i].arm_start_rec then
          track[i].arm_start_rec = false 
        end
        softcut.rec(i,value)
        softcut.rec_level(i,value)
        if value == 0 then 
          -- set the loop end? 
          -- TODO: is this supposed to be on the beat?
          -- question: if its free, is the new loop from when you started and when you stopped the recording?
        else 
          params:set(i.."is_empty",0)
        end
      end
    }
    params:add{type='binary',name="effect",id=i..'effect',behavior='toggle',
      action=function(value)
        print(i.."effect: "..value)
        if value==1 then 
          -- prep for the effect
          -- copy the buffer over
          print(track[i].beat_effect)
          local start = track_buffer[i].start+track[i].beat_effect*clock.get_beat_sec()
          local length = track[i].division_effect*4*clock.get_beat_sec()
          softcut.buffer_copy_mono(track_buffer[i].buffer,track_buffer[i].buffer,start,track_buffer[i+3].start,length,0,0)
          softcut.loop_start(i+3,track_buffer[i+3].start)
          softcut.loop_end(i+3,track_buffer[i+3].start+length)
          track[i].arm_start_effect = true -- start it on the beat
        else
          softcut.level(i,(1-value)*params:get(i.."level"))
          softcut.level(i+3,value*params:get(i.."level"))
          softcut.level_cut_cut(i+3,i,value)
        end
      end
    }
    params:add{type='binary',name="is_empty",id=i..'is_empty',behavior='toggle',
      action=function(value)
        print(i.."is_empty: "..value)
      end
    }
    params:hide(i.."is_empty")
    params:set(i.."is_empty",1)
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
      softcut.buffer(i,track_buffer[i].buffer)
      softcut.level(i,params:get(j.."level"))
      softcut.rate(i,params:get(j.."rate"))
      softcut.pan(i,params:get(j.."pan"))
      softcut.play(i,0)
      softcut.loop_start(i,track_buffer[i].start)
      softcut.loop(i,1)
      softcut.level_slew_time(i,0.01)
      softcut.rate_slew_time(i,0.4)
      softcut.pan_slew_time(i,0.4)
      softcut.recpre_slew_time(i,0.4)
      softcut.rec_level(i,0.0)
      softcut.position(i,track_buffer[i].start)
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

    softcut.loop_end(j,track_buffer[j].start+120)
    softcut.loop_end(j+3,track_buffer[j+3].start+9)

    softcut.play(j+3,1)
    softcut.level(j+3,0)

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
    softcut.pre_level(j,params:get(j.."pre level"))
    softcut.pre_level(j+3,1.0)  
  end
  softcut.poll_start_phase()
  audio.level_adc_cut(1)
end


function clock.transport.start()
  if lattice_timing ~= nil then
    lattice_timing:hard_sync()
  end
end