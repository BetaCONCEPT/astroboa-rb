# encoding: utf-8
#begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'rspec/expectations'
require 'cucumber/formatter/unicode'
$:.unshift(File.dirname(__FILE__) + '/../../../lib')
require 'astroboa-rb'

Before do
  @astroboaClient = Astroboa::Client.new('localhost:8080', 'altcine', 'SYSTEM', 'altcine2010')
  @astroboaClient.on_error do |exception|
    puts exception.message
  end
end

After do
end

Given /^the following text resources persisted to astroboa$/ do |table|
  # table is a Cucumber::Ast::Table
end


# CREATE A NEW TEXT RESOURCE (ASTROBOA OBJECT OF TYPE genericContentResourceObject)
Given /^a text resource \(stored in hash "my_new_text_resource"\) with title "([^"]*)" and body "([^"]*)" has already been persisted to astroboa$/ do |title, body|
  step "a hash object named \"my_new_text_resource\" is created that holds the text resource property values, i\.e\. title=\"#{title}\" and body=\"#{body}\""
  step "method createObject(my_new_text_resource) is called"
end

When /^a hash object named "my_new_text_resource" is created that holds the text resource property values, i\.e\. title="([^"]*)" and body="([^"]*)"$/ do |title, body|
  @my_new_text_resource = {"contentObjectTypeName" => "genericContentResourceObject", "profile" => {"title" => title}, "body" => body}
  puts "this is the resource hash before it is persisted: #{@my_new_text_resource}"
end




# CREATE ASTROBOA OBJECT FROM RUBY HASH
When /^method createObject\(my_new_text_resource\) is called$/ do
  @my_new_text_resource_id = @astroboaClient.createObject @my_new_text_resource
end

Then /^an id has been assigned to it$/ do
    @my_new_text_resource['cmsIdentifier'].should_not eq(nil)
    puts "this is the resource hash after it is persisted: #{@my_new_text_resource}" 
end

Then /^the new resource id is returned by the call$/ do
    @my_new_text_resource_id.should_not eq(nil)
    puts "the call has returned: #{@my_new_text_resource_id}" 
end

Given /^the id of the persisted resource is stored in variable "([^"]*)"$/ do |id_of_resource|
  self.instance_variable_set("@#{id_of_resource}", @my_new_text_resource_id)
  id = self.instance_variable_get("@#{id_of_resource}")
  puts "The id is: #{id}"
end




# READ ASTROBOA OBJECT AS RUBY HASH
When /^method getObject\(id_of_resource_to_read\) is called$/ do
  @retrieved_text_resource = @astroboaClient.getObject @id_of_resource_to_read 
end

Then /^a hash object with the resource is returned$/ do
  @retrieved_text_resource.should_not eq(nil)
  @retrieved_text_resource['cmsIdentifier'].should eq(@id_of_resource_to_read)
  puts "The retrieved resource is: #{@retrieved_text_resource}"
end





# READ ASTROBOA OBJECT AS RUBY OBJECT
When /^method getObject\(id_of_resource_to_read, nil, :object\) is called$/ do
  @retrieved_text_resource = @astroboaClient.getObject(@id_of_resource_to_read, nil, :object)  
end

Then /^an Openstruct object with the resource is returned$/ do
  @retrieved_text_resource.should_not eq(nil)
  @retrieved_text_resource.cmsIdentifier.should eq(@id_of_resource_to_read)
  @retrieved_text_resource.profile.title.should eq('Test Resource 2')
  puts "The retrieved resource is: #{@retrieved_text_resource}"
end

#Given /^the id of the persisted resource is stored in variable "id_of_resource_to_update"$/ do
#  @id_of_resource_to_update = @my_new_text_resource_id
#  puts "The id is: #{@id_of_resource_to_update}"
#end

# UPDATE EXISTING ASTROBOA OBJECT
When /^method updateObject\(([^\)]*)\) is called$/ do |resource_hash_string|
  resource = {"contentObjectTypeName" => "genericContentResourceObject", "cmsIdentifier" => @id_of_resource_to_update, "body" => "Updated Body Text"}
  response = @astroboaClient.updateObject resource
  response.should_not eq(nil)
  puts "response is: #{response}"
end

Then /^the body text of the persisted text resource is "([^"]*)"$/ do |body_text|
  text_resource = @astroboaClient.getObject @id_of_resource_to_update
  text_resource['body'].should eq(body_text)
end



# GET A COLLECTION OF OBJECTS (i.e. search in astroboa with criteria and get back a collection of objects that meet the criteria) 
When /^method getObjectCollection\('objectType="genericContentResourceObject" AND body CONTAINS "Hello"'\) is called$/ do
  query = 'objectType="genericContentResourceObject" AND body CONTAINS "Hello"'
  @resource_collection = @astroboaClient.getObjectCollection(query)
  @resource_collection.should_not eq(nil)
end


Then /^the persisted resource is contained in the resource collection we get back$/ do
  text_resources = @resource_collection['resourceCollection']['resource']
  found_id = nil
  puts "Looking for resource #{@id_of_resource}"
  text_resources.each do |text_resource|
    puts text_resource['cmsIdentifier']
    if text_resource['cmsIdentifier'] == @id_of_resource
      found_id = text_resource['cmsIdentifier']
      break
    end 
  end
  puts found_id
  found_id.should_not eq(nil)
end


# READ ALL MODELED OBJECT TYPES (i.e. if no object type or property is specified when callint the getModel method then all object types are returned)
When /^method getModel is called and the argument "objectTypeOrProperty" is absent or equal to the empty string$/ do
  @resource_type_collection = @astroboaClient.getModel
  @resource_type_collection.should_not eq(nil)
end

Then /^a hash with all object types modeled in the repository is returned and the hash contains the core object type "([^"]*)"$/ do |expected_object_type|
  object_types = @resource_type_collection['arrayOfObjectTypes']['objectType']
  found_type = nil
  object_types.each do |object_type|
    if object_type['name'] == expected_object_type
      found_type = object_type['name']
      break
    end 
  end
  found_type.should_not eq(nil)
end
