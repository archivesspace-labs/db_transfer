require 'rubygems'
require 'bundler/setup'


require 'sequel'
require 'sequel_plus'

require 'csv'

derby = "jdbc:derby:#{File.join(Dir.pwd, "data" , "archivesspace_demo_db")};create=true;aspacedemo=true"
mysql = "jdbc:mysql://localhost:3306/archivesspacedb?user=root&password=messymessy&useUnicode=true&characterEncoding=UTF-8"

# this is the directory where the tsv files are put
export_dir = File.join( Dir.pwd, "exports" )


# need to patch the Export Writer to deal with Date's in the way MySQL wants
# them.
class Sequel::Export::Writer

  def export_data(ds)
    quot = @options[:quote_char]
    ds.each do |row| 
      data = @columns.map do |col|
        case row[col]
        when Date then 
          "#{quot}#{row[col].strftime('%Y-%m-%d')}#{quot}" 
        when DateTime then
          "#{quot}#{row[col].strftime('%Y-%m-%d')}#{quot}" 
        when Time then 
          "#{quot}#{row[col].localtime.strftime('%Y-%m-%d %H:%M:%S')}#{quot}"
        when Float, BigDecimal then 
          row[col].to_f
        when BigDecimal, Bignum, Fixnum then 
          row[col].to_i
        else 
          "#{quot}#{row[col].to_s.gsub(quot, quot * 2 )}#{quot}"
        end
      end
      @file.puts data.join(@options[:delimiter])
    end
  end

end


# first we conntect to derby and dump the tables out.
Sequel.connect(derby) do |db|

  db.tables.each do |table|
    # no need to import this table.. 
    next if table.to_s == "session" 
    puts "exporting #{table}"
    File.open(File.join( export_dir , "#{table.to_s}.tsv" ), "w") { |file| db[table.to_sym].export(file, :quote_char => '"' ) }
  end

end

# now we connect to mysql and put the data in. 
Sequel.connect(mysql) do |db|

  begin
    db.run("SET FOREIGN_KEY_CHECKS=0")
    db.run("SET UNIQUE_CHECKS=0")
    db.run("SET AUTOCOMMIT = 0")

    Dir.glob(File.join(export_dir, "*.tsv")).each do |file|
     begin
      table = File.basename(file, ".tsv").to_sym 
      db[table].truncate 
      
      CSV.foreach( file, :headers => true, :col_sep => "\t", :quote_char => '"' ) do |row|
        begin 
          data = row.to_hash
          data.delete_if { |k,v| v.empty? }
          db[table].insert(data)
        rescue => e
          puts "\n #{ '%' * 100 }"
          puts "problem row #{row.inspect}"
          puts e.message 
          puts "\n #{ '%' * 100 }"
          next 
        end
      end
     rescue => e
       puts e.message
       puts "problem with #{file}"
     end
    end
  ensure
    db.run("SET FOREIGN_KEY_CHECKS=1")
    db.run("SET UNIQUE_CHECKS=1")
    db.run("SET AUTOCOMMIT = 1")
  end

end

