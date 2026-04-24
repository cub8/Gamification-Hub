# frozen_string_literal: true

class ShopController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_read!

  def index; end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end
end
