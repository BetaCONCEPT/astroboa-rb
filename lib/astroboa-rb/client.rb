# encoding: utf-8

require 'logger'
require 'rest-client'
require 'json'
require 'ostruct'


module Astroboa
  
  class Client
  
    def self.version
      Astroboa::VERSION
    end
    
    # get and set options for the JSON parser
    # by default the nesting level is raised from 20 to 50
    attr_accessor :json_options
    
    attr_reader :repository, :astroboaIPAddressOrFQDN, :username
    attr_reader :resourceApiBasePath, :objectsApiPath, :taxonomiesApiPath, :topicsApiPath, :modelsApiPath
    attr_reader :objectsResource, :taxonomiesResource, :topicsResource, :modelsResource
  
    def initialize(astroboaIPAddressOrFQDN, repository, username = nil , password = nil)
      # the IP or Fully Qualified Domain Name of the server that provides the astroboa data services 
      @astroboaIPAddressOrFQDN = astroboaIPAddressOrFQDN
      
      # the id of the repository from which we want to read or write resources (multiple repositories can be served by each astroboa server)
      @repository = repository
      
      @username = username
      @password = password
      
      @resourceApiBasePath = "http://#{astroboaIPAddressOrFQDN}/resource-api"
      
      # this resource is about all repositories and does not require a repository to be specified
      @repositoriesResource = RestClient::Resource.new(@resourceApiBasePath, {:user => username, :password => password, :headers => astroboa_client_headers})
      
      # all other resources require a repository to be specified
      create_repository_resources(repository)

      @log = Logger.new('/tmp/astroboa-rb-log.txt')
      @log.level = Logger::WARN
    
      RestClient.log = @log
      
      # some json payloads have very deep nesting and the JSON parser option should be set to allow deeper nesting
      # the default parser nesting is 20. We set it to 50 and the user may set it to a higher level through :json_options accessor
      @json_options = {:max_nesting => 50}
      
    end
    
    # set the repository
    def repository= (repository)
      @repository = repository
      
      # each time a repository is set we regenerate the resource api calls to target the specified repository
      create_repository_resources(repository)
    end
    
    # set your own logger
    def log= (logger)
      @log = logger
      RestClient.log = logger
    end
  
    #
    # API
    #
  
    def getObject(idOrName, projectionPaths = nil, output = :hash, &exception_block)
      if idOrName && !idOrName.empty?
        begin
          case output
          when :json
            acceptHeader = :json
            outputParam = 'json'
          when :xml
            acceptHeader = :xml
            outputParam = 'xml'
          when :hash, :object
            acceptHeader = :json
            outputParam = 'json'
          else
            message = "Astroboa API cannot return resources as #{output}. Please see the documentation for available output options."
            log.error message
            handle_error(message, nil, &exception_block)
          end
        
          response = nil
          params = {'output' => outputParam}
          if projectionPaths
            params['projectionPaths'] = projectionPaths
          end
          
          response = @objectsResource["#{idOrName}"].get :params => params, :accept => acceptHeader
          
          case output
          when :json, :xml
            return response.body
          when :hash
            return JSON response.body
          when :object
            objectHash = JSON.parse(response.body, @json_options)
            return objectHash.to_openstruct
          end 
        rescue => api_exception
          @log.error "Astroboa getObject call failed. Error is #{api_exception.inspect}. The requested object id (or name) was: #{idOrName}."
          message = "Astroboa getObject call failed. The requested object id (or name) was: #{idOrName}."
          handle_error(message, api_exception, &exception_block)
        end
      else
        message = "You should specify the id or name of the object."
        @log.error message
        handle_error(message, nil, &exception_block)
      end      	
    end
  
  
    def createObject(objectHash, &exception_block)
      if !objectHash or objectHash.empty?
         message = "You should specify an non empty hash of the object you want to create."
          @log.error message
          handle_error(message, nil, &exception_block)
          return
      end
      
      if objectHash.has_key?('cmsIdentifier')
        message = "You have specified an object identifier. Object identifiers are automatically assigned by astroboato new objects. Please remove the identifier if this is a new object or use updateObject if it is an existing object."
        @log.warn message
        handle_error(message, nil, &exception_block)
      else
        begin
          response = @objectsResource.post objectHash.to_json, :content_type => :json 
          objectHash['cmsIdentifier'] = response.body.to_s
          return response.body.to_s
        rescue => api_exception
          @log.error "Astroboa createObject call failed. Error is #{api_exception.inspect}. The object to be created was: #{objectHash}."
          message = "Astroboa createObject call failed. The object to be created was: #{objectHash}."
          handle_error(message, api_exception, &exception_block)
        end 
      end 	
    end
  
  
    def updateObject(objectHash, updateLastModificationTime = true, &exception_block)
      if !objectHash or objectHash.empty?
         message = "You should specify an non empty hash of the object you want to update."
          @log.error message
          handle_error(message, nil, &exception_block)
          return
      end
      
      if objectHash.has_key?('cmsIdentifier')
        begin
          response = @objectsResource["#{objectHash['cmsIdentifier']}"].put objectHash.to_json, :params => {'updateLastModificationTime' => updateLastModificationTime}, :content_type => :json 
          return response.body.to_s
        rescue => api_exception
          @log.error "Astroboa updateObject call failed. Error is #{api_exception.inspect}. The object to be updated was: #{objectHash}."
          message = "Astroboa updateObject call failed. The object to be updated was: #{objectHash}."
          handle_error(message, api_exception, &exception_block)
        end
      else
        message = "You try to update an object that does not have an identifier. If your object is new then use createObject to create a new object."
        @log.error message
        handle_error(message, nil, &exception_block)
      end      	
    end
    
    def getObjectCollection(query = nil, options = {}, &exception_block)
      begin
        projectionPaths = options[:project] 
        offset = options[:offset] ||= 0 
        limit = options[:limit] ||= 50 
        orderBy = options[:orderBy] ||= 'profile.modified desc'
        output = options[:output] ||= :hash
        
        case output
        when :json
          acceptHeader = :json
          outputParam = 'json'
        when :xml
          acceptHeader = :xml
          outputParam = 'xml'
        when :hash, :object
          acceptHeader = :json
          outputParam = 'json'
        else
          message = "Astroboa API cannot return resources as #{output}. Please see the documentation for available output options."
          log.error message
          handle_error(message, nil, &exception_block)
        end
      
        response = nil
        params = {'output' => outputParam}
      
        if query
          params['cmsQuery'] = query
        end
      
        if projectionPaths
          params['projectionPaths'] = projectionPaths
        end
      
        params['offset'] = offset
        params['limit'] = limit
        params['orderBy'] = orderBy
      
        response = @objectsResource.get :params => params, :accept => acceptHeader

        case output
        when :json, :xml
          return response.body
        when :hash
          return JSON.parse(response.body, @json_options)
        when :object
          objectHash = JSON.parse(response.body, @json_options)
          return objectHash.to_openstruct
        end 
      rescue => api_exception
        @log.error "Astroboa getObjectCollection call failed. Error is #{api_exception.inspect}. The requested collection query was: #{query}, with projection paths: #{projectionPaths}, offset: #{offset}, limit: #{limit}, orderBy: #{orderBy}."
        message = "Astroboa getObjectCollection call failed. The requested collection query was: #{query}, with projection paths: #{projectionPaths}, offset: #{offset}, limit: #{limit}, orderBy: #{orderBy}."
        handle_error(message, api_exception, &exception_block)
      end
    end
    
    def getModel(objectTypeOrProperty='', output = :hash, &exception_block)
      begin
        case output
        when :json
          acceptHeader = :json
          outputParam = 'json'
        when :xml
          acceptHeader = :xml
          outputParam = 'xml'
        when :hash, :object
          acceptHeader = :json
          outputParam = 'json'
        else
          message = "Astroboa API cannot return resources as #{output}. Please see the documentation for available output options."
          log.error message
          handle_error(message, nil, &exception_block)
        end
      
        response = nil
        params = {'output' => outputParam}
        
        if objectTypeOrProperty && !objectTypeOrProperty.empty?
          response = @modelsResource["#{objectTypeOrProperty}"].get :params => params, :accept => acceptHeader
        else 
          response = @modelsResource.get :params => params, :accept => acceptHeader
        end
        
        case output
        when :json, :xml
          return response.body
        when :hash
          return JSON.parse(response.body, @json_options)
        when :object
          objectHash = JSON.parse(response.body, @json_options)
          return objectHash.to_openstruct
        end 
      rescue => api_exception
        @log.error "Astroboa getModel call failed. Error is #{api_exception.inspect}. The requested object type or object property was: #{objectTypeOrProperty}."
        message = "Astroboa getModel call failed. The requested object type or property was: #{objectTypeOrProperty}."
        handle_error(message, api_exception, &exception_block)
      end
    end
    
    def on_error(&block)
        @error_callback = block
    end
  
    #
    # implementation
    #
  
    def handle_error(message, api_exception, &exception_block)
      if block_given?
        astroboaClientError = createAstroboaClientException(message, api_exception)
        exception_block.call(astroboaClientError)
      elsif @error_callback
        astroboaClientError = createAstroboaClientException(message, api_exception)
        @error_callback.call(astroboaClientError)
      end
    
      return nil
    
    end
  
    def createAstroboaClientException(message, api_exception)
      api_code = 'There is no astroboa api return code. The api call was not send due to the error'
      api_response = 'There is no astroboa api response. The api call was not send due to the error'
      if api_exception 
        message = "#{message} - Cause: #{api_exception.message}"
        if api_exception.respond_to?(:http_code)
          api_code = api_exception.http_code
        end
        if api_exception.respond_to?(:response)
          api_response = api_exception.response ||= 'The astroboa api call did not produce any response'
        end
      end
      Astroboa::ClientError.new(message, api_code, api_response)
    end
    
    def astroboa_client_headers
      if (defined? self.class.gem_version_string) 
        gem_version = self.class.gem_version_string
      else 
       gem_version = nil
      end
       
      {
        'X-Astroboa-API-Version' => '3.0.0',
        'User-Agent' => gem_version,
        'X-Ruby-Version' => RUBY_VERSION,
        'X-Ruby-Platform' => RUBY_PLATFORM
        }
      end
  
  
      def create_repository_resources(repository)
        @objectsApiPath = "#{@resourceApiBasePath}/#{repository}/objects"
        @taxonomiesApiPath = "#{@resourceApiBasePath}/#{repository}/taxonomies"
        @topicsApiPath = "#{@resourceApiBasePath}/#{repository}/topics"
        @modelsApiPath = "#{@resourceApiBasePath}/#{repository}/models"

        @objectsResource = RestClient::Resource.new(@objectsApiPath, {:user => @username, :password => @password, :headers => astroboa_client_headers})
        @taxonomiesResource = RestClient::Resource.new(@taxonomiesApiPath, {:user => @username, :password => @password, :headers => astroboa_client_headers})
        @topicsResource = RestClient::Resource.new(@topicsApiPath, {:user => @username, :password => @password, :headers => astroboa_client_headers})
        @modelsResource = RestClient::Resource.new(@modelsApiPath, {:user => @username, :password => @password, :headers => astroboa_client_headers})
      end
  end # class Client

end # Module Astroboa
  
  
class Object
  def to_openstruct
    self
  end
end

class Array
  def to_openstruct
    map{ |el| el.to_openstruct }
  end
end

class Hash
  def to_openstruct
    mapped = {}
    each{ |key,value| mapped[key] = value.to_openstruct }
    OpenStruct.new(mapped)
  end
end

