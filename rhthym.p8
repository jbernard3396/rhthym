pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
//system core loop
function _init()
 create_game_manager()
 create_color_manager()
 
end

function _update60()
 gm.update()
 cm.update()
end

function _draw()
 cls()
 gm.draw()
 cm.draw()
end
-->8
//game

function create_game_manager()
 gm = {}
 gm.state = 'menu'
 gm.song = 1
 gm.menu_manager = create_menu_manager()
 gm.game_player = create_game_player()
 gm.start_game = function()
  gm.game_player.instantiate()
  gm.state = 'game'
 end
 gm.update = function()
  if gm.state == 'menu' then
   gm.menu_manager.update()
  elseif gm.state == 'game' then
   gm.game_player.update()
  elseif gm.state == 'over' then
   game_controler.standard()
   if btn(❎) then
    height = start_height
    music(-1,1000)
    _init()
   end
   if btn(🅾️) then
    height = start_height
    music(-1,1000)
    local song = gm.song
    _init()
    music(-1,0)
    gm.song = song
    gm.start_game()
   end
  end
 end
 gm.draw = function()
  if gm.state == 'menu' then
   gm.menu_manager.draw()
  elseif gm.state == 'game' then
   gm.game_player.draw()
  elseif gm.state == 'over' then
   gm.game_player.draw()
   if score_keeper.score > songs[gm.song].hs then
    songs[gm.song].hs = score_keeper.score
   end
   if gm.result == 'death' then
    print('dead: '..gm.death_reason, 28, 20, 7) 
    print('score: '..score_keeper.score, 28, 28, 7)
    print('press c to try again', 28, 44, 7)
	   print('press x to return to menu', 28, 52, 7)
   else //success
    print('congratulations', 28, 20, gm.result_color) 
    print('score: '..flr(score_keeper.score), 28, 28, gm.result_color)
    print('misses: '.. score_keeper.misses, 28,36, gm.result_color) 
    print('bads: '..score_keeper.bads, 28, 44, gm.result_color) 
    print('oks: '..score_keeper.oks, 28, 52, gm.result_color) 
    print('goods: '..score_keeper.goods, 28,60, gm.result_color) 
    print('greats: '..score_keeper.greats, 28, 68, gm.result_color) 
    print('press c to try again', 28, 84, gm.result_color)
    print('press x to return to menu', 28, 92, gm.result_color)
   end
  end
 end
end


