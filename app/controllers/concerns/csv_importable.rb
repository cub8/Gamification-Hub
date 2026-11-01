# frozen_string_literal: true

module CsvImportable
  extend ActiveSupport::Concern

  def new_import; end

  def import
    file = params[:file]
    return render_upload_error(t('shared.csv_import.select_file')) unless file

    @preset = Csv::GroupPresetParser.new({ import_resource_key => file }, story_group: @story_group).call
    return render_upload_error(t('shared.csv_import.empty_file')) if @preset.none?

    dry_run_build(@preset)
    render :import_preview
  rescue Csv::MalformedFile
    render_upload_error(t('shared.csv_import.malformed_file'))
  rescue StarterPackBuilder::InvalidSelection => e
    render_upload_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    render_upload_error(Csv::Localized.record_invalid_message(e.record))
  end

  def confirm_import
    preset = Csv::PresetParams.new(params[:setup], story_group: @story_group).call
    StarterPackBuilder.new(story_group: @story_group, preset: preset).call

    flash_options = { notice: t('shared.csv_import.imported'), alert: warning_message(preset.warnings) }
    redirect_outside_turbo_frame import_redirect_path, **flash_options
  rescue StarterPackBuilder::InvalidSelection => e
    redirect_with_import_alert(e.message)
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_import_alert(Csv::Localized.record_invalid_message(e.record))
  end

  private

  def dry_run_build(preset)
    ActiveRecord::Base.transaction do
      StarterPackBuilder.new(story_group: @story_group, preset: preset).call
      raise ActiveRecord::Rollback
    end
  end

  def render_upload_error(message)
    @upload_error = message
    render :new_import, status: :unprocessable_content
  end

  def redirect_with_import_alert(message)
    redirect_outside_turbo_frame import_redirect_path, alert: message
  end

  def warning_message(warnings)
    warnings.join(' ') if warnings.any?
  end
end
