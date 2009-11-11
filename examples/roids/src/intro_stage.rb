require 'stage'
class IntroStage < Stage
  def start
    @image = @resource_manager.load_image 'intro.png'
    i = @input_manager
    i.reg KeyPressed, :space do
      fire :next_stage
    end
  end

  def stop
    fire :remove_me
  end

  def draw(target)
    @image.blit target.screen, [0,0] if @image
  end
end