#!/usr/bin/env ruby
# encoding: utf-8
# Version = '20190824-130259'

unless job_ids=ARGV[0,1000] and job_ids[0] =~ /\d+/ or job_ids[0] == '-'
  puts <<-eos
  usage:
   #{File.basename(__FILE__)} [JOB ID(s)]
  or
   qstat -u "*" -q GT|#{File.basename(__FILE__)} -
  eos
  exit
end

get_job_name =->(job_id) do
  command = "qstat -j #{job_id}"
  job_name = ""
  scratch = ""
  IO.popen(command) do |e|
    while line=e.gets
      if line =~ /job_name/
        x, job_name = line.chomp.split
      elsif line =~ /stdout_path_list.+(\/srv.+)/
        stdout_file = $1
        if File.exist?(stdout_file)
          File.readlines(stdout_file).each do |line|
            if line =~ /^at/
              at, scratch = line.chomp.split
            end
          end
        end
      end
    end
  end
  [job_name, scratch]
end

reformat_print = ->(line) do
  job_id, prior, name, user, state, date, time, host, cores, *others = line.chomp.split
  job_name, scratch = get_job_name[job_id]
  host_name = host.split('.').first.gsub(/GT@/, '')
  date_time = [date, time].join(":")
  host_scratch = [host_name, scratch].join(":")
  puts [job_id, user, state, date_time, host_scratch, cores, job_name].join("\t")
end

headers = ["job-ID", "user", "state", "date", "host", "cores", "name"]
puts headers.join("\t")
puts "-"*(headers.join("\t").length+headers.length*3)
if job_ids[0] == "-"
  while line=gets
    if line =~ /\s\d+/
      reformat_print[line]
    end
  end
else
  command = 'qstat -u "*" -q GT'
  IO.popen(command) do |e|
    while line = e.gets
      if line =~ /\s(\d+)/
        job_id = $1
        if job_ids.include?(job_id)
          reformat_print[line]
        end
      end
    end
  end
end
