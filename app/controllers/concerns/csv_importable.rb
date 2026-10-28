# frozen_string_literal: true

module CsvImportable
  extend ActiveSupport::Concern

  def new_import; end

  def import
    file = params[:file]
    return redirect_with_import_alert('Wybierz plik CSV.') unless file

    preset = Csv::GroupPresetParser.new({ import_resource_key => file }, story_group: @story_group).call
    return redirect_with_import_alert('Plik nie zawierał żadnych danych.') if preset.none?

    StarterPackBuilder.new(story_group: @story_group, preset: preset).call

    flash_options = { notice: 'Zaimportowano dane z pliku CSV.', alert: warning_message(preset.warnings) }
    redirect_outside_turbo_frame import_redirect_path, **flash_options
  rescue Csv::MalformedFile
    redirect_with_import_alert('Nie udało się odczytać pliku CSV.')
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_import_alert("Import się nie powiódł: #{e.record.errors.full_messages.to_sentence}")
  end

  private

  def redirect_with_import_alert(message)
    redirect_outside_turbo_frame import_redirect_path, alert: message
  end

  def warning_message(warnings)
    warnings.join(' ') if warnings.any?
  end
end
