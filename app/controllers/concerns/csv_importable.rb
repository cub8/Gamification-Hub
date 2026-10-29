# frozen_string_literal: true

module CsvImportable
  extend ActiveSupport::Concern

  def new_import; end

  def import
    file = params[:file]
    return render_upload_error('Wybierz plik CSV.') unless file

    @preset = Csv::GroupPresetParser.new({ import_resource_key => file }, story_group: @story_group).call
    return render_upload_error('Plik nie zawierał żadnych danych.') if @preset.none?

    dry_run_build(@preset)
    render :import_preview
  rescue Csv::MalformedFile
    render_upload_error('Plik ma niepoprawny format - musi się zgadzać z formatem poniżej.')
  rescue StarterPackBuilder::InvalidSelection => e
    render_upload_error(e.message)
  rescue ActiveRecord::RecordInvalid => e
    render_upload_error("Plik zawiera dane, które się nie zapiszą: #{e.record.errors.full_messages.to_sentence}")
  end

  def confirm_import
    preset = Csv::PresetParams.new(params[:setup], story_group: @story_group).call
    StarterPackBuilder.new(story_group: @story_group, preset: preset).call

    flash_options = { notice: 'Zaimportowano dane z pliku CSV.', alert: warning_message(preset.warnings) }
    redirect_outside_turbo_frame import_redirect_path, **flash_options
  rescue StarterPackBuilder::InvalidSelection => e
    redirect_with_import_alert(e.message)
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_import_alert("Import się nie powiódł: #{e.record.errors.full_messages.to_sentence}")
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
