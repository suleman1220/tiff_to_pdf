class PdfController < ApplicationController
  def convert
    res = TiffPdf.new.tiffs_to_pdf
    p "================================="
    p res
  end
end
