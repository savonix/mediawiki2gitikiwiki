require 'dbi'
require 'mydbsetup'
dbh = DBI.connect(@mydb[:host], @mydb[:user], @mydb[:pass])


sth = dbh.prepare("SELECT hungrywiki_revision.rev_id
FROM  hungrywiki_revision, hungrywiki_page
WHERE hungrywiki_revision.rev_page = hungrywiki_page.page_id
AND hungrywiki_page.page_title = ?")

sthz = dbh.prepare("SELECT hungrywiki_text.old_text
FROM  hungrywiki_text
WHERE hungrywiki_text.old_id = ?")

File.open('page_index.mdwn') do |f|
  f.each_line do |page|
    sth.execute(page.gsub("\n",''))
    if results = sth.fetch_all
      results.each do |row|
        begin
          puts row[0]
          sthz.execute(row[0])
          if res2 = sthz.fetch_all
            res2.each do |row|
              begin
                puts row[0]
              rescue NoMethodError
                puts row.inspect
              end
            end
          end
        rescue NoMethodError
          puts row.inspect
        end
      end
    end
  end
end
sth.finish
dbh.disconnect()
