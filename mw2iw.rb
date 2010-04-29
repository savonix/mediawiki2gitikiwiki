require 'dbi'
require 'mydbsetup'
dbh = DBI.connect(@mydb[:host], @mydb[:user], @mydb[:pass])


sth = dbh.prepare("SELECT hungrywiki_text.old_text
FROM  hungrywiki_text, hungrywiki_page
WHERE hungrywiki_text.old_id = hungrywiki_page.page_latest
AND hungrywiki_page.page_title = ?")
File.open('page_index.mdwn') do |f|
  f.each_line do |page|
    sth.execute(page.gsub("\n",''))
    if results = sth.fetch_all
      results.each do |row|
        begin
          puts row[0]
        rescue NoMethodError
          puts row.inspect
        end
      end
    end
  end
end
sth.finish
dbh.disconnect()
