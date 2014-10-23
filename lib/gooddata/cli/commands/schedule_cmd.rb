# c = GoodData::connect('petr.cvengros@gooddata.com', '***')

# GoodData.with_project('', :client => c) do |p|

#   GoodData::Schedule.create
# end

# project_id = 'rydtfhvw1nxajw5q0hbwfr505d4b69ce'
# process_id = 'f6e39954-5b40-4681-90b2-d4356d87a446'
# cron = '20 0 * * *'
# executable = './salesforce_csv/salesforce_csv.rb'

# client = GoodData.connect 'petr.cvengros@gooddata.com', 'worstdata'
# project = client.projects(project_id)
# process = project.processes(process_id)
# schedule = process.create_schedule(cron, executable)
