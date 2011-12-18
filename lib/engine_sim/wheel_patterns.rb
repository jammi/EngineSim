
def read_patterns
  base_path = File.expand_path( $0 )
  2.times do
    base_path = File.split( base_path ).first
  end
  asset_path = File.expand_path( 'assets', base_path )
  wheel_path = File.expand_path( 'trigger_wheels', asset_path )
  patterns = {}
  sectors_key = 'sectors'
  type_key = 'type'
  pattern_key = 'pattern'
  repeat_key = 'repeat'
  wheel_types = [ :even, :missing_tooth, :distributor ]
  Dir.entries( wheel_path ).each do |fn|
    next unless fn.end_with?('.yaml')
    wheel_name = fn[0..-6].to_sym
    yaml_path = File.expand_path( fn, wheel_path )
    unless File.file?( yaml_path )
      warn "Skipping, because not a file: #{fn}"
      next
    end
    unless File.readable?( yaml_path )
      warn "Skipping, because no read permissions: #{fn}"
      next
    end
    yaml_data = YAML.load_file( yaml_path )
    wheel_type = yaml_data[type_key].to_sym
    unless wheel_types.include?( wheel_type )
      warn "Skipping unknown wheel type: #{yaml_data['type']}"
      next
    end
    wheel_data = {
      :sectors => yaml_data[sectors_key],
      :type => yaml_data[type_key].to_sym,
      :pattern => []
    }
    pattern_data = []
    invalid = false
    yaml_data[pattern_key].each do |item|
      if item.class == Hash and item.has_key?(repeat_key)
        arr = item[repeat_key]
        num_repeat = arr.shift
        unless num_repeat.class == Fixnum
          warn "Skipping wheel #{fn}, because invalid repeat number: #{num_repeat.inspect}"
          invalid = true
          break
        end
        pattern_data += (arr * num_repeat)
      elsif item.class == Array and item.length == 2
        pattern_data.push( item )
      else
        warn "Skipping wheel #{fn}, because invalid pattern item: #{item.inspect}"
        invalid = true
        break
      end
    end
    next if invalid
    wheel_data[:pattern] = pattern_data
    patterns[wheel_name] = wheel_data
  end
  patterns
end
