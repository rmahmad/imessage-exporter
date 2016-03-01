require "sqlite3"

if(ARGV.length == 0)
  puts "Please specify one or more iMessage accounts whose conversations you would like to export"
  exit
end

ARGV.each do |uid|
  db = SQLite3::Database.new File.join(ENV['HOME'], '/Library/Messages/chat.db')
  fname = "iMessage chat with #{uid}.txt"
  file = File.open(fname, "w")

  # SQL query based on answer to http://apple.stackexchange.com/questions/108171/export-imessages-in-human-readable-form-for-archival
  db.execute("select is_from_me,date,text from message where handle_id=(
  select handle_id from chat_handle_join where chat_id=(
  select ROWID from chat where guid='iMessage;-;#{uid}'))") do |row|
    file.puts "#{Time.at(row[1]+978307200)} #{row[0] == 1 ? "me" : "buddy"}: #{row[2]}"
  end

  file.close
end