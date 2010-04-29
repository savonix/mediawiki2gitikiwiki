require 'dbi'
require 'mydbsetup'
require 'grit'
include Grit

dbh = DBI.connect(@mydb[:host], @mydb[:user], @mydb[:pass])


sth = dbh.prepare("SELECT #{@mydb[:prefix]}revision.rev_id
FROM  #{@mydb[:prefix]}revision, #{@mydb[:prefix]}page
WHERE #{@mydb[:prefix]}revision.rev_page = #{@mydb[:prefix]}page.page_id
AND #{@mydb[:prefix]}page.page_title = ?")

sthz = dbh.prepare("SELECT #{@mydb[:prefix]}text.old_text
FROM  #{@mydb[:prefix]}text
WHERE #{@mydb[:prefix]}text.old_id = ?")

myrepo = Grit::Repo.new(@mydb[:gitpath])
extension = '.mdwn'

File.open('page_index.mdwn') do |f|
  f.each_line do |page|
    page.gsub!("\n",'')
    sth.execute(page)
    if results = sth.fetch_all
      results.each do |row|
        begin
          puts row[0]
          #page_name = page.downcase.gsub('[','').gsub(']','').gsub(/[^a-z0-9:\/\.]/,'_')
          page_name = page.downcase + extension
          puts page_name
          file_path = @mydb[:gitpath] + '/' + page_name
          #file_name = page_name + extension
          sthz.execute(row[0])
          if res2 = sthz.fetch_all
            res2.each do |row|
              begin
                content = row[0].gsub(/==([^=]+)==/,'## \1' << "\n")
                puts Grit::Blob.create(myrepo, {:name => page_name, :data => '' })
                puts file_path
                puts page_name
                Dir.chdir(@mydb[:gitpath]) {
                  File.open(file_path, "w") { |f| f << content }
                  #Dir.chdir(@mydb[:gitpath]) {
                  myrepo.add(page_name)
                  #}
                  commit_message = 'converted'
                  puts myrepo.commit_index(commit_message)
                }
                break
              rescue NoMethodError
                puts row.inspect
              end
            end
          end
        rescue NoMethodError
          puts row.inspect
        end
        break
      end
    end
  end
end
sth.finish
dbh.disconnect()
