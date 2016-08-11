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
        _updateStatus(transcript, "audio_uploaded")
      end
    end

    def getItem(transcript)
      result = _getTranscript(transcript[:vendor_identifier])
      # @TODO: Any conversion between VoiceBase's response JSON and PUA's.
      result
    end

    private

    # Update status for a transcript.
    def _updateStatus(transcript, status_name)
      transcript_status = TranscriptStatus.find_by_name(status_name)
      transcript.update(transcript_status_id: transcript_status[:id])
    end

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
      result = _getTranscript(media_id)
      if result.success?
        @uploading = false
        true
      else
        @tries += 1
        sleep(1)
        false
      end
    end

    def _getTranscript(media_id)
      @client.get_transcript({
        media_id: media_id
      }, {'Accept' => 'text/srt'})
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
