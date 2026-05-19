require 'xcodeproj'
project_path = 'WOVNapparel.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath('WOVNapparel/Features/Profile', true)
file_name = 'ChromaticAnalyzer.swift'
file_path = "WOVNapparel/Features/Profile/#{file_name}"
file_ref = group.new_reference(file_name)
target.source_build_phase.add_file_reference(file_ref, true)

project.save
