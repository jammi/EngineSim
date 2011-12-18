
=begin
### Debugging settings:
verbose:          true  # whether to display verbose output or be silent
### Engine settings:
rpm:              1000  # engine speed in revolutions per minute
cam_crank_ratio:  2.0   # 4-stroke: 2.0, 2-stroke: 1.0
### Cam wheel settings:
cam_sector_skip:    0    # amount of cam sectors to initially skip
cam_sector_offset:  0.0  # initial cam tooth position in cam sectors (0.0 to 1.0)
cam_pattern:        missing_24_1 # name of cam pattern
### Crank wheel settings:
crank_sector_skip:   0     # amount of crank sectors to initially skip
crank_sector_offset: 0.0   # initial crank tooth in crank sector ratios (0.0 to 1.0)
crank_pattern:      missing_60_2 # name of crank pattern
### PCM Settings
sample_rate:      44100 # Hz
### Audio output settings
len_seconds:      0.12  # length of audio clip; 0.12 seconds is one cam revolution at 1000 rpm on a 4-stroke engine
destination_file: assets/samples/test.wav # path of destination file
=end

def usage
  puts %{
Usage: #{$0} [OPTIONS] OUTPUT_FILE.wav

OUTPUT_FILE:             The destination sample audio output filename, must end with .wav

OPTIONS:
--verbose                Enable verbose output
--rpm 2000               Set engine speed in revolutions per minute (default: 1000)
--time 2.40              Set sample audio clip time (default: 0.12 which is 1 cam rotation)
--cam even_72            Set the cam pattern (default: missing_24_1)
--camskip 6              Coarse-tune cam start position in number of sectors (usually teeth, default: 0)
--camfine -0.25          Fine-tune cam start position in a fraction of a sector ( -1.0 to 1.0, default: 0.0)
--crank freeems_decoder  Set the crank pattern (default: missing_60_2)
--crankskip 12           Coarse-tune crank start position in number of sectors (usually teeth, default: 0)
--crankfine 0.34         Fine-tune crank start position in a fraction of a sector ( -1.0 to 1.0, default: 0.0)
--conf my_conf           Extra configuration to use (default is always the baseline); path or file name
--help                   This message

}
  nil
end

def parse_argv
  return usage if ARGV.empty?
  argv_in = {}
  param_name = nil
  expect_param = false
  int_params = [ :cam_sector_skip, :crank_sector_skip, :rpm ]
  float_params = [ :cam_sector_offset, :crank_sector_offset, :len_seconds ]
  sym_params = [ :cam_pattern, :crank_pattern ]
  arr_params = [ :extra_config_files ]
  arg_map = {
    '--rpm' => :rpm,
    '--time' => :len_seconds,
    '--cam'  => :cam_pattern,
    '--camskip' => :cam_sector_skip,
    '--camfine' => :cam_sector_offset,
    '--crank' => :crank_pattern,
    '--crankskip' => :crank_sector_skip,
    '--crankfine' => :crank_sector_offset,
    '--conf' => :extra_config_files
  }
  ARGV.each do |arg|
    if expect_param
      return usage if arg.start_with?('--')
      if int_params.include?( param_name )
        argv_in[param_name] = arg.to_i
      elsif float_params.include?( param_name )
        argv_in[param_name] = arg.to_f
      elsif arr_params.include?( param_name )
        argv_in[param_name] = [] if argv_in[param_name].nil?
        argv_in[param_name].push( arg )
      else
        argv_in[param_name] = arg
      end
      expect_param = false
      param_name = nil
    elsif arg.start_with?('--')
      if arg == '--help'
        return usage
      elsif arg == '--verbose'
        argv_in[:verbose] = true
      elsif arg_map.include?( arg )
        param_name = arg_map[arg]
        expect_param = true
      else
        warn "ERROR: Invalid option: #{arg}"
        return usage
      end
    elsif arg.end_with?('.wav')
      argv_in[:destination_file] = arg
    else
      warn "ERROR: Invalid param: #{arg}"
      return usage
    end
  end
  return argv_in
end

