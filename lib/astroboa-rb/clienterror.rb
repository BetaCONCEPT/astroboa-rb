# This is the base AstroboaClient exception class. 
# For your convenience you do not need to write rescue code for each astroboa client api call. 
# If an error occurs the exception is not directly raised but rather it is passed to 
# either an exception hadling error block that you may provide in each api call
# or otherwise to the generic error callback that you have specified by means of the "on_error" method 
# if you provide no error handling block and no generic error callback is set then a non successful api call returns nil as a response
# All succeful api calls return non nil responses so a quick and easy way to check the success of the call without writing error
# handling blocks is to check for a non nil response. 
# You can get the status code of the api call (i.e the corresponding http code) by e.api_code. 
# if any response related to the error has been returned, you may see the response by e.api_response
# A message related to the error is available at e.message
# Use e.inspet or e.to_s to get the error message as well as the api response

module Astroboa
  
  class ClientError < RuntimeError
  
    attr_accessor :api_response, :api_code
    attr_writer :message

    def initialize message = nil, api_code = nil, api_response = nil  
      @message = message
      @api_code = api_code
      @api_response = api_response
    end

    def inspect
      "#{message}: #{api_response}"
    end

    def to_s
      inspect
    end

    def message
      @message || self.class.name
    end

  end

end