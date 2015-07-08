# Remove standard rails tasks
original_db_structure_dump_task = Rake.application.instance_variable_get(:@tasks).delete('db:structure:dump')

namespace :db do
  namespace :structure do
    desc 'Dump the database structure to db/structure.sql. Specify another file with DB_STRUCTURE=db/my_structure.sql'
    task :dump => [:environment, :load_config] do
      config = current_config
      filename = ENV['DB_STRUCTURE'] || File.join(Rails.root, "db", "structure.sql")
      case config['adapter']
        when /mysql/
          require 'db_structure_ext'
          ActiveRecord::Base.establish_connection(config)
          connection_proxy = DbStructureExt::MysqlConnectionProxy.new(ActiveRecord::Base.connection)
          File.open(filename, "w+") { |f| f << connection_proxy.structure_dump }

          if connection_proxy.supports_migrations?
            File.open(filename, "a") { |f| f << connection_proxy.dump_schema_information }
          end
        else
          original_db_structure_dump_task.invoke
      end
      #db_namespace['structure:dump'].reenable
    end
  end
end
