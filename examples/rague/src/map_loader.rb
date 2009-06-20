require 'inflector'
require 'map'
require 'generator'

# loads maps from given string array
class MapLoader
  attr_accessor :rague
  
  def initialize(config)
    @config = config
  end
  
  def build_random_map(map, walk_length=400)
    # TODO randomize starting location
    x = 12
    y = 5
    log "Generating random map ..."
    
    a = Generator.new().create_dungeon(Arena.new, walk_length, true, Walker.new(x,y))
    a[x,y] = '@'
    a[x+1,y] = '<'
    
    log "done."
    
    build_map map, a.to_s.split("\n")
  end
  
  def load_map(map, filename)
    full_path = File.join(DATA_PATH,'maps',filename)
    map_lines = File.open(full_path).readlines
    build_map map, map_lines
  end
  
  def build_map(map, map_lines)
    log "Building map..."
    map.size = [map_lines[0].length-1, map_lines.size-1]
    
    map_lines.each_with_index do |row_str, row|
      row_str.strip.length.times do |col|
        
        tile_klass = @config[:tiles][row_str[col]]
        tile = map.spawn :tile, :x => col, :y => row, :action => tile_klass
        tile.lit = false
        tile.solid = true if tile_klass == :wall
        
        if tile_klass.nil?
          name = @config[:actors][row_str[col]]
          unless name.nil?
            x = col * map.tile_width
            y = row * map.tile_height
            
            act = map.spawn name, :x=>x, :y=>y
            if name == :rague
              @rague = act 
              @rague.tile_x = col
              @rague.tile_y = row
            else
              tile.occupants << act
            end
          end
                      
        end
        map.place tile.location, tile
      end
    end
    log "done."
  end
  
end