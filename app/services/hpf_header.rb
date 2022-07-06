class HpfHeader
  def initialize(line)
      @form = [17,16,15,14,13,12] # the form cond be in any of these fields#13  #14
      @font = 9   # 10

      @valid_forms = %w(00CMS1500 XXUB04)  # add to as new forms are created

      last_end = -1
      @flds = []         #first field lways starts at element
      bytes = line.bytes
      bytes.each_with_index  do |b, i|
          if b == 0    # end of field itentifier field is fld[:start] through i
              fld = {}
              fld[:first] = last_end + 1
              last_end = i
              fld[:last] = i - 1
              fld[:value] = ""
              bytes[fld[:first]..fld[:last]].each do |c|
                   fld[:value] += c.chr
              end
              @flds << fld
          end
      end
      if last_end < bytes.length - 1 
          fld = {}
          fld[:first] = last_end + 1
          fld[:last] = bytes.length - 1
          fld[:value] = ""
          puts "Start of contents: #{fld[:first]} - #{fld[:last]}"
          bytes[fld[:first]...fld[:last]].each do |c|
              fld[:value] += c.chr
         end
         @flds << fld
      end
  end

  def elements
      @flds
  end

  def element(index)
     # return nil if index >= @flds.count
      @flds[index -1]
  end

  def form
      return "" if @flds.count < 12
      @form.each do |i|
          val = @flds[i][:value]
          next if val.empty? || val.length < 3
          return val
      end
      return ""
  end

  def font
      @flds[@font][:value]
      #element_value(@font)
  end

  def contents 
      #line = element_value(@flds.count).gsub(/\r?/, "").gsub(/\s+$/, '')+"\n"
      #line.gsub(/^(\s+)/m) { |m| "\xC2\xA0" * m.size }
      #element_value(@flds.count).gsub(/\r?/, "").gsub(/\s+$/, '')   .gsub(/^(\s+)/m) { |m| "\xC2\xA0" * m.size }
      element_value(@flds.count).gsub(/^(\s+)/m) { |m| "\xC2\xA0" * m.size }
  end

  def valid_form?
      @valid_forms.include?(form)
  end

  def has_header?
      @flds.count > 1
  end

      
  def element_value(index)
      #nil if index >= @flds.count
      @flds[index - 1][:value]
  end
end
