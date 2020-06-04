require 'w3c_validators'

include W3CValidators

RSpec::Matchers.define :have_w3c_valid_html do |_|
  validator = NuValidator.new(:validator_uri => 'http://localhost:8888/')

  match do |page|
    results = validator.validate_text(page.html)

    results.errors.length == 0
  end

  failure_message do |page|
    results = validator.validate_text(page.html)
    "url #{page.current_path} should have valid HTML:\n" + results.errors.join("\n")
  end
end

feature 'usager', js: true do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_service, :for_individual, :published) }
  let(:password) { 'a very complicated password' }
  let(:litteraire_user) { create(:user, password: password) }

  scenario 'the homepage has valid HTML' do
    visit root_path
    expect(page).to have_w3c_valid_html
  end

  scenario 'the sign_up pages have valid HTML' do
    visit new_user_registration_path
    expect(page).to have_w3c_valid_html

    fill_in :user_email, with: "some@email.com"
    fill_in :user_password, with: "epeciusetuir"

    perform_enqueued_jobs do
      click_button 'Créer un compte'
      expect(page).to have_w3c_valid_html
    end
  end

  scenario 'the sign_in page has valid HTML' do
    visit new_user_session_path
    expect(page).to have_w3c_valid_html
  end

  scenario 'the commencer page has valid HTML' do
    visit commencer_path(path: procedure.reload.path)
    expect(page).to have_w3c_valid_html
  end

  # def user_send_dossier(user)
  #   login_as user, scope: :user
  #   visit commencer_path(path: procedure.reload.path)
  #
  #   check_html(page)
  #
  #   click_on 'Commencer la démarche'
  #   check_html(page)
  #
  #   choose 'M.'
  #   fill_in 'individual_nom',    with: 'Nom'
  #   fill_in 'individual_prenom', with: 'Prenom'
  #   click_button('Continuer')
  #
  #   click_on 'Déposer le dossier'
  #   expect(page).to have_text('Merci')
  #
  #   check_html(page)
  # end
end
