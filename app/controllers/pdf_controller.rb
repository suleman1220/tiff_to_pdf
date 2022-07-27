require "down"
require "fileutils"
require "net/http"

class PdfController < ApplicationController
  def convert
    url = URI.parse('http://docker1.ihids.com:19100/api/rest/v1/config?name=hpf_connector&version=local_test&company=demo')
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    parsed_res = JSON.parse res.body
    base_path = parsed_res['config']['data'].find {|conf| conf['Name'] == 'base_path'}

    if base_path.present? and base_path["Value"].present?
      tiff_files = []
      params[:files].each do |tiff_file|
        tempfile = Down.download(base_path["Value"] + '/' + tiff_file)
        FileUtils.mv(tempfile.path, Rails.root.join('workdir', tempfile.original_filename))
        tiff_files.push(Rails.root.join('workdir', tempfile.original_filename))
      end
      res_file_path = TiffPdf.new(tiff_files).tiffs_to_pdf
      File.open(res_file_path, 'r') do |f|
        send_data f.read.force_encoding('BINARY'), :filename => "combined_tiffs.pdf", :type => "application/pdf", :disposition => "attachment"
      end
      system "rm " + res_file_path + ' ' + tiff_files.join(' ')
    else
      render json: { success: false, message: "base_path not found!" }
    end
  end
end
