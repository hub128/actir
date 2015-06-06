module Actir
  module ParallelTests
    class Grouper
      class << self
        
        def in_even_groups_by_size(items, num_groups, options= {})
          groups = Array.new(num_groups) { {:items => [], :size => 0} }

          groups_to_fill = (options[:isolate] ? groups[1..-1] : groups)
          group_features_by_size(items_to_group(items), groups_to_fill)

          groups.map!{|g| g[:items].sort }
        end

        private

        def largest_first(files)
          files.sort_by{|item, size| size }.reverse
        end

        def smallest_group(groups)
          groups.min_by{|g| g[:size] }
        end

        def add_to_group(group, item, size)
          group[:items] << item
          group[:size] += size
        end

        def group_features_by_size(items, groups_to_fill)
          items.each do |item, size|
            size ||= 1
            smallest = smallest_group(groups_to_fill)
            add_to_group(smallest, item, size)
          end
        end

        def items_to_group(items)
          items.first && items.first.size == 2 ? largest_first(items) : items
        end
      end
    end
  end
end