-->8
//menu manager
function create_menu_manager()
	if not highscore then
		highscore = 0
	end
 menu = {}
 menu.index = 2
 menu.x_pos = 64
 menu.y_pos = 120
 menu.options = {}
 music(8)
 add(menu.options, play_option())
 add(menu.options, song_option())
 menu.update = function()
  //if btnp(2) then
  // menu.index -= 1
  //elseif btnp(3) then
  // menu.index += 1
  if btnp(1) then
   if menu.options[menu.index].increment then
    menu.options[menu.index].increment(1)
   end
  elseif btnp(0) then
   if menu.options[menu.index].increment then
    menu.options[menu.index].increment(-1)
   end
  elseif btnp(5) then
   music(-1, 1000)
   gm.start_game()
   //menu.options[menu.index].action()
  end
   menu.index = mod_1(menu.index, #menu.options)
 end
 menu.draw = function()
  local x_mid = menu.x_pos
  local y_mid = menu.y_pos
  local line_height = 10
  local char_height = 6
  local char_width = 4
  local y_start = y_mid - (char_height+(line_height*#menu.options))/2
  local y_cur = y_start
  local x_cur
  for i = 0, 16 do
   for j = 0, 16 do
 	  local this_y = i*16
 	  local this_x = j*16
  	 local pixels_unlit = max(min(height-this_y, 16), 0)
  		spr(34, this_x, this_y, 2, 2)
    spr(32, this_x, this_y, 2, pixels_unlit/8)
   end
  end
  spr(68, 15, 64, 2, 2) //r
  spr(72, 31, 64, 2, 2) //h
  spr(70, 47, 64, 2, 2) //y
  spr(74, 63, 64, 2, 2) //t
  spr(72, 79, 64, 2, 2) //h
  spr(76, 95, 64, 2, 2) //m
  for i = 1, #menu.options do
   string = menu.options[i].get_draw()
   string_color = menu.options[i].get_color()
   x_cur =  x_mid-(#string*char_width)/2
   print(string, x_cur, y_cur, string_color)
   if (menu.index == i) then
    //rect(x_cur-2, y_cur-2, x_cur+(char_width*#string), y_cur+char_height, cm.get('extra_1'))
   end
   y_cur+=line_height
  end
 end
 return menu
end

function color_scheme_option()
 local item = {}
 item.get_draw = function()
  return 'color_scheme: '..cm.get_scheme_name()
 end
 item.get_color = function()
  return cm.get('primary_1')
 end
 item.action = function()
  cm.iterate_scheme()
 end
 return item
end

function play_option()
 local item = {}
 item.timer = 0
 item.display = true
 item.get_draw = function()
  item.timer +=1
  if (item.timer == 30) then
   item.display = not item.display
   item.timer = 0
  end
  if (item.display == false) then
   return ''
  end
  return '(press ❎ to start)'
 end
 item.get_color = function()
  return cm.get('extra_3')
 end
 item.action = function()
  
  gm.start_game()
 end
 return item
end

function song_option()
 local num_songs = #song_list()
 local item = {}
 item.song = 1
 item.timer = 0
 item.display = true
 item.get_draw = function()
  item.song_object = song_list()[item.song]
  highscore = item.song_object.hs
  print("highscore: "..flr(highscore), 2, 2, 9) 
 	return 'song '.. item.song ..': ' .. item.song_object.difficulty
 end
 item.get_color = function()
  return cm.get('extra_3')
 end
 item.update = function()
 	highscore = songs[gm.song].hs
 end
 item.increment = function(x)
  item.song += x
  item.song = mod_1(item.song, num_songs)
  gm.song = item.song
 end
 return item
end
-->8
//game_player
start_height = 76
height = start_height
perfect_height = 110
rows = {25,45,65,85}
color_rows = {false, false, false, false}
song = 21
function create_game_player()
 gp = {}
 gp.workers = {}
 add(gp.workers, create_game_controler())
 add(gp.workers, create_timer())
 add(gp.workers, create_player())
 add(gp.workers, create_arrow_keeper())
 add(gp.workers, create_score_keeper())
 add(gp.workers, create_music_player())
 add(gp.workers, create_health_manager())
 add(gp.workers, create_combo_manager())
 gp.update = function()
  for item in all(gp.workers) do
   item.update()
  end
 end
 gp.draw = function()
  for item in all(gp.workers) do
   item.draw()
  end
 end
 gp.instantiate = function()
  for item in all(gp.workers) do
   if item.instantiate then
	   item.instantiate()
	  end
  end
 end
 return gp
end

function create_game_controler()
	local this = {}
  this.dark_b_s = 32
  this.light_b_s = 34

  this.dark_r_s = 44
  this.light_r_s = 46

  this.dspr = this.dark_b_s
  this.lspr = this.light_b_s
  
 this.draw = function()
  draw_row(24, 17, height, 5, 6,1, arrow_keeper.row_cols[1], this.dspr, this.lspr)
  draw_row(44, 17, height, 5, 6,2, arrow_keeper.row_cols[2], this.dspr, this.lspr)
  draw_row(64, 17, height, 5, 6,3, arrow_keeper.row_cols[4], this.dspr, this.lspr)
  draw_row(84, 17, height, 5, 6,4, arrow_keeper.row_cols[3], this.dspr, this.lspr)
 end

 this.flip = function()
  if this.dspr == this.dark_b_s then
    this.dspr = this.dark_r_s
    this.lspr = this.light_r_s
  else 
    this.dspr = this.dark_b_s
    this.lspr = this.light_b_s
  end
 end
 
 this.standard = function()
  this.dspr = this.dark_b_s
  this.lspr = this.light_b_s
 end

 this.update = function()
 end
 game_controler = this
 return this
end

function create_timer()
 local this = {}
 this.notes = {}
 this.space_between_notes = 0
 this.song_to_play = {}
 this.instantiate = function()
  this.song_to_play = song_list()[gm.song]
  this.notes = this.song_to_play.get_notes()
  this.space_between_notes = this.song_to_play.tempo
 end
 
 this.external_time = 0
 this.internal_time = 0
 this.draw = function() 
  --print(this.external_time, 120, 0, cm.get('secondary_1'))
 end
 this.update = function()
  this.internal_time += 1
  if this.internal_time >= this.space_between_notes then
   this.internal_time = 0
   this.external_time += 1	
   if mod(this.external_time, 2) == 0 and combo_manager.get_combo() == 4 then
      game_controler.flip()
   end
   local this_next = tostr(next(this.notes))
   if this_next == -1 then
   	return
   end
   this_dir1 = tonum(sub(this_next,1,1))
   arrow_keeper.generate_arrow(this_dir1)
   if(#this_next > 1) then
	   this_dir2 = tonum(sub(this_next,2,2))
 	  arrow_keeper.generate_arrow(this_dir2)
 	 end
 	 if(#this_next > 2) then
	   this_dir3 = tonum(sub(this_next,3,3))
 	  arrow_keeper.generate_arrow(this_dir3)
 	 end

   
  end
 end
 timer = this
 return this
end

function create_health_manager()
 local this = {}
 this.max_hp = 10
 this.hp = 10
 this.instantiate = function()
  this.hp = this.max_hp
 end
 this.draw = function()
  //rect(0,20,14,30,1)
  //rectfill(2, 22, 2+this.hp, 28, 12)
 end
 
 this.update = function()
   height = start_height + ((124-start_height) * ((this.max_hp - this.hp)/this.max_hp))
 end
 
 this.miss = function()
  this.hp -= 1
  if this.hp <= 0 then
   gm.result = 'death'
   gm.death_reason = 'missed'
   gm.state = 'over'
   music(-1, 2000)
  end
 end

 function create_combo_manager()
  local this = {}
  this.combo = 1
  this.sub_combo = 0
  
  this.set_max = function()
   this.max_sub = this.combo * 30
  end
  
  this.set_max()

  this.increment_combo = function(points)
   this.sub_combo += points
   if this.sub_combo >= this.max_sub then
    if this.combo < 4 then
      this.sub_combo = 0
      this.combo += 1
      this.set_max()
    else 
      this.sub_combo = this.max_sub
    end
   end
  end

  this.kill_combo = function()
    if this.sub_combo > 0 then
     this.sub_combo = 0
    elseif this.combo > 1 then
      this.combo -= 1
      this.set_max()
    end
    
    if this.combo < 4 then
    	game_controler.standard()
    end
  end

  this.update = function()

  end
  this.get_combo = function()
   return this.combo
  end

  this.draw = function()
   this.draw_color = 8
   if this.combo == 4 then
    this.draw_color = 10
   end
    print('combo:', 104, 100, this.draw_color)
    print('x'..this.combo, 104, 106, this.draw_color)
    rect(104,114,124,124,1)
    rectfill(106, 116, 106+(convert_range(this.sub_combo, 0, this.max_sub, 0, 16)), 122, 12)
  end
  combo_manager = this
  return this
 end
 
 this.success = function(level)
  this.hp += level/10
  if this.hp > this.max_hp then
   this.hp = this.max_hp
  end
 end
 health_manager = this
 return this
end

function create_player()
 local this = {}
 this.update = function()
  if(btnp(⬅️)) then
   this.beat('left')
  end
  if(btnp(➡️)) then
   this.beat('right')
  end
  if(btnp(⬆️)) then
   this.beat('up')
  end
  if(btnp(⬇️)) then
   this.beat('down')
  end
 end
 this.beat = function(direction)
  local dir_num = get_dir_num(direction)
  if arrow_keeper.row_proximities[dir_num]<6 and arrow_keeper.closest_arrows[dir_num] then
   arrow_keeper.closest_arrows[dir_num].poof()
   color_rows[dir_num] = true
  elseif score_keeper.score >= 1 then	
   combo_manager.kill_combo()
   health_manager.miss()
  end
 end
 this.draw = function()
 end
 return this
end

function create_score_keeper()
 local this = {}
 this.last_status = ''
 this.score = 0
 this.misses = 0
 this.bads = 0
 this.oks = 0
 this.goods = 0
 this.greats = 0	
 this.draw = function()
  print(flr(this.score),0,120,cm.get('secondary_1'))
  //print(this.last_status, 0, 120, 7)
 end
 this.increment_score = function(score)
  health_manager.success(score) 
  combo_manager.increment_combo(score)
  this.score += score*combo_manager.get_combo() or 1
  if score <= 1 then
   this.bads += 1
   this.last_status = 'bad'
   this.last_status_color = 8
  elseif score <= 3 then
   this.oks += 1
   this.last_status = 'ok'
   this.last_status_color = 9
  elseif score <= 6 then
   this.goods += 1
   this.last_status = 'good'
   this.last_status_color = 10
  elseif score <= 7 then
   this.greats += 1
   this.last_status = 'great'
   this.last_status_color = 14
  end 
  if this.score > highscore then
  	highscore = this.score
  end
  return {this.last_status, this.last_status_color}
 end
 this.update = function()

 end
 score_keeper = this
 return this
end

function create_arrow_keeper()
 local this = {}
 this.closest_arrows={}
 this.row_cols={7, 7, 7, 7}
 this.row_proximities={-1,-1,-1,-1}
 this.arrows = {}
 this.draw = function()
  for arrow in all(this.arrows) do
   arrow.draw()
  end
 end
 this.update = function()
  this.row_proximities={-1,-1,-1,-1}
  for arrow in all(this.arrows) do 
   arrow.update()  
   if not arrow.is_poof then
    if (this.row_proximities[arrow.row] == -1) or (arrow.prox < this.row_proximities[arrow.row]) then
      this.row_proximities[arrow.row] = arrow.prox
      this.closest_arrows[arrow.row] = arrow
    end
   end
  end
  this.get_arrow_cols()
 end
 this.get_arrow_cols = function()
  for i=1, 4 do
   this.row_cols[i] = 7
   if this.row_proximities[i] <= 6 and this.row_proximities[i] > -1then
    this.row_cols[i] = 9
   end
   if this.row_proximities[i] <= 2 and this.row_proximities[i] > -1then
    this.row_cols[i] = 10
   end 
  end
 end
 this.generate_arrow = function(direction)
  local a = nil
  //dir_num = get_dir_num(direction)
  
  dir_num = tonum(direction)
  if dir_num == 0 or dir_num == nil then
   return
  end
  //todo: alot of row data can be figured in arrow
  a = create_arrow(rows[dir_num], ((dir_num-1)*4), ((dir_num-1)*4)+2, dir_num)
  add(this.arrows, a)
 end
 arrow_keeper = this
 return this
end

function create_arrow(x, s1, s2, row)
 local this = {}
 this.x = x
 this.y = -16
 this.x_speed = 0
 this.y_speed = 0
 this.row = row
 this.s1 = s1
 this.s2 = s2
 this.life_time = 50
 this.status = ''
 this.is_poof = false
 this.poof = function()
  this.is_poof = true
  this.x_speed = rand_int(-10,10)/10
  this.y_speed = rand_int(-10,0)/5
  this.status = score_keeper.increment_score(7-this.prox)
 end
 this.prox = abs(perfect_height-this.y)
 this.draw = function()
  if not(this.is_poof) then
   draw_arrow(this.s1, this.s2, this.x, this.y, height)
  else 
   print(this.status[1], this.x, this.y, this.status[2])
  end
 end
 this.update = function()
  if this.life_time <= 0 then
   del(arrow_keeper.arrows, this)  
  end
  if this.is_poof then
   this.life_time-=1
   this.x = this.x + this.x_speed 
   this.y = this.y + this.y_speed
   this.y_speed += .1
  else
   this.y += .5
   this.prox = abs(perfect_height-this.y)
  end
  if this.y == 124 then
   health_manager.miss()
   combo_manager.kill_combo()
   score_keeper.misses += 1
  end
 end
 return this
end


function create_music_player()
 local this = {}
 this.song_to_play = {}
 this.song_length = 0
 this.instantiate = function()
  this.song_to_play = song_list()[gm.song]
  this.song_length = #this.song_to_play.get_notes() + this.song_to_play.start+5
 end
	local song_on = false
	this.draw = function()
	 //sfx(2)
	end
	this.update = function()
  	if (timer.external_time >= this.song_length) then
			 gm.result = 'success'
			 gm.result_color = 7
			 gm.death_reason = 'congratulations'
			 if score_keeper.misses == 0 then
			  gm.death_reason = 'perfect'
			  gm.result_color = 10
			 end
			 gm.state = 'over'
			end
	  if (song_on) then
	   return
	  end
	  if (timer.external_time >= this.song_to_play.start) then
		  song_on = true
		  music(this.song_to_play.song)
			end	
	end
	return this
end
-->8
function draw_row(x, w, h, c1, c2, row, col, s1, s2)
 draw_dots(x, h, s1, s2)
 line(x,0,x,h,c1)
 line(x+w,0,x+w,h,c1)
 line(x,h,x,128,c2)
 line(x+w,h,x+w,128,c2)
 if not color_rows[row] then
  col = 7
 end
 sprite_color(36-2+(2*row), x+1, perfect_height,2, col)
 color_rows[row] = false
end

function draw_dots(x, h, s1, s2)
 if h == nil then
  h = 72
 end
 for i = 0, 16 do
  local this_y = i*16
  local pixels_unlit = max(min(h-this_y, 16), 0)
 	 spr(s2, x+1, this_y, 2, 2)
   spr(s1, x+1, this_y, 2, pixels_unlit/8)
 end
end

function draw_arrow(s1, s2, x, y, h)
 if h == nil then
  h = 72
 end
 local pixels_unlit = max(min(h-y, 16), 0)
 spr(s2, x, y, 2, 2)
 spr(s1, x, y, 2, pixels_unlit/8)
end

function next(array)
 local return_value = array[1]
 if return_value == nil then
  return 0
 end
 del(array, array[1])
 return return_value
end

function frames_till_perfect()
 local start_point = -16
 local end_point = perfect_height
 local speed = .5
 local total_frames = (end_point-start_point)/speed 
 return total_frames
end

-->8
//domain agnostic helpers

function mod(a, b) 
 return a - (flr(a/b)*b)
end

function mod_1(a, b)
 local result = mod(a,b)
 if result == 0 then
  result = b
 end
 return result
end

function wrap(int)
 if int > 128 then
  int = 0
 end
 if int < 0 then
  int = 128
 end
 return int
end

function pick(list)
 return list[rand_int(1, #list)]
end

function rand_int(lo,hi)
 return flr(rnd(hi-lo+1))+lo
end

function sqr(x)
 return x*x
end

function point_in_circle(blt, atd)
 return sqr(atd.x - blt.x)+sqr(atd.y-blt.y) <= sqr(atd.size)
end

function sprite_color(n, x, y, num, override_color)
 if not num then
  num = 1
 end
 local beginning_row = mod(n,16)*8
 local beginning_col = flr(n/16)*8
 for i = 0, 8*num-1 do
  for j = 0, 8*num-1 do
   this_color = sget(beginning_row+i, beginning_col+j) 
   this_name = cm.get_color_name(this_color)
   this_new_color = cm.get(this_name)
   if this_new_color == nil then
   else
    if this_color != nil and override_color then
     this_new_color = override_color
    end
			 pset(i+x, j+y, this_new_color)   
			end
  end
 end
end

function magnitude(vec)
 return sqrt(sqr(vec[1])+sqr(vec[2]))
end

function pi()
 return 3.14
end

function distance(x1, y1, x2, y2)
 return sqrt(sqr(x1-x2)+sqr(y1-y2))
end

function magnitude(vec)
 return sqrt(sqr(vec[1])+sqr(vec[2]))
end

function asin(y)
 return atan2(sqrt(1-y*y),-y)
end

function dot(v1, v2)
 return (v1[1]*v2[1]) + (v1[2]*v2[2])
end

function get_dir_vec(direction)
	if direction == "left" then
		return {-1, 0}
	end
	if direction == "up" then
		return {0, -1}
	end
	if direction == "right" then
		return {1, 0}
	end
	if direction == "down" then
		return {0, 1}
	end
end

function get_dir_num(direction)
	if direction == "left" then
		return 1
	end
	if direction == "up" then
		return 2
	end
	if direction == "down" then
		return 3
	end
	if direction == "right" then
		return 4
	end
end

function convert_range(num, r_0_min, r_0_max, r_1_min, r_1_max)
 if num < r_0_min then
  num = r_0_min
 end
 if num > r_0_max then
  num = r_0_max
 end
 local diff_0 = r_0_max - r_0_min
 local diff_1 = r_1_max - r_0_min
 local multiplier = diff_1/diff_0
 local final_num = num*multiplier
 return final_num
end
-->8
//color manager
function create_color_manager()
 cm = {}
 cm.options = {}
 add(cm.options, create_full_color())
 add(cm.options, create_gray_scale())
 add(cm.options, create_blinding())
 add(cm.options, create_pleasant())
 cm.scheme = 1
 cm.iterate_scheme = function()
  cm.scheme += 1
  cm.scheme = mod_1(cm.scheme, #cm.options)
 end
 cm.get_scheme_name = function()
  return cm.options[cm.scheme].name
 end
 cm.get = function(color_name) 
  return cm.options[cm.scheme][color_name]
 end
 cm.get_color_name = function(color_number)
  for k, v in pairs(cm.options[1]) do
   if v == color_number then
    return k
   end
  end
 end
 cm.update = function()
 
 end
 cm.draw = function()
 
 end
end

function create_full_color()
 color_scheme = {}
 color_scheme.name = 'full_color'
 color_scheme['primary_1'] = 15
 color_scheme['primary_2']= 3
 color_scheme['primary_3'] = 2
 color_scheme['secondary_1'] = 7
 color_scheme['secondary_2'] = 11
 color_scheme['secondary_3'] = 14
 color_scheme['extra_1'] = 8
 color_scheme['extra_2'] = 12
 color_scheme['extra_3'] = 10
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_gray_scale()
 color_scheme = {}
 color_scheme.name = 'gray_scale'
 color_scheme['primary_1'] = 6
 color_scheme['primary_2'] = 5
 color_scheme['primary_3'] = 0
 color_scheme['secondary_1'] = 6
 color_scheme['secondary_2'] = 5
 color_scheme['secondary_3'] = 0
 color_scheme['extra_1'] = 7
 color_scheme['extra_2'] = 6
 color_scheme['extra_3'] = 5
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_blinding()
 color_scheme = {}
 color_scheme.name = 'blinding'
 color_scheme['primary_1'] = 10
 color_scheme['primary_2']= 12
 color_scheme['primary_3'] = 8
 color_scheme['secondary_1'] = 9
 color_scheme['secondary_2'] = 13
 color_scheme['secondary_3'] = 14
 color_scheme['extra_1'] = 11
 color_scheme['extra_2'] = 15
 color_scheme['extra_3'] = 7
 color_scheme['extra_4'] = 6
 return color_scheme
end

function create_pleasant()
 color_scheme = {}
 color_scheme.name = 'pleasant'
 color_scheme['primary_1'] = 4
 color_scheme['primary_2'] = 1
 color_scheme['primary_3'] = 6
 color_scheme['secondary_1'] = 5
 color_scheme['secondary_2'] = 2
 color_scheme['secondary_3'] = 7
 color_scheme['extra_1'] = 13
 color_scheme['extra_2'] = 3
 color_scheme['extra_3'] = 15
 color_scheme['extra_4'] = 0
 return color_scheme
end
-->8

function song_list()
	return songs
end

function song_1_order() 
 local	t = {1,0,2,0,3,0,1,0,3,0,2,0,0,0,0,0,2,0,3,0,4,0,3,0,2,0,1,0,0,0,0,0,1,0,2,0,3,0,4,0,3,0,4,0,0,0,0,0,2,0,3,0,4,0,3,0,1,0,3,0,0,0,0,1,3,2,0,1,3,2,0,1,3,4,0,1,3,4,0,2,4,3,0,2,4,3,0,2,3,2,0,2,3,2,0,1,3,2,0,1,3,2,0,1,3,4,0,1,3,4,0,2,4,3,0,2,4,3,0,2,3,2,0,2,3,2,0,1,3,2,0,1,3,2,0,1,3,4,0,1,3,4,0,2,4,3,0,2,4,3,0,2,3,2,0,2,3,2,0,1,3,2,0,1,3,2,0,1,3,4,0,1,3,4,0,2,4,3,0,2,4,3,0,2,3,2,0,2,3,2,
            2,0,2,0,2,0,2,0,1,0,1,0,2,0,2,0,3,0,3,0,3,0,3,0,4,0,4,0,3,0,3,0,2,0,2,0,2,0,2,0,1,0,1,0,2,0,2,0,4,0,4,0,4,0,4,0,4,0,4,0,4,0,4,0,4,
            1,0,2,0,3,0,1,0,3,0,2,0,0,0,0,0,2,0,3,0,4,0,3,0,2,0,1,0,0,0,0,0,1,0,2,0,3,0,4,0,3,0,4,0,0,0,0,0,2,0,3,0,4,0,3,0,1,0,3}
 //132 132 134 134 243 243 232 232
 return t
end

function song_1_tempo()
	return 15
end

function song_1_start()  
	return 17
end

function song_2_order() 
 local	t = {
            1,0,0,0,2,0,3,0,2,0,0,0,3,0,4,0,3,0,0,0,4,0,0,0,2,0,0,0,1,0,0,0,2,0,0,0,3,0,4,0,1,0,0,0,2,0,3,0,1,0,0,0,2,0,3,0,4,0,3,0,2,0,3,0,
            2,0,0,0,1,0,2,0,3,0,0,0,2,0,3,0,4,0,3,0,2,0,1,0,2,0,0,0,0,0,0,0,2,0,0,0,4,0,0,0,3,0,0,0,1,0,0,0,2,0,0,0,3,0,0,0,2,0,0,0,0,0,0,0,
            2,0,0,0,1,0,2,0,3,0,0,0,2,0,3,0,4,0,3,0,2,0,1,0,2,0,0,0,1,0,0,0,2,0,0,0,4,0,4,0,3,0,0,0,1,0,3,0,2,0,0,0,3,0,3,0,2,0,3,0,2,0,3,0,
            3,0,1,0,1,0,3,0,1,0,1,0,2,0,0,0,3,0,1,0,1,0,3,0,1,0,1,0,4,0,0,0,3,0,1,0,1,0,3,0,1,0,1,0,2,0,0,0,3,0,1,0,1,0,3,0,1,0,1,0,4,0,0,0,
            3,0,1,0,1,0,3,0,1,0,3,0,2,0,1,0,3,0,1,0,1,0,3,0,1,0,4,0,3,0,2,0,3,0,1,0,1,0,3,0,1,0,3,0,1,0,1,0,3,0,1,0,1,0,3,0,4,0,3,0,2,0,0,0,
            
            
             
 }
 
 return t
end

function song_2_tempo()
	return 15
end

function song_2_start()
	return 19
end

function song_3_order()
 local t = {1 ,0,2,0,3,0,4,0,1,0,2,0,3,0,4,0,1 ,0,2,0,4,0,3,0,1 ,0,2,0,4,0,3,0,1 ,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,
   					1 ,0,2,0,3,0,4,0,1,0,2,0,3,0,4,0,1 ,0,2,0,4,0,3,0,1 ,0,2,0,4,0,3,0,1 ,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,
            1 ,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,3 ,0,0,3,0,0,3,0,0 ,3,0,0,3,0,0,3,1 ,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,3,0,0,3,0,0,3,0,0,3,0,0,3,0,0,3,
            1 ,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,3 ,0,0,3,0,0,3,0,0 ,3,0,0,3,0,0,3,1 ,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,3,0,0,3,0,0,3,0,0,3,0,0,3,0,0,3,
            12,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,32,0,0,3,0,0,3,0,4 ,3,0,0,3,0,0,3,14,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,3,0,0,3,0,0,3,0,0,3,0,0,3,0,0,3,
            12,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,32,0,0,3,0,0,3,0,0 ,3,0,0,3,0,0,3,14,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,3,0,0,3,0,0,3,0,0,3,0,0,3,0,0,3,
            4 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2 ,0,0,0,0,0,0,0,1 ,0,0,0,0,0,0,0,3 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            3 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4 ,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,1 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            //14,0,2,0,3,0,4,0,1,0,2,0,3,0,4,0,12,0,2,0,4,0,3,0,12,0,2,0,4,0,3,0,13,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,
   					//13,0,2,0,3,0,4,0,1,0,2,0,3,0,4,0,14,0,2,0,4,0,3,0,1 ,0,2,0,4,0,3,0,12,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,
            1 ,0,2,0,3,0,4,0,1,0,2,0,3,0,4,0,1 ,0,2,0,4,0,3,0,1 ,0,2,0,4,0,3,0,1 ,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,
   					1 ,0,2,0,3,0,4,0,1,0,2,0,3,0,4,0,1 ,0,2,0,4,0,3,0,1 ,0,2,0,4,0,3,0,1 ,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,1,0,3,0,4,0,2,0,
 0}
 return t
end

function song_4_order()
  local t = {
    3, 0, 2, 3, 1, 0, 0, 0, 4, 0, 3, 0, 2, 0, 1, 0, 2, 0, 3, 4, 1, 0, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0,
    3, 0, 2, 3, 1, 0, 0, 0, 4, 0, 3, 0, 2, 0, 1, 0, 2, 0, 3, 4, 1, 0, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0,
    4, 0, 3, 2, 2, 0, 0, 0, 3, 0, 2, 4, 1, 0, 0, 0, 2, 0, 4, 2, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 
    4, 0, 3, 2, 2, 0, 0, 0, 3, 0, 2, 4, 1, 0, 0, 0, 2, 0, 4, 2, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 
    3, 0, 2, 3, 1, 0, 0, 0, 4, 0, 3, 0, 2, 0, 1, 0, 2, 0, 3, 4, 1, 0, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0,
    3, 0, 2, 3, 1, 0, 0, 0, 4, 0, 3, 0, 2, 0, 1, 0, 2, 0, 3, 4, 1, 0, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0,
    4, 0, 3, 2, 2, 0, 0, 0, 3, 0, 2, 4, 1, 0, 0, 0, 2, 0, 4, 2, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 
    4, 0, 3, 2, 2, 0, 0, 0, 3, 0, 2, 4, 1, 0, 0, 0, 2, 0, 4, 2, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0
  }
  return t
end

function song_5_order()
  local t = {
    3,2,4,2,3,2,4,2,3,2,4,2,3,2,4,2, 1,3,2,3,1,3,2,3,1,3,2,3,1,3,2,3,
    3,2,4,2,3,2,4,2,3,2,4,2,3,2,4,2, 3,4,2,4,3,4,2,4,3,4,2,4,3,4,2,4,
    1,2,3,0,0,0,1,2,3,0,0,0,2,3,4,3, 4,3,4,0,1,3,2,3,1,3,2,3,1,3,2,3,
    1,2,3,0,0,0,1,2,3,0,0,0,2,3,4,2, 4,0,0,0,0,0,0,0,3,4,2,4,3,4,2,4,
    1,2,3,0,0,0,1,2,3,0,0,0,2,3,4,3, 4,3,4,0,1,3,2,3,1,3,2,3,1,3,2,3,
    1,2,3,0,0,0,1,2,3,0,0,0,2,3,4,2, 4,0,0,0,0,0,0,0,3,4,2,4,3,4,2,4,

    3,2,3,0,0,0,3,2,3,0,0,0,3,2,3,4, 3,2,1,0,1,3,2,3,1,3,2,3,1,3,2,3,
    3,2,3,0,0,0,3,2,3,0,0,0,3,2,3,4, 1,0,0,0,0,0,0,0,3,4,2,4,3,4,2,4,
    3,2,3,0,0,0,3,2,3,0,0,0,3,2,3,4, 3,2,1,0,1,3,2,3,1,3,2,3,1,3,2,3,
    3,2,3,0,0,0,3,2,3,0,0,0,3,2,3,4, 4,0,0,0,0,0,0,0,3,4,2,4,3,4,2,4,
  0}
  return t
end


songs = {
  //todo, figure out this exactly
  {hs = 0, tempo = 20, start = (frames_till_perfect()/20)+1-8 , song = 32, get_notes = song_4_order, difficulty = 'easy'},
  {hs = 0, tempo = 15, start = (frames_till_perfect()/15)+1, song = 27, get_notes = song_2_order, difficulty = 'medium'},
  {hs = 0, tempo = 15, start = (frames_till_perfect()/15)+1-18, song = 21, get_notes = song_1_order, difficulty = 'hard'}, 
  {hs = 0, tempo = 6, start = (frames_till_perfect()/6)+1, song = 0, get_notes = song_3_order, difficulty = 'very hard'},
  {hs = 0, tempo = 12, start = (frames_till_perfect()/12)+1, song = 43, get_notes = song_5_order, difficulty = 'expert'}
  }
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000dd000000000000006600000000000000dd0000000000000066000000000000dddddd0000000000666666000000000000dd00000000000000660000000
000000d2d00000000000006860000000000000d22d000000000000688600000000000d2222d0000000000688886000000000000d2d0000000000000686000000
00000d22d0000000000006886000000000000d2222d00000000006888860000000000d2222d0000000000688886000000000000d22d000000000000688600000
0000d222d000000000006888600000000000d222222d0000000068888886000000000d2222d0000000000688886000000000000d222d00000000000688860000
000d2222ddddddd00006888866666660000d22222222d000000688888888600000000d2222d0000000000688886000000ddddddd2222d0000666666688886000
00d22222222222d0006888888888886000d2222222222d00006888888888860000000d2222d0000000000688886000000d22222222222d000688888888888600
0d222222222222d006888888888888600d222222222222d006888888888888600dddd222222dddd006666888888666600d222222222222d00688888888888860
0d222222222222d006888888888888600ddddd2222ddddd006666688886666600d222222222222d006888888888888600d222222222222d00688888888888860
00d22222222222d0006888888888886000000d2222d00000000006888860000000d2222222222d0000688888888886000d22222222222d000688888888888600
000d2222ddddddd0000688886666666000000d2222d000000000068888600000000d22222222d00000068888888860000ddddddd2222d0000666666688886000
0000d222d0000000000068886000000000000d2222d0000000000688886000000000d222222d000000006888888600000000000d222d00000000000688860000
00000d22d0000000000006886000000000000d2222d00000000006888860000000000d2222d0000000000688886000000000000d22d000000000000688600000
000000d2d0000000000000686000000000000d2222d000000000068888600000000000d22d00000000000068860000000000000d2d0000000000000686000000
0000000dd0000000000000066000000000000dddddd0000000000666666000000000000dd000000000000006600000000000000dd00000000000000660000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
551155111155115566cc66cccc66cc6600000007770000000000000770000000000077777777000000000077700000009955995555995599aa66aa6666aa66aa
1551155115511551c66cc66cc66cc66c000000700700000000000070070000000000700000070000000000700700000059955995599559956aa66aa66aa66aa6
1155115555115511cc66cc6666cc66cc0000070007000000000007000070000000007000000700000000007000700000559955999955995566aa66aaaa66aa66
51155115511551156cc66cc66cc66cc600007000070000000000700000070000000070000007000000000070000700009559955995599559a66aa66aa66aa66a
551155111155115566cc66cccc66cc6600070000077777770007000000007000000070000007000077777770000070009955995555995599aa66aa6666aa66aa
1551155115511551c66cc66cc66cc66c007000000000000700700000000007000000700000070000700000000000070059955995599559956aa66aa66aa66aa6
1155115555115511cc66cc6666cc66cc0700000000000007070000000000007077777000000777777000000000000070559955999955995566aa66aaaa66aa66
51155115511551156cc66cc66cc66cc670000000000000077000000000000007700000000000000770000000000000079559955995599559a66aa66aa66aa66a
551155111155115566cc66cccc66cc6670000000000000077000000000000007700000000000000770000000000000079955995555995599aa66aa6666aa66aa
1551155115511551c66cc66cc66cc66c070000000000000777777000000777770700000000000070700000000000007059955995599559956aa66aa66aa66aa6
1155115555115511cc66cc6666cc66cc0070000000000007000070000007000000700000000007007000000000000700559955999955995566aa66aaaa66aa66
51155115511551156cc66cc66cc66cc600070000077777770000700000070000000700000000700077777770000070009559955995599559a66aa66aa66aa66a
551155111155115566cc66cccc66cc6600007000070000000000700000070000000070000007000000000070000700009955995555995599aa66aa6666aa66aa
1551155115511551c66cc66cc66cc66c000007000700000000007000000700000000070000700000000000700070000059955995599559956aa66aa66aa66aa6
1155115555115511cc66cc6666cc66cc0000007007000000000070000007000000000070070000000000007007000000559955999955995566aa66aaaa66aa66
51155115511551156cc66cc66cc66cc600000007770000000000777777770000000000077000000000000077700000009559955995599559a66aa66aa66aa66a
00000000000000000011551111551100002222222222200009920000000029900299200000029920022222222222222022220000000022220000000000000000
00000000000000000001155115511000002999999999920009922000000229900299200000029920099999999999999029922000000229920000000000000000
00000000000000000000115555110000002999999999992002992000000299200299200000029920099999999999999029992200002299920000000000000000
00000000000000000000011551100000002992222229992002992200002299200299200000029920022222299222222029999220022999920000000000000000
00000000000000000000001111000000002992000002992002299200002992200299200000029920000000299200000029929922229929920000000000000000
00000000000000000000000110000000002992000002992000299220022992000299200000029920000000299200000029922992299229920000000000000000
00000000000000000000000000000000002992222229992000229920029922000299200000029920000000299200000029922299992229920000000000000000
00000000000000000000000000000000002999999999992000029920029920000299222222229920000000299200000029920229922029920000000000000000
00000000000000000000000000000000002999999999920000022992299220000299999999999920000000299200000029920022220029920000000000000000
00000000000000000000000000000000002999992222200000002999999200000299999999999920000000299200000029920000000029920000000000000000
00000000000000000000000000000000002992999200000000002229922200000299222222229920000000299200000029920000000029920000000000000000
00000000000000000000000000000000002992299920000000000029920000000299200000029920000000299200000029920000000029920000000000000000
00000000000000000000000000000000008aa808aaa800000000008aa800000008aa80000008aa800000008aa80000008aa8000000008aa80000000000000000
00000000000000000000000000000000008aa8008aaa80000000008aa800000008aa80000008aa800000008aa80000008aa8000000008aa80000000000000000
00000000000000000000000000000000008aa80008aaa8000000008aa800000008aa80000008aa800000008aa80000008aa8000000008aa80000000000000000
00000000000000000000000000000000008aa800008aaa800000008aa800000008aa80000008aa800000008aa80000008aa8000000008aa80000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000002c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000002c2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011800200c0351004515055170550c0351004515055170550c0351004513055180550c0351004513055180550c0351104513055150550c0351104513055150550c0351104513055150550c035110451305515055
010c0020102451c0071c007102351c0071c007102251c007000001022510005000001021500000000001021013245000001320013235000001320013225000001320013225000001320013215000001320013215
003000202874028740287302872026740267301c7401c7301d7401d7401d7401d7401d7301d7301d7201d72023740237402373023720267402674026730267201c7401c7401c7401c7401c7301c7301c7201c720
0030002000040000400003000030020400203004040040300504005040050300503005020050200502005020070400704007030070300b0400b0400b0300b0300c0400c0400c0300c0300c0200c0200c0200c020
00180020176151761515615126150e6150c6150b6150c6151161514615126150d6150e61513615146150e615136151761517615156151461513615126150f6150e6150a615076150561504615026150161501615
00180020010630170000000010631f633000000000000000010630000000000000001f633000000000000000010630000000000010631f633000000000000000010630000001063000001f633000000000000000
001800200e0351003511035150350e0351003511035150350e0351003511035150350e0351003511035150350c0350e03510035130350c0350e03510035130350c0350e03510035130350c0350e0351003513035
011800101154300000000001054300000000000e55300000000000c553000000b5630956300003075730c00300000000000000000000000000000000000000000000000000000000000000000000000000000000
003000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01240020051450c145051450c145051450c145051450c145071450e145071450e145071450e145071450e1450d145141450d145141450d145141450d145141450c145071450c145071450c145071450c14507145
0148002021744217402274024744247401f7441f7402074420740207401f7401d7401f7401c7441c7402174421740217402274024744247401c7441c7401d7441f74020740227402474424740247402474500000
012400200e145151450e145151450e145151450e145151450c145131450c145131450c145131450c145131450f145161450f145161450f145161450f145161450e145151450e145151450c145131450c14513145
011200200c1330960509613096131f6330960509615096150c1330960509613096130062309605096050e7130c1330960509613096131f6330960509615096150c1330960509613096130062309605096050e713
014800200c5240c5200c5200c52510524105201052010525115241152011520115251352413520135201352511524115201152011525135241352013520135251452414520145201452013520135201352013525
014800200573405730057300573507734077300773007735087340873008730087350c7340c7300c7300c73505734057300573005735077340773007730077350d7340d7300d7300d7350c7340c7300c7300c735
014800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013c00200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011e00200c505155351853517535135051553518535175350050015535185351a5350050515535185351a53500505155351c5351a53500505155351c5351a53500505155351a5351853500505155351a53518535
010f0020001630020000143002000f655002000020000163001630010000163002000f655001000010000163001630010000163002000f655002000010000163001630f65500163002000f655002000f60300163
013c002000000090750b0750c075090750c0750b0750b0050b0050c0750e075100750e0750c0750b0750000000000090750b0750c0750e0750c0751007510005000000e0751007511075100750c0751007510005
013c00200921409214092140921409214092140421404214022140221402214022140221402214042140421409214092140921409214092140921404214042140221402214022140221402214022140421404214
013c00200521405214052140521404214042140721407214092140921409214092140b2140b214072140721405214052140521405214042140421407214072140921409214092140921409214092140921409214
013c00202150624506285060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400181862500000000001862518625186251862500000186051862018625000001862500000000001862500000000001862518605186251862518605186250000000000000000000000000000000000000000
010f00200c0730000018605000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c073000000000000000
013c0020025500255004550055500455004550055500755005550055500755007550045500455000550005500255002550045500555004550045500555007550055500555007550095500a550095500755009550
013c00201a54526305155451a5451c545000001a5451c5451d5451c5451a545185451a5450000000000000001a5452100521545180051c5450000018545000001a545000001c545000001a545000000000000000
011e00200557005575025650000002565050050557005575025650000002565000000457004570045750000005570055750256500000025650000005570055750256500000025650000007570075700757500000
010a00200e1200e1200e12500000151201512015125000001a1201a1201a12500000151201512015125000001f1201f1201f125000001a1201a1201a12500000131201312013125000000e1200e1200e12500000
013c00201d1201a1251a1251d1201a1251d1201c1201a1251d1201a1251a1251d1201a1251f1201d1201c1251d1201a1251a1251d1201a1251d1201a1251a1251d1201a1251a1251d1201f1201d1201c1201c125
011e0020091351500009135000050920515000091350000009145000000920500000071400714007145000000913500000091350000009205000000913500000091450000009205000000c2000c2050020000000
015000200706007060050600506003060030600506005060030600306005060050600206002060030600306007060070600506005060030600306005060050600306003060050600506007060070600706007060
01280020131251a1251f1251a12511125181251d125181250f125161251b125161250e125151251a125151250f125161251b1251612511125181251d125181250e125151251a125151251f1251a125131250e125
01280020227302273521730227301f7301f7301f7301f7352473024735227302273521730217351d7301d7351f7301f7352173022730217302173522730247302673026730267302673500000000000000000000
012800202773027735267302473524730247302473024735267302673524730267352273022730227302273524730247352273021735217302173021730217351f7301f7301f7301f7301f7301f7301f7301f735
015000200f0600f0600e0600e060070600706005060050600c0600c060060600606007060090600a0600e0650f0600f0600e0600e060070600706005060050600c0600a060090600206007060070600706007065
012800200f125161251b125161250e125151251a12515125131251a1251f1251a12511125181251d125181250f125161251b125161250e125151251a12515125131251a1251f1251a125131251a1251f1251a125
012800201a5201a525185201a525135101351013510135151b5201b5251a5201a525185201852515520155251652016525185201a52518520185251a5201b520155201552015520155251f5001f5001f5001f505
012800201f5201f5251d5201b525155101551015510155151d5201d5251b5201d5251a5101a5101a5101a5151b5201b5251a5201a52518520185201552015525165201652016520165251a5001a5001a5001a505
013c00201003500500000001003509000000000e0300e0351003500000000001003500000000000e0000e00511035000000000011035000000000010030100351103500000000001103500000000000400004005
011e00201813518505000001713517505000001513515505000001013010130101350000000000000000000015135000000000010135000000000011500115001150011500111301113011130111350000000000
01180020071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155051550c155081550c155051550c155081550c155051550c155081550c155051550c137081550c155
01180020071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1570c1550f155
01180020081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1370a1550e155
011800201305015050160501605016050160551305015050160501605016050160551605015050160501a05018050160501805018050180501805018050180550000000000000000000000000000000000000000
011800201305015050160501605016050160551305015050160501605016050160551605015050160501a0501b0501b0501b0501b0501b0501b0501b0501b0550000000000000000000000000000000000000000
011800201b1301a1301b1301b1301b1301b1351b1301a1301b1301b1301b1301b1351b1301a1301b1301f1301a130181301613016130161301613016130161350000000000000000000000000000000000000000
011800201b1301a1301b1301b1301b1301b1351b1301a1301b1301b1301b1301b1351b1301a1301b1301f1301d1301d1301d1301d1301d1301d1301d1301d1350000000000000000000000000000000000000000
01180020081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f1550a155111550e155111550a155111550e155111550a155111550e155111550a155111550e15511155
011800202271024710267102671026710267152271024710267102671026710267152671024710267102971027710267102471024710247102471024710247150000000000000000000000000000000000000000
01180020227102471026710267102671026715227102471026710267102671026715267102471026710297102b7102b7102b7102b7102b7102b7102b7102b7150000000000000000000000000000000000000000
011800202b720297202b7202b7202b7202b7252b720297202b7202b7202b7202b7252b720297202b7202e72029720277202672026720267202672026720267250000000000000000000000000000000000000000
011800202b720297202b7202b7202b7202b7252b720297202b7202b7202b7202b7252b720297202b7202e7202e7202e7202e7202e7202e7202e7202e7202e7250000000000000000000000000000000000000000
011e00201f050210501f0501d050180501a0501d0501d050000001a0500000021050210500000000000000001f050210501f0501d050180501a0501d0501d050000001a05021050000001f0501f0500000000000
011e00201f050210501f0501d050180501a0501d05000000000001d050000001d05024050210502105000000000000000000000000001f0501f05000000000000000000000000000000000000000000000000000
011800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 08004243
00 08014300
00 03014300
00 02030500
04 03434500
00 03414300
00 08014500
00 03040500
01 03024500
02 03020500
02 08010706
01 0a4d0949
00 0a0d090c
00 0a4c0b4c
00 0a0d0e4e
02 0f4d0c09
01 50524356
00 51534356
00 50525456
00 51535556
00 52424356
01 53424318
00 19425b18
00 19175a18
00 19171a18
00 1b565c18
04 1a194318
01 1f1d5e60
00 1f1d5e20
00 1f1d4320
00 161d211e
04 231d211e
01 5c226444
01 25262744
00 292a2844
00 2526272b
04 292a282c
01 2d181624
00 2d181e24
00 2d181e2e
00 2d181e2e
00 2d181e6e
02 2d181e6e
01 2f454305
00 30424305
00 2f324344
00 30334344
00 2f323705
00 30333805
00 31344344
00 36354344
00 31343905
04 36353a05
01 7d427b41
01 3b427b44
04 3c7d7b44
00 7c7d7b44
00 7e527b41
00 7e427b41
00 7e7f7b44
00 7e7f7b44
00 7e417b41
02 7e417b41

