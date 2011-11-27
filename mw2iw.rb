require 'dbi'
require './mydbsetup'
require 'fileutils'
require 'grit'
include Grit

#@debug = true

dbh = DBI.connect(@mydb[:host], @mydb[:user], @mydb[:pass])

# REVISIONS
sth = dbh.prepare("SELECT #{@mydb[:prefix]}revision.rev_text_id,
  #{@mydb[:prefix]}revision.rev_comment,
  #{@mydb[:prefix]}revision.rev_user_text,
  #{@mydb[:prefix]}revision.rev_timestamp
FROM  #{@mydb[:prefix]}revision, #{@mydb[:prefix]}page
WHERE #{@mydb[:prefix]}revision.rev_page = #{@mydb[:prefix]}page.page_id
AND #{@mydb[:prefix]}page.page_title = ? ORDER BY rev_timestamp ASC")

# TEXT
sthz = dbh.prepare("SELECT #{@mydb[:prefix]}text.old_text
FROM  #{@mydb[:prefix]}text
WHERE #{@mydb[:prefix]}text.old_id = ?")

myrepo = Grit::Repo.new(@mydb[:gitpath])
extension = @mydb[:extension]
subdir = @mydb[:subdir]

# PAGES
sthp = dbh.prepare("SELECT #{@mydb[:prefix]}page.page_title
FROM  #{@mydb[:prefix]}page ORDER BY page_title")

sthp.execute()
sthp.fetch do |prow|
  page = prow[0]
  sth.execute(page)
  sth.fetch do |row|

    page_name = subdir + page.downcase.gsub(/[^a-z0-9_]/,'') + extension
    puts "#{row[0]} #{page_name}" unless @debug.nil?
    file_path = @mydb[:gitpath] + '/' + page_name

    sthz.execute(row[0])
    if res2 = sthz.fetch_all
      res2.each do |zrow|
        content = zrow[0].gsub(/(^=+)/) {|s| '#' * s.size }.gsub('[[Category:','[[!tag ').gsub(/=+$/,'')
        msg = Grit::Blob.create(myrepo, {:name => page_name, :data => '' })
        puts "#{msg} #{file_path} #{page_name}" unless @debug.nil?
        Dir.chdir(@mydb[:gitpath]) {
          File.open(file_path, "w") { |f| f << content }
          myrepo.add(page_name)
          commit_message = "#{row[1]} by #{row[2]} on #{row[3]}"
          msg = myrepo.commit_index(commit_message)
          puts msg unless @debug.nil?
        }
      end
    end
  end
end
sth.finish
dbh.disconnect()
