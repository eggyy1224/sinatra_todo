require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  # binding.pry
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list
end

post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/:id" do 
  @list = session[:lists][params[:id].to_i]
  erb :list
end

private

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must between 1 and 100 characters"
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be uniqe"
  end
end
