require 'combine_pdf'
require 'rmagick'

class TiffPdf
    def initialize files
        @document_id = 23
        @user_id = 23
        @test_files = files
    end

    def tiffs_to_file(id, file_name, file_list)
        img = tiffs_to_pdf(id, file_list)
        File.open(file_name, 'w') {|f| f.write(img)}
        file_name
    end

    def tiffs_to_pdf
        random_id = rand(10 ** 10)
        file_list = @test_files 
        puts "Processing Document: #{@document_id} by user #{@user_id}"
        p "=========================================="
        p ENV["TIFF_PROCESSOR"] 
        convert_start_time = Time.now
        begin
            if ENV["TIFF_PROCESSOR"] == 'ps'
                result_name = ps_convert(file_list)
            else
                result_name = pdf_convert(file_list)
            end
        rescue IOError => ex 
            puts "StandardError Tiff Conversion of #{@document_id} failed with #{ex.message}"
            puts "\n!!! Switching to PS method for document #{@document_id}\n\n"
            #TODO: log in db that this documment is bad. We may be able to automatically use the ps methd instead of failing first
            result_name = ps_convert(file_list)
        rescue StandardError => ex
            puts "StandardError Tiff Conversion of #{@document_id} failed with #{ex.message}"
            puts "#{ex.backtrace}"
        rescue  => ex
            puts "Exception Tiff Conversion of #{@document_id} failed with #{ex.message}"    
            puts "#{ex.backtrace}"
        end
        puts "Final result file: #{result_name}"
        puts "Total Time: #{Time.now - convert_start_time}\n"
        # result = File.read( result_name) #File.expand_path(result_name))
        # system "rm " + result_name
        result_name
    end


    def temp_pdf_file_name(random_id,i, user_id)
        xval = File.expand_path("workdir/img-#{random_id}-#{user_id}-#{i}.pdf")
        puts "   PDF temp file: #{xval}"
        xval
    end

    def pdf_file_name(page)
        xval = File.expand_path("workdir/img-#{@user_id}-#{@document_id}-#{page}.pdf")
        puts "   PDF file: #{xval}"
        xval
    end

    def ps_file_name(page)
        xval = xval = File.expand_path("workdir/img-#{@user_id}-#{@document_id}-#{page}.ps")
        puts "   PS file: #{xval}"
        xval
    end

 
    # def test_files()
    #     #file_list = ["public/p01.tiff", "public/p02.tiff", "public/p03.tiff"] #"public/sample2.TIF"#"public/sample3.TIF"
    # end

    def text_to_pdf(source, destination)
      begin 
        hpf_image = HpfImage.new(@user_id, @document_id)
        puts "@@@ Calling HPFIMAGE text_to_pdf conversion"
        pdf = hpf_image.image("text", [source])
        puts "@@@ opening file in binary mode and writing text pdf"
        File.open(destination, 'wb') {|f| f.write(pdf)}
      rescue => e 
        puts "@@@ ERROR IN text_to_pdf: #{e.inspect}"
      end
    end

    def pdf_convert_with_image_magick(destination, source)
      begin
        Magick::Image.read(source).each do |img|
          img.format = "PDF" 
          img.write(destination)
        end
      rescue  => e 
        puts "Error in IMAGE MAGICk CONVERSTION: #{e.inspect}"
        puts "SENDING #{source} to text_to_pdf conversion"
        text_to_pdf(source, destination)
      end 
    end  

    def pdf_convert (file_list)
        concat_array = []
        random_id = rand(10 ** 10)
        convert_start_time = Time.now
        file_list.each_with_index do |img_path, i|
            #puts "   STDERR Starting page: #{i} #{img_path}"
            file_start_time = Time.now
            source = img_path
            destination = pdf_file_name(i)
            #puts "       Destination: #{destination}"

            puts "@@@ PROCESSING SYSTEM COMMAND"
            result = system "tiff2pdf -o #{destination} #{source}" 
            puts "SYSTEM COMMAND RESULT : #{result}"

            unless result
              puts "   System command failed ..."
              puts "   Calling image_magick ...."
              pdf_convert_with_image_magick(destination, source)
            end

            concat_array << destination
            puts "    File #{img_path} convert time: #{(Time.now - file_start_time)*1000}ms"
        end 
        puts "  Total tiff2pdf convert time: #{Time.now - convert_start_time}"

        if concat_array.count == 1
            result_name = concat_array[0]
        else
            result_name = pdf_file_name(10000)
            #
            puts "Combine #{ENV['MERGE']}  Result Name = #{result_name}"
            if true
                start_merge = Time.now
                pdf = CombinePDF.new
                concat_array.each do |doc|
                  puts "@@@ COMBINING #{doc}"
                  pdf << CombinePDF.load(doc)
                end

                res = pdf.save result_name
                # unless res
                #     raise ApiError, "Merge failed bad tiff"
                # end
                files = ""
                concat_array.each do |d|
                    files += d + " "
                end
                system 'rm ' + files
                puts "  COMBINE Merge Time: #{(Time.now - start_merge) * 1000}ms"
            else
                start_merge = Time.now
                cmd = "./pdfcpu merge #{result_name} "
                files = ""
                concat_array.each do |d|
                    files += d + " "
                end
                res = system cmd + files
                unless res
                    raise IOError, "Merge failed bad tiff"
                end
                puts "    Merge results = #{res}"
                system 'rm ' + files
                puts "  PdfCpu merge Time: #{(Time.now - start_merge) * 1000}ms"
            end
        end
        puts "Total process time: #{Time.now - convert_start_time } for #{result_name}"
        result_name
    end


    def ps_convert(file_list)
        concat_array = []
        convert_start_time = Time.now
        file_list.each_with_index do |img_path, page|
            puts "  STDERR Starting page: #{page} #{img_path}"
            file_start_time = Time.now
            source = img_path
            ps_destination = ps_file_name(page)
            #pdf_destination = pdf_file_name(page)
            puts "      PS Destination: #{ps_destination}"
            system "tiff2ps #{source} > #{ps_destination}"  #| ps2pdf - > #{destination}"
            concat_array << ps_destination
            puts "    File ps convert time: #{Time.now - file_start_time}"
        end 
        puts "  PS Convert Time: #{(Time.now - convert_start_time)} seconds"
        result_name = pdf_file_name(10000)
        merge_start = Time.now
        if concat_array.count == 1
            ps_result_name = concat_array[0]
        else
            ps_result_name = ps_file_name(10000)
            puts "    Save to result: #{ps_result_name} - #{result_name}"
            files = ""
            concat_array.each do |d|
                files += d + " "
            end
            cmd = "psjoin #{files} > #{ps_result_name}"
            puts "merge command: #{cmd }"
            system cmd  #{files} > #{ps_result_name}"
        end
        system "ps2pdf #{ps_result_name} #{result_name}"
        system 'rm ' + files
        puts "PS Merge time: #{(Time.now - merge_start)*1000}ms"
        result_name
    end
end