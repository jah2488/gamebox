require 'mode'
require 'physical_level'
require 'director'
require 'actor'
require 'actor_view'
require 'actor_factory'



class ShipView < ActorView
  def setup
    # TODO subscribe for all events here
  end
  def draw(target)
    x = @actor.x
    y = @actor.y
#    p "#{x},#{y}"
    target.draw_box_s [x,y], [x+20,y+20], [150,150,150,255] 
  end
end
class Wall < Actor
  has_behaviors :physical
  # TODO pull out shape info?
end
class WallView < ShipView
end

class Ship < Actor
  has_behaviors :physical
  attr_accessor :moving_forward, :moving_back,
    :moving_left, :moving_right
  def setup
    @speed = 0.7
    @turn_speed = 0.003
  end

  def moving_forward?;@moving_forward;end
  def moving_back?;@moving_back;end
  def moving_left?;@moving_left;end
  def moving_right?;@moving_right;end
  def update(time)
    move_forward time if moving_forward?
    move_back time if moving_back?
    move_left time if moving_left?
    move_right time if moving_right?
  end

  def move_right(time)
    @behaviors[:physical].body.a += time*@turn_speed
    @behaviors[:physical].body.w += time*@turn_speed/5.0 if @behaviors[:physical].body.w > 2.5
  end
  def move_left(time)
    @behaviors[:physical].body.a -= time*@turn_speed
    @behaviors[:physical].body.w -= time*@turn_speed/5.0 if @behaviors[:physical].body.w > 2.5
  end
  def move_back(time)
    @behaviors[:physical].body.apply_impulse(-@behaviors[:physical].body.rot*time*@speed, ZeroVec2) if @behaviors[:physical].body.v.length < 400
  end
  def move_forward(time)
    @behaviors[:physical].body.apply_impulse(@behaviors[:physical].body.rot*time*@speed, ZeroVec2) if @behaviors[:physical].body.v.length < 400
  end
end

class AsteroidLevel < PhysicalLevel
  def setup
    # TODO get this from screen of config
    @width = 1000
    @height = 800
    @space.add_collision_func(:ship, :wall) do |ship, wall|
      # move ship across map
      if wall.body.p.x < 1
        ship.body.p = vec2(@width,ship.body.p.y)
      end
      if wall.body.p.x > @width
        ship.body.p = vec2(0,ship.body.p.y)
      end
      if wall.body.p.y < 1
        ship.body.p = vec2(ship.body.p.x, @height)
      end
      if wall.body.p.y > @height
        ship.body.p = vec2(ship.body.p.x, 0)
      end
    end
  end
end

class ShipDirector < Director
  def update(time)
    # TODO teleport to other side of map?
    for act in @actors
      act.update time
    end
  end
end


class Game

  constructor :wrapped_screen, :input_manager, :sound_manager, :mode_manager

  def setup
    @sound_manager.play :current_rider

    # tmp code here, to draw an actor
    # WHERE SHOULD THIS BUILDING LOGIC COME FROM?
    #  - file describing modes? or hard code them?
    #  - levels in each mode? or hard code them?
    #  - directorys in the level? in the "level definition"?
    mode = Mode.new
    level = AsteroidLevel.new
    mode.level = level
    @mode_manager.add_mode :demo, mode
    factory = ActorFactory.new @mode_manager

    ship = factory.build :ship
    dir = ShipDirector.new
    level.directors << dir
    dir.actors << ship

    wall = factory.build :wall
    dir = Director.new
    level.directors << dir
    dir.actors << wall

    @input_manager.when :event_received do |event|
      case event
      when KeyDownEvent
        case event.key
        when K_LEFT
          ship.moving_left = true
        when K_RIGHT
          ship.moving_right = true
        when K_UP
          ship.moving_forward = true
        when K_DOWN
          ship.moving_back = true
        end
      when KeyUpEvent
        case event.key
        when K_LEFT
          ship.moving_left = false
        when K_RIGHT
          ship.moving_right = false
        when K_UP
          ship.moving_forward = false
        when K_DOWN
          ship.moving_back = false
        end
      end  
    end

    @mode_manager.change_mode_to :demo
  end

  def update(time)
    @mode_manager.update time
    draw
  end

  def draw
    @mode_manager.draw @wrapped_screen
    @wrapped_screen.flip
  end

end
