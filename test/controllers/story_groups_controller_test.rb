# frozen_string_literal: true

require 'test_helper'

class StoryGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = FactoryBot.create(:user, role: :teacher)
    sign_in @current_user
    @story_group = FactoryBot.create(:story_group, owner: @current_user)
  end

  test 'should get index' do
    get story_groups_url
    assert_response :success
  end

  test 'should get new' do
    get new_story_group_url
    assert_response :success
  end

  test 'should create story_group' do
    assert_difference('StoryGroup.count') do
      post story_groups_url,
           params: {
             story_group: {
               currency_name: @story_group.currency_name,
               description:   @story_group.description,
               name:          @story_group.name,
             },
           }
    end

    assert_redirected_to created_story_group_url(StoryGroup.last)
  end

  test 'creates a story group from uploaded CSV files when the setup path is csv' do
    assert_difference('StoryGroup.count') do
      assert_difference('Rank.count', 2) do
        post story_groups_url,
             params: {
               story_group: { currency_name: 'Grosze', description: '', name: 'Zakon CSV' },
               setup:       { path: 'csv', csv: { ranks: fixture_file_upload('ranks_import.csv', 'text/csv') } },
             }
      end
    end

    assert_redirected_to created_story_group_url(StoryGroup.last)
  end

  test 'creates an empty story group when the csv path is chosen but no files are uploaded' do
    assert_difference('StoryGroup.count') do
      assert_no_difference('Rank.count') do
        post story_groups_url,
             params: {
               story_group: { currency_name: 'Grosze', description: '', name: 'Zakon pusty' },
               setup:       { path: 'csv' },
             }
      end
    end

    assert_redirected_to created_story_group_url(StoryGroup.last)
  end

  test 'creates the group when an item references a rank that was never uploaded, matching the preview' do
    file = StringIO.new(<<~CSV)
      nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
      Tarcza,Opis,,42,nie,shield,Widmo (999),,,
    CSV
    upload = Rack::Test::UploadedFile.new(file, 'text/csv', original_filename: 'items.csv')

    assert_difference('StoryGroup.count') do
      assert_difference('Item.count', 1) do
        post story_groups_url,
             params: {
               story_group: { currency_name: 'Grosze', description: '', name: 'Zakon warn' },
               setup:       { path: 'csv', csv: { items: upload } },
             }
      end
    end

    assert_redirected_to created_story_group_url(StoryGroup.last)
    assert_nil Item.last.unlock_rank
  end

  test 'rerenders new with an alert when a CSV file in the wizard is unparseable' do
    assert_no_difference('StoryGroup.count') do
      post story_groups_url,
           params: {
             story_group: { currency_name: 'Grosze', description: '', name: 'Zakon CSV' },
             setup:       { path: 'csv', csv: { ranks: fixture_file_upload('malformed_import.csv', 'text/csv') } },
           }
    end

    assert_response :unprocessable_content
    assert_select 'input[name="setup[path]"][value="csv"][checked]'
    assert_select '[data-group-wizard-target="baseError"]'
  end

  test 'csv_preset_preview renders the parsed rows inside the shared modal frame, with confirm/cancel' do
    assert_no_difference('StoryGroup.count') do
      post csv_preset_preview_story_groups_url,
           params: {
             resource: 'ranks',
             setup:    { csv: { ranks: fixture_file_upload('ranks_import.csv', 'text/csv') } },
           }
    end

    assert_response :success
    assert_select 'turbo-frame#modal' do
      assert_select '.gh-preset-row-name b', text: 'Srebro'
      assert_select 'button', text: 'Zatwierdź'
      assert_select 'button[data-csv-cancel-resource-value=?]', 'ranks', text: 'Anuluj'
    end
  end

  test 'csv_preset_preview reports a duplicate rank threshold inside the modal, with only an OK button' do
    assert_no_difference('StoryGroup.count') do
      post csv_preset_preview_story_groups_url,
           params: {
             resource: 'ranks',
             setup:    { csv: { ranks: fixture_file_upload('duplicate_threshold_ranks_import.csv', 'text/csv') } },
           }
    end

    assert_response :success
    assert_select 'turbo-frame#modal' do
      assert_select '.gh-field-error', text: /nie mogą mieć tego samego progu/i
      assert_select 'button', text: 'OK'
      assert_select 'button', text: 'Zatwierdź', count: 0
    end
  end

  test 'csv_preset_preview reports an unparseable file inside the modal' do
    assert_no_difference('StoryGroup.count') do
      post csv_preset_preview_story_groups_url,
           params: {
             resource: 'ranks',
             setup:    { csv: { ranks: fixture_file_upload('malformed_import.csv', 'text/csv') } },
           }
    end

    assert_response :success
    assert_select 'turbo-frame#modal .gh-field-error', text: /nie udało się odczytać/i
  end

  test 'csv_preset_preview renders an empty modal when the requested resource has no file' do
    post csv_preset_preview_story_groups_url, params: { resource: 'ranks', setup: { csv: {} } }

    assert_response :success
    assert_select 'turbo-frame#modal'
    assert_select '.gh-preset-row', false
    assert_select '.gh-field-error', false
  end

  test 'csv_preset_preview rejects an unknown resource' do
    post csv_preset_preview_story_groups_url, params: { resource: 'nope', setup: { csv: {} } }

    assert_response :not_found
  end

  test 'csv_preset_preview shows an unresolved item reference as a warning, not an error' do
    file = StringIO.new(<<~CSV)
      nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
      Tarcza,Opis,,42,nie,shield,Widmo (999),,,
    CSV
    upload = Rack::Test::UploadedFile.new(file, 'text/csv', original_filename: 'items.csv')

    assert_no_difference('StoryGroup.count') do
      post csv_preset_preview_story_groups_url, params: { resource: 'items', setup: { csv: { items: upload } } }
    end

    assert_response :success
    assert_select 'turbo-frame#modal' do
      assert_select '.gh-field-error', text: /nie znaleziono rangi/i
      assert_select '.gh-preset-row-name b', text: 'Tarcza'
      assert_select 'button', text: 'Zatwierdź'
    end
  end

  test 'csv_preset_preview resolves an item rank reference against a rank from the same batch' do
    ranks_file = StringIO.new(<<~CSV)
      nazwa,próg_waluty,zniżka,ikona
      Złoto,500,15,chev2
    CSV
    items_file = StringIO.new(<<~CSV)
      nazwa,opis_dydaktyczny,opis_fabularny,cena,można_kupić_przy_0_życiach,ikona,ranga_odblokowująca,ranga_minimalna_dla_zniżki,odznaki_odblokowujące,odznaki_dla_zniżki
      Tarcza,Opis,,42,nie,shield,Złoto (500),,,
    CSV

    assert_no_difference('StoryGroup.count') do
      post csv_preset_preview_story_groups_url,
           params: {
             resource: 'items',
             setup:    {
               csv: {
                 ranks: Rack::Test::UploadedFile.new(ranks_file, 'text/csv', original_filename: 'ranks.csv'),
                 items: Rack::Test::UploadedFile.new(items_file, 'text/csv', original_filename: 'items.csv'),
               },
             },
           }
    end

    assert_response :success
    assert_select 'turbo-frame#modal' do
      assert_select '.gh-field-error', false
      assert_select '.gh-preset-row-name small', text: /Wymaga: Złoto/
    end
  end

  test 'csv_preset_preview escapes html-unsafe content coming from the uploaded file' do
    file = StringIO.new(<<~CSV)
      nazwa,próg_waluty,zniżka,ikona
      "<script>alert(1)</script>",200,5,chev1
    CSV
    upload = Rack::Test::UploadedFile.new(file, 'text/csv', original_filename: 'ranks.csv')

    post csv_preset_preview_story_groups_url, params: { resource: 'ranks', setup: { csv: { ranks: upload } } }

    assert_no_match(/<script>alert/, response.body)
    assert_match('&lt;script&gt;', response.body)
  end

  test 'should show story_group' do
    get story_group_url(@story_group)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_group_url(@story_group)
    assert_response :success
  end

  test 'should update story_group' do
    patch story_group_url(@story_group),
          params: {
            story_group: {
              currency_name: @story_group.currency_name,
              description:   @story_group.description,
              name:          @story_group.name,
            },
          }
    assert_redirected_to edit_story_group_url(@story_group)
  end

  test 'should get confirm_destroy' do
    get confirm_destroy_story_group_url(@story_group)
    assert_response :success
  end

  test 'should destroy story_group' do
    assert_difference('StoryGroup.count', -1) do
      delete story_group_url(@story_group), params: { confirm: @story_group.name }
    end

    assert_redirected_to story_groups_url
  end

  test 'destroying from the dialog breaks out of the frame' do
    assert_difference('StoryGroup.count', -1) do
      delete story_group_url(@story_group),
             params:  { confirm: @story_group.name },
             headers: { 'Turbo-Frame' => 'modal' }
    end

    assert_turbo_redirected_to story_groups_url
  end

  test 'should not destroy story_group without the typed name' do
    assert_no_difference('StoryGroup.count') do
      delete story_group_url(@story_group), params: { confirm: 'coś innego' }
    end

    assert_response :unprocessable_content
  end
end
