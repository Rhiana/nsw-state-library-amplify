require 'fileutils'
require 'open-uri'
include CarrierWave::MiniMagick

namespace :s3 do
  # Usage:
  #     rake s3:file_conversion
  desc "convert manually uploaded files to carrierwave objects"
  task image_conversion: :environment do |task|
    success = []
    errors = []

    voice_base = Vendor.find_by uid: "voice_base"

    begin
      [Collection, Transcript].each do |klass|
        klass.find_each do |resource|
          # CarrierWave introduces an image_url which overrides the call to
          # the model attribute so we need to use read_attribute to access it
          image_url = resource.read_attribute(:image_url)

          if image_url.present? && resource.image.blank?
            # Setup to store file from S3 bucket
            dir_name = FileUtils.mkpath('tmp/s3_uploads/')
            file_name = File.basename(image_url)
            file_path = File.join(dir_name, file_name)

            # Download the image from S3 and store in temp folder.
            # * open the tmp file
            # * fetch the image from s3
            # * write the content to the tmp file
            open(file_path, 'wb') do |file|
              file.write open(image_url).read
            end

            # Save the remote image to the model's uploader column
            # On save the image will overwrite the remote file with the same name
            resource.vendor = voice_base
            resource.image = Rails.root.join('tmp', 's3_uploads', file_name).open

            if resource.save!
              success << resource
            else
              errors << resource
            end
          end
        end
      end
    rescue => StandardError => e
      print_result(errors: e)
    end

    print_result(success: success, errors: errors)
  end

  task audio_conversion: :environment do |task|
    success = []
    errors = []
    voice_base = Vendor.find_by uid: "voice_base"

    begin
      Transcript.find_each do |transcript|
      # CarrierWave introduces an image_url which overrides the call to the
      # model attribute so we need to use read_attribute to access it
      audio_url = transcript.read_attribute(:audio_url)

      if audio_url.present? && transcript.audio.blank?
        # Setup to store file from S3 bucket
        dir_name = FileUtils.mkpath('tmp/s3_uploads/')
        file_name = File.basename(audio_url)
        file_path = File.join(dir_name, file_name)

        # Download the audio files from S3 and store in temp folder.
        # * open the tmp file
        # * fetch the audio file from s3
        # * write the content to the tmp file
        open(file_path, 'wb') do |file|
          file.write open(audio_url).read
        end

        # Save the remote audio to the model's uploader column
        # when save the audio will be overwrite the remote file with the same name
        transcript.vendor = voice_base
        transcript.audio = Rails.root.join('tmp', 's3_uploads', file_name).open

        if transcript.save!
          success << transcript
        else
          errors << transcript
        end
      end
    end
    rescue StandardError => e
      print_result(errors: e)
    end

    print_result(success: success, errors: errors)
  end

  def print_result(args)
    if args[:success].empty? && args[:errors].empty?
      puts "*** NO RECORDS TO UPDATE ***"
    elsif args[:success].empty? && args[:errors].present?
      puts "*** FAILED TO UPDATE ***"
      puts args[:errors]
    else
      puts "*** UPDATED #{args[:success].count} RECORDS ***"
      puts "*** FAILED TO UPDATE #{args[:errors].count} RECORDS ***"
      args[:errors].each do |el|
        puts "* #{el.class} - #{el.read_attribute(:audio_url)}"
      end
    end
  end
end
