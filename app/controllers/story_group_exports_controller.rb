# frozen_string_literal: true

class StoryGroupExportsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!

  def show
    @export_form_data = {
      controller:                'csv-export',
      csv_export_base_url_value: download_story_group_export_path(@story_group),
      action:                    'submit->csv-export#download',
    }
  end

  def download
    resource = params[:resource].to_s
    unless Csv::StoryGroupExport.supports?(resource)
      raise ActionController::BadRequest, t('story_group_exports.flash.unknown_resource')
    end

    csv = Csv::StoryGroupExport.new(story_group: @story_group).csv_for(resource)

    send_data "#{Csv::Utf8Bom}#{csv}",
              filename:    "#{resource}.csv",
              type:        'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end
end
