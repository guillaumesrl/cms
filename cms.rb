# frozen_String_literal: true

require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/reloader' if development?
require 'redcarpet'


configure do
  enable :sessions
  set :session_secret, 'super secret'
  set :erb, :escape_html => true
end



before do
  @session = session
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def create_document(name, content = "")
  f = File.open(File.join(data_path, name), "w")
  f.close()
end

def valid_name(filename)
  !filename.empty? && filename.match?(/\w*\.\w{1,5}/)
end

helpers do
  def list_files(pattern)
    Dir.glob(pattern).map { |path| File.basename(path) }
  end

  def render_markdown(content)
    markdown_instance = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown_instance.render(content)
  end

  def load_file(path)
    content = IO.read(path)
    case File.extname(path)
    when ".txt"
      headers["Content-Type"] = "text/plain"
      content
    when ".md"
      render_markdown(content)
    end
  end
end


get '/' do
  pattern = File.join(data_path, "*")
  @list = list_files(pattern)
  erb :index, layout: :layout
end

get '/new' do
  erb :new, layout: :layout
end

get '/:file' do
  file_path = File.join(data_path ,params[:file])
  if File.file?(file_path)
    load_file(file_path)
  else
    session[:message] = "#{params[:file]} does not exist"
    redirect "/"
  end
end

get '/:file/edit' do
  @file = params[:file]
  file_path = File.join(data_path, params[:file])
  @content = IO.read(file_path)
  erb :edit, layout: :layout
end

post '/:file/edit' do
  file_path = File.join(data_path, params[:file])
  File.write(file_path, params[:content])
  session[:message] = "#{params[:file]} has been updated"
  redirect "/"
end

post '/new' do
  p valid_name(params[:document])
  if valid_name(params[:document])
    create_document(params[:document])
    session[:message] = "#{params[:document]} has been created"
    redirect '/'
  else
    session[:message] = "Document name must be provided with an extension"
    erb :new, layout: :layout
  end
end

