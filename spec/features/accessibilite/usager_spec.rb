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

  context 'pages without the need to be logged in' do
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

    scenario 'the contact page has valid HTML' do
      visit contact_path
      expect(page).to have_w3c_valid_html
    end

    scenario 'the commencer page has valid HTML' do
      visit commencer_path(path: procedure.reload.path)
      expect(page).to have_w3c_valid_html
    end
  end

  context "logged in, depot d'un dossier" do

  end

  context "logged in, avec des dossiers dossiers déposés" do
    let(:dossier) { create(:dossier, procedure: procedure, user: litteraire_user) }
    before do
      login_as litteraire_user, scope: :user
    end

    scenario 'liste des dossiers' do
      visit dossiers_path
      expect(page).to have_w3c_valid_html
    end

    scenario 'dossier' do
      visit dossier_path(dossier)
      expect(page).to have_w3c_valid_html
    end

    scenario 'merci' do
      visit merci_dossier_path(dossier)
      expect(page).to have_w3c_valid_html
    end

    scenario 'demande' do
      visit demande_dossier_path(dossier)
      expect(page).to have_w3c_valid_html
    end

    scenario 'messagerie' do
      visit messagerie_dossier_path(dossier)
      expect(page).to have_w3c_valid_html
    end
  end

  # todo: ajouter les tests sur les pages logguées
  # Pages logguées:
  #   - identité
  #    - personne physique
  #    - personne morale
  #     (+ écran de récap d'un établissement)
  # - formulaire de dépot de dossier:
  #   - depot initial
  #   - modifier
  #   - brouillon
  # - x merci
  # - x liste des dossiers
  # - x résumé
  # - x demande
  # - x messagerie
  #
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
