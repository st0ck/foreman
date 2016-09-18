require "erb"
require "foreman/export"

class Foreman::Export::CustomUpstart < Foreman::Export::Base
  def export
    super

    master_file = "#{app}.conf"
    clean File.join(location, master_file)
    write_template master_template, master_file, binding

    engine.each_process do |name, process|
      process_master_file = "#{app}-#{name}.conf"
      clean File.join(location, process_master_file)

      next if engine.formation[name] < 1
      write_template process_master_template, process_master_file, binding

      1.upto(engine.formation[name]) do |num|
        port = engine.port_for(process, num)
        process_file = "#{app}-#{name}-#{num}.conf"
        clean File.join(location, process_file)
        write_template process_template(process), process_file, binding
      end
    end

    export_reload_script
  end

  private

  def export_reload_script
    name = "#{app}-reload.conf"
    clean File.join(location, name)
    write_template reload_template, name, binding
  end

  def reload_template
    "custom_upstart/reload.conf.erb"
  end

  def master_template
    "custom_upstart/master.conf.erb"
  end

  def process_master_template
    "custom_upstart/process_master.conf.erb"
  end

  def process_template(process)
    name =
      case process.command
      when /exec\s+unicorn/ then :unicorn
      when /rake\s+resque/ then :resque
      else :process
      end
    "custom_upstart/#{name}.conf.erb"
  end
end
