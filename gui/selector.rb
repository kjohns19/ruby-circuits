require 'gtk2'
require_relative '../component/all_components'

# Main module for all circuit classes
module Circuits

# Module for gui classes
module Gui

# GTK component to select circuit components
class Selector < Gtk::ScrolledWindow
   attr_reader :selected

   # Initializes a component selector
   def initialize(app)
      super()
      @app = app

      self.set_size_request(200, 250)
      self.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

      # Get all components
      @groups = Group.new
      all = ObjectSpace.each_object(Class).select { |k| k < Circuits::Component }
      all.each do |klass|
         next if klass.name.nil?
         names = klass.name.split('::')
         names.shift
         add_to_group(@groups, names, klass)
      end

      # The tree view to display everything
      @treeview = Gtk::TreeView.new

      # Set up renderer and tree column (we only need 1)
      renderer = Gtk::CellRendererText.new
      column = Gtk::TreeViewColumn.new("Component", renderer)
      column.set_cell_data_func(renderer) do |col, renderer, model, iter|
         renderer.text = iter[0].name
      end

      @treeview.append_column(column)

      @model = Gtk::TreeStore.new(ListItem)

      # Add the components to the model
      add_group(@groups, @model, nil)

      @treeview.model = @model

      # Add tree view
      self.add(@treeview)

      @callbacks = []

      # Function to change selection when user clicks on component name
      last = nil
      @treeview.signal_connect('cursor-changed') do |tree, e|
         selection = tree.selection
         iter = selection.selected
         next unless iter
         if iter[0].component == NilClass
            selection.unselect_iter(iter)
            selection.select_iter(last) if last
         else
            last = iter
            @selected = iter[0].component
            @callbacks.each { |cb| cb.call(@selected) }
            #puts "Selected: #{@selected}"
         end
      end
   end

   def select_callback(&callback)
      @callbacks << callback unless callback.nil?
   end

private
   # Adds a group of components to a parent node
   #  First, add all subgroups (recursively calling add_group for each one)
   #  Then add all components within this group
   def add_group(group, model, parent)
      group.subgroups.sort { |a,b| a[0] <=> b[0] }.each do |k, v|
         p = model.append(parent)
         p[0] = ListItem.new(k.to_s, NilClass)
         add_group(v, model, p)
      end
      group.components.sort.each do |component|
         c = model.append(parent)
         c[0] = component
      end
   end

   # Adds a component class to its correct group
   def add_to_group(group, names, component)
      if names.length == 1
         group.components << ListItem.new(names.first, component)
      else
         add_to_group(group.subgroups[names.first], names[1..-1], component)
      end
   end

   # Item in the tree model
   class ListItem
      attr_reader :name, :component

      def initialize(name, component)
         @name = name
         @component = component
      end

      def to_s
         "#{@name} - #{@component}"
      end

      def <=> b
         compA = @component.creation_time
         compB = b.component.creation_time
         if compA == compB
            compA = @name
            compB = b.name
         end
         compA <=> compB
      end
   end

   # Group to keep track of components and subgroups
   class Group
      attr_reader :subgroups, :components
      def initialize
         @subgroups = Hash.new { |h, k| h[k] = Group.new }
         @components = []
      end
   end
end

end

end
