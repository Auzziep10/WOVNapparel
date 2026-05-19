require 'xcodeproj'
project_path = 'WOVNapparel/WOVNapparel.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath('WOVNapparel/Features/Gallery', true)
group.set_source_tree('<group>')
group.set_path('Features/Gallery')

['TryOnGalleryView.swift', 'TryOnDetailView.swift'].each do |file_name|
  file_path = "WOVNapparel/Features/Gallery/#{file_name}"
  file_ref = group.new_reference(file_name)
  target.source_build_phase.add_file_reference(file_ref, true)
end

project.save
