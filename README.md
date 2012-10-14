# astroboa-rb

While you can directly use the REST-based "Astroboa Resource API" from your Ruby projects 
using the net/http library or any one of the rest client libraries, Astroboa Ruby Client greatly eases your work.

The Ruby client allows you to read, write and search content in any local or remote astroboa repository with just a few lines of code.

## Install

=== For your project using bundler

Add to your Gemfile:

  gem "astroboa-rb"

and run at the command prompt:

  bundle install

=== or as a gem in your ruby environment

Run at the command prompt:

gem install astroboa-rb
 

Below are some examples on how to use the client

## EXAMPLE USE

	# encoding: utf-8
	require 'astroboa-rb'
	
	# CONNECT TO THE REPOSITORY
	# provide the server where astroboa runs and the repository to connect to
	astroboaClient = Astroboa::Client.new('demo.betaconcept.com', 'demorepository')

	astroboaClient.on_error do |exception|
  		puts exception.message
	end

	# CREATE A NEW OBJECT
	# createObject(objectHash, &exception_block)
	# The example uses the 'out of the box' object type:'genericContentResourceObject'
	# This type simulates a simple article or blog entry with "title", "description", "subject"(tags) and "body"(the body text) properties
	# The "title", "description" and "subject" properties are stored inside the "group property" called "profile".
	# "profile" is a default property inherited to all asstroboa objects and groups all dublin core metadata    
	my_new_text_resource = {"contentObjectTypeName" => "genericContentResourceObject", "profile" => {"title" => "My First blog entry", "description" => "How I installed astroboa"}, "body" => 'Go to github and check the installation instructions...'}
	my_new_text_resource_id = astroboaClient.createObject my_new_text_resource
	puts "created object with id: #{my_new_text_resource_id}" 
	
	# GET AN OBJECT AS A RUBY HASH
	# getObject(idOrName, options = {}, &exception_block)
	options = {}
	options[:project] = 'profile.title,body' # project/filter which properties to get back
	options[:output] = 'hash' # in which form to get back the object, possible values are "hash","object","xml","json", default is "hash"
	retrieved_text_resource = astroboaClient.getObject my_new_text_resource_id, options
	puts "The retrieved resource is: #{retrieved_text_resource}"
	puts retrieved_text_resource['profile']['title']

	# GET AN OBJECT AS A RUBY OBJECT
	retrieved_text_resource = astroboaClient.getObject my_new_text_resource_id, output: 'object'  
	puts "I retrieved the resource as object and the title is: #{retrieved_text_resource.profile.title}"
	puts "The retrieved resource is: #{retrieved_text_resource}"

	# UPDATE AN EXISTING OBJECT
	# updateObject(objectHash, updateLastModificationTime = true, &exception_block)
	resource = {"contentObjectTypeName" => "genericContentResourceObject", "cmsIdentifier" => my_new_text_resource_id, "body" => "Updated Body Text...."}
	response = astroboaClient.updateObject resource
	puts "I updated the object and the response is: #{response}"

	# GET THE UPDATED OBJECT BACK
	text_resource = astroboaClient.getObject my_new_text_resource_id
	puts "I will read the updated resource back and the updated body is #{text_resource['body']}"

	# SEARCH AN OBJECT COLLECTION
	# getObjectCollection(query = nil, options = {}, &exception_block)
	options = {}
	
	# project/filter which properties to get back, here we get back only the object titles
	options[:project] = 'profile.title' 
	
	# get objects counting from 'offset' and up. Default is 0. Use it together with limit for result paging
	options[:offset] = 0 
	
	# how many object to get back. Default is 50
	options[:limit] = 50 
	
	# by which property to order the results. 
	# Use 'desc or asc after the field to ask for ascenting or descenting ordering'.
	# use commas to add more ordering fields, eg. 'profile.modified desc, profile.title asc'
	# Default is 'profile.modified desc'
	options[:orderBy] = 'profile.modified desc'  
	
	# in which form to get back the object, possible values are "hash","object","xml","json", default is "hash"
	options[:output] = 'hash'
	
	# Express the query in a similar way you specify the WHERE in SQL queries.
	# Values should be ALWAYS inside double quotes ("")
	query = 'objectType="genericContentResourceObject" AND body CONTAINS "Hello"'
	resource_collection = astroboaClient.getObjectCollection query, options

	text_resources = resource_collection['resourceCollection']['resource']
	found_id = nil
	puts "Looking for resource #{my_new_text_resource_id}"
	text_resources.each do |text_resource|
  		puts text_resource['cmsIdentifier']
  		if text_resource['cmsIdentifier'] == my_new_text_resource_id
    		found_id = text_resource['cmsIdentifier']
    		break
  		end 
	end
	puts "found #{found_id}"


# LICENSE
-------
Released under the LGPL license; see the files LICENSE, COPYING and COPYING.LESSER.


   

