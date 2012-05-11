Feature: Astroboa Ruby Client
	Develop an astroboa ruby client that enables ruby developers 
	to easily read, write and search astroboa resources from ruby programs. 
	The client eliminates the need to execute raw http calls
	to the astroboa REST API and hides the REST API details.
	
	Background:
	    Given the following text resources persisted to astroboa
	    | contentObjectTypeName        | profile.title               | body                           |
	    | genericContentResourceObject | Test Resource 1             | Hello World 1                  |
	    | genericContentResourceObject | Test Resource 2             | Hello World 2                  |
	    | genericContentResourceObject | Test Resource to be updated | This text will be updated soon |

	
	Scenario: Create a new text resource (contentObjectTypeName="genericContentResourceObject") with title "Test Resource" and body "Hello World"
		Given a text resource (stored in hash "my_new_text_resource") with title "Test Resource" and body "Hello World" has already been persisted to astroboa
		Then an id has been assigned to it
			And the new resource id is returned by the call  
		
	Scenario: Read as hash an existing text resource using its id as identifier
		Given a text resource (stored in hash "my_new_text_resource") with title "Test Resource 2" and body "Hello World again" has already been persisted to astroboa
			And the id of the persisted resource is stored in variable "id_of_resource_to_read"
		When method getObject(id_of_resource_to_read) is called
		Then a hash object with the resource is returned 
		
	Scenario: Read as object an existing text resource using its id as identifier
		Given a text resource (stored in hash "my_new_text_resource") with title "Test Resource 2" and body "Hello World again" has already been persisted to astroboa
			And the id of the persisted resource is stored in variable "id_of_resource_to_read"
		When method getObject(id_of_resource_to_read, nil, :object) is called
			Then an Openstruct object with the resource is returned
	
	Scenario: Update the body text of an existing text resource
		Given a text resource (stored in hash "my_new_text_resource") with title "Test Resource to be updated" and body "This text will be updated soon" has already been persisted to astroboa
			And the id of the persisted resource is stored in variable "id_of_resource_to_update"
		When method updateObject({"contentObjectTypeName" => "genericContentResourceObject", "cmsIdentifier" => id_of_resource_to_update, "body" => "Updated Body Text"}) is called
		Then the body text of the persisted text resource is "Updated Body Text"
		
	Scenario: Get a collection of all text resources that their body contains the word hello
		Given a text resource (stored in hash "my_new_text_resource") with title "Hello is contained in body text" and body "The word hello is contained in this text" has already been persisted to astroboa
			And the id of the persisted resource is stored in variable "id_of_resource"
		When method getObjectCollection('contentTypeName="genericContentResourceObject" AND body CONTAINS "Hello"') is called
		Then the persisted resource is contained in the resource collection we get back
		
	Scenario: Get all object types modeled in the repository
		When method getModel is called and the argument "objectTypeOrProperty" is absent or equal to the empty string 
		Then a hash with all object types modeled in the repository is returned and the hash contains the core object type "fileResourceObject" 