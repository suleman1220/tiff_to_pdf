class PdfController < ApplicationController
  def convert
    tiff_files = []
    params[:tiff_files].each do |tiff_file|
      File.open(Rails.root.join('workdir', tiff_file.original_filename), 'wb') do |file|
        file.write(tiff_file.read)
      end
      tiff_files.push(Rails.root.join('workdir', tiff_file.original_filename))
    end
    res_file_path = TiffPdf.new(tiff_files).tiffs_to_pdf
    File.open(res_file_path, 'r') do |f|
      send_data f.read.force_encoding('BINARY'), :filename => "combined_tiffs.pdf", :type => "application/pdf", :disposition => "attachment"
    end
    system "rm " + res_file_path
  end
end
