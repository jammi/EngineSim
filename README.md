
# About EngineSim

EngineSim is an engine signal generator to be used for testing of engine control units and engine management systems.
Currently, just a couple of encoder wheels are supplied and EngineSim's gen_audio_sample utility is can to produce wav audio files based on that output. Cam shaft signal is generated on the left audio channel and crank shaft signal is generated on the right audio channel.


## Installation and dependencies

Just install ruby and add install the *bindata* gem. EngineSim does not depend on any system-specific dependencies (yet).


## TODO

* Implement more features
* Write signal generation parts in C
* Implement simulator complete suite: throttle position sensor, lambda sensor, temperature sensors, air flow sensors, etc.
* Hardware adapter interfaces for capturing cam/crank signals from actual engines


## Credits and copyright

Copyright 2011 Juha-Jarmo Heinonen

EngineSim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [GNU General Public License](http://www.gnu.org/licenses/gpl.html) for more details.
