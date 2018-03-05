require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'pry'
require 'sinatra/content_for'

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
  # binding.pry
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
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :list
end

get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :edit_list
end

post '/lists/:id' do
  new_name = params[:list_name].strip
  error = error_for_list_name(new_name)
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = new_name
    session[:success] = "The list name has been updated."
    redirect "/lists/#{@list_id}"
  end
end

post '/lists/:id/destroy' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_list_todo(text)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The todo was added"
    redirect "/lists/#{@list_id}"
  end
end

post '/lists/:list_id/todos/:todo_id/destroy' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo = @list[:todos]
  todo.delete_at(params[:todo_id].to_i)
  session[:success] = "The todo was deleted"
  redirect "/lists/#{@list_id}"
end

post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todos = @list[:todos]
  todo_id = params[:todo_id].to_i
  todo = todos[todo_id]
  todo[:completed] = params[:completed] == "true"
  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todos = @list[:todos]
  todos.each {|todo| todo[:completed] = true}
  session[:success] = "All todos has been completed"
  redirect "/lists/#{@list_id}"
end

helpers do
  def list_complete?(list)
    !list[:todos].empty? && list[:todos].all? {|todo| todo[:completed] }
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todo_remaining_count(list)
    "#{list[:todos].count {|todo| todo[:completed] }}/#{list[:todos].size}"
  end
end


private

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must between 1 and 100 characters"
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be uniqe"
  end
end

def error_for_list_todo(name)
  if !(1..100).cover? name.size
    "Todo must between 1 and 100 characters"
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be uniqe"
  end
end


