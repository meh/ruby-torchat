#--
# Copyleft meh. [http://meh.paranoid.pk | meh@paranoici.org]
#
# This file is part of torchat for ruby.
#
# torchat for ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# torchat for ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with torchat for ruby. If not, see <http://www.gnu.org/licenses/>.
#++

class Torchat

class Avatar
	attr_writer :rgb, :alpha

	def to_image
		return unless @rgb

		require 'RMagick'

		RMagick::Image.new(64, 64).tap {|image|
			@rgb.bytes.each_slice(3).with_index {|(r, g, b), index|
				image.pixel_color(index % 64, (index / 64.0).ceil, Pixel.new(r, g, b, @alpha ? @alpha[index] : nil))
			}
		}
	end
end

end
