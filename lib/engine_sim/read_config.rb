def read_config( config_name )
  config_name = config_name.to_s if config_name.class == Symbol
  base_path = File.expand_path( $0 )
  2.times do
    base_path = File.split( base_path ).first
  end
  if config_name.start_with?('/')
    ( config_path, config_name ) = File.split( config_path, config_name )
  elsif config_name.include?('/')
    config_path = File.expand_path( config_name, base_path )
    ( config_path, config_name ) = File.split( config_path, config_name )
  else
    asset_path = File.expand_path( 'assets', base_path )
    config_path = File.expand_path( 'config', asset_path )
  end
  unless File.exist?( config_path )
    warn "No such directory: #{config_path}"
    return {}
  end
  if config_name.end_with?('.yaml')
    config_file = config_name
  else
    config_file = config_name + '.yaml'
  end
  config_file_path = File.expand_path( config_file, config_path )
  unless File.exist?( config_file_path )
    warn "No such config file: #{config_file_path}"
    return {}
  end
  config_yaml = YAML.load_file( config_file_path )
  parse_config( config_yaml )
end
def parse_config( config_in )
  config = {}
  validation = {
    :verbose => [ TrueClass, FalseClass ],
    :rpm => [ Fixnum, Float ],
    :cam_crank_ratio => [ Fixnum, Float ],
    :cam_sector_skip => [ Fixnum ],
    :cam_sector_offset => [ Float ],
    :cam_pattern_scale => [ Fixnum, Float ],
    :cam_pattern => [ String, Symbol ],
    :crank_sector_skip => [ Fixnum ],
    :crank_sector_offset => [ Float ],
    :crank_pattern => [ String, Symbol ],
    :sample_rate => [ Fixnum ],
    :len_seconds => [ Fixnum, Float ],
    :destination_file => [ String ]
  }
  valid_keys = validation.keys + validation.keys.map { |k| k.to_s }
  config_in.each do | config_key, config_value |
    unless valid_keys.include?( config_key )
      warn "Invalid config key: #{config_key.inspect}"
      next
    end
    config_key = config_key.to_sym unless config_key.class == Symbol
    valid_types = validation[ config_key ]
    config_class = config_value.class
    unless valid_types.include?( config_class )
      warn "Invalid config value: #{config_value.inspect}"
      next
    end
    prefer_class = valid_types[-1]
    if prefer_class != config_class
      if config_class == String and prefer_class == Symbol
        config_value = config_value.to_sym
      elsif config_class == Symbol and prefer_class == String
        config_value = config_value.to_s
      elsif config_class == Fixnum and prefer_class == Float
        config_value = config_value.to_f
      elsif config_class == Fixnum and prefer_class == Float
        config_value = config_value.round
      elsif config_class != TrueClass and config_class != FalseClass
        warn "Unable to convert config value: #{config_value.inspect}"
      end
    end
    config[ config_key ] = config_value
  end
  return config
end