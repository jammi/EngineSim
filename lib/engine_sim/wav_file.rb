
require 'bindata'

class WAVFile < BinData::Record
  endian :little
  string :ckId, :value => 'RIFF'
  uint32 :cksize, :value => lambda { data.length + 4 + 24 + 8 }
  string :waveid, :value => 'WAVE'
  string :fmt_ckId, :value => 'fmt '
  uint32 :fmt_cksize, :value => 16
  uint16 :pcm_format, :value => 0x0001
  uint16 :pcm_channels, :value => 2
  uint32 :pcm_samplerate, :value => 44100
  uint32 :pcm_bps, :value => 16*44100
  uint16 :pcm_block_align, :value => 32
  uint16 :pcm_bits_per_sample, :value => 16
  string :data_ckId, :value => 'data'
  uint32 :data_cksize, :value => lambda { data.length }
  string :data
end

