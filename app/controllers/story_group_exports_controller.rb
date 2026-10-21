# frozen_string_literal: true

class StoryGroupExportsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!

  UTF8_BOM = [0xEF, 0xBB, 0xBF].pack('C*').force_encoding(Encoding::UTF_8).freeze

  def show
    @export_form_data = {
      controller:                'csv-export',
      csv_export_base_url_value: download_story_group_export_path(@story_group),
      action:                    'submit->csv-export#download',
    }
  end

  def download
    resource = params[:resource].to_s
    raise ActionController::BadRequest, 'Nieznany typ eksportu.' unless Csv::StoryGroupExport.supports?(resource)

    csv = Csv::StoryGroupExport.new(story_group: @story_group).csv_for(resource)

    send_data csv + UTF8_BOM,
              filename:    "#{resource}.csv",
              type:        'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end
end
