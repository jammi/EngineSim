
require 'yaml'

class PCMGenerator
  VOL = 2**15-256 # 0 - 2**15-1
  VOL_REV = 0x8000-VOL
  ON = 0x7fff - VOL_REV
  OFF = 0x8000 + VOL_REV
  require 'engine_sim/read_config'
  DEFAULT_ARGS = read_config( :default )
  require 'engine_sim/wheel_patterns'
  TIMING_PATTERNS = read_patterns
  require 'engine_sim/wav_file'
  def init_pcm_data
    @pcm_data = BinData::Array.new( :type => :uint16le )
  end
  def init_args( args )
    @rpm = args[:rpm].to_f # crank rotations per minute
    @sample_rate = args[:sample_rate].to_f # sampling frequency
    @cam_crank_ratio = args[:cam_crank_ratio] # crank revolutions per cam revolution
    @len_seconds = args[:len_seconds].to_f # length of pcm clip to make
    @cam_sector_offset = args[:cam_sector_offset].to_f # 0..1 sectors
    @crank_sector_offset = args[:crank_sector_offset].to_f # 0..1 sectors
    @cam_sector_skip = args[:cam_sector_skip].round # number of tooth to skip before generating
    @crank_sector_skip = args[:crank_sector_skip].round # number of tooth to skip before generating
  end
  def setup_patterns( crank_name, cam_name )
    unless TIMING_PATTERNS.has_key?( crank_name )
      warn "Invalid crank: #{crank_name.inspect}"
      exit
    end
    crank_pattern = TIMING_PATTERNS[ crank_name ]
    @crank_sectors = crank_pattern[:sectors]
    @crank_sectors *= @cam_crank_ratio if crank_pattern[:type] != :distributor
    @crank_pattern = crank_pattern[:pattern]
    unless TIMING_PATTERNS.has_key?( cam_name )
      warn "Invalid cam: #{cam_name.inspect}"
      exit
    end
    cam_pattern = TIMING_PATTERNS[ cam_name ]
    @cam_sectors = cam_pattern[:sectors]
    @cam_pattern = cam_pattern[:pattern]
  end
  def calc_params
    @sample_length = 1.0/@sample_rate # length of a single sample, in seconds
    @rps = @rpm/60.0 # crank rotations per second
    @crank_rev_time = 1.0/@rps
    @cam_rps = @rps/@cam_crank_ratio # cam rotations per second
    @cam_rev_time = 1.0/@cam_rps # time per cam revolution
    @cam_sector_time = @cam_rev_time / @cam_sectors # how long an 'on' or 'off' state takes
    @cam_offset_time = @cam_sector_time * @cam_sector_offset # how far the cam state has proceeded at tdc
    @crank_sector_time = @cam_rev_time * (1.0/@crank_sectors)
    @crank_offset_time = @crank_sector_time * @crank_sector_offset
  end
  def cycle_pattern( pattern, pattern_state_seconds, position, position_end )
    ( length, state ) = pattern.shift
    pattern.push( [ length, state ] )
    position_over = position - position_end
    pattern_seconds = pattern_state_seconds*length
    return [ state, position+pattern_seconds-position_over ]
  end
  def skip_pattern( pattern, sector_count )
    return 0 if sector_count == 0.0
    sectors_skipped = 0.0
    while sectors_skipped <= sector_count
      ( length, state ) = pattern.shift
      sectors_skipped += length
      pattern.push( [ length, state ] )
    end
    skip_offset = sectors_skipped - sector_count
    if skip_offset != 0
      pattern.unshift( pattern.pop )
      skip_offset -= pattern.first.first
    end
    return skip_offset
  end
  def simulate
    crank_skip_offset = skip_pattern( @crank_pattern, @crank_sector_skip )
    if crank_skip_offset != 0
      print "crank_skip_offset: #{crank_skip_offset.inspect}; #{@crank_offset_time} -> "
      @crank_offset_time += ( @crank_sector_time * crank_skip_offset )
      puts @crank_offset_time
    end
    cam_skip_offset = skip_pattern( @cam_pattern, @cam_sector_skip )
    if cam_skip_offset != 0
      print "cam_skip_offset: #{cam_skip_offset.inspect}; #{@cam_offset_time} -> "
      @cam_offset_time += ( @cam_sector_time * cam_skip_offset )
      puts @cam_offset_time
    end
    position = 0.0
    cam_rev = 0
    cam_rev_end = position + @cam_rev_time + @cam_offset_time
    crank_rev = 0
    crank_rev_end = position + @crank_rev_time + @crank_offset_time
    cam_tooth = 0
    end_position = @len_seconds+@sample_length
    ( crank_state, crank_state_end ) = cycle_pattern( @crank_pattern, @crank_sector_time, position, @crank_offset_time )
    ( cam_state, cam_state_end ) = cycle_pattern( @cam_pattern, @cam_sector_time, position, @cam_offset_time )
    if @verbose
      puts "crank rev secs: #{@crank_rev_time}"
      puts "cam rev secs: #{@cam_rev_time}"
      print "." if cam_state
    end
    while position <= end_position
      unless position <= cam_state_end
        ( cam_state, cam_state_end ) = cycle_pattern( @cam_pattern, @cam_sector_time, position, cam_state_end )
        unless cam_state
          cam_tooth += 1
        end
        print "." if @verbose
      end
      unless position <= crank_state_end
        ( crank_state, crank_state_end ) = cycle_pattern( @crank_pattern, @crank_sector_time, position, crank_state_end )
        print ":" if @verbose
      end
      unless position < crank_rev_end
        crank_rev += 1
        crank_rev_over = position-crank_rev_end
        crank_rev_end = position + @crank_rev_time - crank_rev_over
      end
      unless position <= cam_rev_end
        cam_rev += 1
        cam_rev_over = position-cam_rev_end
        cam_rev_end = position + @cam_rev_time - cam_rev_over
        if @verbose
          puts
          puts "cam tooth: #{cam_tooth}"
          puts "crank rev: #{crank_rev}"
          puts "cam rev: #{cam_rev}"
        end
        cam_tooth = 0
      end
      if cam_state
        @pcm_data.push ON
      else
        @pcm_data.push OFF
      end
      if crank_state
        @pcm_data.push ON
      else
        @pcm_data.push OFF
      end
      position += @sample_length
    end
    puts if @verbose
  end
  def write_wav( data, filename )
    wav = WAVFile.new
    wav.data = data.to_binary_s
    File.open( filename, 'wb' ) do |io|
      wav.write( io )
    end
  end
  def initialize( args )
    if args.has_key?( :extra_config_files )
      extra_conf = args[:extra_config_files]
      args.delete( :extra_config_files )
      extra_conf.each do |extra_conf|
        args = read_config( extra_conf ).merge( args )
      end
    end
    args = DEFAULT_ARGS.merge( parse_config( args ) )
    @verbose = args[:verbose]
    init_args( args )
    setup_patterns( args[:crank_pattern], args[:cam_pattern] )
    init_pcm_data
    calc_params
    simulate
    write_wav( @pcm_data, args[:destination_file] )
  end
end
