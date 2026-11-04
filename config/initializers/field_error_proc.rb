# frozen_string_literal: true

ActionView::Base.field_error_proc = proc { |html_tag, _instance| html_tag }
