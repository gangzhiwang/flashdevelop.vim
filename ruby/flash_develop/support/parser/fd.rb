# Copyright 2012 Endel Dreyer. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'rexml/document'

module FlashDevelop
  module Support
    module Parser

      class FD
        attr_reader :data
        PATTERN = '**/**.as3proj'

        def parse(xml)
          @data = {}
          root = REXML::Document.new(open(xml).read).root

          output_name = File.basename(root.elements['output/movie[@path]'].attribute('path').value.gsub('\\', '/'), '.swf')
          @data[:debug_swf_name] = "#{output_name}-debug.swf"
          @data[:test_swf_name] = "#{output_name}-test.swf"
          @data[:build_options] = {
            'as3' => true,
            'class_name' => File.basename(root.elements['compileTargets/compile[@path]'].attribute('path').value.gsub('\\', '/'), '.as'),
            'default_size' => "#{root.elements['output/movie[@width]'].attribute('width').value} #{root.elements['output/movie[@height]'].attribute('height').value}",
            'source_path' => root.elements['classpaths/class'].collect {|node| node.attribute('path').gsub('\\', '/') },
            #'library_path' => root.elements['libraryPaths/element[@path]'].collect {|node| node.attribute('path').gsub('\\', '/') }
            #'include_libraries' => root.elements['includeLibraries/element[@path]'].collect {|node| node.attribute('path').gsub('\\', '/') }
            #'external_library_path' => root.elements['externalLibraryPaths/element[@path]'].collect {|node| node.attribute('path').gsub('\\', '/') }
            #'rsl' => root.elements['rslPaths/element[@path]'].collect {|node| node.attribute('path').gsub('\\', '/') }
          }

          # Build options
          root.elements['build'].elements.each do |option|
            value = option.attributes.first[1]
            next if value.empty?

            # Transform default boolean values
            value = ((value.index(/true/i)) ? true : false) if value =~ /true|false/i
            next if value == 0

            option_name = option.attributes.first[0].gsub(/[A-Z]/, '-\0').downcase.gsub('-', '_')
            @data[:build_options][option_name] = value
          end

          @data
        end

        protected
        def mxmlc_options
          rake_statements = ""
          @data[:build_options].each_pair do |k, value|
            assignment = (value.kind_of?(Array)) ? '<<' : '='
            values = value.kind_of?(Array)? value : [value]
            values.each do |v|
              rake_statements += "\tt.#{k} #{assignment} #{v.inspect}\n"
            end
          end
          rake_statements
        end

      end
    end
  end
end
