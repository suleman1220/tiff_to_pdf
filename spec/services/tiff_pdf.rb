require 'rails_helper'

RSpec.describe TiffPdf, type: :model do
  describe '#call' do
    it 'pass tiff files array and create combined pdf' do
      files = [
        Rails.root.join('test_files', 'tiff1.tiff'),
        Rails.root.join('test_files', 'tiff2.tiff'),
        Rails.root.join('test_files', 'tiff3.tiff')
      ]

      res_file_path = TiffPdf.new(files).tiffs_to_pdf

      expect(res_file_path).to be_instance_of(String)

      system "rm " + res_file_path
    end
  end
end