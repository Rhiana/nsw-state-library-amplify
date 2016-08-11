module VoiceBase
  class Upload
    def initialize()
      unless ENV['VOICEBASE_CLIENT_TOKEN']
        raise "No client ID set."
      end
      @client = _getClient()
      @uploading = false
      @tries = 0
      @max_tries = 50
    end

    def createItem(transcript)
      success = _createSingleItem(transcript[:audio_url])
      if success
        transcript_status = TranscriptStatus.find_by_name("audio_uploaded")
        transcript.update(transcript_status_id: transcript_status[:id])
      end
    end

    private

    # Create a single transcript for a given audio URL.
    def _createSingleItem(audio_url)
      media_id = nil
      status = nil
      @uploading = true
      result = @client.post '/media', {
        remote_file_url: transcript.audio_url,
        configuration: {
          transcripts: {},
          publish: {}
        }
      }
      if (!!result)
        media_id = result["media_id"]
        status = result["status"]
      end
      @tries = 0
      success = false
      while @uploading == true || @tries < @max_tries
        success = _createSingleItemCheck(media_id)
      end
      success
    end

    def _createSingleItemCheck(media_id)
      result = @client.get_transcript({
        media_id: media_id
      }, {'Accept' => 'text/srt'})
      if result.success?
        @uploading = false
        true
      else
        @tries += 1
        sleep(1)
        false
      end
    end

    def _getClient()
      VoiceBase::Client.new(
        api_version: "2.0.beta",
        id: ENV['VOICEBASE_CLIENT_ID'],
        secret: ENV['VOICEBASE_CLIENT_SECRET'],
      )
    end
  end
end
