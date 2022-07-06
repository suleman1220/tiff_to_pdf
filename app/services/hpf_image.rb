require 'prawn'
require 'combine_pdf'
require 'ruby-filemagic'

class HpfImage
  def initialize(user_id, document_id)
    @document_id = document_id
    @user_id = user_id 
    STDERR.puts "Initializing HpfImage with user:#{@user_id} accessing document#{@document_id}"
    # tiff_image = nil
    # if tiff_method.nil?
    #   tiff_method = ENV['TIFF_CONV']
    # end
    # if tiff_method.nil?
    #   tiff_method = 'rmagick'
    # end
    # @tiff_method = tiff_method
    @overlays = Overlay.new
    
  end

  def preview(mode, image_path_array)
    # mode = ['text', 'tif'].sample
    case mode
    when 'text'
      #image_path_array = ["hpf/135.txt", "hpf/173.txt"]
      image_text([image_path_array[0]])
    when 'tif'
      #image_path_array = ["public/p01.tiff", "public/p01.tiff", "public/p03.tiff"]
      image_tiff([image_path_array[0]])
    end
  end

  def image(mode, image_path_array)
    # mode = ['text', 'tif'].sample
    # puts "MODE IS : #{mode}"
    case mode
    when 'text'
      #image_path_array = ["hpf/135", "hpf/173", "hpf/49"]
      image_text(image_path_array)
    when 'tif'
      # image_path_array = ["public/p01.tiff", "public/p01.tiff", "public/p03.tiff"]
        # image_path_array = ["public/p01.tiff", "public/p01.tiff", "public/p03.tiff"]
        # image_path_array = ["public/0.tiff", "public/1.tiff", "public/2.tiff", "public/3.tiff", "public/4.tiff", "public/5.tiff",
        #   "public/6.tiff", "public/7.tiff", "public/8.tiff","public/9.tiff", "public/10.tiff"]
      image_tiff(image_path_array)
    end
  end

  def preview_tiff(image_path_array)
    image_tiff([image_path_array[0]])
  end

  def preview_text(image_path_array)
    image_text([image_path_array[0]])
  end

  private

  def image_text(file_list)
    #STDOUT.puts "Version 1.3.4"
    file = File.open(file_list[0])
    lines = file.readlines
    line = lines[0]
    hdr = HpfHeader.new(line)
    STDERR.puts "Header form: #{hdr.form}"
    form = @overlays.find(hdr.form)
    leading = form[:leading]
    if form[:form_name].empty?
      form_name = ""
    else
      form_name = form[:form_name]
    end
    font_name = form[:font]
    font_size = form[:font_size]
    margin = form[:margin]
    file.close

    comb_pdf = CombinePDF.new

    file_list.each_with_index do |img_path, page_no|
      STDERR.puts "STDERR Starting page: #{page_no} #{img_path}"

      start_time = Time.now
      fm = FileMagic.new
      file_type = fm.file(img_path, true)   
      STDERR.puts "  Image Type Determination Time: #{(Time.now - start_time) * 1000}ms"

      if ["jpeg", "tiff"].include?(file_type)  
        tiff_proc = TiffPdf.new(@document_id, @user_id)
        data = tiff_proc.tiffs_to_pdf([img_path])
        comb_pdf << CombinePDF.parse(data)
      else
        pdf = Prawn::Document.new(:margin => margin ) #[29,29,29,27.5])
        pdf.font font_name  
        pdf.font_size font_size 

        file = File.open(img_path)# "r:iso-8859-1")
        start_page = false
       
        file.readlines.each_with_index do |line, line_no|
          if start_page
             pdf.start_new_page 
             start_page = false
          end

          if line_no == 0
            STDERR.puts "First line #{line_no}  of page contains header"
            hdr = HpfHeader.new(line)
            line = hdr.contents
            line.slice!('BIG_BANG')
          else
            line = keep_ascii(line)   # TEMP fix matches HPF. remove all special characters.
    	      line = line.gsub(/\r?/, "").gsub(/\s+$/, '') + "\n" # remove all blanks before newline
    	      line = line.gsub(/^(\s+)/m) { |m| "\xC2\xA0" * m.size } # non breaking whitespace at beginning
          end 

          if line.slice('BIG_BANG')
            line = ""
            start_page = true
            next
          end
          STDERR.puts "line #{line_no + 1} #{line}"
          pdf.text line, :leading => leading 
        end

        comb_pdf << CombinePDF.parse(pdf.render)
      end
      file.close

      #pdf.text " Patient: Test Patient:  MRN:  XXXXXX     Page #{page_no + 1} od TBD", :size=> 8
      # if page_no + 1 < file_list.size
      #   STDERR.puts "Starting new page #{page_no + 1} of #{file_list.size}"
      #   start_page = false    # 
      #   pdf.start_new_page # if page_no + 1 < file_list.size
      # end
      #pdf.start_new_page if page_no + 1 < file_list.size
    end

    STDERR.puts "form_name: #{form_name}"
    STDERR.puts "Header form: #{hdr.form}"	
    STDERR.puts "Header font: #{hdr.font}"

    if form_name.empty?
      #comb_pdf << CombinePDF.parse(pdf.render)
      return comb_pdf.to_pdf
    end
    #overlay = "forms/#{form_name}"
    #pdf.render_file('tef-con1.pdf')
    underlay_pdf = CombinePDF.load(form_name).pages[0]  #underlay).pages[0]
    #final = CombinePDF.parse(pdf.render)  #load 'tef-dhf.pdf'
    #final = CombinePDF.load('tef-con1.pdf')  #load 'tef-dhf.pdf'
    #final = comb_pdf << final
    comb_pdf.pages.each {|page| page >> underlay_pdf}
    #puts "    to_pdf "
    comb_pdf.to_pdf   #final.save ('tef_underlay.pdf')
  end
  
  def image_tiff(file_list)
    #img_paths = ["public/p01.tiff", "public/p02.tiff", "public/p03.tiff"] #"public/sample2.TIF"#"public/sample3.TIF"
    # if @tiff_method == "rmagick"
      tiff_proc = TiffPdf.new(@document_id, @user_id)
      #tiff_proc = MagickPdf.new
    # else
    #   tiff_proc = TiffPdf.new(@document_id, @user_id)
    # end

    #puts("tiff_method: #{@tiff_method}  - tiff_proc: #{tiff_proc.inspect}")
    return tiff_proc.tiffs_to_pdf(file_list)

  #   convert_start_time = Time.now
  #   #combine_pdf = CombinePDF.new
  #   concat_array = []
  #   file_list.each_with_index do |img_path, i|
  #     #STDERR.puts "        STDERR Starting page: #{i} #{img_path}"
  #     file_start_time = Time.now
  #     read_time = Time.now
  #     Magick::Image.read(img_path).each do |img|    #there will be only one image in the tiff file
  #       # msg = "     Image #{i} - #{img_path}  Read Time: #{Time.now - read_time}"
  #       # STDERR.puts msg
  #       img.format = "PDF"
  #       file_name = hpf_tempfile_name(i, 'temp')
  #       img.write(file_name)
        
  #       combine_pdf << CombinePDF.load(file_name)
  #       FileUtils.rm(file_name)
  #       STDERR.puts "       STDERR Elapsed time for page: #{i} #{img_path}  - #{Time.now - file_start_time}"
  #     end
  # #puts cmd + files
  #     system cmd + files
  #     system 'rm ' + files
  #   end
  #   #binding.pry
  #   result = combine_pdf.to_pdf
  #   puts "    !!!Conversion time for : #{Time.now - start_time}\n\n"
  #   result
  end

  def clean_line(line)
    bytes = line.bytes
    line_starts = 0
    new_line = ""
    bytes.length.downto(0).each do |i|
        if bytes[i] == 0
            line_starts = i+1
            (line_starts...line.length).each do |i|
                new_line << bytes[i].chr
            end
            break
        end
    end
    if line_starts == 0
        new_line = line
    end
    new_line
  end

def keep_ascii(l)
  b = l.bytes
  line = ""
  b.each do |c|
    line += c.chr if c < 128
  end
  line
end


  def hpf_tempfile_name(i, f)
    return "~/tmp/#{f}-#{i}.pdf" unless f.empty?
    "~/tmp/#{rand(10 ** 10)}-#{f}-#{i}.pdf"
  end

end
