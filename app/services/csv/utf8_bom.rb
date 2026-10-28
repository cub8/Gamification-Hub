# frozen_string_literal: true

module Csv
  Utf8Bom = [0xEF, 0xBB, 0xBF].pack('C*').force_encoding(Encoding::UTF_8).freeze
end
