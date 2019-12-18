#!/usr/bin/env ruby
require 'fileutils'

case ARGV[0]
when "fs8" # Le but: ne pas modifier le répertoire d'origine
	from = ARGV[1]
	to = ARGV[2] || ARGV[1] + "-fs8"
	if Dir.exists? from
		%x{
			mkdir -p #{to}/saved
			cp #{from}/*.png #{to}/saved
			cd #{to}
			pngquant --quality 65-80 saved/*.png
			mkdir -p fs8
			mv saved/*-fs8.png fs8/
			cd fs8
			xattr -c *.png #supprime le @ correspondant dans un ls à un extended attribute
			cd ..
		}
		Dir.chdir to
		Dir["fs8/*-fs8.png"].each do |f|
			f =~ /^fs8\/(.*)\-fs8\.png/
			nf = $1+".png"
			puts f+" -> "+ nf
			FileUtils.cp f,nf
			FileUtils.rm f
		end
		puts "rmdir fs8"
		FileUtils.rmdir "fs8"
		puts "rmdir saved"
		Dir["saved/*.png"].each do |f|
			FileUtils.rm f
		end
		FileUtils.rmdir "saved"

	else
		puts "Warning #{dir} folder does not exist!"
	end
when "4bits"
	from = ARGV[1]
	to = ARGV[2] || "4bits"
	if Dir.exists? from
		%x{
			mkdir -p #{to}
			cp -r #{from}/*.png #{to}
			cd #{to}
			mogrify -colors 16 *.png
		}
	end
when "16x16","32x32","64x64","96x96"
	from = ARGV[1] || "4bits"
	to = ARGV[2] || ARGV[0]
	if Dir.exists? from
		%x{
			mkdir -p #{to}
			cp -r #{from}/*.png #{to}
			cd #{to}
			mogrify -resize #{ARGV[0]} *.png
		}
	end
when "final"
	%x{mkdir -p final}
	predir = ARGV[1] || "96x96"
	Dir["4bits/*.png"].each do |f|
		name=File.basename(f)
		names=Dir[predir+"*/"+name]
		sizes=names.map{|f2| File.size(f2)}
		FileUtils.cp names[sizes.rindex(sizes.min)],"final/"+name
	end
end