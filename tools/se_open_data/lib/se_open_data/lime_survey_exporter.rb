
require 'se_open_data/lime_survey_rpc'
require 'base64'


module SeOpenData

  # Wrapper for SeOpenData::LimeSurveyRpc that makes exporting responses simpler.
  class LimeSurveyExporter
    # Creates an instance, given the API endpoint and
    # your credentials.
    #
    # This can then be used to export multiple survey response sets.
    def initialize(url, username, password)
      @username = username
      @password = password
      @rpc = SeOpenData::LimeSurveyRpc.new(url)
    end

    # Export a single survey response set.
    #
    # Supplemental options correspond to options following the
    # `survey_id` option described here:
    #
    # https://api.limesurvey.org/classes/remotecontrol_handle.html#method_export_responses
    def export_responses(survey_id, *options)
      unless @session_key
        @session_key = @rpc.get_session_key(@username, @password)
      end
      base64_data = @rpc.export_responses(@session_key, survey_id, *options)
      Base64.decode64(base64_data)
    end

    # Releases the session key.
    def finalize
      @rpc.release_session_key(@session_key) if @session_key
      @session_key = nil
    end
  end
end
