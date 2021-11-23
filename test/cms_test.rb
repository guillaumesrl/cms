ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'
require 'fileutils'
Minitest::Reporters.use!

require_relative '../cms'


class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
    create_document("test.txt", "coucou")
    create_document("test.md", "**hello**")
  end
  
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def app
    Sinatra::Application
  end

  def test_index
    get '/'
    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert(last_response.body.include?("test.txt"))
    assert_includes(last_response.body, "test.txt")
  end

  def test_file
    get '/test.txt'
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert(last_response.body.include?("coucou"))
  end

  def test_nonexistantfile
    get '/zfzffz.txt'
    assert_equal(302, last_response.status)
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "does not exist")
  end

  def test_viewing_markdown_files
    get '/test.md'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<strong>")
  end

  def test_editing_document
    get "/test.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_updating_document
    post "/test.txt/edit", content: "new content"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "test.txt has been updated"
  
    get "/test.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end
end