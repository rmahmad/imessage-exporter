require "sqlite3"
require "find"

if(ARGV.length == 0 or ARGV[0] = "-h")
  puts "Please specify one or more iMessage accounts whose conversations you would like to export. Note that this tool will only work with US phone numbers."
  exit
end

ARGV.each do |uid|
  @chatdb = SQLite3::Database.new File.join(ENV['HOME'], '/Library/Messages/chat.db')
  @localcontactdb = SQLite3::Database.new File.join(ENV['HOME'], '/Library/Application Support/AddressBook/AddressBook-v22.abcddb')
  Find.find(File.join(ENV['HOME'], '/Library/Application Support/AddressBook/Sources')) do |f|
    @icloudcontactdb = SQLite3::Database.new f if f =~ /.*\.abcddb$/
  end

  contactname = ""


  if uid.include? "@"
    query = "SELECT ZFIRSTNAME, ZLASTNAME, ZADDRESS FROM ZABCDRECORD LEFT JOIN ZABCDEMAILADDRESS ON ZOWNER = ZABCDRECORD.Z_PK WHERE ZADDRESS = \"#{uid}\""

    @localcontactdb.execute(query) do |row|
      contactname = "#{row[0]} #{row[1]}"
      break
    end
    @icloudcontactdb.execute(query) do |row|
      contactname = "#{row[0]} #{row[1]}"
      break
    end

  else
    query = "SELECT ZFIRSTNAME, ZLASTNAME, ZFULLNUMBER FROM ZABCDRECORD LEFT JOIN ZABCDPHONENUMBER ON ZOWNER = ZABCDRECORD.Z_PK WHERE ZFULLNUMBER LIKE \"%#{uid[-4..-1]}\""

    contacts = @localcontactdb.execute(query)
    contacts = contacts + @icloudcontactdb.execute(query)
    contacts.each do |row|
      row[2].gsub!(/[^0-9]/,'')
      if row[2].length == 10
        if "+1#{row[2]}" == uid
          contactname = "#{row[0]} #{row[1]}"
          break
        end
      elsif row[2].length == 11
        if "+#{row[2]}" == uid
          contactname = "#{row[0]} #{row[1]}"
          break
        end
      elsif row[2].length == 12
        if row[2] == uid
          contactname = "#{row[0]} #{row[1]}"
          break
        end
      end
    end
  end

  fname = "iMessage chat with #{contactname.length != 0 ? contactname : uid}.txt"
  file = File.open(fname, "w")

  # SQL query based on answer to http://apple.stackexchange.com/questions/108171/export-imessages-in-human-readable-form-for-archival
  @chatdb.execute("select is_from_me,date,text from message where handle_id=(
  select handle_id from chat_handle_join where chat_id=(
  select ROWID from chat where guid='iMessage;-;#{uid}'))") do |row|
    file.puts "#{Time.at(row[1]+978307200)} #{row[0] == 1 ? "me" : contactname}: #{row[2]}"
  end

  file.close
end