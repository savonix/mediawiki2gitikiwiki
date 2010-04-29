require 'dbi'
require 'mydbsetup'
dbh = DBI.connect(@mydb[:host], @mydb[:user], @mydb[:pass])


sth = dbh.prepare("SELECT #{@mydb[:prefix]}revision.rev_id
FROM  #{@mydb[:prefix]}revision, #{@mydb[:prefix]}page
WHERE #{@mydb[:prefix]}revision.rev_page = #{@mydb[:prefix]}page.page_id
AND #{@mydb[:prefix]}page.page_title = ?")

sthz = dbh.prepare("SELECT #{@mydb[:prefix]}text.old_text
FROM  #{@mydb[:prefix]}text
WHERE #{@mydb[:prefix]}text.old_id = ?")

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
                puts row[0].gsub(/==([^=]+)==/,'## \1' << "\n")
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
