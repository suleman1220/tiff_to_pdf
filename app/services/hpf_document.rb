class HpfDocument
	def load_tif_image(dv)
		ai        = dv.archived_image
    img_paths = []
    
    ai.hpf_doc_urls.each do |url|
      img_paths <<  '/hpf' + url
    end
    puts "  !!!Starting conversion of document: #{dv.clinical_document_id}\n    #{img_paths}\n"
    STDERR.puts "  Starting conversion of document: #{dv.clinical_document_id}\n\n"
    start_time  = Time.now
    combine_pdf = CombinePDF.new
    
    img_paths.each_with_index do |img_path, i|
      STDERR.puts "       STDERR Starting page: #{i} #{img_path}"
      file_start_time = Time.now
      read_time = Time.now

      Magick::Image.read(img_path).each do |img|
        msg = "Read Time: #{Time.now - read_time}"
        STDERR.puts msg
        img.format = "PDF"

        file_name = get_tempfile_name(i, facility, dv)
        img.write(file_name)
        combine_pdf << CombinePDF.load(file_name)
        
        FileUtils.rm(file_name)
        STDERR.puts "       STDERR Elapsed time for page: #{i} - #{Time.now - file_start_time}"
      end
    end

    STDERR.puts "    !!!Conversion time for #{dv.clinical_document_id}: #{Time.now - start_time}\n\n"
    combine_pdf.to_pdf
	end

	def load_txt_image(dv)
    img_paths = ["public/t1.txt", "public/t2.txt"]
    STDERR.puts "   Images: #{img_paths}"

    pdf = PrawnPdf.new({:margin => [29,29,29,27.5]})
    
    img_paths.each_with_index do |img_path, i|
      STDERR.puts "STDERR Starting page: #{i} #{img_path}"
      File.readlines(img_path).each do |line|
        pdf.text clean_line(line).gsub(/\r\n?/, "").gsub(/^(\s+)/m) { |m| "\xC2\xA0" * m.size }
      end

      pdf.start_new_page if i+1 < img_paths.size
    end

    pdf.render
	end

	def get_tempfile_name(i, facility, dv)
    return "tmp/#{f.hospital_facility_id}-#{dv.clinical_document_id}-#{i}.pdf" unless f.blank?
    "tmp/#{rand(10 ** 10)}-#{dv.clinical_document_id}-#{i}.pdf"
	end

  def clean_line(line)
    bytes = line.bytes
    line_starts = 0
    new_line = ""

    bytes.length.downto(0).each do |i|
      if bytes[i] == 0
        line_starts = i+1
        (line_starts...line.length).each do |i|
          #puts "char: #{i}:  #{bytes[i]}  -  #{bytes[i].chr}"
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

  def preview(dv)
    return if not dv.clinical_document.source == 'HPF'

    facility = Facility.where(name: dv.clinical_document.facility).first
    ai = archived_image

    img_path  =  '/hpf' + ai.hpf_doc_urls[0] unless ai.hpf_doc_urls.blank?
    image_type = ai.image_type

    if image_type == 'tif'

      pdf = CombinePDF.new
      Magick::Image.read(img_path).each do |img|
        img.format = "PDF"
        file_name = hpf_tempfile_name(0, facility)
        img.write(file_name)
        pdf << CombinePDF.load(file_name)
        FileUtils.rm(file_name)
      end
      return pdf.to_pdf
    else
      #img_path = "public/t1.txt" #if img_path.blank?

      pdf = Prawn::Document.new
      pdf.font_size 9
      
      File.readlines(img_path).each do |line|
        pdf.text clean_line(line) 
      end

      pdf.render
    end
  end

	def load(dv)
    ai = dv.archived_image
    image_type = ai.image_type

    case image_type
	    when 'tif'
	      load_tif_image(dv)
	    when 'text'
	    	load_txt_image(dv)
	    else
	    	load_txt_image(dv)
    end
  end
end
