require 'xcodeproj'
project_path = 'WOVNapparel.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath('WOVNapparel/Features/Profile', true)
file_ref = group.files.find { |f| f.path == 'ChromaticAnalyzer.swift' }

if file_ref
  file_ref.set_path('Features/Profile/ChromaticAnalyzer.swift')
  file_ref.source_tree = '<group>'
  project.save
  puts "Fixed path!"
else
  puts "Could not find file reference."
end
