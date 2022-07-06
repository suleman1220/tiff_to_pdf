class Overlay

  def initialize
puts "\n\nInitializeing Overlays"
      @overlays = {}
      set_overlays
  end

  def find(name)
      o = @overlays[name.downcase]
      return @overlays["plain"] if o.nil?
      o
  end


  private

  def set_overlays
      plain
      cms1500
      ub04
      form1111111
      form0000200
  end

  def cms1500
      o = {}
      o[:margin] =  [29,29,29,27.5]
      o[:font]   =  'Courier'
      o[:font_size] = 11.5
      o[:leading]  = -0.57
      o[:form_name]     = "forms/cms_1500.pdf"
      @overlays['00cms1500'] = o
      o
  end

  def ub04
          o = {}
      o[:margin] =   [27,29,29,25]
      o[:font]   =  'Courier'
      o[:font_size] = 11.5
      o[:leading]  = -0.53
      o[:form_name]     = "forms/ub04.pdf"
      @overlays['xxub04'] = o
      o
  end


  def plain
      o = {}
      o[:margin] =   [29,29,29,20]
      o[:font]   =  'Courier'
      o[:font_size] = 12
      o[:leading]  = 0
      o[:form_name]     = ""
      @overlays['plain'] = o
      o
  end

  def form1111111
      o = {}
      o[:margin] =   [20,20,20,20]
      o[:font]   =  'Courier'
      o[:font_size] = 11
      o[:leading]  = 0
      o[:form_name]     = ""
      @overlays['1111111111'] = o
      o
  end

#[top, right, bottom, left]
  def form0000200
      o = {}
      o[:margin] =   [5,0,0,0]
      o[:font]   =  'Courier'
      o[:font_size] = 9.7
      o[:leading]  = 1
      o[:form_name]     = ""
      @overlays['0000000200'] = o
      o
  end
end
