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
	predir = ARGV[1] || "96x96"
	Dir["4bits/*.png"].each do |f|
		name=File.basename(f)
		names=Dir[predir+"*/"+name]
		sizes=names.map{|f2| File.size(f2)}
		FileUtils.cp names[sizes.rindex(sizes.min)],"final/"+name
	end
when "new"
	from = ARGV[1] || "histoires"
	level = ARGV[3] || 5
	%x{
		makeImg.rb 4bits ~/RodaSrv/public/users/Histoires/img/#{from}/orig
		makeImg.rb 96x96 4bits
	}
	(0...level).each do |nb|
		%x{makeImg.rb fs8 96x96#{"-fs8"*nb}}
	end
	%x{makeImg.rb final}
when "deploy"
	topic = ARGV[1] || "histoires"
	to = File.expand_path("~/RodaSrv/public/users/Histoires/img/#{topic}")
	if Dir.exists? to
		%x{
			rm -fr #{to}/96x96
			mkdir -p #{to}/96x96
			cp -R #{topic}/final/* #{to}/96x96
		}
	end
when "new-all"
	%x{
		mkdir -p histoires
		cd histoires
		makeImg.rb new histoires
		cd ..
	}
	%x{
		mkdir -p people
		cd people
		makeImg.rb new people
		cd ..
	}
when "deploy-all"
	%x{
		makeImg.rb deploy histoires
		makeImg.rb deploy people
	}
when "check-all"
	orig = "~/RodaSrv/public/users/Histoires/img"
	["histoires","people"].each do |topic|
		puts "#{topic}\n"
		if Dir["#{topic}/final/*.png"].length == Dir["#{topic}/4bits/*.png"].length
			puts "final png length ok: "+Dir["#{topic}/final/*.png"].length.to_s+"\n"
		end
		
		puts %x{du -sh #{orig}/#{topic}/orig}
		puts %x{du -sh #{topic}/final}
	end
when "help"
	puts "Version rapide\n"
	puts "mkdir -p tmp/img # ou un répertoire temporaire\n"
	puts "cd tmp/img\n"
	puts "makeImg.rb new-all\n"
	puts "makeImg.rb check-all\n"
	puts "makeImg.rb deploy-all\n"
end